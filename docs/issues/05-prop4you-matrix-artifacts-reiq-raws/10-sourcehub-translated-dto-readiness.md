# SourceHub translated DTO publication — contrato/readiness

Status: contrato de prontidão para próxima fatia; sem implementação final de DDL nesta entrega.

[SOURCEHUB_DTO_PUBLICATION_NEXT]

A próxima fatia de SourceHub deve publicar uma tabela conceitual `prop4you_sourcehub.translated_dto_publications` somente depois que o raw record passar por revisão de SourceHub, artefato Matrix e versão de dicionário LeadFinder. A tabela não deve materializar entidades finais de propriedade, owner ou lead; ela deve registrar a publicação de um DTO traduzido, versionado e auditável, pronto para consumo controlado por LeadFinder ou por revisores.

Contrato mínimo recomendado:

- `id uuid primary key default uuidv7()`.
- `public_ref text generated always as (base.make_public_ref('p4yshd', id)) stored`.
- `raw_record_id uuid not null references prop4you_sourcehub.raw_records(id) on delete restrict`.
- `matrix_artifact_id uuid not null` apontando para o artefato Matrix aprovado da próxima DDL de Matrix.
- `leadfinder_dictionary_version_id uuid not null references prop4you_leadfinder.canonical_dictionary_versions(id) on delete restrict`.
- `translated_dto jsonb not null`, com constraint `jsonb_typeof(translated_dto) = 'object'`.
- `translated_dto_sha256 text`, lowercase SHA-256 do JSON canônico ou payload textual definido pela pipeline; constraint `^[0-9a-f]{64}$` quando preenchido.
- `publication_status text not null default 'candidate'` com vocabulário inicial sugerido: `candidate`, `blocked`, `ready_for_review`, `published`, `rejected`, `superseded`, `archived`.
- `publication_kind text not null default 'leadfinder_candidate'` com vocabulário inicial sugerido: `leadfinder_candidate`, `review_snapshot`, `gap_evidence`, `regression_fixture_metadata`, `unknown`.
- `rejection_reason_code text` e `rejection_summary text` para recusas sem dump de payload/PII.
- `gap_reference_schema name`, `gap_reference_table name`, `gap_reference_id uuid` para apontar lacunas de Matrix ou LeadFinder sem acoplar a um nome ainda não congelado.
- `source_lineage_edge_id uuid references prop4you_sourcehub.source_lineage_edges(id) on delete set null` quando a publicação tiver aresta explícita `candidate_dto_for` ou `derived_from`.
- `metadata jsonb not null default '{}'::jsonb` para metadados não secretos.
- colunas de lifecycle padrão (`active`, `activated_at`, `deactivated_at`, `deleted`, `deleted_at`, `deleted_by_actor_id`, `created_at`, `updated_at`, `last_modified_by_actor_id`, `version`) alinhadas com `raw_records`, `corpus_samples`, `source_lineage_edges` e `enrichment_requests`.

Índices recomendados:

- `(raw_record_id, publication_status)`.
- `(matrix_artifact_id, publication_status)`.
- `(leadfinder_dictionary_version_id, publication_status)`.
- `translated_dto` GIN com `jsonb_path_ops` somente para revisão controlada.
- índice parcial para `gap_reference_*` quando `gap_reference_id is not null`.
- chave única ou dedupe lógico em `(raw_record_id, matrix_artifact_id, leadfinder_dictionary_version_id, translated_dto_sha256)` quando checksum existir.

[MATRIX_ARTIFACT_DEPENDENCY]

A DDL atual de Matrix existente neste checkout é `prop4you_matrix.0001_semantic_dictionary.sql`, com tabelas mirror/candidate/review `canonical_families`, `canonical_fields`, `provider_field_candidates` e `field_mapping_reviews`. O PRD desta issue exige uma próxima DDL `database/ddl/projects/prop4you/matrix/0002_mapping_sessions.sql` com sessões e artefatos de transformação.

Para evitar divergência de nomes, SourceHub deve aguardar os nomes finais da próxima fatia Matrix. O contrato esperado é que `matrix_artifact_id` referencie a tabela de artefatos de transformação aprovada por Matrix, provavelmente `prop4you_matrix.transformation_artifacts(id)` se o Worker B/Thor mantiver o nome do PRD. Se o nome final diferir, preservar o conceito: uma publicação DTO deve sempre apontar para exatamente um artefato Matrix aprovado, contendo mapeamentos de campos/path e evidência sem valores brutos.

Pré-condições Matrix para permitir `publication_status = 'published'`:

- artefato Matrix existe e não foi soft-deletado;
- artefato está em estado aprovado/publicável, não apenas candidato;
- artefato registra ou referencia a mesma versão de dicionário LeadFinder usada na publicação;
- artefato não exige provider call para completar o DTO;
- gaps de mapeamento críticos estão resolvidos ou explicitamente vinculados em `gap_reference_*`.

[LEADFINDER_DICTIONARY_DEPENDENCY]

LeadFinder já possui `prop4you_leadfinder.canonical_dictionary_versions`, `canonical_families`, `canonical_fields`, `canonical_gaps` e `growth_pressure_signals`. A publicação DTO deve ter FK obrigatória para `prop4you_leadfinder.canonical_dictionary_versions(id)` porque LeadFinder é o dono do dicionário canônico; Matrix apenas autoriza/explica a transformação.

Regras de prontidão LeadFinder:

- A versão de dicionário deve existir em `prop4you_leadfinder.canonical_dictionary_versions`.
- Preferir `version_status in ('approved','active')` para publicação; `draft`/`in_review` podem gerar apenas `candidate` ou `ready_for_review`.
- Lacunas de dicionário devem apontar para `prop4you_leadfinder.canonical_gaps(id)` quando forem lacunas canônicas conhecidas; usar `gap_reference_*` para manter flexibilidade enquanto a DDL final não congela uma FK específica.
- DTO traduzido deve declarar em `metadata` a `dictionary_version_key` observada, mas a FK por `id` é a verdade relacional.

[NO_PROVIDER_CALLS]

Este contrato não chama provedores, não cria worker, não agenda cron, não usa HTTP, não lê corpus privado e não exige segredos. Qualquer resposta futura de provedor deve entrar primeiro como `prop4you_sourcehub.raw_records`; publicação DTO é derivação/revisão, não coleta de dados.

[NO_PII_DUMP]

Este arquivo não contém payloads REIQ/provedor, valores de owners, contatos, endereços ou amostras raw. A tabela futura deve evitar logs de valores sensíveis em `rejection_summary`, `metadata` e comentários; `translated_dto` pode conter dados pessoais somente sob política/RLS de SourceHub definida em fatia própria, nunca como fixture ou dump gitado.

[RISKS]

- Nomes finais da próxima DDL Matrix ainda podem mudar; não congelar FK para `matrix_artifact_id` antes de `0002_mapping_sessions.sql` existir e aplicar em lab.
- `translated_dto` tende a carregar PII se representar owners/contatos; RLS/políticas de leitura precisam ser definidas antes de expor via PostgREST ou clients.
- Checksum precisa de serialização canônica definida pela pipeline; `jsonb::text` pode não ser contrato suficiente para interoperabilidade externa.
- Publicação sem vínculo consistente entre `raw_record_id`, artefato Matrix e versão LeadFinder pode gerar DTO semanticamente inválido.
- `gap_reference_*` é flexível, mas menos seguro que FKs específicas; converter para FKs quando os objetos de gap Matrix/LeadFinder estiverem estáveis.
- Esta prontidão não substitui prova lab da futura DDL; ela apenas prepara o contrato e os gates de aceitação.

Checklist para próxima fatia:

1. Confirmar nomes reais da DDL Matrix 0002 e escolher FK concreta de `matrix_artifact_id`.
2. Criar DDL `0002_translated_dto_publications.sql` ou nome equivalente em `database/ddl/projects/prop4you/sourcehub/`.
3. Registrar prefixo público `p4yshd` com `base.register_public_id_prefix`.
4. Adicionar comentários para tabela/colunas/constraints/triggers.
5. Criar triggers base de lifecycle.
6. Provar em lab que as dependências aplicam na ordem: base, schemas, providers, leadfinder, matrix 0001, matrix 0002, sourcehub 0001, sourcehub DTO publication.
