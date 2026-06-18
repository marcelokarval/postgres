# Worker B — LeadFinder dictionary promotion review/apply policy

Status: entregue
Escopo: T3 / revisão conceitual repo-only
Repo: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`

## Veredito

A fatia atual já tem uma base correta para preparação segura em `database/ddl/projects/prop4you/leadfinder/0003_prepare_dictionary_promotions.sql`: a tabela `prop4you_leadfinder.dictionary_promotion_preparations` e a função `prepare_dictionary_promotions_from_field_mapping_set(...)` são explicitamente `prepare-only` e não inserem/atualizam `canonical_families` ou `canonical_fields`.

A lacuna é política explícita de review/apply. Recomendo implementar uma próxima DDL separada, por exemplo `leadfinder/0004_dictionary_promotion_review_apply.sql`, com duas fronteiras transacionais:

```text
prepared
  -> in_review
  -> accepted
  -> applied
```

O apply deve criar/linkar apenas estruturas de dicionário (`canonical_families`, `canonical_fields`) a partir de propostas já aceitas, com auditoria e idempotência. Feedback de usuário/workspace nunca deve acionar esse apply diretamente; no máximo vira evidência/recomendação em fila de review, com decisão humana/sistêmica explícita antes da promoção.

## Evidência local usada

Revisão feita apenas com arquivos locais, sem browser, web/MCP, provider calls ou alteração de DDL:

- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/01-prd.md`: exige política para `prepared -> review -> apply`, sem permitir que feedback como DNC/wrong influencie global truth sem gate.
- `docs/issues/12-prop4you-lfg-feedback-promotion-policy/00-detection-and-analysis.md`: escopo inclui review/apply gate para dictionary promotion a partir de prepared proposals.
- `database/ddl/projects/prop4you/leadfinder/0003_prepare_dictionary_promotions.sql`: já cria `dictionary_promotion_preparations`, status inicial `prepared`, view de review e função prepare-only; comentários dizem que não muta `canonical_families/canonical_fields`.
- `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql`: LeadFinder é owner de `canonical_dictionary_versions`, `canonical_families`, `canonical_fields`, com campos de status, evidence origin e metadados sem raw payload values.

## Estado atual relevante

`dictionary_promotion_preparations` já possui:

- `proposal_status` com check atual: `prepared`, `in_review`, `accepted_for_manual_apply`, `deferred`, `rejected`, `superseded`.
- `proposal_kind`: `create_family`, `create_field`, `link_existing_field`, `review_only`.
- ponte para `canonical_dictionary_versions`, `transformation_artifacts`, `raw_evidence_gap_bridges`.
- chaves alvo: `target_family_key`, `target_field_key`.
- links opcionais existentes: `existing_family_id`, `existing_field_id`.
- hints para modelagem/app dictionary: `lfg_app_modeling_hint`, `canonical_dictionary_hint`, `review_payload`, `metadata`.
- garantias importantes: no raw values, prepare-only, gateway-agnostic.

O ponto forte é que o preparador classifica o tipo da proposta sem aplicar nada:

```text
existing field -> link_existing_field
existing family sem field -> create_field
sem family -> create_family
```

O ponto fraco é que `accepted_for_manual_apply` é um estado intermediário ambíguo: ele diz que alguém aceitou para aplicar manualmente, mas não registra decisão estruturada, reviewer, razão, payload congelado, resultado de apply nem idempotência de execução.

## Política recomendada

### 1. Separar preparação, revisão e aplicação

A tabela atual deve continuar sendo fonte das propostas preparadas. A política futura deve adicionar duas estruturas conceituais:

```text
dictionary_promotion_reviews
  - decisão humana/sistêmica explícita sobre uma preparation
  - reviewer, razão, riscos, snapshot do payload aceito
  - não cria família/campo

 dictionary_promotion_applications
  - resultado transacional de aplicar uma review aceita
  - links finais para canonical_family_id/canonical_field_id
  - status applied/failed/rolled_back ou equivalente
  - idempotência por review aceita
```

Motivo: status inline em `dictionary_promotion_preparations` não é suficiente para auditoria nem para repetir apply com segurança.

### 2. Status canônico sugerido

Preferir nomes simples alinhados ao PRD:

```text
prepared        -- gerado automaticamente por Matrix artifact; sem decisão
in_review       -- alguém/processo assumiu a análise
accepted        -- autorizado para apply explícito
rejected        -- não promover
 deferred        -- manter backlog
superseded      -- substituído por proposta/review mais nova
applied         -- resultado final quando o apply concluiu
```

Compatibilidade com o DDL existente:

- curto prazo: mapear `accepted_for_manual_apply` como alias operacional de `accepted`.
- longo prazo: migrar o check constraint para incluir `accepted` e `applied`, ou manter `accepted_for_manual_apply` apenas como legado e registrar o estado real em tabelas de review/apply.

### 3. Regras por `proposal_kind`

#### `create_family`

Apply permitido somente quando:

- preparation está aceita;
- `target_family_key` não existe na mesma `dictionary_version_id`, ou existe com semântica compatível;
- reviewer informou `display_name`, `description`, `family_role`, `evidence_origin` e `metadata` seguros;
- nenhum raw payload value foi copiado para `description/evidence_origin/metadata`.

Resultado esperado:

```text
upsert canonical_families(dictionary_version_id, family_key)
status inicial: candidate ou in_review, nunca approved automático
link application.canonical_family_id
opcionalmente manter preparation.existing_family_id atualizado
```

#### `create_field`

Apply permitido somente quando:

- família alvo existe ou foi criada no mesmo apply;
- `target_field_key` é não nulo;
- `field_key` não existe nessa família/versão, ou existe com semântica compatível;
- reviewer validou `value_kind`, `cardinality`, `materialization_intent`, `pii_classification`.

Resultado esperado:

```text
upsert canonical_fields(dictionary_version_id, family_id, field_key)
status inicial: candidate ou in_review, nunca approved automático
link application.canonical_field_id
opcionalmente manter preparation.existing_field_id atualizado
```

#### `link_existing_field`

Apply não deve criar campo novo. Deve apenas registrar que a proposta foi resolvida por um campo existente:

```text
validate existing_field_id pertence a dictionary_version_id e target family
application.canonical_field_id = existing_field_id
status preparation -> applied/resolved
```

Se o campo existente divergir do target, a review deve rejeitar/supersede, não forçar link.

#### `review_only`

Apply não deve criar nem linkar canonical dictionary. Deve produzir apenas decisão/review e talvez backlog/gap/signal, se uma DDL futura modelar isso. Esse tipo é útil para paths ambíguos, privacy boundary ou evidência insuficiente.

### 4. Não auto-aplicar feedback do usuário

Feedback/votos de usuário devem entrar em outra fila de review, não no apply do dicionário. Mesmo se houver muitos votos `wrong`, `invalid`, `dnc`, `corrected`, `verified` ou similares, isso não autoriza criar family/field global diretamente.

Regra explícita:

```text
workspace/user feedback can recommend review;
review can accept/reject/defer;
only accepted dictionary review can call apply;
apply mutates only dictionary metadata rows, not user feedback rows and not raw values.
```

Motivo: `dnc`, `wrong`, `invalid`, `corrected` são markers/qualidade/contactability ou decisões contextuais. Eles podem indicar pressão para revisar `owner_phone.phone_quality` ou `owner_contact_address.address_deliverability`, mas não provam sozinhos semântica global nova.

## Proposta DDL conceitual

Não editar DDL nesta fatia. Abaixo é contrato conceitual para a futura implementação.

### Tabela de reviews

```sql
create table prop4you_leadfinder.dictionary_promotion_reviews (
  id uuid primary key default uuidv7(),
  preparation_id uuid not null references prop4you_leadfinder.dictionary_promotion_preparations(id) on delete restrict,
  review_status text not null default 'in_review',
  review_decision text,
  reviewer_actor_id text,
  review_reason text not null,
  accepted_payload jsonb not null default '{}'::jsonb,
  risk_assessment jsonb not null default '{}'::jsonb,
  source_evidence_summary jsonb not null default '{}'::jsonb,
  decided_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (preparation_id, review_status) where review_status in ('accepted')
);
```

Checks conceituais:

```text
review_status in ('in_review','accepted','rejected','deferred','superseded')
review_decision in ('accept_create_family','accept_create_field','accept_link_existing_field','reject','defer','supersede','review_only')
accepted_payload/risk_assessment/source_evidence_summary são objetos JSONB
accepted exige reviewer_actor_id, decided_at e accepted_payload mínimo
```

Payload aceito deve congelar os valores que serão usados pelo apply, em vez de depender do preparador mudar depois:

```json
{
  "target_family_key": "owner_phone",
  "target_field_key": "phone_quality",
  "display_name": "Phone quality",
  "description": "Candidate phone quality/reachability meaning.",
  "family_role": "contact",
  "value_kind": "enum",
  "cardinality": "optional",
  "materialization_intent": "dictionary_candidate",
  "pii_classification": "contact",
  "no_raw_values": true
}
```

### Tabela de applications

```sql
create table prop4you_leadfinder.dictionary_promotion_applications (
  id uuid primary key default uuidv7(),
  review_id uuid not null references prop4you_leadfinder.dictionary_promotion_reviews(id) on delete restrict,
  preparation_id uuid not null references prop4you_leadfinder.dictionary_promotion_preparations(id) on delete restrict,
  application_status text not null default 'applied',
  applied_action text not null,
  canonical_family_id uuid references prop4you_leadfinder.canonical_families(id) on delete restrict,
  canonical_field_id uuid references prop4you_leadfinder.canonical_fields(id) on delete restrict,
  applied_by_actor_id text,
  applied_at timestamptz not null default now(),
  apply_payload jsonb not null default '{}'::jsonb,
  result_payload jsonb not null default '{}'::jsonb,
  unique (review_id)
);
```

Checks conceituais:

```text
application_status in ('applied','failed','rolled_back')
applied_action in ('created_family','created_field','linked_existing_field','review_only_noop')
created_family exige canonical_family_id
created_field exige canonical_family_id + canonical_field_id
linked_existing_field exige canonical_field_id
review_only_noop não pode criar/linkar campo novo
```

### Funções/RPCs gateway-agnostic

#### `start_dictionary_promotion_review(...)`

Responsável por:

```text
prepared -> in_review
registrar reviewer/metadata inicial
não aplicar nada
```

Validações:

- preparation existe;
- status atual em `prepared` ou `in_review` compatível;
- não está `rejected/deferred/superseded/applied`;
- ator/reason não secretos.

#### `accept_dictionary_promotion_review(...)`

Responsável por:

```text
in_review -> accepted
congelar accepted_payload
registrar risk_assessment e source_evidence_summary
não aplicar nada
```

Validações mínimas:

- preparation está `in_review`;
- `proposal_kind` combina com `review_decision`;
- target keys seguem constraints existentes;
- payload não contém raw provider values nem PII concreta;
- se `pii_classification in ('contact','person','sensitive')`, exigir razão/privacy boundary explícito;
- se decisão é `link_existing_field`, validar FK e versão.

#### `reject/defer/supersede_dictionary_promotion_review(...)`

Responsável por encerrar a fila sem apply. Deve registrar razão e, se superseded, referência para proposta/review substituta quando houver.

#### `apply_accepted_dictionary_promotion(...)`

Responsável por mutar `canonical_families/canonical_fields` em uma única transação.

Validações antes de mutar:

- review está `accepted`;
- nenhuma application `applied` existe para a review;
- preparation ainda não está `applied/superseded/rejected`;
- dictionary version ainda aceita alteração (`draft`/`in_review`, ou política explícita para `approved/active`);
- accepted_payload bate com preparation ou declara override revisado;
- no raw values em `accepted_payload`, `evidence_origin`, `metadata`.

Ordem transacional recomendada:

```text
begin
  lock preparation row for update
  lock accepted review row for update
  validate status/idempotency
  create/link canonical_family as needed
  create/link canonical_field as needed
  insert dictionary_promotion_applications
  update preparation proposal_status = 'applied' ou metadata.applied=true
  commit
```

Se o DDL atual ainda não permitir `proposal_status = 'applied'`, o apply pode registrar `application_status='applied'` e deixar a preparation como `accepted_for_manual_apply`, mas isso é menos claro. A evolução ideal é permitir `applied`.

## Regras de idempotência e concorrência

- `dictionary_promotion_applications.review_id unique` impede apply duplicado para a mesma decisão.
- `canonical_families(dictionary_version_id, family_key)` já é unique e suporta upsert seguro.
- `canonical_fields(dictionary_version_id, family_id, field_key)` já é unique e suporta upsert seguro.
- Apply deve usar `for update` em preparation/review para evitar duas execuções simultâneas.
- Em conflito de upsert, não sobrescrever descrição/status/PII/materialization de campo existente sem decisão explícita de merge.
- Atualização de `existing_family_id/existing_field_id` na preparation deve ser resultado do apply, não condição única de verdade.

## Guardrails de segurança/semântica

1. Não promover feedback de usuário diretamente para canonical dictionary.
2. Não gravar valores raw/provider, telefones, emails, nomes ou endereços reais em dictionary metadata.
3. Não deixar Matrix aplicar canonical truth; Matrix propõe/revisa artifacts, LeadFinder aplica dictionary.
4. Não aprovar automaticamente candidate_status como `approved`; apply deve criar `candidate` ou `in_review` salvo decisão explícita posterior.
5. Não permitir apply em dictionary version `active` sem política de versioning/branching; preferir nova versão ou draft.
6. Não tratar `review_payload.mapping_item` como fonte livre para descrição final; accepted_payload deve ser sanitizado.
7. Não confundir `materialization_intent='canonical_graph_candidate'` com materialização de owner/property/contact final.
8. Não executar provider calls, enrichments ou HTTP durante review/apply.
9. Não usar broad JSONB como única garantia; checks e FKs devem validar o caminho crítico.
10. Não apagar/sobrescrever proposta preparada; preservar lineage para auditoria.

## Riscos

| Risco | Impacto | Mitigação recomendada |
| --- | --- | --- |
| Auto-promoção a partir de feedback de usuário | Corrupção de truth global por voto contextual/local | Separar feedback review de dictionary review; apply só para reviews aceitas |
| `accepted_for_manual_apply` ambíguo | Não dá para saber se foi aplicado, por quem, ou com qual payload | Criar tabelas de review/application e estado `applied` |
| Raw/PII em `review_payload` ou metadata | Vazamento e mistura de lineage com payload | Checks/validações `no_raw_values`, accepted_payload sanitizado, comentários claros |
| Upsert sobrescrever semântica existente | Mudança silenciosa de campo/família já revisado | Em conflito, linkar ou abrir merge review; não overwrite automático |
| Concorrência no apply | Família/campo duplicado ou application duplicada | Unique constraints existentes + `for update` + unique review application |
| Active dictionary mutation | Quebra consumidores/versionamento | Limitar apply a draft/in_review ou exigir branch/nova versão |
| Matrix virar owner semântico | Inversão de ownership | Funções e tabelas ficam em `prop4you_leadfinder`; Matrix artifact é evidência |
| `review_only` aplicar por engano | Criação indevida de canonical rows | Action `review_only_noop` e check que não cria/linka |
| Feedback DNC/wrong criar campo errado | Mistura marker operacional com dicionário | Usar feedback apenas como signal para reviewer; não como acceptance |

## Critérios de aceite para T7 futuro

A implementação futura da DDL/RPC deve ser aceita quando provar em PG18 lab:

1. `prepare_dictionary_promotions_from_field_mapping_set(...)` continua prepare-only e não muta canonical dictionary.
2. Uma proposal `prepared` pode entrar em `in_review` com reviewer/reason auditável.
3. Uma review pode ser `accepted` sem aplicar nada.
4. `apply_accepted_dictionary_promotion(...)` cria uma `canonical_family` quando `proposal_kind='create_family'` e registra application.
5. `apply_accepted_dictionary_promotion(...)` cria uma `canonical_field` quando `proposal_kind='create_field'` e registra application.
6. `apply_accepted_dictionary_promotion(...)` linka campo existente quando `proposal_kind='link_existing_field'` sem criar duplicata.
7. `review_only` gera noop auditável e não cria/linka canonical rows.
8. Segunda chamada de apply para a mesma review é idempotente ou rejeitada com erro controlado, sem duplicar rows.
9. Proposal `rejected/deferred/superseded` não pode ser aplicada.
10. Feedback/votos de usuário agregados não chamam apply diretamente e não alteram `canonical_families/canonical_fields`.
11. Metadata/evidence/result payloads não contêm raw provider values nem PII concreta.
12. Todos os objetos novos têm comments objetivos e seguem a separação LeadFinder owner / Matrix artifact / workspace feedback.

## Recomendação final

Implementar a política como DDL incremental, não como alteração do preparador existente. A sequência mais segura é:

```text
0003_prepare_dictionary_promotions.sql
  -> continua preparando propostas e revisão visual

0004_dictionary_promotion_review_apply.sql
  -> adiciona review decisions + applications + RPCs de lifecycle
  -> prepared/in_review/accepted/apply explícito
  -> cria/linka canonical_families/canonical_fields somente após aceite
  -> bloqueia auto-apply a partir de feedback de usuário
```

Essa abordagem preserva o valor do trabalho atual, fecha a lacuna de governança pedida no PRD e mantém o contrato database-centric/gateway-agnostic sem provider calls, sem raw values e sem promoção automática de feedback local para verdade global.
