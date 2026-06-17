# Gateway/temporal review — SourceHub translated DTO publications

Status: delivered for Thor review
Worker: C
Updated: 2026-06-17T19:40:50-04:00

## Escopo

Este review verifica se a Slice 09 mantém a publicação de DTO traduzido do SourceHub como contrato database-centric, gateway/runtime agnóstico, e temporalmente separada da materialização LeadFinder/LFG.

Fontes revisadas neste checkout:

- `docs/issues/09-prop4you-sourcehub-translated-dto-publications/00-detection-and-analysis.md`
- `docs/issues/09-prop4you-sourcehub-translated-dto-publications/01-prd.md`
- `database/ddl/projects/prop4you/sourcehub/0001_sourcehub_corpus.sql`
- `database/ddl/projects/prop4you/matrix/0004_quality_report_artifacts.sql`
- `database/ddl/projects/prop4you/matrix/0005_field_mapping_set_artifacts.sql`
- `database/ddl/projects/prop4you/leadfinder/0003_prepare_dictionary_promotions.sql`
- `docs/issues/05-prop4you-matrix-artifacts-reiq-raws/10-sourcehub-translated-dto-readiness.md`
- `docs/issues/07-prop4you-leadfinder-gap-bridge-quality-report/10-temporal-phase-modeling-review.md`
- `docs/issues/08-prop4you-matrix-field-mapping-prepare-promotions/11-executive-synthesis.md`

## Veredito curto

PASS com guardrails obrigatórios para a implementação de `sourcehub/0002_translated_dto_publications.sql`.

A intenção da Slice 09 está correta: SourceHub deve publicar DTOs traduzidos, versionados e rastreáveis a partir de `raw_record + Matrix field_mapping_set + LeadFinder dictionary_version`, sem criar runtime LeadFinder, sem materializar LFG, sem depender de Django/PostgREST/ORM e sem chamadas a providers.

O principal cuidado de implementação é nomear e modelar a tabela como publicação/contrato de DTO, não como tabela operacional de lead/property/owner. A publicação DTO pode ser consumível pelo LeadFinder depois, mas não deve ser a própria materialização LeadFinder.

## Linha temporal T0-T5 validada

```text
T0 SourceHub raw capture / lineage
  -> T1 Matrix raw path extraction / structural evidence
    -> T2 LeadFinder gap/proposal bridge / demand pressure
      -> T3 Matrix quality_report / semantic quality gate
        -> T3.5 Matrix field_mapping_set / translation contract
          -> T4 SourceHub translated DTO publication
            -> T5 LeadFinder/LFG materialization later
```

### T0 — SourceHub raw capture

Responsável por ingress, raw payload, corpus metadata, provider/source metadata e lineage. `sourcehub/0001_sourcehub_corpus.sql` já separa raw records de entidades canônicas e registra que raw records não são property, owner ou lead.

Guardrail para Slice 09: `translated_dto_publications` deve referenciar `raw_records(id)` e preservar lineage, mas nunca reclassificar o raw record como verdade operacional.

### T1 — Matrix extraction

Responsável por evidência estrutural segura: paths, tipos, contagens e frequência. Não deve copiar valores escalares raw para docs/proofs.

Guardrail para Slice 09: DTO publicado pode conter JSONB de contrato traduzido, mas os proofs/docs da slice devem mostrar contagens, refs, hashes e chaves, não payloads raw ou PII.

### T2 — LeadFinder gap/proposal bridge

Responsável por pressão de modelagem e lacunas, não runtime. O bridge ainda não é filtro final de mapa/lista/detail.

Guardrail para Slice 09: publicação DTO pode apontar para gaps/preparations como contexto, mas não deve criar tabelas LFG, filas operacionais, views finais de busca, ranking, scoring, lists, presets ou materialized views de runtime.

### T3 — Matrix quality_report

Responsável por revisão de qualidade e readiness semântico. `matrix/0004_quality_report_artifacts.sql` explicita `sourcehub_dto_publication = false` e `leadfinder_materialization = T5_later`.

Guardrail para Slice 09: um quality_report sozinho não autoriza publicação. O gate publicável precisa exigir field_mapping_set adequado e dictionary version coerente.

### T3.5 — Matrix field_mapping_set

Responsável por contrato de tradução. `matrix/0005_field_mapping_set_artifacts.sql` marca `gateway_agnostic = true`, `sourcehub_dto = T4_later`, `lfg_materialization = T5_later`, e declara que Matrix é dona do artefato semântico.

Guardrail para Slice 09: `translated_dto_publications.matrix_artifact_id` deve referenciar `prop4you_matrix.transformation_artifacts(id)` com `artifact_kind = 'field_mapping_set'`, não qualquer artefato Matrix genérico sem checagem.

### T4 — SourceHub translated DTO publication

Responsável por publicar um DTO traduzido, versionado, auditável e vinculado a raw lineage + Matrix artifact + LeadFinder dictionary version.

O DTO é uma fronteira de integração e revisão. Ele não é materialização operacional.

Requisitos recomendados para T4:

- tabela em `prop4you_sourcehub`, preferencialmente `translated_dto_publications`;
- FK obrigatória para `prop4you_sourcehub.raw_records(id)`;
- FK obrigatória para `prop4you_matrix.transformation_artifacts(id)`;
- FK obrigatória para `prop4you_leadfinder.canonical_dictionary_versions(id)`;
- check ou trigger que garanta `artifact_kind = 'field_mapping_set'` no artefato Matrix;
- check ou trigger que garanta coerência entre `matrix_artifact.dictionary_version_id` e `leadfinder_dictionary_version_id`;
- `translated_dto jsonb not null` com objeto JSON;
- `translated_dto_sha256` para reprodutibilidade/hash;
- status de publicação separado de status de materialização;
- public ref com prefixo SourceHub novo, por exemplo `p4yshd`;
- lifecycle padrão base;
- comentários explícitos de gateway-agnostic, no provider calls e no LFG materialization.

### T5 — LeadFinder/LFG materialization later

Responsável por tabelas finais de busca, filtros, mapa/list/detail, scoring, ranking, workspaces/listas/presets, owner/contact operational views e índices runtime.

Guardrail para Slice 09: nenhuma tabela, função, view ou proof deve reivindicar LFG materialization. A acceptance da slice deve provar contagem 0 para materialização LFG.

## Gateway/runtime agnostic review

A slice deve permanecer agnóstica porque a regra do repo é: gateways são transporte/consumidores, não donos da verdade de negócio.

Critérios PASS:

- DDL SQL puro sob `database/ddl/projects/prop4you/sourcehub/`.
- Nenhum pacote Django, model Python, serializer DRF, PostgREST-specific RPC ou rota HTTP obrigatória.
- Sem dependência de framework para gerar IDs, timestamps, lifecycle ou status.
- Funções SQL, se existirem, recebem IDs/JSONB e retornam records/projeções; qualquer gateway pode chamá-las.
- Comentários/proofs podem mencionar PostgREST/Django apenas como possíveis consumidores, nunca como owner ou pré-requisito.

Red flags a bloquear:

- nomes como `leadfinder_materialized_*`, `lfg_*`, `property_*`, `owner_*` dentro de SourceHub 0002;
- colunas que representem filtro final (`list_status`, `map_cluster_id`, `score`, `workspace_id`, `preset_id`) em `translated_dto_publications`;
- trigger que publique automaticamente em tabelas LeadFinder;
- job/cron/provider call embutido;
- RLS/exposure pública antes de política explícita de leitura do DTO.

## DTO publication vs LFG materialization

Diferença obrigatória:

- DTO publication: registro auditável de uma tradução de evidência raw para um contrato JSONB versionado, com lineage e hash.
- LFG materialization: criação de fatos/entidades/índices operacionais LeadFinder para busca e uso do produto.

A Slice 09 deve implementar somente a primeira.

A tabela de publicação pode ter status como `candidate`, `ready_for_review`, `published`, `rejected`, `superseded`, `archived`. Ela não deve ter status como `materialized`, `indexed_for_search`, `lead_active`, `in_campaign`, ou equivalentes de runtime. Se houver necessidade de rastrear consumo futuro, usar `metadata` não-secreta ou uma futura tabela explícita de T5.

## Riscos

1. Confundir `published` com `materialized`.
   - Mitigação: comentário de tabela/colunas dizendo que publicação DTO não cria LeadFinder/LFG operational rows.

2. Aceitar qualquer Matrix artifact como fonte.
   - Mitigação: check via trigger/função para `artifact_kind = 'field_mapping_set'` e `artifact_gate_status` adequado.

3. Divergência entre dictionary version do DTO e do artifact Matrix.
   - Mitigação: trigger ou função de publicação valida `transformation_artifacts.dictionary_version_id = leadfinder_dictionary_version_id`.

4. Vazamento de payload/PII em proof/docs.
   - Mitigação: proofs mostram counts, UUID/public_ref, artifact_key, dictionary_version_key, hash e status; não mostram `raw_payload` nem dumps completos de `translated_dto`.

5. Gateway acoplado por conveniência de proof.
   - Mitigação: prova primária via SQL/lab. Browser/PostgREST proof, se existir, é consumidor opcional.

6. Publicação automática cedo demais.
   - Mitigação: diferenciar `candidate/ready_for_review` de `published`; permitir publicação somente quando raw review + Matrix field_mapping_set + dictionary version estiverem coerentes.

7. Perder reprodutibilidade.
   - Mitigação: registrar `raw_payload_sha256` quando disponível, `translated_dto_sha256`, artifact id/key e dictionary version id/key no proof.

## Next step recomendado

Implementar `database/ddl/projects/prop4you/sourcehub/0002_translated_dto_publications.sql` como DDL idempotente e não destrutiva, com:

1. tabela `prop4you_sourcehub.translated_dto_publications`;
2. prefixo público `p4yshd` registrado em `base.register_public_id_prefix`;
3. FKs para raw record, Matrix transformation artifact e LeadFinder dictionary version;
4. trigger/função de validação de artifact/dictionary/status;
5. lifecycle triggers base;
6. view de revisão que omita payload raw e evite dump integral de DTO;
7. helper SQL opcional para criar publicação candidate a partir de IDs explícitos;
8. prova PG18 lab com pelo menos 10 DTO publications e 0 LFG materializations.

## Acceptance wording proposto

Use esta wording para a aceitação da Slice 09:

```text
ACCEPTED when PG18 lab applies SourceHub 0002 after Matrix 0005 and LeadFinder 0003; creates at least 10 SourceHub translated DTO publication rows linked to raw_records, Matrix field_mapping_set artifacts, and LeadFinder dictionary versions; proves reproducible DTO hashes/lineage without printing raw payload values; remains gateway/runtime agnostic with no Django/PostgREST/ORM dependency; and proves LeadFinder/LFG materialization count remains 0.
```

Acceptance negativa obrigatória:

```text
REJECT if SourceHub 0002 creates LeadFinder/LFG operational tables, materialized views, runtime filters, provider calls, framework-specific code, automatic dictionary promotion, or docs/proofs that dump raw provider payload values/PII.
```
