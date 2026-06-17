# Review/proposta — SourceHub translated DTO publications

Status: proposta de implementação DDL, não decisão final.
Worker: B — SourceHub DTO DDL implementation proposal.
Escopo alvo: `database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql`.

## 1. Conclusão curta

A implementação de `sourcehub/0002_translated_dto_publications.sql` é viável agora que `prop4you_matrix.transformation_artifacts` existe em `matrix/0002` e o artefato `field_mapping_set` foi formalizado em `matrix/0005`.

Minha recomendação é criar uma tabela SourceHub própria, `prop4you_sourcehub.translated_dto_publications`, com:

- FK obrigatória para `prop4you_sourcehub.raw_records(id)`.
- FK obrigatória para `prop4you_matrix.transformation_artifacts(id)`.
- FK obrigatória para `prop4you_leadfinder.canonical_dictionary_versions(id)`.
- `translated_dto jsonb` como DTO traduzido/revisável, não entidade LeadFinder final.
- hash `translated_dto_sha256` opcional, validado por regex, mas sem fingir canonicalização universal dentro do banco.
- função publish idempotente que faz upsert por chave lógica.
- views de revisão/publicação/gaps.
- linha temporal explícita: T0 raw, T1/T2/T3/T3_5 Matrix/LeadFinder bridge, T4 SourceHub DTO, T5 LeadFinder materialization posterior.

Não recomendo materializar qualquer tabela LFG/LeadFinder nesta fatia. Esta fatia deve publicar somente DTO candidato/auditável em SourceHub.

## 2. Evidência lida no repo

Arquivos revisados:

- `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`
- `database/ddl/projects/prop4you/sourcehub/README.md`
- `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql`
- `database/ddl/projects/prop4you/matrix/0005_field_mapping_set_artifacts.sql`
- `database/ddl/projects/prop4you/leadfinder/0003_prepare_dictionary_promotions.sql`
- `docs/issues/05-prop4you-matrix-artifacts-reiq-raws/10-sourcehub-translated-dto-readiness.md`

Pontos relevantes:

- `sourcehub/0001` já define raw evidence, corpus samples, lineage edges e enrichment queue. Ele não publica DTO final.
- O README de SourceHub já antecipa `translated_dto_publications` e o prefixo `p4yshd`.
- `matrix/0002` congelou o FK natural para artefatos: `prop4you_matrix.transformation_artifacts(id)`.
- `matrix/0005` define o `field_mapping_set` como artifact_kind e declara SourceHub DTO como T4_later, LeadFinder materialization como T5_later.
- `leadfinder/0003` é prepare-only; não materializa famílias/campos finais. Isso reforça que `sourcehub/0002` também deve ser prepare/publish-only, sem LFG materialization.

## 3. Boundaries obrigatórios

A DDL proposta deve declarar no cabeçalho:

```sql
-- package: prop4you/sourcehub
-- file: 0002_translated_dto_publications.sql
-- status: experimental / non-final
-- purpose: SourceHub translated DTO publication records derived from raw SourceHub evidence and approved Matrix artifacts.
-- depends-on: database/ddl/base, prop4you schemas, providers, sourcehub/0001, leadfinder/0001, matrix/0002, matrix/0005
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC] Callable by any gateway/ORM/PostgREST/direct SQL.
-- [NO_PROVIDER_CALLS] No HTTP/provider calls, workers, cron, secrets, or corpus reads.
-- [NO_LFG_MATERIALIZATION] Does not insert/update LeadFinder canonical graph/materialized entities.
-- [SOURCEHUB_T4] Publishes translated DTO records only; LeadFinder materialization remains T5_later.
```

## 4. Tabela recomendada

Nome: `prop4you_sourcehub.translated_dto_publications`.

Campos recomendados:

```sql
create table if not exists prop4you_sourcehub.translated_dto_publications (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4yshd', id)) stored,

  raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict,
  matrix_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict,
  leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict,

  publication_key text not null,
  publication_status text not null default 'candidate',
  publication_kind text not null default 'leadfinder_candidate',
  dto_schema_version text not null default 'sourcehub.translated_dto.v0',

  translated_dto jsonb not null,
  translated_dto_sha256 text,
  source_payload_sha256 text,
  matrix_artifact_sha256 text,

  publication_gate_status text not null default 'ready_for_review',
  rejection_reason_code text,
  rejection_summary text,

  gap_reference_schema name,
  gap_reference_table name,
  gap_reference_id uuid,
  source_lineage_edge_id uuid references prop4you_sourcehub.source_lineage_edges(id) on delete set null,

  temporal_phase jsonb not null default jsonb_build_object(
    'raw_capture','T0',
    'matrix_extraction','T1',
    'leadfinder_gap_bridge','T2',
    'matrix_quality_report','T3',
    'matrix_field_mapping_set','T3_5',
    'sourcehub_dto_publication','T4',
    'leadfinder_materialization','T5_later'
  ),
  metadata jsonb not null default '{}'::jsonb,

  active boolean not null default true,
  activated_at timestamptz,
  deactivated_at timestamptz,
  deleted boolean not null default false,
  deleted_at timestamptz,
  deleted_by_actor_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1,

  constraint translated_dto_publications_public_ref_key unique (public_ref),
  constraint translated_dto_publications_publication_key_key unique (publication_key),
  constraint translated_dto_publications_publication_key_format_chk check (publication_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
  constraint translated_dto_publications_status_chk check (publication_status in ('candidate','blocked','ready_for_review','published','rejected','superseded','archived')),
  constraint translated_dto_publications_kind_chk check (publication_kind in ('leadfinder_candidate','review_snapshot','gap_evidence','regression_fixture_metadata','unknown')),
  constraint translated_dto_publications_schema_version_chk check (dto_schema_version ~ '^[a-z][a-z0-9_.:-]{1,79}$'),
  constraint translated_dto_publications_dto_object_chk check (jsonb_typeof(translated_dto) = 'object'),
  constraint translated_dto_publications_dto_sha256_chk check (translated_dto_sha256 is null or translated_dto_sha256 ~ '^[0-9a-f]{64}$'),
  constraint translated_dto_publications_source_sha256_chk check (source_payload_sha256 is null or source_payload_sha256 ~ '^[0-9a-f]{64}$'),
  constraint translated_dto_publications_artifact_sha256_chk check (matrix_artifact_sha256 is null or matrix_artifact_sha256 ~ '^[0-9a-f]{64}$'),
  constraint translated_dto_publications_gate_status_chk check (publication_gate_status in ('not_started','ready_for_review','passed','blocked','not_applicable')),
  constraint translated_dto_publications_gap_reference_chk check (
    (gap_reference_schema is null and gap_reference_table is null and gap_reference_id is null)
    or
    (gap_reference_schema is not null and gap_reference_table is not null and gap_reference_id is not null)
  ),
  constraint translated_dto_publications_metadata_object_chk check (jsonb_typeof(metadata) = 'object'),
  constraint translated_dto_publications_temporal_phase_object_chk check (jsonb_typeof(temporal_phase) = 'object'),
  constraint translated_dto_publications_published_gate_chk check (publication_status <> 'published' or publication_gate_status = 'passed'),
  constraint translated_dto_publications_version_positive_chk check (version > 0)
);
```

### Observação sobre idempotência e hash

Eu manteria `translated_dto_sha256` opcional por dois motivos:

1. O contrato lido alerta que `jsonb::text` pode não ser uma canonicalização externa suficiente.
2. A pipeline/gateway pode calcular uma serialização canônica fora do banco e persistir o hash.

Para dedupe, usar dois níveis:

```sql
create unique index if not exists translated_dto_publications_hash_dedupe_key
  on prop4you_sourcehub.translated_dto_publications (
    raw_record_id,
    matrix_artifact_id,
    leadfinder_dictionary_version_id,
    translated_dto_sha256
  )
  where translated_dto_sha256 is not null and deleted = false;
```

E `publication_key` como chave idempotente universal quando o hash ainda não existe.

## 5. Índices recomendados

```sql
create index if not exists translated_dto_publications_raw_status_idx
  on prop4you_sourcehub.translated_dto_publications (raw_record_id, publication_status);

create index if not exists translated_dto_publications_matrix_status_idx
  on prop4you_sourcehub.translated_dto_publications (matrix_artifact_id, publication_status);

create index if not exists translated_dto_publications_dictionary_status_idx
  on prop4you_sourcehub.translated_dto_publications (leadfinder_dictionary_version_id, publication_status);

create index if not exists translated_dto_publications_gate_idx
  on prop4you_sourcehub.translated_dto_publications (publication_gate_status, publication_status, created_at desc);

create index if not exists translated_dto_publications_gap_reference_idx
  on prop4you_sourcehub.translated_dto_publications (gap_reference_schema, gap_reference_table, gap_reference_id)
  where gap_reference_id is not null;

create index if not exists translated_dto_publications_dto_gin_idx
  on prop4you_sourcehub.translated_dto_publications using gin (translated_dto jsonb_path_ops);

create index if not exists translated_dto_publications_metadata_gin_idx
  on prop4you_sourcehub.translated_dto_publications using gin (metadata jsonb_path_ops);
```

## 6. Views recomendadas

### 6.1 Review projection

`prop4you_sourcehub.v_translated_dto_publication_review` deve juntar:

- publication id/public_ref/key/status/kind/gate.
- raw record public_ref, provider_id/payload_class_id, raw hash.
- Matrix artifact key/kind/status/gate/schema version.
- LeadFinder dictionary version key/status.
- hashes e timestamps.

Filtro: `p.deleted = false`.

### 6.2 Published/candidate safe projection

`prop4you_sourcehub.v_translated_dto_publication_candidates` pode expor o DTO somente para `publication_status in ('ready_for_review','published')` e `active = true`, mas ainda sem presumir exposição pública. Nome deve deixar claro que é projeção de SourceHub, não facade client final.

### 6.3 Gap projection

`prop4you_sourcehub.v_translated_dto_publication_gaps` para rows `blocked` ou com `gap_reference_id is not null`, ajudando reviewers a voltar para Matrix/LeadFinder sem materializar LFG.

## 7. Função publish recomendada

Nome: `prop4you_sourcehub.publish_translated_dto(...)`.

Assinatura proposta:

```sql
create or replace function prop4you_sourcehub.publish_translated_dto(
  p_raw_record_id uuid,
  p_matrix_artifact_id uuid,
  p_leadfinder_dictionary_version_id uuid,
  p_translated_dto jsonb,
  p_publication_key text default null,
  p_translated_dto_sha256 text default null,
  p_publication_status text default 'ready_for_review',
  p_publication_kind text default 'leadfinder_candidate',
  p_gap_reference_schema name default null,
  p_gap_reference_table name default null,
  p_gap_reference_id uuid default null,
  p_actor_id text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns prop4you_sourcehub.translated_dto_publications
language plpgsql
volatile
as $$
-- proposta: ver corpo abaixo
$$;
```

Regras no corpo:

1. Validar parâmetros nulos: raw, artifact, dictionary, translated_dto.
2. Validar `jsonb_typeof(p_translated_dto) = 'object'`.
3. Buscar `raw_records`; bloquear se `deleted = true`, `review_status` não está aceito ou `leadfinder_publication_status` está `blocked/not_ready`, exceto quando status pedido for `candidate`/`blocked`.
4. Buscar `transformation_artifacts`; exigir `deleted=false`.
5. Para `published`, exigir `artifact_status='approved'` e `artifact_gate_status='passed'`. Para `ready_for_review`, aceitar `artifact_status in ('generated','in_review','approved')` e gate `ready_for_review/passed`.
6. Exigir que `artifact.dictionary_version_id = p_leadfinder_dictionary_version_id`.
7. Buscar `canonical_dictionary_versions`; para `published`, preferir/exigir `version_status in ('approved','active')` se esse vocabulário estiver confirmado no `leadfinder/0001`.
8. Gerar `publication_key` determinístico quando não informado, por exemplo:
   - com hash: `dto:` + raw uuid sem hífen + `:` + artifact uuid sem hífen + `:` + primeiros 16 chars do hash.
   - sem hash: `dto:` + raw uuid sem hífen + `:` + artifact uuid sem hífen + `:` + dictionary uuid sem hífen.
9. Fazer `insert ... on conflict (publication_key) do update`.
10. Retornar a linha.
11. Opcional, mas recomendado: criar/atualizar `source_lineage_edges` com `lineage_kind='candidate_dto_for'` e `derived_object_schema/table/id` apontando para a tabela publication, guardando o id em `source_lineage_edge_id`.

Pseudocorpo essencial:

```sql
-- Buscar raw/artifact/dictionary em variáveis.
-- Validar Matrix gate/status conforme p_publication_status.
-- Validar dictionary_version_id consistente.
-- effective_key := coalesce(nullif(btrim(p_publication_key), ''), generated_key);

insert into prop4you_sourcehub.translated_dto_publications as p (
  raw_record_id,
  matrix_artifact_id,
  leadfinder_dictionary_version_id,
  publication_key,
  publication_status,
  publication_kind,
  dto_schema_version,
  translated_dto,
  translated_dto_sha256,
  source_payload_sha256,
  matrix_artifact_sha256,
  publication_gate_status,
  gap_reference_schema,
  gap_reference_table,
  gap_reference_id,
  temporal_phase,
  metadata,
  last_modified_by_actor_id
) values (
  p_raw_record_id,
  p_matrix_artifact_id,
  p_leadfinder_dictionary_version_id,
  effective_key,
  p_publication_status,
  p_publication_kind,
  'sourcehub.translated_dto.v0',
  p_translated_dto,
  nullif(btrim(p_translated_dto_sha256), ''),
  raw_row.raw_payload_sha256,
  artifact_row.content_sha256,
  case when p_publication_status = 'published' then 'passed' else 'ready_for_review' end,
  p_gap_reference_schema,
  p_gap_reference_table,
  p_gap_reference_id,
  jsonb_build_object(...linha temporal... ),
  jsonb_build_object(
    'source','prop4you_sourcehub.publish_translated_dto',
    'gateway_agnostic',true,
    'no_provider_calls',true,
    'no_lfg_materialization',true,
    'sourcehub_phase','T4',
    'leadfinder_materialization','T5_later'
  ) || coalesce(p_metadata, '{}'::jsonb),
  p_actor_id
)
on conflict (publication_key) do update
  set publication_status = excluded.publication_status,
      publication_kind = excluded.publication_kind,
      translated_dto = excluded.translated_dto,
      translated_dto_sha256 = excluded.translated_dto_sha256,
      source_payload_sha256 = excluded.source_payload_sha256,
      matrix_artifact_sha256 = excluded.matrix_artifact_sha256,
      publication_gate_status = excluded.publication_gate_status,
      gap_reference_schema = excluded.gap_reference_schema,
      gap_reference_table = excluded.gap_reference_table,
      gap_reference_id = excluded.gap_reference_id,
      metadata = p.metadata || excluded.metadata,
      updated_at = now(),
      last_modified_by_actor_id = p_actor_id
returning * into row_out;
```

### Cuidado importante

Se usar a unique index parcial por hash, `on conflict` não deve tentar mirar essa partial index diretamente. O caminho robusto é `on conflict (publication_key)` e a partial unique index fica como guarda adicional.

## 8. Lifecycle, comentários e prefixo

Seguir padrão de `sourcehub/0001`:

```sql
drop trigger if exists translated_dto_publications_set_lifecycle_defaults on prop4you_sourcehub.translated_dto_publications;
create trigger translated_dto_publications_set_lifecycle_defaults
  before insert on prop4you_sourcehub.translated_dto_publications
  for each row execute function base.set_lifecycle_defaults();

-- touch_updated_at
-- increment_version

select base.register_public_id_prefix('p4yshd', 'prop4you_sourcehub', 'translated_dto_publications', 'Prop4You SourceHub translated DTO publication');
```

Adicionar `comment on table`, `comment on column` para todas as colunas e comentários nas views/função/triggers. O texto deve repetir explicitamente que `translated_dto` é DTO publicado/revisável, não entidade LeadFinder materializada.

## 9. Linha temporal proposta

A DDL deve fixar o mapa temporal em comments e metadata:

- T0: SourceHub `raw_records` captura payload bruto/evidência.
- T1: Matrix extrai caminhos/tipos/contagens.
- T2: LeadFinder gap bridge/preparação cruza lacunas e dicionário.
- T3: Matrix quality report.
- T3_5: Matrix `field_mapping_set` artifact (`matrix/0005`).
- T4: SourceHub `translated_dto_publications` publica DTO traduzido e auditável.
- T5_later: LeadFinder/LFG materialization, fora do escopo desta DDL.

## 10. Gateway agnostic

A função publish deve ser SQL/RPC pura. Nada de Django signal, PostgREST-only, provider SDK, job worker ou HTTP. Qualquer gateway deve poder chamar a função com os mesmos argumentos e obter a mesma linha idempotente.

## 11. No LFG materialization

Esta DDL não deve:

- inserir em entidades finais LeadFinder;
- atualizar `canonical_families`/`canonical_fields`;
- promover dictionary preparations;
- gerar owners/properties/leads;
- assumir tabela LFG final.

O único vínculo LeadFinder obrigatório é a FK para `canonical_dictionary_versions(id)` e, opcionalmente, referência flexível de gap via `gap_reference_*`.

## 12. Incertezas / decisões pendentes

1. Confirmar o vocabulário real de `canonical_dictionary_versions.version_status` em `leadfinder/0001` antes de codificar gate rígido para `published`.
2. Definir se `publication_kind='regression_fixture_metadata'` deve permanecer, pois pode soar como fixture; se mantido, comentar que é metadata only e sem payload raw gitado.
3. Definir a canonicalização de `translated_dto_sha256`. Recomendo não calcular automaticamente em SQL nesta fatia; aceitar hash externo validado.
4. Definir RLS/política de exposição antes de qualquer facade pública, pois `translated_dto` pode conter PII.
5. Decidir se a função publish cria lineage edge automaticamente ou se isso fica para função separada. Minha preferência: criar automaticamente com guarda idempotente por metadata/derived_object para preservar linha temporal.

## 13. Veredito

Proposta aprovada conceitualmente para implementação experimental, com a ressalva de que o arquivo SQL final deve ser revisado contra `leadfinder/0001` antes de congelar gates de version_status e antes de expor qualquer view client-facing.

O desenho preserva: tabela, views, função publish, idempotência, hash, linha temporal, gateway agnostic e no LFG materialization.
