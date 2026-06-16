# Worker B — Prop4You-Inertia LeadFinder: system boundaries and data-model evidence

Escopo analisado: `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src` em modo somente leitura, com foco em `apps/system/matrix`, `apps/system/sourcehub`, `apps/system/lead_finder`, `apps/public/lead_finder`, `domains/real_estate`, `domains/data` e testes relacionados. Não executei chamadas de provider e não copiei payloads/PII; a evidência abaixo é estrutural, por arquivos/modelos/testes.

## [LEADFINDER_GROUP]

Conclusão: no Prop4You-Inertia, “LeadFinder group” deve ser lido como o contêiner do coração canônico de inventário imobiliário, não como apenas a UI pública `apps/public/lead_finder` nem como Matrix/SourceHub. Ele agrupa as apps/tabelas/famílias que materializam e redistribuem a verdade pesquisável de propriedade/owner/lead.

Container funcional observado:

- Apps de sistema:
  - `apps/system/lead_finder`: boundary de consumo/materialização do inventário canônico.
  - `apps/system/matrix`: boundary semântico/admissão de provider e baseline, upstream.
  - `apps/system/sourcehub`: ingress/handoff producer, upstream.
- App pública/workspace:
  - `apps/public/lead_finder`: consulta/serializa inventário para UI pública, sem possuir raw ingress nem graph truth.
- Domínio/tabelas centrais em `domains/real_estate.models`:
  - Propriedade/endereço: `Property`, `PropertyLocation`, `SystemAddress` por FK.
  - Detalhes/fotos: `PropertyDetails`, incluindo `photos`, `property_type`, building/land/listing fields.
  - Histórico/snapshots: `PropertyHistory`/`PropertySnapshot`.
  - Situações/lead type: `PropertySituation` com `situation_type`, `situation_status`, datas, case/document.
  - Valuation: `PropertyValuation` com assessed/appraised/estimated values, mortgage/equity.
  - Owner/ownership: `OwnerEntity`, `Ownership`, `PartyRole`, `OwnerEntityRepresentative`.
  - Relações históricas/pessoais: `PersonRelationship`.
  - Contact satellites/status: `OwnerContactAddress`, `OwnerPhone`, `OwnerEmail`, com status/callability/sendability, DNC, bounce etc.
  - Overlays/workspace ainda presentes mas distintos: `PropertyTag`, `PropertyList`, `SavedProperty`, registries/tags de contato.

Evidência principal:

- `apps/system/lead_finder/README.md:1-6` define `apps/system/lead_finder` como boundary da canonical inventory, downstream de SourceHub e upstream de public/workspace.
- `apps/system/lead_finder/README.md:200-216` lista o baseline materializado atual: `Property`/`PropertyLocation`/`SystemAddress`, `PropertyDetails`, `OwnerContactAddress`, `OwnerPhone`, `OwnerEmail`, `PartyRole`, legal timeline reduzida em `PropertySituation`, `OwnerEntity`, `Ownership`, snapshots e typed source facts.
- `apps/system/lead_finder/README.md:236-287` congela o pacote de expansão: details, owner/ownership, mailing address, contact satellites, legal timeline, valuation, party roles, role addresses e relationship evidence.
- `apps/system/lead_finder/contracts.py:60-72` enumera famílias de materialização: `identity_address`, `property_details`, `owner_ownership`, `mailing_address`, `contact_satellites`, `party_roles`, `entity_representatives`, `relationship_evidence`, `legal_timeline`, `valuation_financial`, `systemic_taxonomy`.
- `domains/real_estate/models/__init__.py:1-13` documenta que `PropertyLeadFinder` é o modelo canônico usado por Lead Finder, scoring, enrichment e flows de sistema, enquanto `PropertySimple` é resíduo legacy/simple; o barrel export é deliberadamente estreito para evitar reacoplamento amplo.

## [SYSTEM_MATRIX]

Conclusão: Matrix não é dono do “system heart”; Matrix é engine semântico/admissão acima do SourceHub. Ele consome o baseline publicado pelo LeadFinder group, mapeia provider/state/list reality contra esse baseline, aprova genome/artifact e bloqueia/admite runtime por tuple provider/list/mapping.

Evidência:

- `apps/system/matrix/README.md:3-9` diz que Matrix é boundary de canonical schema intelligence, upstream de SourceHub, dono do significado/mapping artifacts, não de raw ingress, adapters ou entidades canônicas.
- `apps/system/matrix/README.md:11-22` explicita a leitura corrigida: Lead Finder group possui baseline inicial por necessidade de materialização; Matrix mapeia provider reality para esse baseline; Matrix sugere crescimento; approval/HITL valida; Matrix é semantic engine sobre baseline LF-owned.
- `apps/system/matrix/README.md:183-197` limita perguntas/responsabilidades de Matrix e impõe admission artifacts consumidos por SourceHub para tuples `provider/list_type/mapping_version`.
- `apps/system/matrix/models.py:97-118` materializa `MatrixLeadFinderDefaultBaseline`, com `baseline_payload`, `published_contract_ref`, `supplied_by="lead_finder_group"`.
- `apps/system/matrix/models.py:219-240` inicia `MatrixSchemaGenome`, compilado da análise de corpus sobre baseline LF, com `provider_slug`, `list_type_slug`, `state_slug`, `mapping_version`, refs de provider mapping/ontology/genome.

Risco corrigido: chamar Matrix de “dono da canonical domain” ou “system heart” reintroduz o erro de centralizar runtime fact/relational truth em uma camada de mapping/approval. Matrix deve aprovar e versionar semântica; não materializar `Property`, `OwnerEntity`, contacts etc.

## [SOURCEHUB_OR_EQUIVALENT]

Conclusão: SourceHub é o equivalente/porta de ingress e producer. Ele começa quando dados externos/upload/produto entram em forma raw ou SourceHub-compatible handoff; publica DTOs/family packets para Lead Finder. Ele não deve persistir o graph canônico final nem assumir a UI/workspace.

Evidência:

- `apps/system/sourcehub/README.md:3-9` define SourceHub como boundary para ingress externo e producer stage da canonical pipeline; owns raw payload intake -> canonical DTO publication; não owns graph nem subscriber-facing behavior.
- `apps/system/sourcehub/README.md:31-75` descreve o family packet para Lead Finder baseline: identity, building, land, mailing_contact, role_addresses, party_roles, relationship_evidence, legal_timeline, valuation_financial, taxonomy_bridge, operator_lineage_only. Regra importante: são seeds/evidence producer-stage, não writes automáticos; Lead Finder é materializer downstream.
- `apps/system/sourcehub/README.md:174-198` lista owns/does not own: raw payload intake, append-only records, ETL, source facts, raw-to-canonical DTO, producer taxonomy framing; não owns canonical graph entities, public search/workspace, CRM/registry, adapters.
- `domains/data/models/sourcehub.py:36-96` define `SourceHubRawRecord` com provider/list/state, ingestion mode, payload hash/raw payload, processing status e unique scope/hash. É bronze/raw lineage, não graph truth.
- `apps/system/sourcehub/README.md:217-229` indica que runtime é `provider -> SourceHub consumes approved Matrix artifact refs -> Lead Finder consumes SourceHub handoff`; Matrix não reabre por payload aprovado.
- `apps/system/sourcehub/README.md:262-317` exige SourceHub sempre que fluxo cria/atualiza canonical property truth, inclusive product-originated (`My Property`, `Skip Trace`) via `SourceHubProductOriginAddressSeedEnvelope`.

## [DJANGO_MISTAKE_RISK]

Erro Django-era identificado: no port legado, modelos do antigo `system/lead_finder/.../models/*.py` foram espalhados dentro de `domains/real_estate.models` e depois parcialmente corrigidos por boundaries novas (`apps/system/matrix`, `apps/system/sourcehub`, `apps/system/lead_finder`) e por testes de observabilidade/materialização. O risco é interpretar a organização Django/domain atual como ownership final: “está em `domains.real_estate`, logo real_estate é o app produto”, ou “está em `apps/public/lead_finder`, logo public LF é o dono”. A leitura correta é: `domains/real_estate` contém entidades/tabelas canônicas compartilhadas; `apps/system/lead_finder` é o application boundary de consumo/materialização; `apps/public/lead_finder` é adapter/consumer público.

Onde as correções começaram:

- Documentação/boundary explícita:
  - `apps/system/lead_finder/README.md` introduz a divisão Matrix -> SourceHub -> Lead Finder -> public/workspace e declara o runtime residue ainda espalhado.
  - `apps/system/matrix/README.md` corrige Matrix como engine semântico sobre baseline Lead Finder-owned.
  - `apps/system/sourcehub/README.md` corrige SourceHub como producer/ingress e não materializer final.
- Contratos de aplicação:
  - `apps/system/lead_finder/contracts.py:98-116` define DTO input de SourceHub para Lead Finder, já semanticamente alinhado; Lead Finder não reabre approval Matrix por request.
  - `apps/system/lead_finder/contracts.py:136-147` formaliza runtime aprovado e triggers de reentry Matrix.
- Serviços de materialização:
  - `apps/system/lead_finder/hydration.py:1-10` declara que consome SourceHub DTOs e materializa slice mínima: Property, PropertyLocation, OwnerEntity, Ownership, PropertySituation, PropertySnapshot; provider-specific logic fica fora.
  - `apps/system/lead_finder/acquisition.py:1-16` define acquisition address-first e usa `SystemAddress` como canonical identity antes de projection/property.
- Testes de runtime/correção:
  - `domains/real_estate/tests/test_lead_finder_hydration.py` cobre hidratação com Matrix runtime genome seeded, party roles, snapshots, legal timeline e anchor SystemAddress.
  - `domains/data/tests/test_skip_trace_sourcehub_promotion.py:145-166` exige artifact Matrix-approved e SourceHub frames DirectSkip provider result em family envelopes.
  - Testes de admin observability (`test_property_admin_lineage_observability.py`, `test_property_details_admin_observability.py`, `test_property_situation_admin_observability.py`, `test_property_history_admin_observability.py`, `test_owner_contact_address_admin_observability.py`, `test_party_role_history_admin_observability.py`) reforçam lineage/canonical family visibility.
  - `apps/public/lead_finder/tests/test_boundary.py:29-102` garante que public summaries/detail mascaram owner e não retornam raw/latest DTO/contact payloads.

Onde as correções pararam ou ainda estão incompletas:

- O próprio `apps/system/lead_finder/README.md:189-198` admite runtime residue em `domains.real_estate.models`, `domains.real_estate.services.property.*` e `interfaces.web.lead_finder`; package existe para explicitar ownership antes de lift completo.
- `apps/system/lead_finder/README.md:217-227` lista incompletudes: source-list taxonomy first-class, system labels/tags owner/contact, richer contact satellite materialization e split limpo entre systemic taxonomy e overlay/workspace residue.
- `apps/system/lead_finder/README.md:288-302` aponta deferências ainda dependentes de proof: tag/label families e promoção de owner projection/mailing address em cenários específicos.
- `apps/system/lead_finder/contracts.py:92-95` ainda marca `manual` e `skip_trace` como compatibility residue até rewires product-origin lands.
- `apps/public/lead_finder/api_queries.py` continua sendo adapter público que chama `PropertyQueryService` (`domains.real_estate.services.property`), mostrando que o query/search runtime ainda não foi totalmente levantado para `apps/system/lead_finder`.

Risco prático: se a canonical-cycle analysis tratar o estado atual das pastas como arquitetura definitiva, vai preservar o erro Django-era. A arquitetura desejada já está documentada/testada em parte, mas ainda não terminou a migração física de todo runtime.

## [MODEL_EVIDENCE]

Evidência por família/tabela:

1. Propriedade/endereço
   - `domains/real_estate/models/canonical_graph.py:22-97`: `PropertyLocation` é projeção materializada sobre `SystemAddress`, com street/city/state/zip/county/apn, geospatial fields e FK `system_address`.
   - `domains/real_estate/models/canonical_graph.py:195-219`: `Property` é canonical lead/asset entity, FK `location`, FK `system_address`, `is_owner_occupied`.
   - `apps/system/lead_finder/acquisition.py:122-229`: `CanonicalPropertyAcquisitionService` resolve `SystemAddress`, sincroniza `PropertyLocation`, cria/atualiza `Property`.

2. Detalhes, fotos, land/building/listing
   - `domains/real_estate/models/detail_models.py:39-59`: `PropertyDetails` OneToOne com `Property`.
   - `domains/real_estate/models/detail_models.py:62-174`: property type, beds/baths/sqft/year, lot/zoning/subdivision/legal_description, listing status/price/urls e `photos` JSON.
   - `apps/system/lead_finder/README.md:238-241` e `:370-381`: details seed já tem consumer sancionado e deve materializar assincronamente.

3. Histórico/snapshots
   - `domains/real_estate/models/history_models.py:64-88`: `PropertyHistory` FK `Property` + JSON `dto` como canonical DTO snapshot.
   - `domains/real_estate/models/history_models.py:106-131`: detecção de canonical/portable snapshot e alias `PropertySnapshot = PropertyHistory`.

4. Situações/lead type/legal timeline reduzida
   - `domains/real_estate/models/situation_models.py:22-36`: enum de situações: foreclosure, pre_foreclosure, tax_sale, probate, heirship, divorce etc.
   - `domains/real_estate/models/situation_models.py:47-149`: `PropertySituation` com `situation_type`, `situation_status`, dates, document/case e `situation_data`.
   - `apps/system/lead_finder/README.md:209-215`: legal timeline reduzida é promovida em `PropertySituation`.

5. Valuation/financial
   - `domains/real_estate/models/valuation_models.py:18-35`: `PropertyValuation` por `Property`.
   - `domains/real_estate/models/valuation_models.py:37-104`: estimated/assessed/appraised values, mortgage balance, original loan, equity amount/percentage, valuation date/source/confidence.
   - `apps/system/lead_finder/README.md:258-268`: P4Y-824 landed canonical `PropertyValuation` para valuation/equity baseline.

6. Owner/ownership/roles
   - `domains/real_estate/models/canonical_party_graph.py:34-152`: `OwnerEntity` pessoa/company com normalized names/address, data_sources/confidence.
   - `domains/real_estate/models/canonical_party_graph.py:265-423`: `Ownership` bridge entity-property com current/history dates, investor/cash buyer/portfolio/absentee signals.
   - `domains/real_estate/models/canonical_party_graph.py:432-552`: `PartyRole` property-scoped roles, related_owner, source_reference, confidence e unique current constraints.
   - `domains/real_estate/models/canonical_party_graph.py:555-700`: `OwnerEntityRepresentative` company-person representative relationship.

7. Mailing/contact address and contact status
   - `domains/real_estate/models/canonical_party_graph.py:703-837`: `OwnerContactAddress` entity -> `SystemAddress`, optional `Property`, primary/current/po_box/deliverable/validation status and source confidence.
   - `domains/real_estate/models/canonical_party_graph.py:839-1003`: `OwnerPhone` entity phone satellite com normalized phone, phone type/subtype/status, valid, DNC, call stats, quality, `is_callable`.
   - `domains/real_estate/models/canonical_party_graph.py:1006-1174`: `OwnerEmail` entity email satellite com normalized email, type/status, valid/primary, bounce/sent/open/click counters, `is_sendable`.

8. Relações históricas/pessoais
   - `domains/real_estate/models/relationship_models.py:21-95`: `PersonRelationship` from/to person, relationship type, confidence, verified, data_sources.
   - `domains/real_estate/models/relationship_models.py:115-168`: unique/no-self constraints e inverse relationship logic.

9. Skip Trace / SourceHub data bridge
   - `domains/data/models/skip_trace.py:68-106`: `SkipTraceRequest` já carrega `canonical_property`, `sourcehub_request_public_id`, `sourcehub_raw_record_public_id`, `sourcehub_seed_public_id`, evidenciando product-origin -> SourceHub -> canonical property bridge.
   - `domains/data/tests/test_skip_trace_sourcehub_promotion.py:64-143`: seeds Matrix baseline/genomes para DirectSkip e `prop4you_product` manual submit antes da promoção.
   - `domains/data/tests/test_skip_trace_sourcehub_promotion.py:145-166`: DirectSkip promotion precisa de artifact Matrix-approved e SourceHub handoffs.

10. Public Lead Finder boundary
   - `apps/public/lead_finder/tests/test_boundary.py:29-102`: summaries/detail retornam masked owner preview e não expõem owner raw name, raw DTO, phones/emails.
   - `apps/public/lead_finder/tests/test_boundary.py:104-155`: localização pública busca grouped area suggestions, ignora full address keys e não retorna address suggestions.
   - `apps/public/lead_finder/api_queries.py:62-140`: public app monta map payload usando filtros e `PropertyQueryService`, ou seja, consome inventário; não materializa raw/provider truth.

## [RECOMMENDATION]

Recomendação para a canonical-cycle analysis:

1. Tratar “LeadFinder group” como owning baseline/materialization container: `apps/system/lead_finder` + canonical graph tables/families em `domains/real_estate` + public/workspace consumers downstream. Não reduzir a `apps/public/lead_finder`.
2. Preservar a cadeia de ownership:
   - Matrix: significado, baseline snapshot, genome/admission, drift/HITL.
   - SourceHub: ingress/raw lineage/source facts/family envelopes.
   - Lead Finder: consumo/materialização do graph pesquisável e handoff público/workspace.
   - Public/workspace: consulta, máscara, salvar/tag/list/export como overlays, não systemic truth.
3. No ciclo canônico, evitar que `source_list_type_slug`, `system_tag_slugs`, `workspace tags/lists/statuses` virem taxonomy truth por fallback. O runtime autorizado hoje é `PropertySituation`, `PropertyDetails.property_type`, derived materialized system tags e famílias explicitamente promovidas.
4. Quando propor correção de schema/tabelas, partir das famílias já evidenciadas: property/address, details/photos, history/snapshot, situations/legal timeline, valuation, owner/ownership/party roles, representative, relationship evidence, contact address, phones/emails/status.
5. Separar “correção arquitetural documentada/testada” de “migração física completa”: há fortes boundaries e testes, mas ainda existe residue em `domains.real_estate.services.property.*`, `interfaces.web.lead_finder` e compat fields (`manual`, `skip_trace`). O plano deve completar esse lift sem quebrar contratos públicos.
6. Usar os testes existentes como guardrails: Matrix admission, SourceHub promotion, Lead Finder hydration, admin lineage observability, public masking/no raw payload.
