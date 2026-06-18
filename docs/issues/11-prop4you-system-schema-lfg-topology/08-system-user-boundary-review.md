# Review A — fronteira `system`/LFG vs workspace do usuário

Status: delivered
Escopo: repo-only, arquitetural, database-centric PG18
Artefatos revisados:

- `docs/issues/11-prop4you-system-schema-lfg-topology/00-detection-and-analysis.md`
- `docs/issues/11-prop4you-system-schema-lfg-topology/01-prd.md`
- `docs/database-centric-app-model.md`
- `docs/issues/10-prop4you-lfg-staging-materialization-operational/11-executive-synthesis.md`
- `database/ddl/projects/prop4you/leadfinder_group/README.md`
- `database/ddl/projects/prop4you/leadfinder_group/0001_staging_candidates.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0002_materialization_runs.sql`
- `database/ddl/projects/prop4you/leadfinder_group/0003_operational_minimum.sql`

## Resultado executivo

A fronteira recomendada é tratar o legado Django `system`/LFG como um sistema interno separado, com comportamento de terceiro interno, e não como o schema/tabela do usuário logado.

No modelo PG18 database-centric:

```text
LFG / system-like internal upstream
  = inteligência, corpus, provider facts, public records, contato, dicionário, DTO, lineage, qualidade, eventos operacionais próprios

workspace do usuário P4Y
  = seleção, snapshot, referência, estado de análise, uso, preferências/visibilidade, refresh explícito, decisões do usuário
```

Portanto, nomes parecidos entre os dois lados não são duplicidade por si só. Eles representam contextos semânticos diferentes. Exemplo: um `tag`, `label`, `wrong`, `dnc`, `status`, `group`, `lead`, `contact` ou `property` no LFG pode significar evidência/cálculo/sinal de origem; no workspace do usuário pode significar anotação, decisão, filtro, tarefa, consumo ou snapshot daquele usuário/conta.

A separação deve ser desenhada como fronteira de produto/dado, não como convenção de frontend. Angular ou qualquer gateway deve consumir uma fachada/API estável, mas não deve definir a verdade de domínio.

## Modelo mental recomendado

### 1. LFG como terceiro interno

O esclarecimento do usuário aponta para LFG como um sistema à parte que serve informações ao P4Y. Mesmo que seja operado pelo mesmo produto, ele deve ser modelado como um upstream interno:

```text
providers / public records / corpus privado
  -> SourceHub ingress/lineage/DTO publication
  -> Matrix mapping/artifacts/quality
  -> LeadFinder dictionary/canonical semantics
  -> LeadFinder Group staging/materialization/operational minimum
  -> P4Y workspace snapshots/refs/usage
```

Consequências:

- LFG pode ter carga de ingestão alta e variável sem bloquear o caminho quente do usuário.
- LFG guarda histórico, evidência, versões, hash, qualidade e lineage mesmo quando nenhum usuário selecionou aquele dado.
- LFG pode reprocessar, corrigir, superseder ou recalcular sem automaticamente alterar o workspace do usuário.
- O workspace do usuário consome LFG por ID/ref/hash/version, não por cópia informal de tabelas internas.

### 2. Workspace como camada de consumo e snapshot

O workspace do usuário logado deve guardar estado derivado do uso:

- quais grupos/propriedades/contatos/leads o usuário selecionou, comprou, abriu, salvou, exportou ou analisou;
- snapshot de campos exibidos no momento do uso;
- referência para a fonte LFG original (`public_ref`, `id`, `version`, `hash`, `dictionary_version`, `matrix_artifact`, `sourcehub_publication`);
- estado de refresh: atual, stale, pending_refresh, user_pinned, superseded, conflict;
- uso/billing/auditoria do consumo;
- notas, tags e decisões do usuário sem confundí-las com sinais LFG.

O workspace não deve virar dono de provider/public-record/contact intelligence. Ele pode guardar snapshots e overrides locais, mas a origem e a evolução da inteligência permanecem no LFG/SourceHub/Matrix/LeadFinder.

## Separação por responsabilidade

| Responsabilidade | Dono recomendado | Observação |
| --- | --- | --- |
| Raw provider/public payload | SourceHub | Ingress, corpus, lineage, hash; sem expor raw ao workspace. |
| DTO traduzido/publicado | SourceHub + Matrix + LeadFinder version | Publicação versionada, com artifact/dictionary version. |
| Semântica/campos canônicos | LeadFinder + Matrix | LeadFinder define dicionário; Matrix governa mapping/artifact/quality. |
| Grupo operacional LFG | `prop4you_leadfinder_group` | Staging, materialization, operational groups/events/facets mínimos. |
| Contato/provider/public records | LFG/system-like upstream | Inteligência compartilhável e reprocessável. |
| Seleção de usuário | Workspace P4Y | Ref/snapshot/estado de consumo. |
| Notas/tags/labels do usuário | Workspace P4Y | Não promovem fatos globais sem fluxo explícito de feedback/review. |
| Usage/billing/export/audit do usuário | Workspace/Billing | Métrica de consumo, não fato LFG. |
| Visibilidade/autorização | Workspace/API facade/RLS | O usuário não lê tabelas LFG raw/domain diretamente. |

## Evidências no repo

### SourceHub/Matrix/LFG já seguem fronteira técnica inicial

O T5 mínimo implementado em `prop4you_leadfinder_group` já evita virar workspace de usuário:

- `staging_candidates` consome `prop4you_sourcehub.translated_dto_publications`, não provider diretamente.
- `materialization_runs/results` funciona como gate revisável entre staging e operacional.
- `operational_groups/events/facets` são mínimos, internos e não representam o produto final de usuário.
- Os comentários de DDL reforçam `[NO_PROVIDER_CALLS]`, `[NO_RAW_PAYLOAD_DUMP]`, `[GATEWAY_AGNOSTIC]` e `[NO_TABLE_EXPLOSION]`.
- O proof da issue 10 mostra pipeline provado: 97 raws -> 10 DTOs -> 10 staging candidates -> 1 run -> 10 results -> 10 groups -> 10 events -> 30 facets.

Isto é compatível com a fronteira: LFG materializa inteligência operacional interna; workspace só deve consumir isso por contrato.

### O doc database-centric reforça gateway como transporte

`docs/database-centric-app-model.md` define:

```text
schema/domain = durable truth
api = facade
realtime/outbox = downstream transport
gateway = transport, not owner of business truth
```

Logo, a separação não deve depender de Django/Angular. O legado Django `system` é evidência de contexto e nomenclatura, mas a forma canônica PG18 deve ser schemas/DDL/funções/RLS/fachadas.

## Boundary contract proposto

### Contrato de leitura do workspace para LFG

O workspace deve referenciar LFG por contrato estável, por exemplo:

```text
workspace_saved_item
  workspace_id
  user/account id
  lfg_public_ref ou lfg_group_id
  lfg_version/hash observado
  source_publication_id/hash observado quando aplicável
  matrix_artifact_id/hash observado quando aplicável
  dictionary_version_id observado
  snapshot jsonb redigido/normalizado para UI/uso
  snapshot_taken_at
  refresh_status
  user_state
  usage/billing correlation
```

Regras:

1. O snapshot é do workspace; a inteligência é do LFG.
2. Alteração no LFG não deve sobrescrever silenciosamente snapshot salvo pelo usuário.
3. Refresh deve ser explícito ou controlado por política documentada.
4. O workspace pode comparar `hash/version` para detectar staleness.
5. O workspace pode manter campos desnormalizados para performance, mas precisa manter lineage/ref.

### Contrato de escrita do workspace para LFG

O workspace não deve escrever diretamente em tabelas LFG de inteligência. Escritas de usuário devem seguir um caminho separado:

```text
workspace feedback/anotação
  -> feedback/event/outbox/fila/review queue
  -> LFG/Matrix review opcional
  -> promoção explícita se virar inteligência global
```

Exemplos:

- usuário marca telefone como errado: no workspace é `user_contact_marker=wrong_for_this_user/context`; no LFG pode virar evidence candidate, nunca mutation direta de `provider_contact_fact`.
- usuário marca DNC: no workspace pode significar preferência/compliance daquela conta/campanha; no LFG pode existir como sinal global/provider/jurídico se houver fonte e governança própria.
- usuário cria label/tag: no workspace é organização/segmentação local; no LFG só vira taxonomia/semântica global por review/promoção.

## Onde `system` entra

O legado Django `system` deve ser tratado como nome histórico/contexto de origem, não como destino literal obrigatório.

Recomendação:

```text
Django legacy `system`
  -> extrair responsabilidades
  -> classificar cada item como upstream LFG, workspace, transversal/base, billing, identity ou API facade
  -> modelar em schemas PG18 explícitos
```

Não criar um grande schema `system` genérico para misturar:

- usuários logados;
- provider corpus;
- contatos públicos;
- dicionário/mapping;
- tags/labels de usuário;
- materialização LFG;
- billing/usage.

Se algum schema `system` for mantido por compatibilidade, ele deve ser uma fachada/transição com limites claros, não o bounded context canônico.

## Anticorruption layer entre LFG e workspace

A fronteira precisa de uma camada anticorrupção para não vazar semântica interna:

```text
prop4you_leadfinder_group.* internal domain
  -> api/workspace read function ou materialized read projection
  -> workspace snapshot/ref table
  -> client/gateway
```

Essa camada deve:

- redigir/remover raw/provider-sensitive fields;
- estabilizar nomes de campos para consumidores;
- anexar `source_version`, `hash`, `dictionary_version` e `observed_at`;
- controlar rate/load/tenant access;
- evitar joins pesados no caminho quente.

## Implicações para ingestão alta e carga variável

Como LFG é upstream interno com ingestão alta:

- Ingestão, normalização e materialização devem ficar fora de transações de usuário.
- Jobs/queues/outbox/cron/worker devem atualizar LFG independentemente do workspace.
- Workspace deve operar em snapshots/refs já prontos, com refresh assíncrono quando necessário.
- Queries de usuário não devem depender de reprocessamento SourceHub/Matrix/LFG em tempo real.
- Eventos LFG podem notificar staleness/novas versões, mas não devem forçar mutation síncrona no workspace.

Isto preserva latência e isolamento de falhas: uma onda de provider ingestion ou rematerialização LFG não deve degradar login, listas, anotações, billing/usage ou leitura de snapshots já salvos.

## Decisões recomendadas

1. Nomear explicitamente LFG/system-like como upstream interno, não workspace.
2. Criar/planejar um bounded context de workspace separado quando chegar a hora de DDL, por exemplo `prop4you_workspace` ou equivalente, sem editar DDL nesta task.
3. Workspace deve guardar refs/snapshots/usage, não corpus/inteligência global.
4. LFG deve guardar inteligência/corpus/contato/provider/public records e seus metadados de qualidade/lineage/versionamento.
5. Similaridade de nomes não é duplicidade; exigir coluna/contexto de ownership antes de consolidar tabelas.
6. Qualquer promoção de feedback do usuário para inteligência LFG deve passar por fila/review/artifact, nunca update direto.
7. Expor dados LFG ao usuário por API/read projection redigida e versionada, não por tabela interna raw/domain.
8. Usar hashes/version para refresh e comparação de staleness; evitar overwrites implícitos.
9. Manter gateway/runtime agnostic: Django, PostgREST, FastAPI ou Angular são consumidores/transporte.
10. Não transformar `system` em lixeira semântica; extrair e realocar responsabilidades.

## Riscos encontrados

- Risco de colisão semântica: campos como `tag`, `label`, `status`, `wrong`, `dnc`, `lead`, `property` e `contact` podem parecer duplicados, mas precisam de ownership/contexto.
- Risco de acoplamento operacional: se o workspace ler tabelas LFG internas diretamente, ingestão/materialização pode afetar latência do usuário.
- Risco de sobrescrita de snapshot: atualizações LFG automáticas podem apagar decisões/visão histórica do usuário se não houver version/hash/pin.
- Risco de vazamento de payload: workspace/API não deve expor raw payload, provider-sensitive fields ou DTO scalar dump sem redaction contract.
- Risco de schema `system` genérico: misturar legado, LFG e usuário logado reduz auditabilidade e quebra a arquitetura database-centric.

## Critérios para decidir se uma tabela/campo pertence ao LFG ou ao workspace

Perguntas de decisão:

1. O dado existe mesmo sem usuário ter visto/salvo? Provável LFG/SourceHub/Matrix/LeadFinder.
2. O dado vem de provider/public record/corpus/skip trace/dicionário? Provável LFG/system-like upstream.
3. O dado expressa seleção, nota, filtro, lista, campanha, export, compra, uso ou preferência de uma conta? Provável workspace/billing.
4. O dado precisa ser reprocessado em massa após mudança de dictionary/mapping/provider? Provável LFG.
5. O dado precisa preservar “o que o usuário viu naquele momento”? Provável workspace snapshot.
6. O dado é feedback de usuário que talvez melhore inteligência global? Primeiro workspace/event feedback; promoção posterior por review.

## Conclusão

A separação correta é produto/dado, não UI/framework:

```text
LFG/system-like internal upstream owns intelligence.
P4Y user workspace owns consumption state.
```

A DDL T0-T5 mínima já aponta nessa direção ao manter SourceHub/Matrix/LeadFinder/LFG como schemas internos, versionados e gateway-agnostic. A próxima etapa arquitetural deve formalizar o contrato de workspace como consumidor: tabelas de refs/snapshots/usage, funções de snapshot/refresh, e uma fachada API redigida que não exponha raw/internal LFG diretamente.
