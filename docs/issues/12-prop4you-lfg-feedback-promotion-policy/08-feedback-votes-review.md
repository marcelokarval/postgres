# Worker A — LFG feedback/vote weak relationship contract

Status: entregue
Escopo: T2 / revisão-proposta conceitual repo-only
Repo: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`
Gerado em: 2026-06-18T10:31:29-04:00

## Veredito executivo

O feedback de usuário sobre DNC, telefone errado, e-mail errado, endereço postal errado, contato inválido, stale, corrected, verified etc. deve ser modelado como sinal fraco dentro de `prop4you_leadfinder_group`, não como mutação direta no workspace nem como alteração imediata da verdade global LFG.

Contrato recomendado:

```text
prop4you_user_workspace
  - owner de usuário/workspace/ações locais/snapshots/anotações locais
  - pode emitir feedback por gateway/RPC/evento
  - não possui FK forte exigida pelo LFG

prop4you_leadfinder_group
  - owner da fila de feedback recebida
  - guarda votos com refs fracas para workspace/user/snapshot/item
  - agrega votos em buckets de revisão
  - calcula recomendação automática de política
  - exige review/aprovação para aplicar marker global/canonical
```

Regra central: um voto isolado de usuário nunca aplica marker global. Votos alimentam agregação; agregação recomenda; revisão humana ou policy-gate autorizada decide; somente a decisão aprovada cria/atualiza marker global LFG-owned.

## Decisões de boundary usadas

Decisão do Karval registrada nesta issue:

```text
workspace schema = prop4you_user_workspace
LFG/system schema = prop4you_leadfinder_group
feedback do usuário fica em tabela no prop4you_leadfinder_group
relacionamento fraco para item e usuário/workspace
votos/agregação recomendam marker global/canonical
review humano aplica
```

Isso está alinhado com a arquitetura anterior:

- LFG/system owns global markers, contactability, qualidade, evidence, lineage e versões.
- Workspace owns decisões locais, snapshots, listas, tags, labels, notas e preferências tenant/user.
- Feedback bridge é explícito; não se reaproveita tabela de marker local como marker global.
- Topologia futura pode separar bancos; portanto refs fracas são preferíveis a FKs cross-boundary.

## Vocabulário contratual

### Item kinds suportados

Usar enum/check conceitual compatível com o PRD:

```text
phone
email
mailing_address
owner
property
contact
group
facet
unknown
```

### Marker kinds suportados

Usar enum/check conceitual compatível com o PRD:

```text
dnc
wrong
invalid
stale
corrected
verified
unreachable
deliverable
undeliverable
other
```

### Weak relationship

Neste contrato, relacionamento fraco significa:

1. Guardar identificadores textuais/versionados suficientes para reconciliar depois.
2. Não exigir FK forte para `prop4you_user_workspace`.
3. Não exigir FK forte para item LFG final, porque o item pode ser snapshot, facet, operational_group, contato futuro, item externo/materializado ou estar em outro banco.
4. Preservar hash/versão/refs no momento do voto para audit e replay.
5. Aceitar que resolução posterior pode falhar ou encontrar item superseded/stale.

Campos fracos recomendados:

```text
workspace_schema_name       -- esperado: prop4you_user_workspace
workspace_ref               -- public_ref/text/uuid-as-text; sem FK
workspace_account_ref       -- opcional; sem FK
workspace_user_ref          -- opcional; sem FK
workspace_snapshot_ref      -- opcional; sem FK
workspace_campaign_ref      -- opcional; sem FK

lfg_item_kind               -- phone/email/mailing_address/etc.
lfg_item_ref                -- public_ref/id/hash/path conhecido pelo consumidor; sem FK obrigatória
lfg_item_version            -- versão do snapshot/facet/grupo visto pelo usuário
lfg_item_hash               -- content/facet/snapshot hash visto pelo usuário
lfg_group_ref               -- opcional, weak ref para operational group ou group public_ref
lfg_facet_ref               -- opcional, weak ref para operational_group_facets ou path
source_publication_ref      -- opcional, para lineage SourceHub quando conhecido
matrix_artifact_ref         -- opcional, para lineage Matrix quando conhecido
```

## Tabela conceitual 1: feedback votes

Nome recomendado:

```text
prop4you_leadfinder_group.feedback_votes
```

Responsabilidade: registrar, de forma append-friendly, cada feedback/voto enviado por workspace/user sobre um item LFG observado em um snapshot/version/hash específico.

DDL conceitual, não implementação final:

```sql
create table prop4you_leadfinder_group.feedback_votes (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgfv', id)) stored,

  -- weak workspace/user refs; no FK cross-boundary
  workspace_schema_name text not null default 'prop4you_user_workspace',
  workspace_ref text not null,
  workspace_account_ref text,
  workspace_user_ref text,
  workspace_snapshot_ref text,
  workspace_campaign_ref text,

  -- weak LFG item refs; no mandatory FK
  lfg_item_kind text not null,
  lfg_item_ref text not null,
  lfg_item_version text,
  lfg_item_hash text,
  lfg_group_ref text,
  lfg_facet_ref text,
  source_publication_ref text,
  matrix_artifact_ref text,

  -- vote semantics
  marker_kind text not null,
  marker_value jsonb not null default 'true'::jsonb,
  vote_signal text not null default 'assert',
  reason_code text,
  user_comment text,
  evidence_payload jsonb not null default '{}'::jsonb,
  confidence numeric(5,4) not null default 0.5000,
  vote_weight numeric(8,4) not null default 1.0000,

  -- lifecycle/review bridge
  vote_status text not null default 'submitted',
  supersedes_vote_ref text,
  aggregate_bucket_key text,
  observed_at timestamptz not null default now(),
  submitted_at timestamptz not null default now(),

  -- privacy/audit/gateway agnostic metadata
  source_channel text not null default 'workspace_feedback',
  privacy_class text not null default 'workspace_feedback_no_raw_payload',
  metadata jsonb not null default '{}'::jsonb,

  active boolean not null default true,
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1
);
```

Checks recomendados:

```text
workspace_schema_name = 'prop4you_user_workspace'
lfg_item_kind in (phone,email,mailing_address,owner,property,contact,group,facet,unknown)
marker_kind in (dnc,wrong,invalid,stale,corrected,verified,unreachable,deliverable,undeliverable,other)
vote_signal in (assert,retract,confirm,dispute,correct,verify)
vote_status in (submitted,accepted_for_aggregation,ignored_duplicate,invalid,withdrawn,aggregated,archived)
confidence between 0 and 1
vote_weight > 0 and vote_weight <= configured max
jsonb_typeof(marker_value) is not null
evidence_payload and metadata are json objects
```

Índices recomendados:

```text
(lfg_item_kind, lfg_item_ref, marker_kind, submitted_at desc) where deleted=false
(workspace_ref, workspace_user_ref, submitted_at desc) where deleted=false
(aggregate_bucket_key, submitted_at desc) where deleted=false
(marker_kind, vote_status, submitted_at desc) where deleted=false
GIN(evidence_payload jsonb_path_ops)
```

Unicidade parcial recomendada para reduzir spam sem bloquear correções legítimas:

```text
unique active latest assertion per:
  workspace_ref + workspace_user_ref + lfg_item_kind + lfg_item_ref + marker_kind + normalized(marker_value) + lfg_item_hash
```

Se o usuário muda de opinião, preferir novo voto `retract/dispute/correct` ou `supersedes_vote_ref`, não update destrutivo do voto antigo.

## Bucket de agregação

`aggregate_bucket_key` deve ser determinístico e calculável a partir de uma normalização estável:

```text
bucket = sha256(
  lfg_item_kind || '|' || normalized_lfg_item_ref || '|' ||
  marker_kind || '|' || normalized_marker_value
)
```

Para itens versionados, a política deve decidir se o bucket agrupa por item canonical ou por snapshot/hash:

- Para `wrong phone`, `dnc`, `invalid`, `unreachable`: preferir bucket por item canonical quando resolvido; fallback por weak ref/hash.
- Para `stale`: incluir versão/hash no bucket porque stale é relativo à versão observada.
- Para `corrected`: bucket deve incluir um `proposed_correction_hash`, nunca expor PII crua em chave pública.
- Para `mailing_address wrong`: incluir normalização geográfica/endereço se houver canonical parser; se não houver, manter bucket weak e exigir review.

## Tabela conceitual 2: aggregate review queue

Nome recomendado:

```text
prop4you_leadfinder_group.feedback_marker_aggregates
```

Responsabilidade: materializar o estado agregado por bucket de item+marker, com estatísticas, conflito, evidência resumida e recomendação de política. Esta tabela não aplica marker global; ela apenas prepara a revisão.

DDL conceitual:

```sql
create table prop4you_leadfinder_group.feedback_marker_aggregates (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgfa', id)) stored,

  aggregate_bucket_key text not null unique,
  lfg_item_kind text not null,
  normalized_lfg_item_ref text not null,
  marker_kind text not null,
  normalized_marker_value jsonb not null default 'true'::jsonb,

  vote_count integer not null default 0,
  weighted_vote_score numeric(12,4) not null default 0,
  distinct_workspace_count integer not null default 0,
  distinct_user_count integer not null default 0,
  dispute_count integer not null default 0,
  retract_count integer not null default 0,
  latest_vote_at timestamptz,
  first_vote_at timestamptz,

  confidence_score numeric(5,4) not null default 0,
  conflict_score numeric(5,4) not null default 0,
  freshness_score numeric(5,4) not null default 0,

  recommendation text not null default 'no_action',
  recommendation_reason text,
  review_status text not null default 'not_opened',
  policy_version text not null,
  policy_snapshot jsonb not null default '{}'::jsonb,
  evidence_summary jsonb not null default '{}'::jsonb,
  sample_vote_refs jsonb not null default '[]'::jsonb,

  opened_for_review_at timestamptz,
  closed_at timestamptz,
  active boolean not null default true,
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1
);
```

Checks recomendados:

```text
recommendation in (
  no_action,
  collect_more_votes,
  open_human_review,
  recommend_global_marker,
  recommend_reject,
  recommend_workspace_only,
  blocked_conflict
)
review_status in (
  not_opened,
  queued,
  in_review,
  accepted_for_global_marker,
  rejected,
  needs_more_evidence,
  blocked,
  applied,
  superseded
)
```

Índices recomendados:

```text
(recommendation, review_status, updated_at desc) where deleted=false
(marker_kind, review_status, confidence_score desc) where deleted=false
(lfg_item_kind, normalized_lfg_item_ref, marker_kind) where deleted=false
GIN(evidence_summary jsonb_path_ops)
```

## Tabela conceitual 3: review decisions

Nome recomendado:

```text
prop4you_leadfinder_group.feedback_marker_reviews
```

Responsabilidade: registrar a decisão humana/sistêmica sobre um aggregate. Esta é a autorização para aplicação posterior, não o marker em si.

DDL conceitual:

```sql
create table prop4you_leadfinder_group.feedback_marker_reviews (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfgfr', id)) stored,

  aggregate_id uuid not null,              -- FK forte aceitável dentro do schema LFG
  aggregate_public_ref text not null,
  review_decision text not null,
  review_reason text,
  reviewer_actor_id text not null,
  reviewed_at timestamptz not null default now(),

  proposed_global_marker_kind text not null,
  proposed_global_marker_value jsonb not null default 'true'::jsonb,
  proposed_scope text not null default 'lfg_global',
  proposed_confidence numeric(5,4) not null default 0,
  proposed_effective_at timestamptz,
  proposed_expires_at timestamptz,
  proposed_lineage jsonb not null default '{}'::jsonb,

  apply_status text not null default 'not_applied',
  applied_marker_ref text,
  applied_at timestamptz,
  apply_actor_id text,
  apply_error text,

  metadata jsonb not null default '{}'::jsonb,
  active boolean not null default true,
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1
);
```

Checks recomendados:

```text
review_decision in (accept_global_marker,reject,needs_more_evidence,workspace_only,duplicate,blocked,not_applicable)
apply_status in (not_applied,ready_to_apply,applied,failed,voided,superseded)
proposed_scope in (lfg_global,lfg_group,lfg_contact,lfg_phone,lfg_email,lfg_address,lfg_facet)
```

Observação: `aggregate_id` pode ter FK forte para `feedback_marker_aggregates` porque ambos são LFG-owned. As refs para workspace/user/item continuam fracas.

## Tabela conceitual 4: global/canonical marker apply

Nome recomendado para estado atual:

```text
prop4you_leadfinder_group.global_markers
```

Nome recomendado para trilha append-only:

```text
prop4you_leadfinder_group.global_marker_events
```

Responsabilidade: armazenar markers LFG-owned aplicados após review. Este é o único local da verdade global/canonical gerada por feedback agregado.

DDL conceitual do estado atual:

```sql
create table prop4you_leadfinder_group.global_markers (
  id uuid primary key default uuidv7(),
  public_ref text generated always as (base.make_public_ref('p4ylfggm', id)) stored,

  lfg_item_kind text not null,
  normalized_lfg_item_ref text not null,
  marker_kind text not null,
  marker_value jsonb not null default 'true'::jsonb,
  marker_status text not null default 'active',
  marker_scope text not null default 'lfg_global',

  confidence numeric(5,4) not null default 0,
  source_kind text not null default 'feedback_review',
  source_review_ref text not null,
  source_aggregate_ref text not null,
  lineage jsonb not null default '{}'::jsonb,

  effective_at timestamptz not null default now(),
  expires_at timestamptz,
  superseded_by_marker_ref text,
  active boolean not null default true,
  deleted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_modified_by_actor_id text,
  version integer not null default 1
);
```

Unicidade recomendada:

```text
unique active canonical marker per:
  lfg_item_kind + normalized_lfg_item_ref + marker_kind + normalized(marker_value) + marker_scope
where active=true and deleted=false and marker_status='active'
```

Eventos recomendados:

```text
global_marker_applied
global_marker_superseded
global_marker_voided
global_marker_expired
global_marker_conflict_opened
```

## Funções conceituais / use cases

### 1. Submit vote

```text
prop4you_leadfinder_group.submit_feedback_vote(...)
```

Contrato:

- Entrada por gateway/RPC/worker, sem depender de HTTP específico.
- Valida item_kind/marker_kind/vote_signal.
- Normaliza refs fracas.
- Calcula `aggregate_bucket_key`.
- Insere voto append-friendly.
- Não aplica marker global.
- Retorna `feedback_vote_ref` e status.

### 2. Recompute aggregate

```text
prop4you_leadfinder_group.recompute_feedback_marker_aggregate(p_bucket_key text, p_policy_version text)
```

Contrato:

- Recalcula contagens, votos ponderados, distinct workspace/user, disputes/retractions.
- Atualiza `feedback_marker_aggregates`.
- Produz recommendation conforme policy snapshot.
- Pode abrir review queue quando threshold alcançado.
- Não aplica marker global.

### 3. Review aggregate

```text
prop4you_leadfinder_group.review_feedback_marker_aggregate(p_aggregate_ref text, p_decision text, ...)
```

Contrato:

- Exige reviewer actor/system actor autorizado.
- Cria row em `feedback_marker_reviews`.
- Se `accept_global_marker`, marca `apply_status = ready_to_apply`.
- Não deve apagar votos nem aggregate history.

### 4. Apply reviewed marker

```text
prop4you_leadfinder_group.apply_reviewed_feedback_marker(p_review_ref text, p_actor_id text)
```

Contrato:

- Só aceita review com `review_decision = accept_global_marker` e `apply_status = ready_to_apply`.
- Insere/atualiza `global_markers`.
- Insere `global_marker_events`.
- Atualiza review para `applied`.
- Atualiza aggregate para `applied`.
- É idempotente por `source_review_ref`.

## Política de recomendação automática

A recomendação automática deve ser conservadora. Ela recomenda review; não aplica sozinha.

Política inicial sugerida, parametrizável por `policy_version`:

```text
base_min_votes = 5
base_min_distinct_workspaces = 3
base_min_confidence_score = 0.7000
max_conflict_score_for_recommendation = 0.2500
max_retract_ratio = 0.2000
freshness_window_days = 180
```

Ajustes por marker:

| Marker | Política recomendada |
| --- | --- |
| dnc | Abrir review com prioridade alta; exigir evidência/compliance; não auto-aplicar sem review humano/política formal. |
| wrong | Exigir múltiplos workspaces ou evidência forte; conflito alto bloqueia. |
| invalid | Pode recomendar com provider/system evidence adicional; votos sozinhos abrem review. |
| stale | Recomendação deve focar refresh/revalidation, não marker global definitivo. |
| corrected | Exigir proposed correction hash/lineage; review obrigatório para evitar PII falsa. |
| verified | Exigir fonte confiável e anti-abuse; votos positivos podem desfazer ou superseder wrong apenas com review. |
| unreachable | Pode ser temporário; preferir expires_at/recheck. |
| deliverable/undeliverable | Exigir evidência de canal e data; validade temporal curta. |
| other | Sempre human review/manual classification antes de global marker. |

Estados de recomendação:

```text
no_action
collect_more_votes
open_human_review
recommend_global_marker
recommend_reject
recommend_workspace_only
blocked_conflict
```

## Anti-abuse e privacidade

Requisitos mínimos:

1. Rate limit por workspace/user/item/marker via gateway ou função.
2. Deduplicação por snapshot/hash para evitar vote stuffing.
3. Ponderação por trust tier do workspace, quando existir, mas armazenada como snapshot de peso para audit.
4. Não gravar raw phone/email completo em comentário/evidence sem redaction policy.
5. `user_comment` deve ser opcional e potencialmente redigível; não participar da chave agregada.
6. `evidence_payload` deve carregar referências/resumos, não dumps de provider/PII.
7. Review deve registrar actor e motivo.
8. Aplicação deve ser idempotente e auditável.
9. Conflito entre `wrong` e `verified`, ou `dnc` e `deliverable`, deve bloquear/requerer review explícito.

## RLS/exposição/API futura

Como as tabelas vivem em `prop4you_leadfinder_group`, não expor raw tables diretamente ao usuário final. Expor apenas use cases/facades:

```text
api.submit_lfg_feedback_vote(...)       -- futuro facade PostgREST/API
api.get_my_feedback_status(...)         -- escopado por workspace/user
admin/review views                      -- apenas operadores LFG
```

Regras:

- Workspace user pode inserir feedback via função com `workspace_ref/user_ref` validado pelo gateway/RLS do workspace.
- Workspace user pode ler status do próprio feedback, não votos de outros workspaces.
- Operador LFG pode ver aggregate/review com redaction adequada.
- Aplicação de global marker exige role/service/reviewer LFG, nunca user workspace direto.

## Regras de integração com operational_groups/facets atuais

O DDL atual de `prop4you_leadfinder_group` possui `operational_groups`, `operational_group_events` e `operational_group_facets` como mínimo operacional. Este contrato não exige alterar essas tabelas agora.

Compatibilidade recomendada:

- Se feedback aponta para `group`, usar `lfg_item_kind = 'group'` e `lfg_item_ref = operational_group.public_ref` quando disponível.
- Se aponta para `facet`, usar `lfg_item_kind = 'facet'`, `lfg_facet_ref` e `lfg_item_hash`/path.
- Se aponta para phone/email/address ainda não finalizados como tabela própria, usar `lfg_item_kind = phone/email/mailing_address` com weak ref normalizada derivada do snapshot/facet.
- Quando futuros contacts/phones/emails canônicos existirem, criar resolver que mapeia weak refs antigas para canonical refs sem reescrever o histórico de votos.

## Fluxo ponta a ponta recomendado

```text
1. Usuário no workspace vê snapshot LFG versionado.
2. Usuário marca: phone wrong / DNC / email undeliverable / address wrong.
3. Gateway chama submit_feedback_vote com refs fracas:
   workspace_ref, user_ref, snapshot_ref, item_kind, item_ref, item_hash, marker_kind.
4. LFG grava feedback_votes.
5. Job/função recomputa aggregate bucket.
6. Aggregate calcula recommendation:
   collect_more_votes / open_human_review / recommend_global_marker / blocked_conflict.
7. Revisor LFG decide em feedback_marker_reviews.
8. Só review accepted cria global_markers/global_marker_events.
9. Workspace recebe depois sinal de refresh/staleness/marker global atualizado, sem perder annotation local.
```

## Critérios de aceite para implementação posterior

Para T6, considerar completo quando o lab demonstrar:

1. Criação de votos para `phone wrong`, `email wrong`, `mailing_address wrong` e `dnc` com workspace/user weak refs.
2. Agregação de múltiplos votos em bucket único.
3. Recomendação automática sem aplicação direta.
4. Review humano/sistêmico aceitando um aggregate.
5. Apply idempotente criando marker global LFG-owned.
6. Tentativa de apply sem review falha.
7. Voto conflitante muda conflict_score ou bloqueia recomendação.
8. Views/admin read model mostram aggregate/review sem expor PII crua.

## Guardrails finais

- Não criar FK forte para `prop4you_user_workspace` neste contrato.
- Não deixar `feedback_votes` virar tabela de annotation local do workspace.
- Não aplicar `global_markers` a partir de voto unitário.
- Não misturar marker workspace-owned com marker LFG-owned só porque têm o mesmo nome humano.
- Não armazenar provider raw payload nem segredos em evidence/comment.
- Não modelar `dnc` como simples boolean universal sem lineage/effective_at/review.
- Não fazer refresh sobrescrever nota local do workspace; feedback bridge e global marker são camadas distintas.

## Recomendação para Thor/T6

Implementar a fatia em quatro blocos idempotentes, se possível no mesmo pacote LFG:

```text
1. feedback_votes
2. feedback_marker_aggregates + recompute function/view
3. feedback_marker_reviews + review function
4. global_markers/global_marker_events + apply function idempotente
```

Manter a nomenclatura explícita `feedback_*` para bridge/review e `global_marker*` para verdade LFG aplicada. Isso preserva o relacionamento fraco, suporta topologia multi-DB futura e deixa claro que workspace feedback é evidência candidata, não autoridade global.
