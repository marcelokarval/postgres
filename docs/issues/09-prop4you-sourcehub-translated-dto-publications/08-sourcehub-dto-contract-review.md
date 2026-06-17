# Revisão de contrato — SourceHub translated DTO publications (T4)

Status: proposta arquitetural / revisão de contrato
Worker: A
Escopo: SourceHub DTO traduzido publicado a partir de `raw_records` + Matrix `field_mapping_set` + LeadFinder `dictionary_version`
Data: 2026-06-17

## 1. Veredito

O contrato T4 deve existir como uma publicação SourceHub própria, não como mutação direta de LeadFinder nem como extensão informal de `raw_records`.

Recomendação: criar uma tabela/projeção futura em `prop4you_sourcehub` para publicações DTO traduzidas, com dependências explícitas para:

- `prop4you_sourcehub.raw_records.id` — evidência bruta e linhagem de origem.
- `prop4you_matrix.transformation_artifacts.id` — artefato Matrix `field_mapping_set` aprovado/revisado.
- `prop4you_leadfinder.canonical_dictionary_versions.id` — versão do dicionário LeadFinder usada para nomear/semantizar campos.

A publicação T4 deve materializar um DTO JSONB semântico, revisável e versionado, mas ainda não deve criar entidades canônicas finais de propriedade, owner, lead, contato ou situação. Esse passo continua sendo T5/later ou outro fluxo explícito de materialização.

## 2. Requested vs recommended

| Tema | Requested / necessário | Recommended / contrato proposto |
| --- | --- | --- |
| Owner do T4 | SourceHub translated DTO publication | `prop4you_sourcehub` deve possuir a tabela de publicação; Matrix fornece tradução; LeadFinder fornece dicionário. |
| Entrada mínima | `raw_record` + `field_mapping_set` + `dictionary_version` | Exigir FK para os três elementos e validar consistência entre `field_mapping_artifact.dictionary_version_id` e `dictionary_version_id` da publicação. |
| Forma do DTO | Publicar DTO traduzido | Armazenar `translated_dto jsonb` como objeto, com envelope explícito: contract/version, source, dictionary, fields, lineage, quality. |
| Gate Matrix | Usar `field_mapping_set` | Só aceitar artefato `artifact_kind = 'field_mapping_set'`, `artifact_schema_version = 'matrix.field_mapping_set.raw_path.v0'` ou sucessor compatível, `artifact_gate_status in ('passed','ready_for_review')` conforme ambiente; produção deve exigir `passed`. |
| Gate SourceHub raw | Usar raw existente | Exigir `raw_records.deleted = false`, `raw_records.active = true`, `review_status = 'accepted_for_mapping'` ou estado equivalente aprovado, `matrix_mapping_status = 'mapped'`. |
| Gate LeadFinder | Usar dictionary version | Exigir versão de dicionário ativa/aprovada/compatível quando o DDL de status do dicionário estiver consolidado. Não inferir versão por chave textual. |
| Valores brutos | DTO traduzido pode conter valores derivados do raw | Permitido conter valores normalizados necessários ao DTO, mas nunca segredos, credenciais, dumps brutos, payload completo, nem PII não classificada. Diferenciar `raw_payload` de `translated_dto`. |
| Publicação | Criar registro publicável | Publicação deve ser idempotente por `(raw_record_id, field_mapping_artifact_id, dictionary_version_id, dto_contract_version)` ou por `publication_key`. |
| Materialização LeadFinder | Não solicitada agora | Não criar/alterar `canonical_families`, `canonical_fields`, runtime LFG, propriedades ou leads. Apenas publicar candidato DTO SourceHub. |

## 3. Contrato recomendado

Nome sugerido da tabela futura:

```text
prop4you_sourcehub.translated_dto_publications
```

Nome alternativo aceitável se o time preferir enfatizar estágio candidato:

```text
prop4you_sourcehub.dto_candidate_publications
```

Contrato lógico:

```text
raw_records.raw_payload
  -> Matrix raw path extraction / gap bridge / quality_report
  -> Matrix transformation_artifacts(artifact_kind = field_mapping_set)
  -> LeadFinder dictionary_version context
  -> SourceHub translated_dto_publications.translated_dto
  -> later LeadFinder/LFG materialization, explicitly outside T4
```

## 4. Colunas obrigatórias

Colunas de identidade e publicação:

- `id uuid primary key default uuidv7()`
- `public_ref text generated always as (base.make_public_ref('p4yshdto', id)) stored` ou prefixo curto registrado equivalente.
- `publication_key text not null` — chave estável e idempotente.
- `publication_status text not null default 'draft'`
- `dto_contract_version text not null` — exemplo: `sourcehub.translated_dto.v0`.

Colunas de dependência/linhagem:

- `raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict`
- `field_mapping_artifact_id uuid not null references prop4you_matrix.transformation_artifacts(id) on delete restrict`
- `dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict`
- `provider_id uuid references prop4you_provider.providers(id) on delete restrict`
- `payload_class_id uuid references prop4you_provider.payload_classes(id) on delete restrict`
- `source_lineage_edge_id uuid references prop4you_sourcehub.source_lineage_edges(id) on delete set null` opcional, se a publicação também registrar edge `candidate_dto_for`.

Colunas de conteúdo:

- `translated_dto jsonb not null` — DTO traduzido; deve ser objeto.
- `translation_summary jsonb not null default '{}'::jsonb` — contagens, campos aplicados, campos bloqueados, warnings.
- `quality_summary jsonb not null default '{}'::jsonb` — snapshot dos sinais de qualidade usados para publicar.
- `redaction_summary jsonb not null default '{}'::jsonb` — política de PII/redação aplicada.
- `content_sha256 text` — checksum determinístico do DTO publicado, quando disponível.
- `metadata jsonb not null default '{}'::jsonb`

Colunas de workflow/revisão:

- `publication_gate_status text not null default 'not_started'`
- `review_status text not null default 'unreviewed'`
- `published_at timestamptz`
- `published_by_actor_id text`
- `reviewed_at timestamptz`
- `reviewed_by_actor_id text`
- `superseded_by_publication_id uuid references prop4you_sourcehub.translated_dto_publications(id) on delete set null`
- `superseded_at timestamptz`

Colunas de lifecycle padrão:

- `active boolean not null default true`
- `activated_at timestamptz`
- `deactivated_at timestamptz`
- `deleted boolean not null default false`
- `deleted_at timestamptz`
- `deleted_by_actor_id text`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `last_modified_by_actor_id text`
- `version integer not null default 1`

## 5. Estados recomendados

`publication_status`:

- `draft`
- `generated`
- `in_review`
- `published`
- `blocked`
- `rejected`
- `superseded`
- `archived`

`publication_gate_status`:

- `not_started`
- `checking`
- `ready_for_review`
- `passed`
- `blocked`
- `not_applicable`

`review_status`:

- `unreviewed`
- `in_review`
- `accepted_for_publication`
- `needs_mapping_revision`
- `needs_dictionary_revision`
- `needs_redaction`
- `rejected`

## 6. Invariantes

1. A publicação T4 é SourceHub-owned.
   - Matrix não publica DTO final.
   - LeadFinder não publica DTO SourceHub.
   - SourceHub não redefine semântica de campo; apenas aplica Matrix + dictionary_version.

2. `field_mapping_artifact_id` deve apontar para `transformation_artifacts.artifact_kind = 'field_mapping_set'`.

3. `dictionary_version_id` da publicação deve ser igual ao `dictionary_version_id` do artefato Matrix.

4. `raw_record_id` deve permanecer como evidência bruta imutável de origem. `translated_dto` nunca substitui `raw_payload`.

5. `translated_dto` deve ser JSON object, não array/scalar.

6. `translation_summary`, `quality_summary`, `redaction_summary` e `metadata` devem ser JSON objects.

7. `content_sha256`, se informado, deve ser lowercase SHA-256 de 64 hex chars.

8. Publicação deve ser idempotente. Reexecução com o mesmo raw/artifact/dictionary/contract não deve criar duplicata não intencional.

9. Publicação `published` deve ter `published_at` não nulo.

10. Publicação `superseded` deve ter `superseded_at` ou `superseded_by_publication_id`.

11. DTO publicado não pode conter o payload bruto completo nem campos secretos operacionais.

12. Campos PII/contact/person devem exigir `redaction_summary` ou classificação explícita antes de `publication_gate_status = 'passed'`.

13. Uma publicação bloqueada por Matrix deve apontar para `review_status = 'needs_mapping_revision'` ou equivalente.

14. Uma publicação bloqueada por LeadFinder dictionary deve apontar para `review_status = 'needs_dictionary_revision'` ou equivalente.

15. T4 não deve mutar `canonical_families`, `canonical_fields`, runtime LFG, property/owner/lead tables ou provider request queues.

## 7. Envelope mínimo do `translated_dto`

Formato recomendado de alto nível:

```json
{
  "contract": "sourcehub.translated_dto.v0",
  "source": {
    "raw_record_id": "uuid",
    "raw_record_public_ref": "p4yshr_...",
    "provider_key": "optional",
    "payload_class_key": "optional"
  },
  "dictionary": {
    "dictionary_version_id": "uuid",
    "dictionary_version_key": "..."
  },
  "matrix": {
    "field_mapping_artifact_id": "uuid",
    "artifact_key": "...",
    "artifact_schema_version": "matrix.field_mapping_set.raw_path.v0"
  },
  "fields": {
    "family_key.field_key": {
      "value": "normalized value or structured value",
      "value_kind": "text|numeric|boolean|date|timestamp|uuid|enum|jsonb|unknown",
      "source_path_label": "...",
      "confidence": "unknown|low|medium|high|reviewed"
    }
  },
  "lineage": {
    "phase": "T4_sourcehub_translated_dto",
    "raw_payload_embedded": false
  },
  "quality": {
    "warnings": [],
    "blocked_fields": []
  }
}
```

Observação: o envelope pode evoluir, mas deve preservar `contract`, `source`, `dictionary`, `matrix`, `fields`, `lineage` e `quality` como chaves mínimas enquanto `sourcehub.translated_dto.v0` estiver em uso.

## 8. Validação esperada

Validação por constraint/trigger/RPC futura:

- FK existentes para `raw_record_id`, `field_mapping_artifact_id`, `dictionary_version_id`.
- Check de formato para `publication_key` e `dto_contract_version`.
- Check de enum para `publication_status`, `publication_gate_status`, `review_status`.
- Check JSON object para `translated_dto`, summaries e metadata.
- Check SHA-256 para `content_sha256`.
- Unique recomendado: `(raw_record_id, field_mapping_artifact_id, dictionary_version_id, dto_contract_version)` quando `deleted = false`, ou unique global em `publication_key`.
- Trigger/RPC para validar que o artefato é `field_mapping_set` e pertence à mesma `dictionary_version_id`.
- Trigger/RPC para impedir `published` sem gate `passed`, `published_at`, e DTO com envelope mínimo.
- Trigger/RPC para atualizar `raw_records.leadfinder_publication_status` para `candidate_dto_ready` ou `published` somente após sucesso T4, sem materializar LeadFinder.
- Inserção opcional em `source_lineage_edges` com `lineage_kind = 'candidate_dto_for'` para ligar raw record a publicação DTO, se a tabela futura puder ser referenciada por `(derived_object_schema, derived_object_table, derived_object_id)`.

Validação de prova esperada em lab:

- DDL aplica sem alterar os DDLs principais existentes nesta revisão.
- Raw record de teste aprovado para mapping gera exatamente 1 publicação para 1 artifact/dictionary/contract.
- Reexecução não duplica publicação.
- Artefato que não seja `field_mapping_set` é rejeitado.
- Artefato com `dictionary_version_id` divergente é rejeitado.
- DTO sem envelope mínimo é rejeitado.
- DTO com `raw_payload` embutido é rejeitado ou bloqueado.
- Publicação T4 não altera contagem de `canonical_families`/`canonical_fields`.
- Publicação T4 não cria materialização LFG/runtime.

## 9. Não-goals

- Não editar DDL principal nesta revisão.
- Não criar provider calls, workers, HTTP clients ou integrações externas.
- Não commitar raw payload real, fixtures com PII ou valores de provider.
- Não transformar Matrix em owner de DTO publicado.
- Não transformar LeadFinder em owner de payload bruto ou publicação SourceHub.
- Não materializar property/owner/lead/contact/situation canônicos.
- Não auto-promover dictionary proposals.
- Não definir contrato Django/PostgREST/FastAPI específico; o contrato é database-centric e gateway-agnostic.

## 10. Compatibilidade com os DDLs revisados

### SourceHub `0001_sourcehub_corpus.sql`

Compatível. `raw_records` já separa raw evidence de publicação futura via:

- `matrix_mapping_status`
- `leadfinder_publication_status`
- `raw_payload` como evidência, não DTO
- `source_lineage_edges.lineage_kind` incluindo `candidate_dto_for` e `matrix_mapping_input`

A lacuna é apenas a tabela/RPC T4 explícita; não há necessidade de mudar o DDL existente nesta revisão.

### Matrix `0005_field_mapping_set_artifacts.sql`

Compatível. O artefato `field_mapping_set` declara:

- `contract = matrix.field_mapping_set.raw_path.v0`
- `artifact_kind = field_mapping_set`
- `sourcehub_dependency = SourceHub translated DTO publication must reference this artifact after review`
- `temporal_phase.sourcehub_dto = T4_later`
- `value_policy = no_raw_values`

T4 deve consumir esse artifact após revisão, não substituí-lo.

### LeadFinder `0003_prepare_dictionary_promotions.sql`

Compatível. O prepare-only preserva o limite correto:

- prepara propostas de dictionary promotion
- não muta canonical dictionary
- não publica DTO SourceHub
- marca `sourcehub_dto = T4_later`

T4 deve usar a `dictionary_version_id` e, quando aplicável, o resultado humano/revisado das promoções; não deve aplicar promoções automaticamente.

## 11. Decisão recomendada

Aprovar o desenho T4 como nova unidade SourceHub, em slice posterior, com DDL próprio e RPC idempotente de publicação. Manter os DDLs revisados intactos nesta tarefa.

Prioridade para o próximo worker/slice:

1. Especificar PRD T4.
2. Criar `prop4you_sourcehub.translated_dto_publications`.
3. Criar função idempotente `publish_translated_dto_from_mapping(...)` ou nome equivalente.
4. Adicionar prova integrada mostrando T4 sem mutação de LeadFinder canonical dictionary e sem materialização LFG.
