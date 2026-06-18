# Worker C — tags, labels, markers e phone markers: split semântico LFG/system vs workspace

Status: entregue
Escopo: T4 / revisão arquitetural repo-only
Repo: `/home/marcelo-karval/Backup/Projetos/supabase-postgres-18-fork/postgres`

## Veredito

Tags, labels, markers e phone markers com nomes parecidos nos contextos `system`/LFG e workspace do usuário não são duplicação por si só. Eles representam camadas semânticas diferentes:

- No LFG/system, marcadores são evidência sistêmica de qualidade, contactability, proveniência, taxonomia operacional e sinais globais derivados de provider/public-record/SourceHub/Matrix/LeadFinder.
- No workspace do usuário logado, tags/labels/markers são decisão, anotação, organização, workflow e contexto tenant/subscriber sobre um snapshot/seleção consumida do LFG.

Portanto, `dnc`, `wrong`, `bad phone`, `qualified`, `hot`, `probate`, `tax_sale` ou rótulos similares podem existir nos dois lados sem serem a mesma entidade. O nome humano pode coincidir; o owner, o escopo, a validade temporal, a política de refresh, o audit trail e a autoridade são distintos.

## Evidência local usada

Esta revisão é repo-only e se apoia nos documentos/DDL locais abaixo, sem provider calls, browser, web/MCP ou edição de DDL:

- `docs/issues/11-prop4you-system-schema-lfg-topology/01-prd.md`: risco explícito de tratar tags/labels/phone markers LFG como se fossem user-owned annotations/workspace state.
- `docs/issues/11-prop4you-system-schema-lfg-topology/00-detection-and-analysis.md`: LFG armazena provider/public-record/contact intelligence, tags/labels/phone markers e versioning; nomes similares não implicam duplicação.
- `docs/issues/03-prop4you-leadfinder-canonical-cycle-analysis/09-prop4you-inertia-leadfinder-system-boundaries.md`: contatos/status (`OwnerPhone`, `OwnerEmail`, DNC, callability/sendability) ficam no sistema/canonical graph; overlays/workspace (`PropertyTag`, `PropertyList`, `SavedProperty`, registries/tags de contato) são distintos.
- `docs/issues/04-prop4you-leadfinder-dictionary-from-raws/08-raw-to-leadfinder-family-field-analysis.md`: `contact_satellites` inclui `is_dnc`, status, validade, qualidade e estatísticas; `systemic_taxonomy` é distinta de tags/listas de workspace/subscriber.
- `docs/issues/09-prop4you-sourcehub-translated-dto-publications/08-sourcehub-dto-contract-review.md`: DTO SourceHub publicado é versionado, dependente de raw record + Matrix artifact + dictionary version, e não materializa automaticamente entidades finais.
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/10-lfg-operational-facets-review.md`: operacional LFG inicial deve usar `facets` estruturadas, não uma lixeira de tags; `contact_hint` não vira tabela final de phone/email nesta fatia.

## Modelo mental recomendado

```text
Provider/raw/public record
  -> SourceHub raw/lineage/source facts
  -> Matrix mapping/admission/quality semantics
  -> LeadFinder/LFG DTO/materialized operational facets
  -> workspace snapshot/selection/reference
  -> user annotations/tags/lists/actions
```

A seta final não deve ser lida como cópia livre nem como ownership transfer. Workspace consome um estado publicado/versionado do LFG e pode registrar decisões locais, mas não deve sobrescrever a evidência sistêmica global.

## Split semântico por categoria

| Categoria | LFG/system | Workspace usuário logado |
| --- | --- | --- |
| Tags sistêmicas | Taxonomia derivada de provider/list type/Matrix/LF dictionary; ex.: `system_property_tag`, `phone_tag`, `email_tag`, list/source taxonomy | Organização do usuário/tenant; ex.: campanha, lista, prioridade, motivo interno, etiqueta customizada |
| Labels | Labels de classificação, leitura, qualidade ou materialization/search; governadas por versão/hash/evidence | Labels visuais ou operacionais escolhidos pelo usuário/equipe; governadas por RLS/tenant/workspace |
| Markers | Sinais sistêmicos como qualidade, source confidence, duplicate hints, contactability, deliverability, list provenance | Notas/decisões de usuário como "ligar depois", "não interessa", "cliente pediu", "minha lista" |
| Phone markers | `is_dnc`, `dnc_reason`, `is_valid`, `wrong/dead/bad phone`, `last_called_at`, `call_count`, `quality_score`, status/callability quando derivados de provider, enrichment ou operação sistêmica autorizada | Feedback/decisão do usuário sobre aquele snapshot: "não ligar neste workspace", "número errado para minha campanha", "preferido", "tentativa local", "manual override pending review" |
| Situações | Fatos estruturados (`PropertySituation`, legal timeline, list provenance) ou facets `situation_fact`; não devem virar tag solta | Percepção/workflow do usuário sobre a oportunidade; pode referenciar situação LFG mas não redefini-la globalmente |

## DNC/wrong: mesmo nome, semântica diferente

### `dnc` no LFG/system

`dnc` sistêmico é evidência de contactability/compliance/qualidade associada ao telefone ou contato, com lineage. Pode vir de provider, skip trace, corpus, enriquecimento, operação sistêmica ou consolidação aprovada. Ele deve responder perguntas como:

- Qual evidência suporta que este número é DNC?
- A marca vale globalmente, por provider, por jurisdição, por fonte ou por janela temporal?
- Qual versão do DTO/materialização continha esse marker?
- Quem/processo registrou ou alterou o marker sistêmico?
- Esse marker reduz callability para todos os consumidores ou só informa risco?

Esse marker não é uma preferência do usuário. Ele pertence ao fluxo LFG/SourceHub/Matrix/LeadFinder e precisa de `lineage`, `observed_at/effective_at`, `source`, `confidence/quality`, `version/content_hash` e audit.

### `dnc` no workspace

`dnc` de usuário/workspace é decisão local/tenant. Pode significar "este workspace não quer ligar", "este assinante marcou como não contatar", "campanha X exclui esse número", ou "feedback do operador ainda não promovido". Ele deve responder perguntas como:

- Qual tenant/workspace/user/campanha marcou?
- É uma decisão local ou uma sugestão de correção global?
- Aplica-se só a uma propriedade/lista/snapshot ou ao contato inteiro dentro do tenant?
- Deve abrir evento de review para LFG ou permanecer privado ao workspace?

Esse marker não deve automaticamente alterar o DNC sistêmico global.

### `wrong` / `bad phone`

`wrong` sistêmico significa evidência de qualidade/contactability baixa ou incompatibilidade de identidade: número inválido, número não pertence ao owner, telefone morto, duplicado incorreto, provider evidence contraditória etc. Deve preservar prova, confidence, fonte e versão.

`wrong` no workspace pode ser apenas feedback contextual: "o usuário ligou e a pessoa disse que não é o lead", "não serve para minha campanha", "número errado neste snapshot". Pode alimentar fila de review/feedback loop, mas não deve virar correção global sem gate.

## Regra de ownership

1. LFG/system é o owner de marcadores que afirmam algo sobre qualidade global, contactability, provider evidence, materialization, source taxonomy ou canonical/operational graph.
2. Workspace é o owner de marcadores que expressam decisão, anotação, lista, UI, campanha, preferência, override local ou estado de trabalho do tenant.
3. SourceHub é o owner de raw lineage/source facts e publicações DTO traduzidas.
4. Matrix é o owner de semântica/mapping/admission/gate e artifacts de qualidade.
5. LeadFinder/LFG é o owner do consumo/materialização operacional/canonical group/facets.
6. Public/workspace consome e referencia LFG por ID/versão/hash; não possui raw truth nem provider truth.

## Implicações para snapshot/versioned DTO

O split exige que workspace armazene referência versionada ao LFG, não uma cópia anônima que perde lineage.

Campos/contratos futuros recomendados para snapshots de workspace:

- `lfg_group_id` ou `lfg_public_ref`.
- `sourcehub_publication_id`/`sourcehub_publication_public_ref` quando o snapshot nasce de DTO publicado.
- `dto_contract_version`.
- `lfg_materialization_version` ou `operational_group.version`.
- `content_sha256` / `payload_hash` / `facet_hash` conforme estágio.
- `snapshot_taken_at`.
- `snapshot_reason` (`user_saved`, `campaign_export`, `manual_review`, `refresh_acceptance`, etc.).
- `snapshot_staleness_status` (`current`, `stale_available`, `refresh_requested`, `refresh_failed`, `superseded`).
- `workspace_annotations` ou tabela lateral tenant-owned, nunca dentro do DTO LFG publicado.

O DTO versionado deve separar:

```text
lfg_evidence.markers[]        -- owner LFG/system, global/evidence/contactability
workspace_annotations.markers[] -- owner tenant/user, local/decision/workflow
lineage/version/hash           -- comparação e refresh
```

Mesmo quando uma UI mostra uma lista única de chips, a API/DTO deve carregar `scope`, `owner_context`, `source`, `effective_at`, `version` e `editable_by_user` para impedir mistura semântica.

## Implicações para refresh

Refresh não é merge cego. Quando LFG muda, workspace deve comparar versão/hash e decidir:

1. LFG publica nova versão/facet/DTO.
2. Workspace detecta que o snapshot está stale por `version/hash`.
3. Usuário/tenant ou política aceita refresh.
4. O refresh atualiza campos e markers LFG-owned no snapshot/projeção.
5. Annotations/workspace markers permanecem tenant-owned e só são remapeados por regra explícita.
6. Conflitos viram evento de review, não overwrite silencioso.

Exemplos:

- LFG troca phone marker de `callable` para `dnc`: workspace deve receber staleness/refresh signal; campanha pode bloquear automaticamente por política de compliance, mas preservar auditoria da decisão.
- Usuário marca `wrong`: workspace registra localmente; opcionalmente emite feedback event para review LFG, sem alterar `OwnerPhone.is_valid` global.
- LFG corrige `wrong` para `valid`: workspace mostra nova evidência, mas não apaga a nota local do usuário sem regra.

## Implicações para audit e realtime

### Audit

Audit deve distinguir trilhas:

- Audit sistêmico LFG: alterações em evidence/facets/phone markers, source lineage, DTO version, Matrix artifact, dictionary version, materialization run/result, actor/process/system job.
- Audit workspace: ações de usuário, listas, tags, labels, local DNC/wrong, notes, refresh acceptance/rejection, campaign membership.
- Feedback bridge: evento explícito quando workspace sugere promoção/correção global (`workspace_feedback_submitted`, `lfg_review_opened`, `lfg_feedback_accepted/rejected`).

Campos úteis em eventos futuros:

- `event_scope`: `lfg_system`, `workspace`, `feedback_bridge`.
- `tenant_id/workspace_id/user_id` quando aplicável.
- `lfg_ref`, `lfg_version`, `snapshot_id`.
- `marker_key`, `marker_value`, `previous_value`, `source_kind`.
- `evidence_ref`, `confidence`, `reason_code`.
- `causation_id`, `correlation_id`.

### Realtime

Realtime também deve separar canais/contratos:

- Canal LFG/system: publica nova versão, marker/facet changed, materialization refreshed, source quality changed. Consumidores devem tratar como upstream staleness/change notification.
- Canal workspace: publica ação local, tag/list/note alterada, refresh aceito, campanha afetada.
- Canal feedback/review: publica status de sugestão enviada pelo workspace para revisão sistêmica.

Evitar realtime que envie `phone_marker_changed` sem `scope`, porque isso induz UI e backend a misturarem DNC global com DNC local.

## Futuras tabelas recomendadas

Sem editar DDL nesta fatia, a modelagem futura deve preferir nomes que carreguem o owner/contexto no próprio contrato.

### LFG/system-owned

Possíveis tabelas futuras, se/when o operacional mínimo evoluir:

- `prop4you_leadfinder_group.system_markers`
- `prop4you_leadfinder_group.system_marker_events`
- `prop4you_leadfinder_group.contact_markers`
- `prop4you_leadfinder_group.phone_contactability_evidence`
- `prop4you_leadfinder_group.system_taxonomy_labels`
- `prop4you_leadfinder_group.operational_group_facets` com `facet_type = contact_hint/source_quality/systemic_taxonomy`

Requisitos:

- `marker_scope = 'lfg_system'` ou equivalente.
- FK forte somente para contratos estáveis dentro do LFG/materialization; provider/SourceHub/Matrix instável via lineage quando necessário.
- `lineage jsonb`, `evidence_ref`, `source_kind`, `confidence`, `observed_at`, `effective_at`.
- `version`, `content_sha256` e eventos append-only para mudanças importantes.

### Workspace-owned

Possíveis tabelas futuras:

- `prop4you_workspace.saved_lfg_items` ou `workspace_property_snapshots`.
- `prop4you_workspace.workspace_tags` / `workspace_labels`.
- `prop4you_workspace.workspace_item_tags`.
- `prop4you_workspace.workspace_contact_markers`.
- `prop4you_workspace.workspace_snapshot_refresh_events`.
- `prop4you_workspace.workspace_lfg_feedback_events`.

Requisitos:

- `tenant_id/workspace_id/user_id` explícitos e RLS/workspace ownership.
- Referência a LFG por `lfg_public_ref/id + version/hash`, não FK obrigatória cross-node em topologias separadas.
- Ações locais auditáveis e reversíveis.
- Campo de `promotion_status` apenas para feedback a LFG, não para mutação global direta.

### Bridge/feedback

Se o produto precisar capturar feedback de usuários para melhorar LFG global, criar bridge explícito em vez de reutilizar a mesma tabela:

- `workspace_feedback_events`: tenant-owned append-only.
- `lfg_feedback_review_queue`: system-owned review gate.
- `lfg_feedback_decisions`: system-owned aceite/rejeição com reviewer/system actor.

Isso permite usar feedback humano sem transformar workspace em fonte global automática.

## Guardrails arquiteturais

1. Não criar uma tabela genérica `tags` compartilhada por system e workspace sem `scope/owner_context` forte.
2. Não promover `system_property_tag` para `workspace tag`, nem `PropertyTag` para taxonomy sistêmica.
3. Não transformar `lead_type`/provider list slug em situação final sem Dictionary + Matrix artifact.
4. Não deixar `operational_group_facets` virar lixeira de tags; usar `facet_type`, `facet_key`, `facet_value` objeto, status/review e lineage.
5. Não permitir que user marker `wrong/dnc` sobrescreva contato global sem fila de review e evidence.
6. Não apagar annotation local durante refresh de LFG sem política explícita.
7. Não expor raw phone/email/provider payload ao workspace; consumir projections/snapshots com máscara/contrato público.
8. Não emitir audit/realtime sem `scope`.

## Decisão recomendada para o artefato canônico T5

Incluir a seguinte regra no documento de arquitetura:

```text
Tags/labels/markers são nomes de interação, não nomes de ownership.
O owner semântico é definido por scope + fonte + autoridade + versão:
LFG/system markers = evidência/qualidade/contactability/taxonomia global.
Workspace markers = decisão/anotação/workflow/tenant context.
Nomes iguais como dnc/wrong são homônimos de contextos diferentes; só se comunicam por snapshot/refresh/feedback events explícitos.
```

Essa regra resolve a aparente duplicação e mantém o pipeline Matrix -> SourceHub -> LFG -> workspace consistente com DTO versionado, refresh controlado, audit separado e evolução futura de tabelas sem acoplamento indevido.
