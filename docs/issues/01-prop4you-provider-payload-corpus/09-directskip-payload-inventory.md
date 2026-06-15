# 09 — Inventário DirectSkip / skip trace owner-contact payload

Status: análise estática concluída por Worker B.
Escopo: backend Prop4You read-only em `/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src`; repo de destino em `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork`.

[NO_PROVIDER_CALLS]
Nenhuma chamada a provider/API foi realizada. A análise usou somente código, testes, fixtures e contratos locais.

[NO_PII_DUMP]
Este inventário não reproduz valores reais de nomes, telefones, e-mails, endereços, IDs de request ou payloads brutos. Quando fixtures/testes continham PII ou dados com aparência de PII, foram inventariados apenas caminhos, famílias de campos, contagens, chaves e implicações sem valores.

## Resumo executivo

DirectSkip aparece em dois níveis principais:

1. Cliente/contrato operacional de skip trace:
   - request canônico: owner name + property address + mailing address opcional + custom fields;
   - response bruto DirectSkip: `status`, `result_code`, `contacts[]` com `names[]`, `phones[]`, `emails[]`, `confirmed_address[]`, `relatives[]`;
   - response normalizado: `ProviderResponse` com `phones`, `emails`, `related_people`, `addresses`, `confirmed_address`, `owner_returned`, `match_metrics`, `result_metrics`, `raw_data`.

2. Matrix/SourceHub/Lead Finder:
   - DirectSkip é provider corpus `directskip` / `skip_trace_contact_discovery`;
   - Matrix compila DTO pre-SourceHub com `materialization_policy = evidence_only_before_sourcehub`;
   - SourceHub produz handoffs familiares para mailing/contact satellites/relationship evidence e mantém raw provider response como lineage;
   - promoção para owner/canonical graph é condicionada por candidate graph, owner-match e policy gates; skip trace enriquece, não define verdade canônica de owner/property.

[DIRECTSKIP_PATH_INVENTORY]

| Área | Caminho | Evidência útil |
|---|---|---|
| Cliente DirectSkip | `infrastructure/integrations/directskip/client.py` | Payload DirectSkip de 14 campos; parse de `status`, `result_code`, `contacts`, `phones`, `emails`, `confirmed_address`, `relatives`; normaliza para `ProviderResponse`; preserva `raw_data`. |
| Schemas multi-provider | `infrastructure/integrations/skiptrace/schemas.py` | `StandardSearchFields`, `PhoneContact`, `EmailContact`, `RelativeContact`, `ProviderResponse`; inclui campos forenses `owner_returned`, `match_metrics`, `result_metrics`, `raw_data`. |
| Modelos de request/result | `domains/data/models/skip_trace.py` | `SkipTraceRequest` guarda owner/property/mailing input; `SkipTraceResult` guarda structured contacts, `owner_returned`, `related_people`, `match_metrics`, `result_metrics`, `raw_response`, `provider_name`. |
| Cache/auditoria system | `domains/data/models/system_cache.py` | `SystemSkipTraceResult` e `SystemSkipTraceSnapshot`; snapshots têm `request_payload` e `response_payload`; cache dedup inclui owner/contact JSONs. |
| Auditoria snapshot | `domains/data/services/skip_trace/audit.py` | Enriquecimento de `request_payload` com tracking id e persistência de `response_payload`/error payload. |
| Orquestração skip trace | `domains/data/services/skip_trace/orchestrator.py` | Conecta `ProviderResponse.raw_data`, `SkipTraceResult` e SourceHub handoffs; mapping version `directskip.skip_trace_contact_discovery.v2`; promotion guard antes de materialização. |
| Provider contract helpers | `domains/data/services/skip_trace/provider_contract.py` | Construção de request payload/custom fields para DirectSkip. |
| SourceHub producer | `apps/system/sourcehub/producer.py` | Normaliza `owner_returned`; deriva confidence; constrói candidate graph; bloqueia promoção address-only; produz handoffs por família. |
| Owner-resolution adapter | `domains/real_estate/services/owner_resolution/skiptrace_adapter.py` | Transforma `SkipTraceResult` em `OwnerIdentityEvidence` por identity, phone, email, address, relationship. |
| Matrix DTO compiler | `apps/system/matrix/directskip_owner_resolution_dto.py` | Compila payload DirectSkip bruto em semantic primitives e envelope pre-SourceHub. |
| Matrix field mapping | `apps/system/matrix/directskip_owner_resolution_mapping.py` | Inventário field-level: input context, provider outcome, contacts/names/phones/emails/address/relatives. |
| Contact specs | `apps/system/matrix/directskip_owner_resolution_contact_specs.py` | Mapeamento das famílias DirectSkip retornadas para owner_identity, owner_phone, owner_email, owner_contact_address, owner_relationship_evidence. |
| Teste DTO | `apps/system/matrix/tests/test_directskip_owner_resolution_dto.py` | Confirma campos brutos esperados e landing semântico; contém asserts com PII, não reproduzidos aqui. |
| Teste primitives | `apps/system/matrix/tests/test_directskip_owner_primitives_pilot.py` | Confirma semantic primitives: name, address anchor, mailing address, contact phone, email, relationship person; contém PII, não reproduzidos aqui. |
| Teste SourceHub promotion | `domains/data/tests/test_skip_trace_sourcehub_promotion.py` | Confirma handoffs por família, Matrix artifact approval, candidate graph e bloqueio de address-only owner promotion; contém fixtures sintéticas com PII-like, não reproduzidas aqui. |
| Fixture real local | `apps/system/matrix/tests/fixtures/directskip_real_response.json` | Shape real local DirectSkip; top-level `input/status/contacts/result_code`; não foi dumpado. |
| Registry raw copy | `apps/system/matrix/registry/directskip/skip_trace_contact_discovery/tx/data/undated/directskip_real_response.json` | Cópia corpus local com o mesmo shape DirectSkip; não foi dumpada. |
| Registry Matrix | `apps/system/matrix/registry/directskip/skip_trace_contact_discovery/{schema,contracts,data,analysis,tx/...}/*.json` | 211 JSONs locais no subtree; análise estática mostra artifacts de schema/contracts/data/analysis para provider/list type, sem chamadas externas. |

## Estruturas de payload observadas

### Request payload / input context

Famílias de campos de entrada DirectSkip:

- Identidade owner solicitada:
  - `first_name` / `firstname`
  - `last_name` / `lastname`
  - `middle_name` aparece no modelo interno `SkipTraceRequest`, mas o payload DirectSkip operacional usa first/last no contrato cliente.
- Property context:
  - `property_address`
  - `property_city` ou `city` conforme camada
  - `property_state` ou `state`
  - `property_zip` ou `zip_code`
  - `property_unit` existe no modelo de request interno, mas não aparece como campo DirectSkip client payload dedicado.
- Mailing / owner contact context opcional:
  - `mailing_address` / `mailing_street`
  - `mailing_city`
  - `mailing_state`
  - `mailing_zip`
- Provider tracking / residue:
  - `custom_field_1`, `custom_field_2`, `custom_field_3` no cliente;
  - mapping Matrix também cobre `input.custom_field1`, `input.custom_field2`, `input.custom_field3` em fixture/contract shape;
  - snapshots adicionam `_tracking_id` no audit layer.
- Segredos:
  - cliente monta `api_key`; não deve entrar em payload corpus canônico nem logs/documentos.

Implicação: o request payload mistura owner seed, property context, mailing context e tracking provider slots. O corpus canônico precisa distinguir `request_context` de evidência observada pelo provider.

### Raw response / response_payload shape

Shape DirectSkip bruto local confirmado por código/fixture:

- top-level:
  - `input`
  - `status`
  - `contacts`
  - `result_code`
- `status`:
  - `error`
- `result_code`:
  - `result_code`
- `contacts[]`:
  - `names[]`
  - `phones[]`
  - `emails[]`
  - `confirmed_address[]`
  - `relatives[]`
- `contacts[].names[]` keys observadas/inventariadas:
  - `firstname`
  - `lastname`
  - `age`
  - `deceased`
- `contacts[].phones[]`:
  - `phonenumber`
  - `phonetype`
- `contacts[].emails[]`:
  - `email`
- `contacts[].confirmed_address[]`:
  - `street`
  - `city`
  - `state`
  - `zip`
- `contacts[].relatives[]`:
  - `name`
  - `age`
  - `phones[]`
- `contacts[].relatives[].phones[]`:
  - `phonenumber`
  - `phonetype`

Persistência/lineage:

- `ProviderResponse.raw_data` preserva o bruto.
- `SkipTraceResult.raw_response` guarda raw provider response.
- `SystemSkipTraceSnapshot.response_payload` guarda payload de sucesso/erro em auditoria.
- `SourceHubRawRecord.raw_payload` recebe handoff provider/list type com request public id, provider payloads, metrics e lineage.

## Famílias owner/contact e landing semântico

| Família | Raw DirectSkip | Landing atual | Observação |
|---|---|---|---|
| Owner identity | `contacts[].names[].firstname`, `lastname`, `age`, `deceased`; também owner_returned normalizado | `owner_identity`; `OwnerIdentityEvidence` identity fields | Observado pelo provider, mas ainda evidência, não verdade canônica por si só. |
| Owner phone | `contacts[].phones[].phonenumber`, `phonetype` | `owner_phone`, `PhoneContact`, `OwnerIdentityEvidence.PHONE` | `phonetype` exige normalização de taxonomia; mapping marca gap para novo campo/dicionário. |
| Owner email | `contacts[].emails[].email` | `owner_email`, `EmailContact`, `OwnerIdentityEvidence.EMAIL` | E-mail é contato satellite; precisa dedupe/normalização lower-case. |
| Owner contact address / mailing | `contacts[].confirmed_address[].street/city/state/zip` | `owner_contact_address`, mailing/address primitives | Pode diferir de property address; deve virar contact/mailing evidence, não propriedade canônica automaticamente. |
| Related people | `contacts[].relatives[].name/age/phones[]` | `owner_relationship_evidence`, `related_people`, relationship primitive | Telefones de relatives não devem ser promovidos como owner_phone sem subject/link explícito. |
| Provider outcome | `status.error`, `result_code.result_code` | provider outcome/result metrics/residue | Operacional/lineage; não é owner property fact. |
| Request context | `input.*`, `custom_field*` | request context/residue | Útil para comparação e explainability; não deve ser confundido com provider-observed truth. |

## Evidence rows úteis para corpus

| Evidence row | Fonte | Campo(s) | Uso recomendado |
|---|---|---|---|
| R1 | `directskip/client.py` parse legacy/modern | `status.error`, `result_code`, first `contacts[]` | Contrato mínimo para parser e provider outcome. |
| R2 | `directskip/client.py` `_build_payload` | 14-field payload DirectSkip | Dicionário de request context; separar owner/property/mailing/custom/api_key. |
| R3 | `skiptrace/schemas.py` `ProviderResponse` | `owner_returned`, `match_metrics`, `result_metrics`, `raw_data` | Esqueleto provider-normalized corpus. |
| R4 | `models/skip_trace.py` `SkipTraceResult` | structured JSON + `raw_response` | Alvo persistido de response bruto e normalizado. |
| R5 | `matrix/directskip_owner_resolution_mapping.py` | 30 raw fields esperados | Inventário field-level com fit/gap/residue policy. |
| R6 | `matrix/directskip_owner_resolution_contact_specs.py` | contact family specs | Regras para owner vs related-person contacts. |
| R7 | `matrix/directskip_owner_resolution_dto.py` | semantic primitives | Ponte para canonical owner resolution pre-SourceHub. |
| R8 | `sourcehub/producer.py` candidate graph | provider candidates/address-only/relative/co-owner | Regras de promoção e bloqueios. |
| R9 | `owner_resolution/skiptrace_adapter.py` | `OwnerIdentityEvidence` rows | Como transformar result em evidência addressable por source ref. |
| R10 | registry `directskip/skip_trace_contact_discovery` | schema/contracts/analysis artifacts | Corpus local Matrix para comparison/drift sem provider call. |

[OWNER_CANONICAL_IMPLICATIONS]

1. DirectSkip deve permanecer enrichment/evidence source. O próprio stack já usa `materialization_policy = evidence_only_before_sourcehub` e Matrix como semantic owner.
2. Request context não é evidência independente. Nome/endereço enviados ao provider devem ser guardados para lineage/comparação, mas não podem reforçar a própria identidade sem observação retornada.
3. `confirmed_address` deve ser tratado como owner contact/mailing address candidate. Quando difere de property address, SourceHub já classifica como mailing differs from property; não promover para property truth.
4. Related-person contacts são subject-linked. Telefones/e-mails/endereços de relatives precisam permanecer vinculados ao related person, não ao owner principal.
5. Candidate graph é obrigatório para payloads multi-contact ou ambiguous. Address-only match não prova owner identity; co-owner lane requer canonical owner public id; submitted owner relative-only deve bloquear promoção automática de contatos para o owner submetido.
6. `owner_returned` precisa de comparação com canonical owners e request owner. Sem match de nome/canonical owner, confidence deve ser capado ou promotion blocked.
7. `phonetype`/phone taxonomy precisa de dicionário canônico antes de uso analítico forte (`Mobile`, `Residential`, `landline`, `voip`, `unknown`, etc.).
8. Provider outcome (`status.error`, `result_code`) deve alimentar observability, retry/error classification e corpus drift, não owner graph.

## Necessidades de comparação com canonical dictionary

Prioridade alta:

- Mapear `contacts[].phones[].phonetype` para taxonomia canônica de phone type e preservar raw label.
- Comparar `contacts[].names[]` e `owner_returned` com canonical owner dictionary: name normalization, aliases, middle initials, suffixes, entity type person/company/trust/LLC.
- Comparar `confirmed_address` com canonical address dictionary: property address vs mailing/contact address; unit normalization; PO Box; occupancy parsing.
- Formalizar relationship dictionary para `relatives[].relationship` quando presente/ausente; atualmente tests usam fallback/unknown/relative.
- Definir policy para `age`, `date_of_birth`, `deceased`: identity evidence only, retention/minimization e access controls.
- Distinguir provider `input.*` field names (`firstname`, `address`, `zip`) de application payload names (`first_name`, `property_address`, `zip_code`) no corpus dictionary.
- Registrar raw_response key dictionary com versionamento `directskip.skip_trace_contact_discovery.v2` e drift checks.

Prioridade média:

- Normalizar result metrics: contacts/phones/emails/related/confirmed_address counts, provider result code, provider request id.
- Normalizar match metrics: ownerNameExactMatch, requested/returned owner names, submitted owner status, promotion policy, confidence caps.
- Definir redact/mask profiles por família para fixtures e docs.

## PII / segurança / retenção

PII sensível presente nas fontes locais:

- nomes de owners e relatives;
- telefones;
- e-mails;
- endereços completos e units;
- idade, DOB e deceased flags;
- request ids/tracking ids/custom fields que podem correlacionar usuários;
- API key em payload client se persistida por engano.

Recomendações:

- Nunca dump de `raw_response`, `raw_data`, `request_payload` ou `response_payload` em docs/issues.
- Corpus canônico deve usar shape/key inventory, fixtures sintéticas redigidas ou valores mascarados.
- `api_key` deve ser excluída/redigida antes de qualquer raw payload corpus/snapshot compartilhável.
- DOB/idade/deceased devem ter minimização e acesso restrito; são identity evidence de alto risco.
- Related-person data exige cuidado adicional: não é o sujeito principal do request e pode conter contatos de terceiros.
- Retenção atual no modelo menciona 10 anos para skip trace; corpus/fixtures devem ter política separada de sanitização.

[RESIDUAL_RISKS]

- Fixtures e testes locais ainda contêm valores PII/PII-like. Este inventário não os reproduziu, mas qualquer automação futura de corpus precisa redaction explícita.
- Há divergência de naming entre DirectSkip raw fixture (`firstname`, `phonenumber`, `zip`) e normalized/app fields (`first_name`, `phone_number`, `zip_code`). Sem canonical dictionary, há risco de drift silencioso.
- `custom_field_*` pode carregar identifiers internos ou user refs; precisa classificação como sensitive correlation metadata.
- `raw_response`/`response_payload` podem conter campos provider novos não cobertos pelos 30 raw fields mapeados; registry analysis deve alimentar drift detection.
- Parser usa primeiro `contacts[0]` em trechos do cliente/DTO; SourceHub candidate graph cobre multi-contact em promotion, mas corpus precisa representar todos os contacts para não perder evidência.
- Phone/email promotion depende de match owner/candidate; se a camada de materialização ignorar handoff policy, pode associar contato de pessoa errada.
- Contratos Matrix registry são numerosos e versionados por sessão; é necessário escolher fonte canônica de artifact (`directskip.skip_trace_contact_discovery.v2`) e descartar snapshots obsoletos ou duplicados.
