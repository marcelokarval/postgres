# 08 — Revisão DirectSkip unified projection group

Status: concluído
Worker: A
Escopo: DirectSkip / skip trace como grupo unificado de projeção LFG para phone/email, mailing address e relationship evidence.

Política de privacidade: este artefato reproduz apenas nomes de campos, caminhos estruturais, contagens e decisões de modelagem. Nenhum valor bruto de JSON, telefone, e-mail, nome, endereço ou outro PII foi impresso.

## Decisão aplicada

DirectSkip deve entrar no review board como um único `candidate_group` unificado, não como três grupos independentes, porque phones/emails, mailing address e relationship evidence são emitidos pelo mesmo JSON/envelope de skip trace e compartilham:

- `provider_slug=directskip`;
- `list_type_slug=skip_trace_contact_discovery`;
- o mesmo `raw_record_public_id` / lineage de provider;
- a mesma versão de schema/mapping;
- o mesmo contexto de property/owner seed;
- as mesmas regras de promotion policy, confidence cap, normalizer failure e auditoria.

A separação física futura pode usar tabelas/views específicas por família de seed, mas a decisão de projeção e os gates devem ser avaliados juntos para evitar publicar telefone/e-mail sem o contexto de endereço e relacionamento que explica a origem e a qualidade da evidência.

## Evidência revisada

Fontes lidas:

- `docs/issues/16-prop4you-inertia-json-corpus-lfg-manifest/08-directskip-skiptrace-corpus-review.md`
- `docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-base-summary.v1.json`
- `docs/schemas/prop4you/lfg/projection-policy.v1.json`

Achados reutilizados da revisão de corpus:

- 261 candidatos LFG DirectSkip/skip trace parseáveis.
- 6 handoffs SourceHub `directskip-sourcehub-handoffs.json` observados.
- 6/6 handoffs têm `contact_satellites_handoff`.
- 6/6 handoffs têm `mailing_contact_handoff`.
- 6/6 handoffs têm `relationship_evidence_handoff`.
- 0/6 handoffs têm `co_owner_contact_satellites_handoff` na amostra revisada.
- O resumo LFG classifica `directskip_skiptrace` como família relevante e `contact_satellites` como envelope canônico dominante.

## Candidate group recomendado

`candidate_group_key` sugerido:

```text
directskip_skip_trace_unified_contact_evidence
```

Campos recomendados para seed do grupo:

| Campo | Valor recomendado |
| --- | --- |
| `group_label` | DirectSkip skip trace unified contact evidence |
| `source_family` | `directskip_skiptrace` |
| `canonical_envelope_hint` | `contact_satellites` |
| `semantic_lane` | `contact_enrichment` |
| `provider_slug` | `directskip` |
| `list_type_slug` | `skip_trace_contact_discovery` |
| `projection_policy_key` | `lfg_projection_policy.v1` |
| `privacy_class` | `pii_sensitive` |
| `default_decision` | `candidate_review_required` |
| `grouping_rule` | phone/email, mailing address e relationship evidence permanecem juntos por envelope/lineage comum |
| `lineage_required` | true |
| `raw_values_allowed_in_docs` | false |

Relação com política v1:

- JSONB-first para raw payload, provider residue, arrays variáveis, artefatos Matrix e envelopes antes da projeção final.
- Relational-first apenas para anchors, edges, constraints, auth boundaries, snapshots temporais e projeções indexadas de alto valor.

## Candidate paths recomendados

Os caminhos abaixo são paths estruturais/canônicos. Eles não contêm valores raw.

### 1. Envelope SourceHub compartilhado

Candidate paths:

- `contact_satellites_handoff.provider_slug`
- `contact_satellites_handoff.list_type_slug`
- `contact_satellites_handoff.canonical_schema_version`
- `contact_satellites_handoff.mapping_version`
- `contact_satellites_handoff.raw_record_public_id`
- `contact_satellites_handoff.seed_public_id`
- `contact_satellites_handoff.canonical_property_public_id`
- `contact_satellites_handoff.canonical_owner_public_id`
- `contact_satellites_handoff.target_owner_role`
- `contact_satellites_handoff.producer_stage`
- `contact_satellites_handoff.consumer_stage`
- `contact_satellites_handoff.queue`
- `contact_satellites_handoff.ingested_at`
- `contact_satellites_handoff.state_slug`

Projection kind recomendado:

- `relational_column` para identificadores, enums/slug, versões e timestamps usados em join, filtro, auditoria e uniqueness.
- `jsonb_lineage` para envelope completo, caso o DDL tenha coluna de preservação do envelope original.

Justificativa:

- São anchors de lineage e governança. Devem ser consultáveis para dedupe, replay, auditoria e isolamento por provider/list type.

### 2. Phone seeds

Candidate paths:

- `contact_satellites_handoff.phone_seeds[]`
- `contact_satellites_handoff.phone_seeds[].owner_ref`
- `contact_satellites_handoff.phone_seeds[].role_in_record`
- `contact_satellites_handoff.phone_seeds[].phone_number`
- `contact_satellites_handoff.phone_seeds[].contact_role`
- `contact_satellites_handoff.phone_seeds[].phone_type`
- `contact_satellites_handoff.phone_seeds[].phone_subtype`
- `contact_satellites_handoff.phone_seeds[].contact_source_confidence`

Projection kind recomendado:

- `relational_child_projection` ou `materialized_review_path` para linhas de seed telefônico, com valor sensível mascarado/normalizado somente no runtime protegido.
- `jsonb_lineage` para seed completo antes de aprovação.

Default de decisão:

- `review_required`; não publicar em inventário pesquisável até gates e promotion policy passarem.

Observação de privacidade:

- `phone_number` é PII. O review board deve guardar o path e classificação; não deve armazenar valor raw no seed documental.

### 3. Email seeds

Candidate paths:

- `contact_satellites_handoff.email_seeds[]`
- `contact_satellites_handoff.email_seeds[].owner_ref`
- `contact_satellites_handoff.email_seeds[].role_in_record`
- `contact_satellites_handoff.email_seeds[].email`
- `contact_satellites_handoff.email_seeds[].contact_role`
- `contact_satellites_handoff.email_seeds[].contact_source_confidence`

Projection kind recomendado:

- `relational_child_projection` ou `materialized_review_path` para linhas de seed de e-mail, com valor sensível mascarado/normalizado somente no runtime protegido.
- `jsonb_lineage` para seed completo antes de aprovação.

Default de decisão:

- `review_required`; não publicar em inventário pesquisável até gates e promotion policy passarem.

Observação de privacidade:

- `email` é PII. Mesma regra de não imprimir raw values e exigir RLS/retention antes de exposição.

### 4. Mailing/contact address seed

Candidate paths:

- `mailing_contact_handoff.provider_slug`
- `mailing_contact_handoff.list_type_slug`
- `mailing_contact_handoff.canonical_schema_version`
- `mailing_contact_handoff.mapping_version`
- `mailing_contact_handoff.raw_record_public_id`
- `mailing_contact_handoff.seed_public_id`
- `mailing_contact_handoff.canonical_property_public_id`
- `mailing_contact_handoff.state_slug`
- `mailing_contact_handoff.mailing_address_seed`
- `mailing_contact_handoff.mailing_address_seed.address_line`
- `mailing_contact_handoff.mailing_address_seed.secondary_address_line`
- `mailing_contact_handoff.mailing_address_seed.address_number`
- `mailing_contact_handoff.mailing_address_seed.street_line`
- `mailing_contact_handoff.mailing_address_seed.street_name`
- `mailing_contact_handoff.mailing_address_seed.city`
- `mailing_contact_handoff.mailing_address_seed.state`
- `mailing_contact_handoff.mailing_address_seed.zip_code`
- `mailing_contact_handoff.mailing_address_seed.county`
- `mailing_contact_handoff.mailing_address_seed.country`
- `mailing_contact_handoff.mailing_address_seed.normalized_address`
- `mailing_contact_handoff.mailing_address_seed.address_hash`
- `mailing_contact_handoff.mailing_address_seed.is_po_box`
- `mailing_contact_handoff.mailing_address_seed.contact_address_type`
- `mailing_contact_handoff.property_address_seed`
- `mailing_contact_handoff.property_address_comparison`

Projection kind recomendado:

- `relational_column` para envelope e flags/hash usados em dedupe, comparação e join.
- `relational_child_projection` para componente de endereço se houver necessidade de busca/filtro.
- `jsonb_lineage` para `property_address_comparison` completo e componentes variáveis/explicativos.

Default de decisão:

- `review_required`.
- Endereço isolado não deve promover owner/property truth; ele é evidência de contato/mailing dentro do envelope DirectSkip.

### 5. Relationship evidence seeds

Candidate paths:

- `relationship_evidence_handoff.provider_slug`
- `relationship_evidence_handoff.list_type_slug`
- `relationship_evidence_handoff.canonical_schema_version`
- `relationship_evidence_handoff.mapping_version`
- `relationship_evidence_handoff.raw_record_public_id`
- `relationship_evidence_handoff.seed_public_id`
- `relationship_evidence_handoff.canonical_property_public_id`
- `relationship_evidence_handoff.state_slug`
- `relationship_evidence_handoff.owner_returned`
- `relationship_evidence_handoff.property_address_comparison`
- `relationship_evidence_handoff.relationship_evidence_seeds[]`
- `relationship_evidence_handoff.relationship_evidence_seeds[].evidence_ref`
- `relationship_evidence_handoff.relationship_evidence_seeds[].display_name`
- `relationship_evidence_handoff.relationship_evidence_seeds[].first_name`
- `relationship_evidence_handoff.relationship_evidence_seeds[].middle_name`
- `relationship_evidence_handoff.relationship_evidence_seeds[].last_name`
- `relationship_evidence_handoff.relationship_evidence_seeds[].relationship_label`
- `relationship_evidence_handoff.relationship_evidence_seeds[].relationship_type`
- `relationship_evidence_handoff.relationship_evidence_seeds[].age`
- `relationship_evidence_handoff.relationship_evidence_seeds[].identity_resolution_status`
- `relationship_evidence_handoff.relationship_evidence_seeds[].possible_duplicate_of_owner`
- `relationship_evidence_handoff.relationship_evidence_seeds[].duplicate_resolution_vote_required`
- `relationship_evidence_handoff.relationship_evidence_seeds[].owner_match_confidence`
- `relationship_evidence_handoff.relationship_evidence_seeds[].relationship_evidence_confidence`

Projection kind recomendado:

- `relational_edge_candidate` para evidência de relação owner/relative/associate quando aprovada semanticamente.
- `relational_column` para status, flags de duplicidade e confidences usados em review queue.
- `jsonb_lineage` para `owner_returned`, `property_address_comparison` e evidência completa.

Default de decisão:

- `review_required`.
- Relationship evidence não cria canonical owner nem canonical relative automaticamente.

### 6. Métricas, lineage e policy blocks

Candidate paths:

- `contact_satellites_handoff.match_metrics`
- `contact_satellites_handoff.portable_intelligence`
- `contact_satellites_handoff.transformation_lineage`
- `mailing_contact_handoff.portable_intelligence`
- `mailing_contact_handoff.transformation_lineage`
- `relationship_evidence_handoff.transformation_lineage`
- paths derivados de `promotion_policy`
- paths derivados de `recommended_result_status`
- paths derivados de `confidence_cap_applied`
- paths derivados de `normalizer_failure_detected`

Projection kind recomendado:

- `jsonb_lineage` para blocos completos.
- `derived_relational_column` para flags/status de alto valor no review board e em filas de promoção.

Default de decisão:

- `keep_jsonb_with_selected_derived_columns`.

## Gate defaults recomendados

A política v1 exige sete gates para qualquer candidato. Defaults para este grupo:

| Gate | Chave | Default DirectSkip | Motivo |
| ---: | --- | --- | --- |
| 1 | `representative_corpus_observed` | `pass_candidate` para envelope/paths observados nos 6 handoffs; `needs_fixture` para co-owner | Há corpus observado para três handoffs principais; co-owner não apareceu na amostra. |
| 2 | `matrix_leadfinder_semantic_approval` | `pending_review` | Matrix governa significado; DirectSkip não define verdade canônica. |
| 3 | `stable_or_intentionally_provider_specific` | `pass_candidate` para paths SourceHub versionados; `pending_review` para raw/provider residue | SourceHub estabiliza o envelope; raw DirectSkip continua mutável. |
| 4 | `query_join_filter_sort_unique_fk_rls_postgis_or_constraint_need` | `pass_candidate` para envelope ids, confidences, status e seeds pesquisáveis; `jsonb_default` para blocos explicativos | Há necessidade clara de join/dedupe/review, mas não para todo JSON. |
| 5 | `safe_cast_or_coercion_exists` | `pending_review` | Requer normalizadores/mascaramento para telefone, e-mail, endereço e confidences. |
| 6 | `durable_lineage_to_raw_json` | `pass_candidate` | Envelope contém raw/seed ids, versions, stage e transformation lineage. |
| 7 | `privacy_pii_classified` | `pass_candidate` com classe `pii_sensitive` e exposição bloqueada por padrão | Paths de contato/endereço/nome são PII e precisam classificação explícita. |

Regra de aprovação:

- Nenhum candidate path deve ser `approved_for_projection` enquanto os sete gates não estiverem passados.
- Default operacional do grupo: `candidate_review_required`.
- Default de exposição: `not_public`, `no_public_api_rls_until_envelopes_stabilize`.

## Recomendações para DDL seed

1. Seedar um grupo único `directskip_skip_trace_unified_contact_evidence`.
2. Amarrar todos os candidate paths acima a esse mesmo grupo.
3. Registrar `candidate_path_family` como uma das famílias:
   - `shared_envelope`
   - `phone_seed`
   - `email_seed`
   - `mailing_address_seed`
   - `relationship_evidence_seed`
   - `policy_metrics_lineage`
4. Usar `projection_kind` com vocabulário mínimo:
   - `relational_column`
   - `relational_child_projection`
   - `relational_edge_candidate`
   - `derived_relational_column`
   - `jsonb_lineage`
   - `keep_jsonb`
5. Seedar sete gate rows por candidate path.
6. Marcar `privacy_class=pii_sensitive` para telefone, e-mail, endereço, nomes, idade e relationship evidence.
7. Marcar `privacy_class=internal` ou `restricted` para lineage/policy/match metrics conforme escopo de acesso.
8. Incluir `no_raw_values_in_docs=true` e `raw_lineage_required=true` no metadata JSONB do grupo/candidato.

## Riscos e controles

Riscos principais:

- Publicação prematura de contato PII antes de RLS, mascaramento, retention e política de promoção.
- Fragmentação incorreta do envelope em grupos independentes, perdendo contexto de qualidade/lineage.
- Tratar DirectSkip como fonte canônica de owner/property, contrariando a regra LFG de que Skip Trace enriquece, mas não define a verdade.
- `co_owner_contact_satellites_handoff` não foi observado nos 6 handoffs; modelagem deve exigir fixture/prova antes de aprovação.
- Campos de relationship evidence podem criar falsos positivos de parentes/co-owners se projetados como edge canônica sem voto/resolução.
- Raw payload e Matrix registry são úteis para parser/drift/governança, mas não devem virar registros operacionais achatados.

Controles recomendados:

- Review board com sete gates obrigatórios.
- `candidate_review_required` como default.
- `keep_jsonb` para raw payload, provider residue, Matrix artifacts, portable intelligence e transformation lineage completo.
- Colunas derivadas apenas para status/flags/confidences necessários ao review e dedupe.
- Teste/fixture separado para co-owner antes de qualquer seed aprovado.
- Auditoria de promotion policy antes de tornar contatos pesquisáveis.

## Conclusão

A recomendação é avançar com um único grupo DirectSkip unificado no review board. O grupo deve conter paths de phone/email, mailing address e relationship evidence juntos, com projeção relacional seletiva apenas para anchors, seeds, status/flags e edges candidatos que sejam necessários para busca, join, dedupe, review ou auditoria. Raw payloads, artefatos Matrix, lineage e blocos explicativos permanecem JSONB-first.
