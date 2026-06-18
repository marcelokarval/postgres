# Worker C — Revisão DDL registry e prova

Status: complete
Data: 2026-06-18T15:20:41-04:00
Escopo: recomendação/revisão apenas. Não altera DDL existente.

## Leituras feitas

- `database/ddl/projects/prop4you/leadfinder_group/0001_staging_candidates.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0002_materialization_runs.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0003_operational_minimum.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0004_user_feedback_markers.sql`
- `database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql`
- `database/ddl/projects/prop4you/leadfinder/0004_dictionary_promotion_review_apply.sql`
- `scripts/proof-prop4you-ddl-lab.sh`
- `docs/issues/15-prop4you-lfg-canonical-jsonschema-envelope-registry/{00,01,02,04-subagent-manifest}.md`

Também rodei `DRY_RUN=1 scripts/proof-prop4you-ddl-lab.sh` e confirmei a ordem atual de aplicação: base DDL, Prop4You provider/sourcehub/matrix/leadfinder, SourceHub T4, LFG `0001..0004`, e por fim `leadfinder/0004_dictionary_promotion_review_apply.sql`.

## Diagnóstico do DDL atual

O pacote LFG já tem uma boa fundação para encaixar um registry leve:

- Usa schema próprio: `prop4you_leadfinder_group`.
- Mantém boundary explícito: gateway-agnostic, sem provider calls, sem cópia de raw payload.
- Fluxo temporal já está claro:
  - T4 SourceHub `translated_dto_publications`;
  - T5.0 `staging_candidates`;
  - T5.1 `materialization_runs/results`;
  - T5.2 `operational_groups/events/facets`;
  - feedback marker review/apply gate.
- Já usa padrões consistentes que o registry deve repetir:
  - `id uuid default uuidv7()`;
  - `public_ref` gerado via `base.make_public_ref(...)`;
  - `*_key` único e com regex `^[a-z][a-z0-9_.:-]{1,191}$`;
  - status/gate/review enums por `check` simples;
  - JSONB objeto validado por `jsonb_typeof(...)`;
  - lifecycle columns + triggers `base.set_lifecycle_defaults`, `base.touch_updated_at`, `base.increment_version` quando há colunas compatíveis.

Lacuna: os JSONB contracts atuais aparecem como strings em `*_schema_version`, `contract`, `artifact_schema_version` e comentários. Falta uma fonte queryable/canonical para:

- quais envelopes existem;
- qual `$id`/schema version é canônico;
- qual artefato repo-local originou a row;
- como promover JSONB para projeção relacional;
- quais gates são obrigatórios antes de materialização ou auto-apply de markers.

## Recomendação de arquivo DDL

Criar:

`database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql`

Cabeçalho sugerido:

```sql
-- package: prop4you/leadfinder_group
-- file: 0005_canonical_jsonschema_registry.sql
-- status: experimental / non-final
-- purpose: Queryable registry for LFG canonical JSONSchema envelopes and projection policy.
-- depends-on: leadfinder_group/0004_user_feedback_markers.sql
-- idempotency: idempotent
-- destructive: false
-- [GATEWAY_AGNOSTIC]
-- [REGISTRY_ONLY]
-- [NO_PROVIDER_CALLS]
-- [NO_RAW_PAYLOAD_VALUES]
-- [NO_FINAL_PRODUCT_TABLE_EXPLOSION]
```

## Tabelas mínimas

### 1. `prop4you_leadfinder_group.canonical_jsonschema_envelopes`

Tabela mínima para registrar cada envelope/version e o JSONSchema em JSONB.

Colunas recomendadas:

```sql
id uuid primary key default uuidv7(),
public_ref text generated always as (base.make_public_ref('p4ylfgjs', id)) stored,
envelope_key text not null,
envelope_status text not null default 'active',
envelope_kind text not null,
schema_version text not null default 'v1',
schema_id text not null,
schema_title text not null,
schema_path text not null,
schema_sha256 text,
json_schema jsonb not null,
projection_policy_key text,
pii_classification text not null default 'mixed_review_required',
raw_value_policy text not null default 'no_raw_payload_values',
notes text,
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
version integer not null default 1
```

Constraints recomendadas:

```sql
constraint canonical_jsonschema_envelopes_public_ref_key unique (public_ref),
constraint canonical_jsonschema_envelopes_key_version_key unique (envelope_key, schema_version),
constraint canonical_jsonschema_envelopes_schema_id_key unique (schema_id),
constraint canonical_jsonschema_envelopes_key_format_chk check (envelope_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
constraint canonical_jsonschema_envelopes_version_format_chk check (schema_version ~ '^v[0-9]+([.][0-9]+)?$'),
constraint canonical_jsonschema_envelopes_status_chk check (envelope_status in ('draft','active','deprecated','superseded','archived')),
constraint canonical_jsonschema_envelopes_kind_chk check (envelope_kind in ('property','owner','contact_satellites','realtor_evidence','taxonomy','canonical_index','unknown')),
constraint canonical_jsonschema_envelopes_schema_object_chk check (jsonb_typeof(json_schema)='object'),
constraint canonical_jsonschema_envelopes_schema_required_keys_chk check (json_schema ? '$schema' and json_schema ? '$id' and json_schema ? 'title' and json_schema ? 'type'),
constraint canonical_jsonschema_envelopes_schema_type_object_chk check (json_schema->>'type' = 'object'),
constraint canonical_jsonschema_envelopes_additional_props_present_chk check (json_schema ? 'additionalProperties'),
constraint canonical_jsonschema_envelopes_sha_chk check (schema_sha256 is null or schema_sha256 ~ '^[0-9a-f]{64}$'),
constraint canonical_jsonschema_envelopes_pii_chk check (pii_classification in ('none','public','internal','pii','mixed_review_required','unknown')),
constraint canonical_jsonschema_envelopes_raw_policy_chk check (raw_value_policy in ('no_raw_payload_values','hashes_and_refs_only','normalized_values_allowed_internal','unknown')),
constraint canonical_jsonschema_envelopes_metadata_chk check (jsonb_typeof(metadata)='object'),
constraint canonical_jsonschema_envelopes_version_positive_chk check (version > 0)
```

Índices:

```sql
create index if not exists canonical_jsonschema_envelopes_status_idx
  on prop4you_leadfinder_group.canonical_jsonschema_envelopes (envelope_status, envelope_kind, created_at desc)
  where deleted=false;

create index if not exists canonical_jsonschema_envelopes_schema_gin_idx
  on prop4you_leadfinder_group.canonical_jsonschema_envelopes using gin (json_schema jsonb_path_ops);
```

### 2. `prop4you_leadfinder_group.projection_policies`

Tabela mínima para registrar a política inteira de projeção/promotional gates como JSONB versionado.

Colunas recomendadas:

```sql
id uuid primary key default uuidv7(),
public_ref text generated always as (base.make_public_ref('p4ylfgpp', id)) stored,
policy_key text not null,
policy_status text not null default 'active',
policy_version text not null default 'v1',
policy_path text not null,
policy_sha256 text,
policy_payload jsonb not null,
default_jsonb_decision text not null default 'keep_jsonb_until_gate_passed',
marker_auto_apply_policy text not null default 'low_risk_requires_registry_policy_and_review_gate',
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
version integer not null default 1
```

Constraints recomendadas:

```sql
constraint projection_policies_public_ref_key unique (public_ref),
constraint projection_policies_key_version_key unique (policy_key, policy_version),
constraint projection_policies_key_format_chk check (policy_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
constraint projection_policies_version_format_chk check (policy_version ~ '^v[0-9]+([.][0-9]+)?$'),
constraint projection_policies_status_chk check (policy_status in ('draft','active','deprecated','superseded','archived')),
constraint projection_policies_sha_chk check (policy_sha256 is null or policy_sha256 ~ '^[0-9a-f]{64}$'),
constraint projection_policies_payload_object_chk check (jsonb_typeof(policy_payload)='object'),
constraint projection_policies_required_keys_chk check (policy_payload ? 'promotion_gates' and policy_payload ? 'default_decision' and policy_payload ? 'marker_auto_apply'),
constraint projection_policies_gate_count_chk check (jsonb_array_length(coalesce(policy_payload->'promotion_gates','[]'::jsonb)) >= 7),
constraint projection_policies_default_decision_chk check (default_jsonb_decision in ('keep_jsonb_until_gate_passed','project_when_all_gates_pass','never_project_without_review','unknown')),
constraint projection_policies_marker_policy_chk check (marker_auto_apply_policy in ('disabled','low_risk_requires_registry_policy_and_review_gate','review_only','unknown')),
constraint projection_policies_metadata_chk check (jsonb_typeof(metadata)='object'),
constraint projection_policies_version_positive_chk check (version > 0)
```

Índices:

```sql
create index if not exists projection_policies_status_idx
  on prop4you_leadfinder_group.projection_policies (policy_status, policy_version, created_at desc)
  where deleted=false;

create index if not exists projection_policies_payload_gin_idx
  on prop4you_leadfinder_group.projection_policies using gin (policy_payload jsonb_path_ops);
```

### 3. Opcional, mas útil: `prop4you_leadfinder_group.projection_policy_gate_requirements`

Se quiser provar cada gate sem JSONPath complexo no proof script, adicionar uma tabela derivada/seedada com uma row por gate. Se quiser manter o registry mais leve possível, não crie agora; valide o array `promotion_gates` em SQL/Python no proof.

Caso criada, colunas mínimas:

```sql
id uuid primary key default uuidv7(),
policy_id uuid not null references prop4you_leadfinder_group.projection_policies(id) on delete restrict,
gate_key text not null,
gate_order integer not null,
gate_status text not null default 'required',
required boolean not null default true,
description text not null,
metadata jsonb not null default '{}'::jsonb,
created_at timestamptz not null default now(),
updated_at timestamptz not null default now(),
constraint projection_policy_gate_requirements_policy_gate_key unique (policy_id, gate_key),
constraint projection_policy_gate_requirements_order_key unique (policy_id, gate_order),
constraint projection_policy_gate_requirements_gate_key_format_chk check (gate_key ~ '^[a-z][a-z0-9_.:-]{1,191}$'),
constraint projection_policy_gate_requirements_order_chk check (gate_order between 1 and 99),
constraint projection_policy_gate_requirements_status_chk check (gate_status in ('required','optional','deprecated','archived')),
constraint projection_policy_gate_requirements_metadata_chk check (jsonb_typeof(metadata)='object')
```

Minha recomendação para esta slice: começar com 2 tabelas somente. A terceira pode ser adiada porque o PRD pede registry leve e o policy JSON já é o artefato canônico.

## Seed rows recomendadas

Inserir por `on conflict do update`, sem raw payload e sem PII.

### `canonical_jsonschema_envelopes`

Uma row ativa para cada arquivo do PRD:

1. `lfg.property_envelope`:
   - `envelope_kind='property'`
   - `schema_version='v1'`
   - `schema_path='docs/schemas/prop4you/lfg/property-envelope.v1.schema.json'`
2. `lfg.owner_envelope`:
   - `envelope_kind='owner'`
   - `schema_path='docs/schemas/prop4you/lfg/owner-envelope.v1.schema.json'`
3. `lfg.contact_satellites_envelope`:
   - `envelope_kind='contact_satellites'`
   - `schema_path='docs/schemas/prop4you/lfg/contact-satellites-envelope.v1.schema.json'`
4. `lfg.realtor_evidence_envelope`:
   - `envelope_kind='realtor_evidence'`
   - `schema_path='docs/schemas/prop4you/lfg/realtor-evidence-envelope.v1.schema.json'`
5. `lfg.taxonomy_envelope`:
   - `envelope_kind='taxonomy'`
   - `schema_path='docs/schemas/prop4you/lfg/taxonomy-envelope.v1.schema.json'`
6. `lfg.canonical_envelope_index`:
   - `envelope_kind='canonical_index'`
   - `schema_path='docs/schemas/prop4you/lfg/lfg-canonical-envelope-index.v1.schema.json'`

Para cada seed, registrar:

- `schema_id = json_schema->>'$id'`;
- `schema_title = json_schema->>'title'`;
- `schema_sha256` calculado pelo proof antes de montar a DDL ou mantido como literal gerado no arquivo `0005`;
- `projection_policy_key='lfg.projection_policy'`;
- `raw_value_policy` de acordo com o envelope, preferindo `no_raw_payload_values` ou `normalized_values_allowed_internal` quando o envelope representa valores normalizados internos.

### `projection_policies`

Uma row ativa:

- `policy_key='lfg.projection_policy'`
- `policy_version='v1'`
- `policy_path='docs/schemas/prop4you/lfg/projection-policy.v1.json'`
- `default_jsonb_decision='keep_jsonb_until_gate_passed'`
- `marker_auto_apply_policy='low_risk_requires_registry_policy_and_review_gate'`

O `policy_payload` deve conter pelo menos estes 7 gates, em ordem estável:

1. `canonical_semantics_known`
2. `source_lineage_hashes_present`
3. `pii_redaction_policy_passed`
4. `quality_threshold_passed`
5. `review_gate_passed`
6. `query_access_pattern_proven`
7. `relational_owner_boundary_known`

Para marker auto-apply, manter o padrão conservador:

- nunca aplicar marker global a partir de um único voto;
- low-risk marker precisa de policy row ativa;
- precisa de aggregate/review gate, compatível com `0004_user_feedback_markers.sql`;
- DNC/wrong/invalid/stale devem continuar review-gated, a menos que policy futura especifique exceção e prova.

## Views/funções leves recomendadas

Não são obrigatórias para o mínimo, mas ajudam o proof e operadores:

```sql
create or replace view prop4you_leadfinder_group.v_canonical_jsonschema_registry as
select e.envelope_key,
       e.envelope_kind,
       e.schema_version,
       e.schema_id,
       e.schema_title,
       e.schema_path,
       e.schema_sha256,
       e.envelope_status,
       p.policy_key,
       p.policy_version,
       p.default_jsonb_decision,
       p.marker_auto_apply_policy,
       e.updated_at
  from prop4you_leadfinder_group.canonical_jsonschema_envelopes e
  left join prop4you_leadfinder_group.projection_policies p
    on p.policy_key = e.projection_policy_key
   and p.deleted=false
   and p.policy_status='active'
 where e.deleted=false;
```

Função opcional de lookup sem validar JSONSchema completo dentro do PG:

```sql
create or replace function prop4you_leadfinder_group.active_jsonschema_envelope(p_envelope_key text)
returns prop4you_leadfinder_group.canonical_jsonschema_envelopes
language sql stable
as $$
  select *
    from prop4you_leadfinder_group.canonical_jsonschema_envelopes
   where envelope_key = p_envelope_key
     and envelope_status = 'active'
     and active = true
     and deleted = false
   order by created_at desc
   limit 1
$$;
```

Não recomendo implementar validação JSONSchema completa em PL/pgSQL nesta slice. A prova pode validar sintaxe/requisitos com Python stdlib e o DB deve registrar/consultar os contratos.

## Proof assertions recomendadas

Criar `scripts/proof-prop4you-lfg-jsonschema-registry.sh` como wrapper seguro, não como substituto destrutivo do proof atual.

Assertivas estáticas antes do DB:

1. Todos os arquivos esperados existem em `docs/schemas/prop4you/lfg/`.
2. Todos parseiam com Python stdlib `json`.
3. Cada schema contém `$schema`, `$id`, `title`, `type`, `additionalProperties`.
4. Cada schema tem `type='object'`.
5. O index referencia todos os cinco envelopes principais.
6. `projection-policy.v1.json` contém `promotion_gates` com pelo menos os 7 gates canônicos.
7. `projection-policy.v1.json` contém `marker_auto_apply` e seu default conservador.
8. Nenhum artefato/schema contém chaves proibidas óbvias para fixtures/raw dumps, como `raw_payload`, `secret`, `password`, `api_key`, `token` como valor exemplar. O teste deve ser heurístico e não bloquear termos em descrições legítimas como `no_raw_payload_values` se forem explicitamente política.

Assertivas DB após aplicar DDL em lab:

1. Schema `prop4you_leadfinder_group` existe.
2. Tabelas novas existem:
   - `canonical_jsonschema_envelopes`
   - `projection_policies`
3. View existe, se criada:
   - `v_canonical_jsonschema_registry`
4. Contagens mínimas:
   - `canonical_jsonschema_envelopes` = 6 rows ativas e não deletadas.
   - `projection_policies` = 1 row ativa e não deletada.
5. Todos os `schema_sha256` são lowercase 64 hex ou nulos somente se a política deliberadamente permitir; recomendo exigir não nulo no proof.
6. Todos os `json_schema` têm `$schema`, `$id`, `title`, `type`, `additionalProperties`.
7. Todos os `json_schema->>'type' = 'object'`.
8. Nenhum `schema_path` aponta para fora de `docs/schemas/prop4you/lfg/`.
9. `policy_payload->'promotion_gates'` contém os 7 gates canônicos.
10. `marker_auto_apply_policy='low_risk_requires_registry_policy_and_review_gate'`.
11. `default_jsonb_decision='keep_jsonb_until_gate_passed'`.
12. `projection_policy_key` dos envelopes resolve uma policy ativa.
13. O DDL antigo continua intacto: pelo menos uma smoke count para `staging_candidates`, `materialization_runs`, `materialization_results`, `operational_groups`, `user_feedback_votes`, `global_item_markers` em `information_schema.tables`.
14. Sem provider calls: o wrapper não deve executar HTTP/curl/wget nem scripts externos; só `psql` e Python stdlib.
15. Sem impressão de payloads: relatório deve imprimir contagens, paths, ids, hashes e status, não `json_schema` completo se houver risco de over-dump. Para schemas repo-local sem PII, pode imprimir lista de `$id` e hashes.

## Integração segura com o proof wrapper

Recomendação de desenho:

1. O novo wrapper deve rodar a prova existente como etapa base:

```bash
KEEP_DB=1 LAB_DB="${LAB_DB:-pg18_prop4you_lfg_jsonschema_registry_lab}" scripts/proof-prop4you-ddl-lab.sh
```

2. O wrapper deve usar um `LAB_DB` próprio por padrão para não conflitar com `pg18_prop4you_ddl_lab`.

3. Após a prova base com `KEEP_DB=1`, aplicar somente:

```text
database/ddl/projects/prop4you/leadfinder_group/0005_canonical_jsonschema_registry.sql
```

4. Em caso de falha, o wrapper deve:

- preservar mensagens de erro reais;
- não esconder falha de `proof-prop4you-ddl-lab.sh`;
- dropar o lab DB apenas se `KEEP_DB` externo não for `1`.

5. Evitar editar o script existente agora, a menos que a tarefa T6 decida adicionar `0005` ao apply order canônico. Para esta issue, o wrapper novo pode chamar o script antigo com `KEEP_DB=1` e depois aplicar o `0005`; isso reduz risco de regressão no proof atual.

6. Ao gerar relatório, usar um caminho novo:

```text
docs/reports/prop4you-lfg-jsonschema-registry-proof.md
```

7. O relatório deve declarar explicitamente limites:

- prova registry/queryability, não valida JSONSchema completo no PG;
- não cria tabelas finais property/owner/contact;
- não chama providers;
- não faz ingestão real;
- não prova produção/VPS.

## Posição sobre ordem de aplicação

A ordem segura é após LFG `0004_user_feedback_markers.sql`, porque:

- o registry pertence ao boundary LFG;
- policy de marker auto-apply referencia semanticamente o gate de feedback marker/review/apply já definido em `0004`;
- evita dependência circular com SourceHub/Matrix/LeadFinder;
- não precisa alterar tabelas existentes.

No futuro, se `scripts/proof-prop4you-ddl-lab.sh` passar a representar todo o pacote experimental Prop4You, inserir `0005` logo após:

```text
leadfinder_group/0004_user_feedback_markers.sql
leadfinder_group/0005_canonical_jsonschema_registry.sql
leadfinder/0004_dictionary_promotion_review_apply.sql
```

Mas para o proof dedicado desta issue, prefiro wrapper isolado chamando o proof base e aplicando `0005` em seguida.

## Riscos e mitigação

- Risco: duplicar verdade entre JSON files e DDL seed literals.
  - Mitigação: proof calcula sha256 dos arquivos e compara com rows; se o DDL embutir JSON, gerar/atualizar literals de forma controlada.
- Risco: registry virar runtime validator pesado.
  - Mitigação: nesta slice, registry é queryable contract; validação JSONSchema profunda fica fora do PG.
- Risco: policy permissiva demais para markers.
  - Mitigação: default conservador e compatível com `0004`: aggregate recomenda; review/apply decide; single vote nunca aplica global truth.
- Risco: proof imprimir payload/schema inteiro.
  - Mitigação: relatório imprime contagens, `$id`, paths e hashes; nada de raw/provider values.

## Conclusão

A estrutura mínima recomendada é de duas tabelas: `canonical_jsonschema_envelopes` e `projection_policies`, com seed rows idempotentes para 6 schemas e 1 projection policy. O proof PG18 deve ser um wrapper dedicado que reutiliza o lab DDL existente com `KEEP_DB=1`, aplica `0005`, valida contagens/constraints/keys/hashes/gates e escreve relatório sem raw payload/PII. Isso entrega automaticidade suficiente para futuras DDL/materializações sem antecipar o grafo final de property/owner/contact.
