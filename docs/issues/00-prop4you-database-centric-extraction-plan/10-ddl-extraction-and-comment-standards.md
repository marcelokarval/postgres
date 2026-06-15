# Padrões de extração DDL e comentários — Prop4You database-centric

Status: draft/subagent-C
Data: 2026-06-14
Escopo: plano documental; não implementa DDL de produção.

## 1. Objetivo

Definir o padrão que deve guiar a futura extração das regras do Prop4You para pacotes DDL versionados em PostgreSQL 18, com foco em:

- ordem de extração dos domínios;
- formato esperado do pacote DDL;
- padrões de `COMMENT ON` para schemas, tabelas, colunas, funções, triggers, views, políticas e jobs;
- política de mutação dos DDLs enquanto Matrix, SourceHub, LeadFinder e payloads de provedores ainda estão em revisão;
- checklist de revisão;
- plano de validação em laboratório.

Este documento usa como evidência principal:

```text
docs/reports/prop4you-inertia-app-inventory-and-extraction-order.md
docs/database-centric-app-model.md
docs/database-centric-soft-ddd-rule.md
docs/pg18-database-centric-ddl-strategy.md
database/ddl/base/README.md
/home/marcelo-karval/Backup/Projetos/prop4you/prop4you-inertia/backend/src
```

## 2. Princípios normativos

1. DDL de projeto não entra na imagem PG18 base. Prop4You deve viver sob `database/ddl/projects/prop4you/`.
2. Django/Inertia é evidência, não desenho final. Modelos, serviços, tasks e migrations ajudam a identificar regras, mas não devem ser copiados mecanicamente.
3. Schemas são domínios/bounded contexts; tabelas são verdade durável, ledgers, snapshots, filas ou registros operacionais; funções são casos de uso; `api.*` é fachada.
4. Tabelas de domínio não devem ser expostas diretamente para clientes por padrão. Use funções/views controladas em `api`.
5. JSONB e lineage são substrato de primeira classe para payloads de provedores, SourceHub, Matrix e DTOs internos.
6. DDLs devem ser explicitamente versionados, revisáveis e aplicáveis em laboratório limpo antes de qualquer uso fora do lab.
7. Comentários SQL são parte do contrato. Objeto sem comentário objetivo é objeto incompleto.
8. Arquivos DDL já aplicados e registrados por checksum não devem ser reescritos silenciosamente; correções devem virar novos arquivos versionados.

## 3. Ordem de extração DDL

A ordem abaixo combina o inventário da aplicação com o modelo database-centric. Ela prioriza dependência semântica, não apenas FK física.

### 3.1 Ordem macro

0. `base/core substrate` já existente
   - Validar que o pacote `database/ddl/base/` cobre install tracking, extensões, contexto, public refs, lifecycle, JSONB helpers, normalização, audit, realtime e `api` base.
   - Não transformar `core.db` Django em um domínio Prop4You separado salvo se surgirem regras de produto não cobertas pela base.

1. `identity`
   - Usuários, perfil, onboarding, MFA, legal acceptance, tokens, feature flags e limites de segurança.
   - Razão: quase todos os domínios referenciam usuário/ator/workspace.

2. `geography`
   - Áreas, endereços, candidatos de geocodificação, termos/feed de área.
   - Razão: propriedade e contato de proprietário dependem de endereço/área.

3. `billing` / `finance`
   - Planos, créditos, USD balance, uso, payment metadata, checkout/session tokens, limites de acesso.
   - Razão: gates de acesso, delinquency e uso precisam de verdade estável para testes de API e RLS.

4. `property` / `leadfinder` canonical graph
   - Propriedade, localização, owner entity, ownership, party roles, contatos, valuations, details, situations estruturadas, lead score/intelligence, workspace CRM.
   - Razão: este é o núcleo de negócio. Lead Finder define o grafo canônico; situations são fatos estruturados, não tags genéricas.

5. `sourcehub`
   - Ingresso, raw records, lineage, snapshots, publicação de DTO canônico, batches de importação.
   - Razão: SourceHub deve preservar payload e origem, depois publicar/promover para o grafo canônico sem redefinir propriedade/owner como verdade final.

6. `skiptrace`
   - Requests, provider runs, results, candidate contacts, caches, snapshots, financial projections.
   - Razão: Skip Trace enriquece owner/property; não define a verdade primária do grafo.

7. `matrix`
   - Genomas/schema semantics, baselines, approval records, corpus sessions, field review, growth pressure signals, dicionário canônico e contratos DTO quando duráveis.
   - Razão: Matrix governa significado, comparação e mapeamentos; deve ser extraída depois que limites de canonical graph e SourceHub estiverem explícitos.

8. `sales`
   - Contacts, deals, stages, tasks, documents, handoffs, analytics.
   - Razão: CRM depende de identity e, conceitualmente, do grafo de propriedade/owner/lead.

9. `communication`
   - Templates, campaigns, recipients, mensagens operacionais.
   - Razão: comunicação ativa leads/CRM e depende de identity/sales/lead context.

10. `invitations/onboarding adjunct`
    - Só extrair DDL próprio se houver tabelas/regras duráveis de produto; no inventário atual não há modelos first-party relevantes.

11. `api facade` e interfaces públicas
    - Traduzir `apps.public.*` e `interfaces.web.*` por último para `api.*` functions/views, após domínio, RLS e contratos JSON estarem estáveis.

### 3.2 Slices recomendados

| Slice | Nome sugerido | Conteúdo | Gate antes de avançar |
| --- | --- | --- | --- |
| S0 | `prop4you_base_alignment` | dependências em `base`, prefixos públicos reservados, schemas vazios comentados | base package revalidado em lab |
| S1 | `prop4you_identity_core` | account/user/profile/legal/token/onboarding | atores e contexto resolvíveis |
| S2 | `prop4you_geography_core` | areas, addresses, spatial/index strategy | endereço normalizado consultável |
| S3 | `prop4you_billing_usage` | planos, créditos, usage/limits | gates de acesso testáveis |
| S4 | `prop4you_property_graph_core` | property/location/owner/ownership/contacts/party roles | grafo canônico mínimo testável |
| S5 | `prop4you_property_workspace` | lists, saved properties, notes, tags/status/list registries, filter presets | workspace RLS/projeções testáveis |
| S6 | `prop4you_lead_intelligence` | situations, scores, intelligence, attempts, valuations/details | facts estruturados e scores auditáveis |
| S7 | `prop4you_sourcehub_lineage` | raw records, ingest batches, lineage, DTO publication | raw -> canonical promotion auditável |
| S8 | `prop4you_skiptrace_enrichment` | requests/results/provider runs/candidates/cache | enriquecimento sem redefinir truth |
| S9 | `prop4you_matrix_semantics` | dictionary, mapping artifacts, approvals, reviews | dicionário com ciclo de aprovação |
| S10 | `prop4you_sales_communication` | CRM/deals/campaigns | domínio core completo |
| S11 | `prop4you_api_facade` | `api.*` RPC/views/client contracts | domínio + policies completos |

## 4. Formato do pacote DDL

### 4.1 Local canônico

```text
database/ddl/projects/prop4you/
  README.md
  0001_schemas.sql
  0002_identity_tables.sql
  0003_geography_tables.sql
  0004_billing_tables.sql
  0005_property_graph_tables.sql
  0006_property_workspace_tables.sql
  0007_lead_intelligence_tables.sql
  0008_sourcehub_lineage_tables.sql
  0009_skiptrace_enrichment_tables.sql
  0010_matrix_semantics_tables.sql
  0011_sales_communication_tables.sql
  0012_public_id_registry.sql
  0013_lifecycle_triggers.sql
  0014_constraints_indexes.sql
  0015_domain_functions.sql
  0016_views_projections.sql
  0017_api_facade.sql
  0018_audit_realtime_hooks.sql
  0019_jobs.sql
  0020_policies.sql
  0021_comments_contract.sql
  tests/
    0001_smoke.sql
    0002_comments_catalog_check.sql
    0003_idempotency_probe.sql
```

Observação: o shape acima é orientativo. O pacote pode ser dividido por domínio quando o volume justificar, mas a ordem deve continuar explícita e numérica.

### 4.2 Cabeçalho obrigatório por arquivo SQL

Cada arquivo DDL futuro deve começar com um bloco de metadados em comentário SQL comum:

```sql
-- package: prop4you
-- file: 0005_property_graph_tables.sql
-- status: draft|experimental|stable|deprecated
-- purpose: cria o núcleo canônico de propriedade/owner/ownership.
-- depends-on: base>=0001, prop4you:0001_schemas, prop4you:0003_geography_tables
-- idempotency: idempotent_where_possible
-- destructive: false
-- review-gate: property_graph_schema_review
```

Regras:

- `purpose` descreve o porquê do arquivo, não uma repetição do nome.
- `depends-on` deve listar dependências de pacote/arquivo/domínio relevantes.
- `destructive: true` exige arquivo separado, plano de migração e aprovação explícita.
- O cabeçalho não substitui `COMMENT ON`; ele documenta o arquivo, não os objetos.

### 4.3 Ordem interna por arquivo

Dentro de cada arquivo, preferir esta ordem:

1. `create schema if not exists` quando aplicável;
2. `create type/domain` somente se necessário e bem justificado;
3. tabelas base sem FKs cíclicas primeiro;
4. tabelas dependentes;
5. constraints adicionais quando não couberem inline;
6. indexes;
7. triggers;
8. funções internas do domínio;
9. views/projeções;
10. grants/RLS/policies;
11. `COMMENT ON` próximo do objeto ou em arquivo dedicado `0021_comments_contract.sql` quando a revisão de comentários for separada.

### 4.4 Dependência de base

Prop4You deve usar explicitamente o contrato base quando adequado:

- `id uuid primary key default uuidv7()`;
- `created_at`, `updated_at`, `deleted_at`, `version`, `metadata`;
- triggers de lifecycle do `base`;
- `base.public_id_prefix_registry` e helpers de public ref;
- `audit.log` para mutações significativas;
- `realtime.event_outbox` para eventos transportáveis;
- JSONB helpers quando o payload for aceito diretamente;
- `jobs.*` para trabalhos internos chamados via `cron.schedule_in_database(...)` a partir do DB scheduler.

Não usar herança PostgreSQL (`INHERITS`) como padrão para simular BaseModel Django.

## 5. Padrão de comentários SQL

### 5.1 Regra geral

Todo objeto durável ou invocável deve ter `COMMENT ON` objetivo, documental e orientado a contrato.

Obrigatório comentar:

- schemas;
- tabelas;
- colunas de tabelas duráveis;
- constraints não triviais;
- indexes com semântica de consulta importante;
- funções/procedures;
- triggers;
- views/materialized views;
- policies RLS;
- tipos/domains/enums criados pelo projeto.

Comentários devem responder, quando aplicável:

```text
O que este objeto representa?
Quem é o dono semântico?
De onde vem o dado?
Qual invariant/contrato protege?
Como se relaciona com raw payload, canonical graph, Matrix, SourceHub ou Skip Trace?
Quem pode chamar/consumir?
Qual é a regra de mutação?
```

### 5.2 Estilo

Use frases curtas em português, na voz ativa, sem marketing e sem ambiguidade.

Bom:

```sql
comment on table sourcehub.raw_record is
  'Registro bruto de ingresso SourceHub/provedor. Preserva payload original, origem e lineage; não é verdade canônica de propriedade.';
```

Ruim:

```sql
comment on table sourcehub.raw_record is 'Tabela de dados.';
```

Ruim:

```sql
comment on column property.property.payload is 'JSON do imóvel.';
```

Melhor:

```sql
comment on column property.property.source_snapshot is
  'Snapshot JSONB normalizado usado para auditoria e comparação; campos canônicos estáveis devem ter colunas próprias ou geradas.';
```

### 5.3 Comentários de schema

Formato recomendado:

```sql
comment on schema property is
  'Domínio Prop4You do grafo canônico de propriedades, owners, ownership e fatos estruturados relacionados.';
```

Cada schema deve declarar sua fronteira e o que ele não faz.

Exemplos orientativos:

```sql
comment on schema sourcehub is
  'Domínio de ingresso, raw lineage, snapshots e publicação de DTO canônico. Não redefine a verdade final de propriedade/owner.';

comment on schema skiptrace is
  'Domínio de enriquecimento por provedores de skip trace. Produz candidatos/contatos e evidências; não cria ownership canônico por si só.';

comment on schema matrix is
  'Domínio de semântica, dicionário canônico, mapeamentos e aprovações de significado entre payloads, DTOs e Lead Finder.';
```

### 5.4 Comentários de tabela

Cada tabela deve identificar seu tipo:

- entidade canônica;
- relationship/link;
- ledger;
- snapshot;
- raw ingress;
- queue/outbox;
- projection backing;
- configuração/reference data.

Exemplo orientativo:

```sql
comment on table property.ownership is
  'Relação canônica entre owner entity e propriedade. Representa ownership aceito pelo domínio após lineage/evidência; não armazena payload bruto de provedor.';
```

### 5.5 Comentários de coluna

Colunas devem comentar semântica, origem, unidade, nulabilidade intencional e regra de derivação quando houver.

Exemplos orientativos:

```sql
comment on column property.property.apn is
  'Assessor Parcel Number conforme jurisdição de origem. Pode não ser globalmente único sem county/state.';

comment on column sourcehub.raw_record.provider_payload is
  'Payload JSONB original recebido do provedor ou ingest interno, preservado para replay, comparação e auditoria.';

comment on column sourcehub.raw_record.provider_payload_hash is
  'Hash determinístico do payload canônico serializado para deduplicação e detecção de drift.';

comment on column leadfinder.lead_score.score is
  'Pontuação calculada do lead no intervalo documentado pela função de scoring vigente; não deve ser editada manualmente.';
```

### 5.6 Comentários de função/procedure

Funções devem declarar:

- se são internas de domínio ou fachada `api`;
- efeitos colaterais;
- invariants validados;
- formato de retorno;
- se emitem audit/realtime/job.

Exemplos orientativos:

```sql
comment on function property.promote_sourcehub_record(uuid) is
  'Função interna: promove um registro SourceHub aprovado para o grafo canônico de propriedade/owner, registrando audit e lineage. Não expor diretamente a clientes.';

comment on function api.search_properties(jsonb) is
  'Fachada cliente: busca propriedades por filtros estáveis e retorna contrato JSONB versionado. Não expõe tabelas internas do domínio property.';
```

### 5.7 Comentários de trigger

Triggers devem explicar o momento e o motivo, não apenas repetir o nome.

```sql
comment on trigger property_touch_updated_at on property.property is
  'Atualiza updated_at e metadados de modificação antes de alterações persistidas na entidade canônica property.';
```

### 5.8 Comentários de policy RLS

Policies devem declarar sujeito, escopo e operação.

```sql
comment on policy property_property_org_select on property.property is
  'Permite SELECT para atores cujo contexto atual possui acesso ao escopo organizacional ou property/<id> correspondente.';
```

### 5.9 Comentários de views/projeções

Views devem deixar claro se são contrato de API, projeção interna ou apoio operacional.

```sql
comment on view api.property_search_result is
  'Projeção client-facing para listagem de propriedades. Contrato estável; mudanças breaking exigem versão ou nova view/função.';
```

### 5.10 Comentários para JSONB e campos gerados

Colunas JSONB precisam declarar se são raw, normalized, metadata, DTO, snapshot ou contract.

Campos gerados/projetados devem referenciar o caminho JSON ou a regra de derivação.

```sql
comment on column sourcehub.raw_record.normalized_payload is
  'Payload JSONB normalizado pelo pipeline SourceHub para comparação semântica; preserva provider_payload como evidência original.';

comment on column sourcehub.raw_record.provider_listing_id is
  'Coluna projetada/gerada a partir de provider_payload quando o caminho de listing id está estável para o provedor.';
```

## 6. Política de mutação dos DDLs

### 6.1 Estados de maturidade

Cada arquivo/objeto relevante deve ser classificado em um estado documental:

| Estado | Uso | Regra de mudança |
| --- | --- | --- |
| `draft` | desenho inicial, não aplicado fora de lab | pode mudar livremente antes de ser aplicado |
| `experimental` | aplicado em lab; contratos em comparação | mudanças permitidas via novo arquivo quando já registrado por checksum |
| `candidate` | pronto para revisão ampla | apenas mudanças pequenas/aditivas ou novo arquivo de correção |
| `stable` | contrato aceito para uso por consumidores | sem breaking change sem migração versionada e plano de compatibilidade |
| `deprecated` | substituído por contrato novo | manter compatibilidade até remoção planejada |

### 6.2 Regras para mudanças

1. Antes de aplicação/registro em lab: o arquivo pode ser reescrito, desde que ainda não exista checksum registrado.
2. Depois de aplicado por installer com checksum: não editar o arquivo para mudar significado. Criar novo arquivo `NNNN_fix_or_extend_*.sql`.
3. Mudanças destrutivas (`drop column`, alteração de tipo incompatível, remoção de função, mudança de contrato JSON/API) devem ficar isoladas em arquivo próprio com `destructive: true`.
4. Mudanças em `api.*` devem ser compatíveis por padrão. Se quebrar cliente, criar `api.func_v2` ou novo contrato e deprecar o anterior.
5. Mudanças em tabelas raw/lineage devem preservar replay/auditoria. Nunca perder payload bruto sem migração explícita e backup comprovado.
6. Mudanças em Matrix/dicionário podem criar novas versões de regra/mapping sem sobrescrever histórico aprovado.
7. Campos gerados/projetados a partir de JSONB só devem ser promovidos quando o caminho JSON for estável e documentado.
8. Public refs (`<prefix>_<uuid7>`) e prefix registry não devem mudar significado após publicados.
9. Policies RLS devem ser revisadas junto com qualquer nova tabela, view ou função client-facing.
10. Seeds/reference data devem ser separados do DDL estrutural quando o dado puder variar por ambiente.

### 6.3 Compatibilidade durante revisão Matrix/SourceHub/LeadFinder

Enquanto o dicionário canônico não estiver fechado:

- preferir preservar payloads raw e normalized JSONB;
- criar colunas canônicas apenas para semânticas estáveis e consultadas frequentemente;
- usar tabelas de mapping/versionamento para Matrix em vez de sobrescrever significado;
- manter SourceHub e Skip Trace como fontes de evidência/enriquecimento, não como donos do grafo canônico;
- tratar Lead Finder/property graph como contrato canônico candidato, sujeito a ajustes por evidência de payload.

## 7. Checklist de revisão DDL

### 7.1 Checklist por arquivo

- [ ] Cabeçalho contém package, file, status, purpose, depends-on, idempotency, destructive e review-gate.
- [ ] Arquivo está numerado e não depende de ordem implícita.
- [ ] DDL é idempotente quando razoável; quando não é, isso está documentado.
- [ ] Não mistura mudança destrutiva com mudança aditiva.
- [ ] Não referencia schema/tabela/função que ainda não existe na ordem de aplicação.
- [ ] Não cria objeto Prop4You em pacote base.
- [ ] Não expõe domínio direto no `public` por conveniência.
- [ ] Usa `api.*` para fachada cliente quando aplicável.
- [ ] Usa helpers de `base` em vez de duplicar lifecycle/public ref/audit/realtime sem motivo.
- [ ] Inclui `COMMENT ON` para todos os objetos novos relevantes.

### 7.2 Checklist por tabela

- [ ] Tipo da tabela está claro: entidade, relação, ledger, raw, snapshot, queue, projection ou reference.
- [ ] Colunas lifecycle/public ID/metadata seguem contrato base quando apropriado.
- [ ] FKs representam dependência real; UUID/public refs não escondem dependência semântica.
- [ ] Constraints expressam invariants conhecidas.
- [ ] Índices correspondem a consultas previstas, FKs ou filtros RLS.
- [ ] JSONB tem estratégia: raw/normalized/metadata/DTO/snapshot.
- [ ] Campos gerados/projetados declaram caminho/regra de derivação.
- [ ] Soft delete, versionamento e audit estão decididos, não implícitos.
- [ ] RLS/policies foram planejadas se há tenancy/acesso por usuário/org.

### 7.3 Checklist por função/API

- [ ] Função interna fica no schema de domínio; função client-facing fica em `api`.
- [ ] Nome descreve use case, não detalhe técnico.
- [ ] Valida invariants que não cabem em constraints simples.
- [ ] Registra audit em mutações relevantes.
- [ ] Emite realtime/outbox quando há consumidor downstream.
- [ ] Retorna contrato estável, preferencialmente JSONB documentado para API.
- [ ] Define `security definer` apenas com justificativa e search_path seguro.
- [ ] Tem comentário declarando efeitos colaterais e escopo de uso.

### 7.4 Checklist de comentários

- [ ] Comentário explica semântica e fronteira, não apenas repete o nome.
- [ ] Comentário diferencia raw evidence, canonical truth, projection e API contract.
- [ ] Comentário de payload JSONB declara origem e finalidade.
- [ ] Comentário de função declara se é interna ou fachada.
- [ ] Comentário de policy declara sujeito, escopo e operação.
- [ ] Comentário não contém segredo, URL sensível, token, credencial ou dado pessoal real.
- [ ] Comentário não promete comportamento ainda não implementado.

## 8. Plano de validação em laboratório

A validação futura deve ocorrer contra banco limpo de laboratório, preferencialmente `pg18_ddl_lab`, sem mutar produção, Docker externo ou segredos.

### 8.1 Preparação

1. Confirmar que a stack PG18 local está rodando conforme política do repo.
2. Criar/recriar banco de lab controlado quando o script de proof permitir.
3. Aplicar `database/ddl/base/` com `scripts/apply-ddl-package.sh`.
4. Registrar saída de apply, reapply e estado de `base.ddl_migrations`.

### 8.2 Aplicação do pacote Prop4You

1. Aplicar `database/ddl/projects/prop4you/` em ordem numérica.
2. Reaplicar o pacote para testar idempotência onde declarada.
3. Verificar que checksums de arquivos aplicados não sofreram drift.
4. Confirmar que `pg_cron` segue política multi-produto: product/lab DB não instala `pg_cron` se `cron.database_name` for `postgres`; schedules são feitos via `cron.schedule_in_database(...)` no DB scheduler.

### 8.3 Consultas de catálogo obrigatórias

Executar checks que falhem se faltarem comentários:

```sql
-- Exemplo documental: detectar tabelas sem comentário em schemas Prop4You.
select n.nspname, c.relname
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
left join pg_description d on d.objoid = c.oid and d.objsubid = 0
where n.nspname in ('identity','geography','billing','property','leadfinder','sourcehub','skiptrace','matrix','sales','communication','api')
  and c.relkind in ('r','p','v','m')
  and d.description is null;
```

```sql
-- Exemplo documental: detectar colunas sem comentário em tabelas Prop4You.
select n.nspname, c.relname, a.attname
from pg_attribute a
join pg_class c on c.oid = a.attrelid
join pg_namespace n on n.oid = c.relnamespace
left join pg_description d on d.objoid = c.oid and d.objsubid = a.attnum
where n.nspname in ('identity','geography','billing','property','leadfinder','sourcehub','skiptrace','matrix','sales','communication')
  and c.relkind in ('r','p')
  and a.attnum > 0
  and not a.attisdropped
  and d.description is null;
```

```sql
-- Exemplo documental: listar funções sem comentário em schemas de domínio/API.
select n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
left join pg_description d on d.objoid = p.oid
where n.nspname in ('identity','geography','billing','property','leadfinder','sourcehub','skiptrace','matrix','sales','communication','api','jobs')
  and d.description is null;
```

### 8.4 Smoke funcional mínimo por slice

Cada slice deve ter smoke próprio, sem dados reais sensíveis:

- schemas existem;
- tabelas essenciais aceitam insert sintético mínimo quando permitido;
- constraints rejeitam estado inválido conhecido;
- triggers lifecycle atualizam `updated_at`/`version`;
- public refs são registradas e resolvidas;
- função de domínio principal executa caminho feliz e erro esperado;
- função `api.*` retorna contrato JSONB estável;
- audit/realtime outbox recebe evento quando a função promete evento;
- RLS bloqueia/permite conforme contexto sintético.

### 8.5 Evidência esperada

Para cada execução de lab, persistir artefatos em `.tmp/prop4you-dbcentric/` ou relatório de proof permitido:

```text
apply.out
reapply.out
ddl_status.tsv
missing_comments.tsv
smoke.out
rls.out
api_contract.out
```

Este subagente não criou esses scripts/provas porque o escopo atual é documental e proíbe implementação de DDL de produção.

## 9. Exemplos orientativos de DDL documentado

Os exemplos abaixo são apenas padrões de estilo. Não devem ser copiados como DDL final sem análise de payload/dicionário.

```sql
create schema if not exists sourcehub;

comment on schema sourcehub is
  'Domínio de ingresso, raw lineage, snapshots e publicação de DTO canônico para Prop4You.';

create table sourcehub.raw_record (
  id uuid primary key default uuidv7(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version bigint not null default 1,
  provider_code text not null,
  provider_record_key text,
  provider_payload jsonb not null,
  normalized_payload jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb
);

comment on table sourcehub.raw_record is
  'Registro bruto de ingresso SourceHub/provedor. Preserva evidência original e normalizada para replay, comparação e promoção canônica.';

comment on column sourcehub.raw_record.provider_code is
  'Código estável da origem do payload, como realtor, directskip ou ingest interno; não contém segredo de credencial.';

comment on column sourcehub.raw_record.provider_payload is
  'Payload JSONB original recebido da origem, preservado sem perda semântica para auditoria e reprocessamento.';

comment on column sourcehub.raw_record.normalized_payload is
  'Representação JSONB normalizada para comparação Matrix/SourceHub/LeadFinder; não substitui o payload original.';
```

```sql
create or replace function api.publish_sourcehub_candidate(p_raw_record_id uuid)
returns jsonb
language plpgsql
as $$
begin
  -- Exemplo orientativo apenas.
  return jsonb_build_object('ok', false, 'reason', 'not_implemented_in_documentation_example');
end;
$$;

comment on function api.publish_sourcehub_candidate(uuid) is
  'Exemplo de fachada: solicita publicação/promocão controlada de um raw record SourceHub para fluxo canônico. Contrato documental, não DDL final.';
```

## 10. Gatilhos para não avançar

Não congelar DDL como `stable` se qualquer item abaixo estiver aberto:

- payloads reais/representativos de provedores ainda não foram comparados;
- Matrix dictionary não tem ciclo de revisão/aprovação;
- SourceHub não distingue raw, normalized, snapshot, DTO e canonical promotion;
- Skip Trace cria ou sobrescreve owner/property truth diretamente;
- API expõe tabelas de domínio diretamente sem justificativa;
- comentários não cobrem objetos duráveis e invocáveis;
- RLS/policies estão ausentes para dados tenant-bound;
- lab não prova apply/reapply e comentários de catálogo.

## 11. Saída esperada para Thor/revisor

Este documento deve ser revisado contra T4:

- ordem de extração: definida nas seções 3.1 e 3.2;
- package shape: definido na seção 4;
- SQL comment standard: definido na seção 5;
- comentários orientativos/documentais para tabelas/colunas/funções/triggers/policies/views: seção 5 e exemplos da seção 9;
- mutation policy: seção 6;
- review checklist: seção 7;
- lab validation plan: seção 8;
- sem implementação de DDL de produção: mantido por escopo e exemplos marcados como orientativos.
