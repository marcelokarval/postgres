# Plano — Dicionário canônico Matrix <-> SourceHub <-> LeadFinder

Status: draft para revisão
Worker: B
Idioma: pt-BR
Fonte inspecionada: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`

## 1. Tese operacional

A extração Prop4You para DDL database-centric não deve começar congelando tabelas a partir dos models Django. O fluxo canônico deve começar pelo contrato semântico entre três donos:

1. LeadFinder define o grafo canônico e publica o baseline semântico que descreve famílias, campos, aliases, regras de validação e prioridades de materialização.
2. Matrix compara payloads de provedores contra esse baseline, mantém o dicionário semântico, aprova genomes/mappings por escopo de provedor/lista/estado/versão e registra conflitos/drift.
3. SourceHub recebe payloads brutos, preserva linhagem, aplica somente artefatos Matrix ativos, publica DTOs canônicos/famílias de seeds e entrega ao LeadFinder para materialização.

Regra central: Matrix governa significado; SourceHub governa ingresso/linhagem/publicação de DTO; LeadFinder governa o grafo canônico consumível. Skip Trace, Realtor, REIQ e fluxos produto-originated enriquecem ou fornecem evidência, mas não definem por si só verdade durável de propriedade, dono ou situação.

## 2. Evidência de código analisada

### Matrix

Arquivos principais:

- `apps/system/matrix/models.py`
- `apps/system/matrix/analysis_runtime.py`
- `apps/system/matrix/provider_admission.py`
- `apps/system/matrix/*_pre_sourcehub_dto.py`
- `apps/system/matrix/*_pre_sourcehub_contracts.py`
- `apps/system/matrix/primitives/*`

Achados relevantes:

- `MatrixLeadFinderDefaultBaseline` armazena snapshot do baseline publicado pelo LeadFinder: `baseline_key`, `baseline_version`, `canonical_ontology_ref`, `published_contract_ref`, `baseline_payload`, `supplied_by`.
- `MatrixSchemaGenome` é o artefato runtime aprovado por escopo: `provider_slug`, `list_type_slug`, `state_slug`, `mapping_version`, `artifact_version`, `field_mappings`, `transformations`, `validation_rules`, `compiled_schema`, `confidence_threshold`, contadores de campos e vínculo para o baseline LeadFinder.
- O lifecycle atual diferencia `draft`, `pending_approval`, `approved`, `active`, `deprecated`, `archived` e garante apenas um genome ativo por escopo.
- `MatrixCorpusSession` modela onboarding/revalidation com `raw_record_public_ids`, `sample_payloads`, `corpus_stats`, `step_outputs`, `analysis_summary` e vínculo a baseline/genome.
- `MatrixFieldReview`, `MatrixApprovalRecord` e `MatrixGrowthPressureSignal` já representam revisão HITL, aprovação e pressão de crescimento semântico.
- `analysis_runtime.py` já possui uma costura explícita chamada `build_canonical_dictionary_runtime_snapshot`, que monta `canonical_fields`, famílias, alias catalog, alias entries e alias lookup a partir do baseline LeadFinder + genomes ativos.
- `provider_admission.py` bloqueia SourceHub se não houver `MatrixSchemaGenome` ativo para `provider_slug/list_type_slug/mapping_version`, expondo `MATRIX_RUNTIME_REENTRY_TRIGGERS`: `new_provider`, `new_list_type`, `new_mapping_version`, `new_canonical_family`, `new_taxonomy_family`, `promotion_rule_change`, `provider_drift_detected`, `semantic_conflict_detected`.

### SourceHub

Arquivos principais:

- `domains/data/models/sourcehub.py`
- `apps/system/sourcehub/contracts.py`
- `apps/system/sourcehub/producer.py`
- `apps/system/sourcehub/*_ingestion.py`
- `apps/system/sourcehub/*_normalization.py`

Achados relevantes:

- `SourceHubRawRecord` é a camada bronze: `provider_slug`, `list_type_slug`, `state_slug`, `ingestion_mode`, `payload_format`, `processing_status`, `external_reference_id`, `payload_hash`, `raw_payload`, `ingested_at`, `processed_at`; há unicidade por escopo + hash.
- `contracts.py` declara explicitamente as ownership rules: SourceHub owns raw record persistence, lineage tracking, canonical transformation; Matrix provides semantic mapping artifacts; LeadFinder consumes canonical DTOs.
- `SourceHubRawPayloadEnvelope` formaliza ingresso bruto.
- `SourceHubCanonicalDTOEnvelope`, `SourceHubAddressSeedEnvelope`, `SourceHubProductOriginAddressSeedEnvelope`, `SourceHubPropertyDetailsSeedEnvelope`, `SourceHubMailingContactSeedEnvelope`, `SourceHubPartyRolesSeedEnvelope`, `SourceHubRelationshipEvidenceSeedEnvelope`, `SourceHubLegalTimelineSeedEnvelope`, `SourceHubValuationFinancialSeedEnvelope` formalizam publicação por famílias.
- `CanonicalProvenanceBlock` preserva `provider_mapping_ref`, `canonical_ontology_ref`, `runtime_approval_mode`, `matrix_reentry_triggers`, `raw_record_public_id`, `payload_hash`, `schema_genome_ref`, `matrix_genome_public_id`, artefato compilado e contrato LeadFinder publicado.
- `SourceHubTaxonomyFramingBlock` distingue framing/taxonomia do provedor (`source_list_type_slug`) de verdade canônica. A própria docstring alerta que `list_type_slug` não vira automaticamente `situation_type`.
- `CanonicalSituationBlock` deixa claro que situações são fatos estruturados, não tags.
- `PortableIntelligenceBlock` marca inteligência portátil como `semantic_owner=matrix_artifact` e projeção determinística SourceHub.

### LeadFinder

Arquivos principais:

- `apps/system/lead_finder/baseline.py`
- `apps/system/lead_finder/baseline_authoring.py`
- `apps/system/lead_finder/contracts.py`
- `apps/system/lead_finder/hydration.py`
- `domains/real_estate/models/canonical_graph.py`
- `domains/real_estate/models/canonical_party_graph.py`
- `domains/real_estate/models/situation_models.py`
- `domains/real_estate/models/*_models.py`

Achados relevantes:

- `baseline.py` declara que o Lead Finder Group owns the canonical/default genome e Matrix consome esse contrato; o conteúdo semântico é JSON-first/versionado.
- O baseline exige `family_catalog`, `families`, `field_catalog`, `semantic_owner`, `source_of_truth`, `approval_status`, `published_contract_ref`, `canonical_ontology_ref`.
- `baseline_authoring.py` modela source pack, candidate delta, lifecycle `draft -> candidate_review -> approved -> published -> superseded/retired` e convergência de `MatrixGrowthPressureSignal` para evolução do baseline.
- `hydration.py` consome DTOs SourceHub e materializa o grafo mínimo: `Property`, `PropertyLocation`, `OwnerEntity`, `Ownership`, `PropertySituation`, `PropertySnapshot/PropertyHistory`, além de famílias de detalhes, valuation, timeline, representantes, contatos, party roles, comparables e overlays.
- A hidratação declara que lógica provider-specific deve ficar fora do LeadFinder; LeadFinder materializa payloads canônicos, não payload bruto do provedor.
- Snapshots preservam provenance (`raw_record_public_id`, `dto_public_id`, `mapping_version`, `canonical_schema_version`, `provider_slug`, `list_type_slug`, tempos de ingestão/processamento) e source facts.

## 3. Dicionário canônico: conceito e conteúdo mínimo

O dicionário canônico é um contrato versionado, auditável e consultável no banco que responde:

- Qual é o campo/família canônica?
- Qual é o significado de negócio?
- Quais aliases/provedor-campos apontam para ele?
- Qual transformação/normalização é permitida?
- Qual validação é obrigatória?
- Qual materialização downstream é permitida?
- Quem é o dono semântico?
- Qual baseline/genome/mapping aprovou a decisão?
- Qual evidência bruta sustentou a decisão?

### Estrutura sugerida do payload do dicionário

```json
{
  "dictionary_ref": "matrix.dictionary.lead_finder.lf_default.v1",
  "dictionary_version": "lf_default.v1",
  "semantic_owner": "lead_finder_group",
  "canonical_ontology_ref": "matrix.ontology.lead_finder_baseline.v1",
  "published_contract_ref": "lead_finder.default_genome.lf_default.v1",
  "families": {
    "identity": ["street_address", "city", "state", "apn"],
    "owner_identity": ["owner_display_name", "owner_entity_type"],
    "legal_timeline": ["case_number", "date_filed"],
    "valuation_financial": ["estimated_value", "equity_percentage"]
  },
  "field_catalog": {
    "street_address": {
      "family": "identity",
      "semantic_type": "postal_address_line",
      "type": "string",
      "business_meaning": "Linha principal do endereço físico do imóvel canônico.",
      "aliases": ["property_address", "situs_address", "address"],
      "confusable_with": ["mailing_street_address"],
      "transform_hints": ["trim", "normalize_street"],
      "validation_rules": {"required_for_property_identity": true},
      "downstream_projection_hints": ["PropertyLocation.street_address"]
    }
  },
  "alias_catalog": {
    "situs_address": "street_address",
    "property_address": "street_address"
  },
  "conflict_rules": [
    {
      "rule_key": "mailing_address_not_property_identity",
      "when_alias": "mailing_address",
      "do_not_promote_to": "street_address",
      "route_to_family": "mailing_contact"
    }
  ]
}
```

### Entidades DDL futuras sugeridas

Em DDL database-centric, o dicionário deve virar schemas/tabelas/funções, não apps Python:

- `matrix.semantic_dictionary`
  - `public_id`, `dictionary_ref`, `dictionary_version`, `semantic_owner`, `canonical_ontology_ref`, `published_contract_ref`, `status`, `payload jsonb`, `activated_at`, `deprecated_at`.
- `matrix.canonical_family`
  - família, descrição, prioridade, consumidores obrigatórios, regras de promoção.
- `matrix.canonical_field`
  - campo, família, tipo, semantic_type, significado, exemplos, anti-exemplos, validações, transform hints.
- `matrix.field_alias`
  - alias normalizado, campo canônico, escopo opcional de provider/list/state, confiança, origem (`lead_finder_published_contract`, `active_provider_genome`, `peer_active_genome`, `hitl_review`).
- `matrix.provider_payload_corpus`
  - amostras de `SourceHubRawRecord`, hashes, estatísticas de campos, paths JSON, tipos observados.
- `matrix.provider_field_mapping`
  - source path -> canonical field/family, confidence, match_type, transformation_ref, validation_ref, review status.
- `matrix.semantic_conflict`
  - conflito, severidade, campos/provedores afetados, decisão, status, resolução.
- `sourcehub.raw_record`
  - equivalente database-centric de `SourceHubRawRecord`.
- `sourcehub.canonical_dto_publication`
  - envelope DTO/seed publicado, lineage, hash, schema version, matrix artifact refs.
- `lead_finder.property_graph_*`
  - grafo canônico consumindo DTOs, nunca payload bruto diretamente.

## 4. Workflow canônico de comparação de payloads

### 4.1 Ingresso e preservação bruta

1. SourceHub recebe `SourceHubRawPayloadEnvelope`.
2. Persiste `SourceHubRawRecord` com `raw_payload`, `payload_hash`, `provider_slug`, `list_type_slug`, `state_slug`, `ingestion_mode`, `payload_format`.
3. Nenhuma escrita canônica ocorre neste passo.
4. Se o provider/list/mapping ainda não tem genome Matrix ativo, SourceHub deve marcar o item como aguardando admissão/Matrix, não improvisar mapeamento.

### 4.2 Formação de corpus Matrix

1. Matrix cria `MatrixCorpusSession` de `onboarding` ou `revalidation` apontando para `raw_record_public_ids`.
2. Extrai paths JSON, tipos observados, samples, cardinalidade, presença/frequência, nullish values, formatos de data/telefone/email/número.
3. Compara cada path contra:
   - `field_catalog` do baseline LeadFinder.
   - `alias_catalog` do baseline.
   - aliases contextualizados.
   - genomes ativos do mesmo list_type/state e peers.
4. Classifica cada campo como:
   - match canônico de alta confiança;
   - match canônico de baixa confiança;
   - evidência não materializável;
   - framing/taxonomia;
   - campo novo candidato;
   - conflito semântico;
   - drift de provider.

### 4.3 Revisão e aprovação

1. Campos ambíguos geram `MatrixFieldReview`.
2. Lacunas geram `MatrixGrowthPressureSignal`:
   - `missing_canonical_field`
   - `underfed_canonical_family`
   - `promotion_rule_gap`
   - `sourcehub_framing_gap`
   - `provider_drift_observed`
3. HITL decide: aprovar, rejeitar, deferir ou pedir baseline delta.
4. Matrix compila `MatrixSchemaGenome` com `field_mappings`, `transformations`, `validation_rules`, `compiled_schema`, `analysis_summary`, `growth_classification`.
5. Genome só entra em runtime após `approve()` + `activate()`.

### 4.4 Admissão SourceHub

1. SourceHub chama a regra equivalente a `get_matrix_approved_provider_artifact`.
2. Se não houver genome ativo para provider/list/mapping, bloqueia admissão.
3. Se houver, SourceHub transforma raw -> DTO/seed e carrega no `CanonicalProvenanceBlock`:
   - `provider_mapping_ref`
   - `canonical_ontology_ref`
   - `matrix_genome_public_id`
   - `schema_genome_ref`
   - `matrix_compiled_artifact_ref/version`
   - `published_contract_ref/version`
   - `lead_finder_published_contract_ref/version`
   - `raw_record_public_id`
   - `payload_hash`
4. SourceHub publica uma das famílias:
   - full property DTO;
   - address seed;
   - product-originated address seed;
   - property details seed;
   - mailing/contact seed;
   - party roles;
   - relationship evidence;
   - legal timeline;
   - valuation/financial;
   - territory/area;
   - comparables/evidence-only.

### 4.5 Consumo LeadFinder

1. LeadFinder recebe somente DTO/seed SourceHub.
2. Materializa grafo por famílias e regras de aquisição/upsert.
3. Mantém snapshot/histórico com lineage para replay/auditoria.
4. Nunca usa `provider_slug/list_type_slug` como verdade canônica automática. Esses campos são provenance/framing, não domínio.

## 5. Contratos DTO obrigatórios

### SourceHubRawPayloadEnvelope

Campos mínimos:

- `provider_slug`
- `list_type_slug`
- `state_slug`
- `ingested_at`
- `stage=sourcehub`
- `ingestion_mode`
- `payload_format`
- `raw_payload`
- `external_reference_id`

### CanonicalProvenanceBlock

Campos obrigatórios no futuro DDL:

- `canonical_schema_version`
- `provider_slug`
- `list_type_slug`
- `state_slug`
- `mapping_version`
- `provider_mapping_ref`
- `canonical_ontology_ref`
- `runtime_approval_mode=consume_approved_matrix_artifact_only`
- `matrix_reentry_triggers`
- `raw_record_public_id`
- `payload_hash`
- `ingested_at`
- `processed_at`
- `schema_genome_ref`
- `matrix_genome_public_id`
- `matrix_compiled_artifact_ref/version`
- `matrix_compiled_from_session_public_id`
- `published_contract_ref/version`
- `lead_finder_published_contract_ref/version`

### CanonicalPropertyDTO

Famílias mínimas que LeadFinder pode consumir:

- `property.location`
- `property.details`
- `owners[]`
- `ownerships[]`
- `situations[]`
- `owner_projection_candidate`
- `mailing_address`
- `role_addresses[]`
- `contact_phones[]`
- `contact_emails[]`
- `party_roles[]`
- `entity_representatives[]`
- `legal_timeline`
- `valuation_financial`
- `provider_reference`
- `listing_evidence`
- `media_evidence`
- `market_status_evidence`
- `portable_intelligence`
- `address_source_facts[]`
- `property_source_facts[]`
- `provenance`

### Exemplo: situação estruturada

```json
{
  "situations": [
    {
      "situation_type": "pre_foreclosure",
      "situation_status": "active",
      "date_filed": "2026-01-10",
      "case_number": "2026-CF-1234",
      "external_reference_id": "reiq:abc123"
    }
  ],
  "provenance": {
    "provider_slug": "reiq",
    "list_type_slug": "pre_foreclosure",
    "mapping_version": "reiq.pre_foreclosure.fl.v1",
    "raw_record_public_id": "shraw_..."
  }
}
```

Observação: `list_type_slug=pre_foreclosure` sozinho não cria a situação. A situação só existe quando SourceHub, autorizado por Matrix, mapeia campos para `CanonicalSituationBlock`.

### Exemplo: endereço de correspondência não é endereço do imóvel

```json
{
  "property": {
    "location": {
      "street_address": "100 Main St",
      "city": "Orlando",
      "state": "FL"
    }
  },
  "mailing_address": {
    "street_address": "PO Box 123",
    "city": "Miami",
    "state": "FL",
    "recipient_name": "Maria Silva"
  },
  "taxonomy_framing": {
    "source_list_type_slug": "tax_sale",
    "downstream_family_targets": ["identity", "mailing_contact", "valuation_financial"]
  }
}
```

O conflito `mailing_address` vs `property.location.street_address` deve ser resolvido no dicionário via `confusable_with`/`conflict_rules`, não por heurística ad hoc em LeadFinder.

## 6. Lifecycle do dicionário semântico

### 6.1 Estados

Estados propostos para `matrix.semantic_dictionary` e contrato LeadFinder relacionado:

1. `draft` — edição local, sem consumo runtime.
2. `candidate_review` — delta gerado a partir de corpus/pressures e aguardando revisão.
3. `approved` — semântica aceita, ainda não ativa.
4. `published` ou `active` — versão runtime consumível por Matrix/SourceHub.
5. `superseded` ou `deprecated` — versão substituída, ainda auditável/replayável.
6. `retired` ou `archived` — não usada para novos DTOs, preservada para lineage.

### 6.2 Evolução normal

1. LeadFinder publica baseline vN.
2. Matrix sincroniza snapshot ativo.
3. Matrix compara corpus e abre reviews/pressures.
4. Se a mudança é apenas provider-specific, Matrix publica novo genome vN.patch sem mudar baseline.
5. Se a mudança altera conceito/família/campo canônico, gera candidate delta para LeadFinder.
6. LeadFinder aprova e publica baseline vN+1.
7. Matrix revalida genomes afetados contra vN+1.
8. SourceHub só consome novo mapping após genome ativo.

### 6.3 Versionamento

- Baseline LeadFinder: `lf_default.v1`, `lf_default.v2`, etc.
- Ontologia: `matrix.ontology.lead_finder_baseline.v1`.
- Published contract ref: `lead_finder.default_genome.lf_default.v1`.
- Provider mapping ref: `matrix.provider_mapping.<provider>.<list_type>[.<state>].<version>`.
- Genome ref: `matrix.genome.<provider>.<list_type>[.<state>].<version>`.
- Artifact compiled version: semver ou versão imutável (`1.0.0`, `1.0.1`) vinculada ao genome.
- DTO schema version: `sourcehub.canonical_property_dto.vN` ou `pilot.v0` enquanto em piloto.

Regra: qualquer DTO materializado precisa carregar todas as versões relevantes para permitir replay com o mesmo significado original.

## 7. Resolução de conflitos

### 7.1 Tipos de conflito

- Alias ambíguo: mesmo alias aponta para campos canônicos diferentes.
- Família errada: campo do provedor parece `identity`, mas é `mailing_contact` ou `provider_reference`.
- Tipo incompatível: campo esperado como data chega como texto livre não parseável.
- Semântica de lista confundida com fato: `list_type_slug` usado como `situation_type` sem evidência estruturada.
- Provider drift: campo mudou de formato/nome/meaning mantendo o mesmo provider/list.
- Promoção prematura: evidência deveria ficar em `*_evidence` ou source facts, mas foi promovida para verdade canônica.
- Owner/property conflation: owner returned de skip trace tratado como owner truth sem cadeia de decisão.
- Taxonomia/tag confundida com situação: workspace tags ou system labels viram lead taxonomy indevidamente.

### 7.2 Política de decisão

1. Campo canônico existente + alias inequívoco + validação ok: auto-aprovável.
2. Campo canônico existente + baixa confiança: `MatrixFieldReview.awaiting_hitl`.
3. Campo novo dentro de família existente: `MatrixGrowthPressureSignal.missing_canonical_field`.
4. Família nova: candidate delta LeadFinder obrigatório.
5. Campo provider-specific sem valor canônico: preservar em evidence/residue/source_facts.
6. Conflito entre provedores: Matrix mantém alias escopado por provider/list/state até baseline decidir generalizar.
7. LeadFinder só materializa quando DTO explicita família canônica e provenance aprovada.

### 7.3 Exemplo de conflito

```json
{
  "conflict_key": "reiq.owner_name_vs_mortgagor_name",
  "provider_slug": "reiq",
  "list_type_slug": "loan_modification",
  "source_fields": ["owner_name", "mortgagor_name"],
  "candidate_targets": ["owners[].display_name", "party_roles[].display_name"],
  "decision": "owner_name materializa owner; mortgagor_name materializa party_role=mortgagor unless same normalized identity",
  "status": "approved",
  "requires_snapshot_lineage": true
}
```

## 8. Como isso altera a ordem de extração

Ordem anterior simplificada tenderia a extrair models Django por domínio/tabela. A ordem correta passa a ser semântica/contratual:

1. Base DDL comum: install tracking, public refs/uuid7, JSONB contract helpers, audit/outbox se necessário.
2. `sourcehub` bronze: raw records, payload hash, ingestion lineage, payload snapshots, DTO publication ledger.
3. `lead_finder` baseline semântico mínimo: contratos de família/campo/alias como JSONB versionado e tabelas de catálogo.
4. `matrix` dictionary/control plane: corpus sessions, dictionary snapshots, field reviews, genomes, approval records, growth pressure/conflicts.
5. `sourcehub` transformation/publication: funções/RPCs que exigem Matrix active genome para publicar DTO/seed.
6. `lead_finder` acquisition/materialization: property/location first, owner/ownership second, situations structured third, snapshots/provenance always.
7. Famílias incrementais: property_details, valuation_financial, legal_timeline, mailing/contact, party_roles, relationship_evidence, representatives, comparables, territory.
8. Public/API facades: LeadFinder, MyProperty, SkipTracing, operator tools consomem projeções; não definem verdade.
9. Generated/projected columns: só depois que JSONB paths do SourceHub/Matrix estiverem estáveis e aceitos no dicionário.

Impacto: antes de escrever DDL durável para uma entidade ou coluna, deve existir uma resposta no dicionário: família, campo, owner semântico, mapping, validação, materialização e conflito conhecido.

## 9. Plano de implementação DDL futuro

### Slice A — Catálogo semântico mínimo

- Criar schema `matrix` com tabelas de dictionary, family, field, alias, dictionary_version.
- Criar schema `lead_finder` com baseline published contract ledger ou espelhar em `matrix.lead_finder_default_baseline`.
- Criar funções:
  - `matrix.publish_dictionary_version(payload jsonb)`
  - `matrix.activate_dictionary_version(dictionary_ref, version)`
  - `matrix.resolve_alias(alias, provider_slug, list_type_slug, state_slug)`

### Slice B — SourceHub bronze + corpus

- Criar `sourcehub.raw_record` com payload JSONB e unicidade por escopo/hash.
- Criar `matrix.corpus_session` e `matrix.corpus_sample` apontando para raw records.
- Criar função de análise de estrutura JSONB em modo determinístico: paths, tipos, samples, frequência.

### Slice C — Genome e aprovação

- Criar `matrix.provider_genome`, `matrix.provider_field_mapping`, `matrix.field_review`, `matrix.approval_record`, `matrix.growth_pressure_signal`.
- Garantir unique active genome por `provider/list/state`.
- Criar RPC `matrix.require_active_genome(provider, list, mapping_version, state)`.

### Slice D — SourceHub DTO publication

- Criar `sourcehub.dto_publication` com payload DTO JSONB, lineage JSONB, schema_version, matrix refs.
- Criar constraints/checks mínimos para `CanonicalProvenanceBlock`.
- Criar fila/outbox para downstream LeadFinder.

### Slice E — LeadFinder graph consumption

- Materializar `lead_finder.property`, `property_location`, `owner_entity`, `ownership`, `property_situation`, `property_snapshot` primeiro.
- Só depois materializar famílias especializadas.
- Todo materializer exige `sourcehub.dto_publication_public_id` ou equivalente lineage.

## 10. Critérios de aceite

### Documentação/planejamento

- Este plano está versionado em `docs/issues/00-prop4you-database-centric-extraction-plan/09-matrix-sourcehub-leadfinder-canonical-dictionary.md`.
- O plano cita explicitamente donos: Matrix, SourceHub, LeadFinder.
- O plano inclui comparação de payloads, lifecycle de dicionário, DTO contracts, SourceHub ingress/lineage, consumo LeadFinder, resolução de conflitos, versionamento e impacto na ordem de extração.

### Para implementação futura

- Nenhum provider payload pode ser materializado em LeadFinder sem `sourcehub.raw_record` e lineage.
- Nenhum SourceHub DTO runtime pode ser publicado sem genome Matrix ativo.
- Nenhum novo campo canônico pode entrar em runtime sem baseline/dictionary version aprovado.
- `provider_slug/list_type_slug` devem permanecer provenance/framing até mapeados explicitamente em bloco canônico.
- Situações devem estar em `CanonicalSituationBlock`/tabela equivalente, nunca apenas em tags.
- Skip Trace/DirectSkip deve alimentar owner/contact/relationship evidence; não deve sobrescrever owner truth sem regra de owner resolution aprovada.
- Snapshots LeadFinder devem carregar `raw_record_public_id`, `dto_publication_public_id` ou `dto_public_id`, `mapping_version`, `canonical_schema_version`, `matrix_genome_public_id` e contrato LeadFinder publicado.
- Conflitos semânticos devem gerar review/pressure, não fallback silencioso.
- JSONB raw/evidence deve ser preservado antes de qualquer coluna gerada/projetada.
- Colunas projetadas só são aceitas quando o dicionário marca path como estável e frequentemente consultado.

## 11. Questões/riscos para revisão Thor

- O backend atual mistura alguns artefatos semânticos em Python/JSON e models Django; a DDL final deve separar catálogo versionado, runtime active snapshots e DTO publication ledger.
- `pilot.v0` ainda aparece como schema version em SourceHub producer; a extração deve decidir quando promover para versão estável (`sourcehub.canonical_property_dto.v1`).
- Há muitos DTOs pre-sourcehub por provider/list; a implementação DDL deve evitar criar uma tabela por provider/list. O caminho correto é corpus JSONB + mapping versionado + DTO canônico.
- A baseline LeadFinder atual é arquivo JSON/runtime loader; no PG18 database-centric ela deve ter ledger e ativação no banco, mantendo compatibilidade de artifact refs.
- Comparables, territory/area e overlays são evidência/projeções especializadas; não devem atrasar o núcleo property/location/owner/situation, mas precisam lineage desde o início.
