# 10 — Arquitetura corrigida: ciclo LeadFinder <-> Matrix <-> SourceHub

Status: delivered by Worker C
Date: 2026-06-16
Scope: análise documental/DDL local; sem chamadas de provider/runtime/prod; sem dump de payload/PII.

## [CIRCULAR_DEPENDENCY] Correção capturada

A correção de Karval muda o centro de gravidade do desenho:

```text
LeadFinder group
  -> gera / materializa o dicionário canônico e o grafo canônico
  -> expõe versão aprovada do dicionário para uso de mapeamento

Matrix
  -> consome o dicionário canônico vindo do LeadFinder group
  -> consome dados raw/novos como evidência de uma sessão de mapeamento
  -> produz um DTO de transformação / artefato de mapping, não a verdade final

SourceHub
  -> consome DTO de provider + raw evidence + mapping aprovado
  -> traduz o payload para JSON/DTO consumível pelo LeadFinder group
  -> preserva raw, lineage, status e publicação

LeadFinder group
  -> consome o JSON/DTO traduzido
  -> materializa/atualiza entidades canônicas
  -> detecta lacunas/novos conceitos
  -> evolui o dicionário canônico, reiniciando o ciclo de revisão quando necessário
```

Isto é uma dependência circular por desenho, mas deve ser um ciclo governado por versões, não um acoplamento direto de tabela/runtime. A quebra correta é:

- LeadFinder é o dono da semântica canônica e do grafo final.
- Matrix é um revisor/compilador de mapeamento que roda sobre uma versão do dicionário e evidência raw.
- SourceHub é o tradutor/publicador com lineage; não define semântica final.
- Provider registry é catálogo auxiliar; não deve puxar a arquitetura para provider-first.

## Comparação contra o DDL atual do issue 02

### Pontos alinhados

O DDL atual já evita alguns erros graves:

- `prop4you_sourcehub.raw_records` preserva raw JSONB como evidência e declara que não é canonical property/owner/lead.
- `source_lineage_edges` separa lineage de verdade canônica.
- `enrichment_requests` modela intenção/queue sem provider calls.
- `prop4you_matrix.provider_path_mappings` mapeia paths para campos canônicos sem executar provider code.
- READMEs e reviews dizem que o DDL é experimental/non-final e que LeadFinder materialization é futuro.

### Desalinhamentos importantes

O DDL atual ainda carrega viés provider/Matrix-first:

1. `prop4you_matrix.canonical_families` e `canonical_fields` parecem ser o nascimento do dicionário canônico dentro da Matrix.
2. O `depends-on` da Matrix aponta para SourceHub, mas não para um pacote LeadFinder dictionary/grafo.
3. As famílias seedadas por `experimental_ddl` (`property_identity`, `owner_identity`, etc.) são plausíveis, porém não provêm de uma versão LeadFinder-owned.
4. `mapping_versions` é provider-corpus oriented (`reiq.provider_corpus.v0`, etc.), antes de existir uma versão explícita do dicionário canônico do LeadFinder que esses mappings implementam.
5. SourceHub tem status `leadfinder_publication_status`, mas ainda não tem contrato/tabela explícita de publicação traduzida para LeadFinder-consumable JSON/DTO.
6. LeadFinder ainda é apenas README skeleton; não há DDL mínimo que estabeleça o canonical generator antes de Matrix/SourceHub avançarem.

Conclusão: como prova experimental de raw/corpus/mapping gate, o issue 02 é aceitável. Como direção de próxima implementação, ele não deve ser promovido sem inserir LeadFinder dictionary/grafo como origem canônica.

## [LEADFINDER_CANONICAL_GENERATOR] Papel correto do LeadFinder group

LeadFinder group deve ser modelado como container de geração de leads/oportunidades e dono do canonical graph. Ele deve produzir pelo menos:

- versões de dicionário canônico (`dictionary_version`, status, validade, lineage de aprovação);
- famílias/campos/conceitos canônicos nascidos do uso final do LeadFinder;
- entidades/fatos canônicos materializados ou candidatos: property candidate, owner candidate, ownership/contact evidence, situation fact, lead/opportunity, score/intelligence, source/evidence links;
- lacunas canônicas (`canonical_gap` / growth pressure) que pedem revisão Matrix e/ou novo SourceHub enrichment;
- contrato de entrada: quais DTOs traduzidos podem ser consumidos, com versão de dicionário e mapping.

Regra: Matrix pode armazenar uma cópia operacional/read-model do dicionário para revisão, mas a autoridade de criação/evolução vem do LeadFinder group.

## [MATRIX_ONCE_DTO] Papel correto da Matrix

Matrix deve operar como etapa de compilação/revisão, não como dono permanente da verdade:

```text
Input:
  - LeadFinder canonical dictionary version N
  - SourceHub raw/new evidence pointers
  - provider/internal path observations

Process:
  - extrair paths/tipos sem vazar valores sensíveis
  - revisar correspondência path -> conceito canônico
  - registrar conflito/lacuna quando o dicionário não cobre o dado
  - gerar transformação DTO / mapping artifact versionado

Output:
  - Matrix transformation artifact aprovado/rejeitado
  - DTO schema/shape para SourceHub translator
  - gap signals para LeadFinder evoluir o dicionário quando necessário
```

"Once" aqui significa uma execução/sessão versionada contra uma versão congelada do dicionário e um conjunto de evidências, não um pipeline que mantém Matrix como source of truth. Ao final da sessão, o produto durável da Matrix é o artefato de transformação/review, não entidade canônica.

## [SOURCEHUB_TRANSLATOR] Papel correto do SourceHub

SourceHub deve ter duas camadas distintas:

1. Ingress/lineage/raw evidence: já representada por `raw_records`, `corpus_samples`, `source_lineage_edges`.
2. Translation/publication: ainda faltante no DDL atual.

A camada faltante deve consumir:

- raw record(s);
- provider DTO/class metadata;
- Matrix transformation artifact aprovado;
- LeadFinder dictionary version alvo.

E produzir:

- JSON/DTO consumível pelo LeadFinder group;
- status de publicação (`candidate`, `ready`, `published`, `rejected`, `superseded`);
- checksums/versões;
- lineage raw -> translated DTO -> LeadFinder materialization result;
- erro/gap sem chamar provider diretamente.

SourceHub traduz e publica; não decide que um owner/property/lead é verdadeiro.

## [CURRENT_STEP_RISK] Risco de repetir o erro Django

Risco atual: MÉDIO-ALTO se o próximo passo continuar adicionando DDL a partir de provider/sourcehub/matrix antes de um esqueleto LeadFinder canonical generator.

Por quê:

- O erro Django foi deixar apps/modelos/sistemas auxiliares moldarem a verdade de negócio antes de explicitar o grafo canônico.
- O DDL atual ainda cria `canonical_*` dentro de Matrix, com seeds experimentais, antes de existir LeadFinder-owned dictionary.
- Se a próxima DDL congelar `canonical_fields`, provider path mappings ou SourceHub publication semantics como verdade, a Matrix vira novo "Django model layer" e SourceHub vira novo "provider-first pipeline".
- O risco não é o raw corpus existir primeiro; o risco é promover estruturas de review para canonical truth.

Mitigação imediata:

- Congelar o issue 02 como laboratório experimental/non-final.
- Não adicionar final property/owner/lead DDL derivado de paths Matrix.
- Antes de ampliar Matrix, criar o mínimo de LeadFinder canonical dictionary/gap/materialization contract.
- Renomear mentalmente/semanticamente `matrix.canonical_*` como mirror/candidate/review dictionary se permanecer em Matrix; autoridade deve apontar para LeadFinder dictionary version.

## Pipeline corrigido com gates

```text
G0 — LeadFinder canonical seed gate
  LeadFinder define dictionary_version N e conceitos mínimos necessários para gerar leads/oportunidades.
  Saída: dicionário canônico versionado e aprovado/experimental.

G1 — SourceHub raw corpus gate
  SourceHub registra raw_records/corpus_samples/lineage sem promoção canônica.
  Saída: evidência privada/revisável, sem provider calls e sem fixture commitada.

G2 — Matrix mapping session gate
  Matrix recebe dictionary_version N + raw pointers.
  Saída: transformation artifact / DTO mapping versionado, com gaps/conflitos.

G3 — SourceHub translator gate
  SourceHub aplica mapping aprovado a raw/provider DTO e gera translated DTO JSON para LeadFinder.
  Saída: publication candidate com lineage/checksum/status.

G4 — LeadFinder materialization gate
  LeadFinder valida translated DTO contra dictionary_version N, materializa fatos/entidades/leads ou rejeita.
  Saída: canonical facts/leads + materialization result.

G5 — Dictionary evolution gate
  Lacunas, conflitos e novos padrões geram LeadFinder canonical gap/growth signal.
  LeadFinder aprova dictionary_version N+1; Matrix remapeia apenas o delta necessário.
```

Gates de bloqueio:

- Sem `dictionary_version` LeadFinder: Matrix mapping não pode ser aprovado como canônico.
- Sem Matrix artifact aprovado: SourceHub não pode publicar DTO como LeadFinder-ready.
- Sem SourceHub lineage/checksum/status: LeadFinder não materializa fato canônico.
- Sem LeadFinder materialization result: SourceHub publication não deve ser marcada `published` final.
- Sem gap/evolution approval: novos campos ficam `candidate/review_required`, não viram tabela final.

## [NEXT_DDL_DIRECTION] Implicações para a próxima DDL

Ordem recomendada antes de qualquer promoção final:

1. Criar `database/ddl/projects/prop4you/leadfinder/0001_canonical_dictionary.sql` ou equivalente mínimo.
   - `canonical_dictionary_versions`
   - `canonical_concepts` / `canonical_families` / `canonical_fields` owned by LeadFinder
   - `canonical_gaps` / `growth_pressure_signals`
   - comments + public refs/status/versioning

2. Ajustar Matrix para depender conceitualmente de LeadFinder dictionary.
   - Adicionar `leadfinder_dictionary_version_id` em mapping/session/artifact.
   - Tratar `matrix.canonical_*` como cache/review mirror ou migrar autoridade para LeadFinder.
   - Criar tabela de `transformation_artifacts` / `mapping_sessions` se o DDL atual for insuficiente.

3. Adicionar SourceHub translation/publication DDL.
   - `translated_dto_publications` ou `leadfinder_publication_candidates`
   - FK/pointer para raw_record, Matrix transformation artifact, LeadFinder dictionary version.
   - JSONB DTO de saída, checksum, status, rejection/gap metadata.

4. Só depois criar materialização LeadFinder de entidade/fato/lead.
   - As primeiras tabelas devem refletir o grafo de geração de leads, não provider payload shape.
   - Provider/raw lineage deve entrar por links/evidence, não por colunas copiadas diretamente.

5. Revisar nomes do DDL atual antes de estabilizar.
   - `matrix.canonical_families/fields` pode induzir erro de ownership.
   - Preferir `matrix.dictionary_field_refs`, `matrix.field_review_candidates` ou mover canonical source para LeadFinder.

Decisão final de Worker C: o passo atual só é seguro se permanecer como laboratório experimental de raw/mapping. O próximo passo seguro é LeadFinder canonical generator mínimo, seguido por Matrix artifact linking e SourceHub translator/publication. Continuar expandindo Matrix/SourceHub sem esse pivô repete o erro de deixar o mecanismo auxiliar definir a verdade de negócio.
