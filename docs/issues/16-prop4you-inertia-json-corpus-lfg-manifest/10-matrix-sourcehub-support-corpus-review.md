# 10 — Revisão Matrix / SourceHub / LeadFinder: JSONs de registry, config, testes e suporte para o corpus LFG

Status: concluído
Worker: C
Escopo: `prop4you-inertia` JSON corpus LFG, com foco em Matrix, SourceHub e LeadFinder
Manifests usados:
- `docs/corpus/prop4you/lfg/prop4you-inertia-json-manifest.v1.jsonl`
- `docs/corpus/prop4you/lfg/prop4you-inertia-lfg-corpus-candidates.v1.jsonl`

Nota de privacidade: esta revisão não reproduz valores JSON brutos. As conclusões abaixo usam somente caminhos-família, papéis de arquivo, chaves/categorias em nível estrutural, tipos raiz e contagens agregadas.

## 1. Resumo executivo

A revisão confirma que Matrix, SourceHub e LeadFinder formam um subconjunto de alta relevância para o corpus LFG, mas com papéis diferentes:

1. Matrix registry: evidência primária de mapeamento semântico, contratos, análises, source manifests, schemas compilados e sessões históricas. Deve entrar como corpus LFG com política de ingestão controlada por papel.
2. LeadFinder system JSONs: evidência de suporte canônico. São baseline/artifacts que definem o destino da materialização, não exemplos brutos de provider. Devem ser preservados como referência normativa para envelopes e gates.
3. SourceHub JSONs: mistura de evidência de handoff/canonical DTO, amostras legadas/test fixtures e saídas temporárias de provas. Devem ser ingeridos por família, com separação entre payload bruto, handoff estruturado, audit/report e cache gerado.
4. Tooling/cache/documentação gerada: deve ficar fora da ingestão automática ou entrar apenas como metadata operacional, porque não representa evidência de domínio estável.

## 2. Contagens verificadas

Base completa do manifest:

| Conjunto | Arquivos no manifest | Candidatos LFG | Root type | Soma de path/type pairs em candidates |
|---|---:|---:|---|---:|
| Manifest JSON geral | 13.160 | n/a | misto | n/a |
| Candidate JSONL geral | 3.545 | 3.545 | misto | n/a |
| Matrix system JSON | 316 | 316 | object | 193.284 |
| Matrix registry JSON | 315 | 315 | object | 193.236 |
| LeadFinder system JSON | 9 | 9 | object | 4.259 |
| SourceHub-named JSON | 58 | 58 | object | 11.965 |

Observações:
- Todos os JSONs de Matrix registry revisados aparecem como `lfg_corpus_candidate`.
- Todos os JSONs de LeadFinder system revisados aparecem como `lfg_corpus_candidate`.
- Todos os JSONs SourceHub-named revisados aparecem como `lfg_corpus_candidate`, mas nem todos devem ter a mesma prioridade de ingestão.

## 3. Matrix registry

### 3.1 Famílias de origem

| Família de origem | Arquivos |
|---|---:|
| `backend/src/apps/system/matrix/registry/directskip/...` | 210 |
| `backend/src/apps/system/matrix/registry/reiq/...` | 98 |
| `backend/src/apps/system/matrix/registry/contracts/...` e contexto de registry | 7 |
| Total Matrix registry | 315 |

### 3.2 Papéis de registry

| Papel | Arquivos | Soma de path/type pairs | Decisão corpus |
|---|---:|---:|---|
| analysis / baseline-only | 58 | 161.583 | Corpus LFG forte; evidencia cobertura, alias, drift e snapshot de baseline. |
| analysis / contextual | 58 | 5.893 | Corpus LFG forte; evidencia contexto, workspace, discrepância e análise de campo. |
| analysis / discrepancy | 58 | 733 | Corpus LFG forte; evidencia diferenças entre dataset/provider e expectativas canônicas. |
| contracts | 72 | 2.918 | Suporte canônico e corpus; define shape esperado para sessões, artifacts e snapshots. |
| data/source_manifest/raw data | 60 | 3.720 | Evidência de lineage/ingress; ingestão deve ser controlada e redigida. |
| schema | 7 | 18.354 | Suporte canônico forte; material para validar envelopes/schemas. |
| outros contextos de registry | 2 | 35 | Suporte de configuração semântica; baixa prioridade isolada, útil como metadata. |

### 3.3 Leitura do papel Matrix

Matrix registry deve ser tratado como evidência LFG porque codifica:

- contratos publicados e snapshots efetivos;
- relação provider/list/state com baseline version;
- session identity, artifact kind e public references;
- análise baseline-only, contextual e discrepancy;
- schemas/genomes compilados;
- source manifests e superfícies de origem.

Para o corpus LFG, a distinção essencial é:

- `contracts` e `schema`: suporte canônico/gate de shape.
- `analysis/*`: evidência semântica e material de treinamento/validação para mapping/projection.
- `data/*_source_manifest`: lineage admissível como metadata.
- `data` com payload provider: evidência bruta sensível; não deve ser ingerida sem redaction e sem envelope de provenance.
- context files: suporte de configuração, não amostra de verdade materializada.

## 4. LeadFinder system JSON

### 4.1 Famílias e papéis

| Família | Arquivos | Soma de path/type pairs | Decisão corpus |
|---|---:|---:|---|
| `backend/src/apps/system/lead_finder/baselines/...` | 8 | 2.857 | Suporte canônico obrigatório. |
| `backend/src/apps/system/lead_finder/artifacts/...` | 1 | 1.402 | Artifact de baseline/genome; suporte canônico obrigatório. |
| Total LeadFinder system | 9 | 4.259 | Não é payload bruto; é contrato de destino. |

### 4.2 Leitura do papel LeadFinder

LeadFinder é o dono da materialização canônica e do inventário pesquisável. Portanto, seus JSONs não devem ser tratados como exemplos de ingressão provider, mas como:

- baseline do grafo canônico;
- catálogo de famílias/campos/micro-baselines;
- referência de versão/contrato publicado;
- destino das projeções que SourceHub entrega e que Matrix mapeia.

Em termos de ingestão, esses arquivos devem ser carregados antes dos samples Matrix/SourceHub para permitir validação de projection gates: o corpus provider só é promovível se puder ser explicado contra o baseline LeadFinder ou marcado como growth suggestion/HITL.

## 5. SourceHub JSON

### 5.1 Famílias de origem

| Família SourceHub | Arquivos | Decisão corpus |
|---|---:|---|
| `.tmp/.../outputs` e provas runtime | 20 | Evidência útil, mas efêmera; ingerir apenas se associada a issue/proof e marcada como runtime proof. |
| `_projeto-antigo/backend/docs/sourcehub/audit_.../raw_samples` | 26 | Evidência legada/test fixture; alta utilidade para shapes provider, com redaction obrigatória. |
| `_projeto-antigo/backend/docs/sourcehub/payload_samples` | 10 | Evidência legada/test fixture; útil para comparação de envelopes, com redaction obrigatória. |
| `_projeto-antigo/backend/src/system/sourcehub/audits` | 1 | Audit/report; suporte de lineage e cobertura, não sample primário. |
| `frontends/docusaurus/.docusaurus/...` | 1 | Tooling/cache gerado; excluir da ingestão de domínio. |
| Total SourceHub-named | 58 | Mistura: corpus + suporte + tooling. |

### 5.2 Papéis observados

A estrutura agregada indica três formas principais de SourceHub JSON:

1. Handoff/canonical DTO ou pre-SourceHub DTO:
   - contém chaves estruturais de DTO, schema/versioning, producer/consumer stage, queue e mapping metadata;
   - deve ser corpus LFG forte quando ligado a Matrix/LeadFinder;
   - deve validar envelope canônico antes de materialização.

2. Raw samples / payload samples:
   - raiz object com seções de resposta, erro/status e dados provider;
   - evidência importante para mapeamento e regressão;
   - risco maior de PII/domínio sensível; ingestão automatizada deve armazenar apenas shape, fingerprints e amostras redigidas.

3. Audit/proof/cache:
   - reports de auditoria ou outputs de execução comprovam pipeline e gates;
   - caches de docs gerados não devem contaminar o corpus de domínio.

## 6. Evidence vs support vs tooling

| Grupo | Evidência LFG | Suporte de projeto/canônico | Tooling/cache | Recomendação |
|---|---:|---:|---:|---|
| Matrix registry | Alta | Alta | Baixa | Ingerir por role; separar contracts/schema/analysis/data. |
| LeadFinder system JSON | Média | Muito alta | Baixa | Ingerir como baseline normativo, não como sample provider. |
| SourceHub handoff/proofs | Alta | Média | Média | Ingerir quando houver provenance de proof/issue; marcar runtime/ephemeral. |
| SourceHub legacy samples | Alta | Média | Baixa | Ingerir shape e redacted sample; nunca promover valores brutos. |
| Docusaurus generated JSON | Baixa | Baixa | Alta | Excluir da ingestão LFG; manter somente se a pipeline precisar auditar cache gerado. |

## 7. Como estes JSONs suportam envelopes canônicos e projection gates

### 7.1 Envelope canônico

Os conjuntos revisados dão cobertura para um envelope canônico com, no mínimo, estas categorias estruturais:

- origem/provider/list/state;
- versão de baseline e contrato publicado;
- artifact kind e session/public identity;
- lineage/source manifest;
- mapping/versioning metadata;
- handoff DTO ou pre-SourceHub DTO;
- análise semântica e discrepância;
- status/erros de ingestão sem valores brutos;
- classificação de dado bruto vs dado canônico vs dado proposto.

Matrix contribui os contratos, schemas e análises; SourceHub contribui ingress/lineage/framing/handoff; LeadFinder contribui baseline de destino e families/campos materializáveis.

### 7.2 Projection gates

Os projection gates futuros devem usar estas regras:

1. Gate de shape: validar root type, top-level key families e path/type pairs contra contracts/schema Matrix e baseline LeadFinder.
2. Gate de provenance: exigir provider/list/state/session/source manifest ou metadata equivalente antes de aceitar evidence JSON.
3. Gate de role: classificar arquivo como `contract`, `schema`, `analysis`, `source_manifest`, `raw_sample`, `handoff`, `audit`, `runtime_proof` ou `generated_cache`.
4. Gate de promoção: SourceHub handoff só vira candidato de materialização LeadFinder quando está ligado a baseline version e mapping version; raw sample isolado fica em staging.
5. Gate de privacidade: payload bruto e legacy samples devem gerar somente shapes, fingerprints, counts e amostras redigidas para o corpus público/operacional.
6. Gate de drift/growth: campos que aparecem em Matrix analysis/discrepancy e não cabem no baseline LeadFinder devem ser marcados como growth suggestions, não promovidos automaticamente.

## 8. Recomendações para ingestão automatizada futura

1. Implementar classificação determinística por path role antes de ler conteúdo profundo:
   - `matrix/registry/contracts` => canonical support/contract;
   - `matrix/registry/schema` => canonical support/schema;
   - `matrix/registry/analysis/*` => semantic evidence;
   - `matrix/registry/**/data/*_source_manifest` => lineage support;
   - `matrix/registry/**/data/*` sem source_manifest => raw evidence, restricted;
   - `lead_finder/baselines` e `lead_finder/artifacts` => LF baseline support;
   - `docs/sourcehub/**/raw_samples` e `payload_samples` => legacy provider evidence, restricted;
   - `.tmp/**sourcehub**` => runtime proof, ephemeral;
   - `.docusaurus` => generated cache, exclude.

2. Persistir manifest enriquecido com os seguintes campos derivados:
   - `source_family`, `registry_role`, `evidence_role`, `privacy_tier`, `ingestion_priority`, `projection_gate_hint`, `canonical_owner`.

3. Não usar `lfg_corpus_candidate` sozinho como sinal de ingestão final. Ele deve ser refinado por papel:
   - corpus-evidence;
   - canonical-support;
   - project-support;
   - restricted-raw;
   - generated-tooling-exclude.

4. Para SourceHub legado e Matrix `data`, armazenar primeiro path/type pairs, root type, top-level key families e hashes; valores brutos somente em ambiente restrito.

5. Rodar validação cruzada LF baseline -> Matrix schema/contracts -> SourceHub handoff, produzindo relatório de:
   - campos cobertos;
   - campos órfãos;
   - aliases/discrepâncias;
   - campos sensíveis;
   - sugestões de crescimento pendentes de HITL.

6. Excluir caches gerados e package/tooling JSON do corpus de domínio, mesmo quando o manifest os marcar como structured JSON.

## 9. Decisão final por área

- Matrix registry: incluir como corpus LFG e suporte canônico, com ingestão granular por role.
- LeadFinder baseline/artifacts: incluir como suporte canônico obrigatório para gates e projeção; não contar como provider sample.
- SourceHub handoffs/proofs: incluir como evidence quando vinculados a runtime proof/issue; marcar como ephemeral quando sob `.tmp`.
- SourceHub legacy raw/payload samples: incluir como restricted evidence; redaction obrigatória e preferência por shape-only no corpus inicial.
- Generated documentation/cache: excluir da ingestão automática LFG.

## 10. Comandos de verificação executados

Foram executadas leituras e agregações locais sobre os manifests JSONL existentes. As saídas usadas para esta revisão continham apenas contagens, paths, root types, context tags, classificações, top-level key names e path/type pair counts; nenhum valor JSON bruto foi reproduzido neste relatório.
