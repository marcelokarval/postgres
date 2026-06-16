# Inventário seguro do corpus REIQ bruto para ingestão JSONB lab

Escopo: inventário local, somente leitura, do corpus em `prop4you-inertia/backend/src/apps/system/matrix/registry/reiq`, com foco em `loan_modification/fl/{data,contracts,analysis}`.

[NO_PROVIDER_CALLS]
Nenhuma chamada a provedor externo, API remota, LLM provider ou serviço de produção foi executada. A análise foi feita localmente por varredura de arquivos e parse JSON.

[NO_PII_DUMP]
Este relatório não despeja valores brutos, nomes, endereços, telefones, documentos, identificadores pessoais, payloads completos ou segredos. Identificadores de sessão foram agregados ou pseudonimizados por hash curto apenas para contagem operacional.

## Método seguro

- Varredura local com Python sobre arquivos `.json`.
- Parse JSON apenas para forma estrutural: objeto/array, contagens, tamanho em bytes, presença por classe de artefato.
- Hashes usados somente como resumo de integridade/agregação; não há conteúdo bruto no relatório.
- Campos do payload datado foram classificados por famílias sem expor valores.

## Raiz analisada

- Corpus REIQ local: `apps/system/matrix/registry/reiq`
- Foco REIQ FL loan modification: `apps/system/matrix/registry/reiq/loan_modification/fl`

[REIQ_RAW_COUNT]

Resumo global do corpus REIQ local:

| Escopo | Arquivos totais | JSON válidos | Observação |
| --- | ---: | ---: | --- |
| `registry/reiq` | 98 | 98 | Todos os arquivos encontrados são JSON parseáveis |
| `loan_modification/fl` | 97 | 97 | Foco principal do inventário |
| Fora de `fl` | 1 | 1 | `loan_modification/context.json` no nível da família |

Contagem por família/estado no corpus REIQ:

| Família/estado | JSON |
| --- | ---: |
| `loan_modification/fl` | 97 |
| `loan_modification/context.json` | 1 |

Contagem por diretório/classe no foco `loan_modification/fl`:

| Classe | JSON | Bytes totais | Min bytes | Max bytes | Shape JSON | Hash agregado curto |
| --- | ---: | ---: | ---: | ---: | --- | --- |
| `data` manifests de sessão | 19 | 98.182 | 4.876 | 5.195 | 19 objetos | `aadc512196eabd8d` |
| `data/date_payload` | 1 | 1.677 | 1.677 | 1.677 | 1 objeto | `5a8bf6dd697667c7` |
| `contracts` | 19 | 106.451 | 1.115 | 7.692 | 19 objetos | `89a7c7b4ebf0399f` |
| `analysis/baseline-only` | 19 | 5.933.549 | 3.143 | 329.467 | 19 objetos | `107103d11241d9e6` |
| `analysis/contextual` | 19 | 555.322 | 5.986 | 30.530 | 19 objetos | `83b92d4a64419636` |
| `analysis/discrepancy` | 19 | 329.259 | 3 | 18.292 | 19 objetos | `f88891361b1308a1` |
| `context.json` local | 1 | 2.694 | 2.694 | 2.694 | 1 objeto | `bf4295b506e9e8f5` |

Resumo agregado do foco `loan_modification/fl`:

| Métrica | Valor |
| --- | ---: |
| JSON no foco | 97 |
| Bytes totais | 7.027.134 |
| Menor arquivo | 3 bytes |
| Maior arquivo | 329.467 bytes |
| Média por arquivo | 72.444,7 bytes |
| Hash agregado curto do conjunto | `6d239b1e18a54f46` |
| Erros de parse JSON | 0 |

## Contagens por data

| Data derivada de diretório | JSON | Classe |
| --- | ---: | --- |
| 2025-11-27 | 1 | payload bruto datado em `data/<data>/...json` |

O payload datado é um objeto JSON com 51 chaves de topo. Os nomes e valores dos campos não foram despejados neste relatório por segurança.

## Contagens por sessão

Foram detectadas 19 sessões. Cada sessão possui exatamente 5 artefatos associados no foco:

- 1 manifesto em `data`
- 1 contrato em `contracts`
- 1 análise `baseline-only`
- 1 análise `contextual`
- 1 análise `discrepancy`

Distribuição: `19 sessões x 5 artefatos = 95 artefatos de sessão`.

Hashes curtos pseudonimizados de sessão e contagem por classe:

| Sessão hash12 | data | contracts | baseline-only | contextual | discrepancy | Total |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `03045f19d81a` | 1 | 1 | 1 | 1 | 1 | 5 |
| `22d1ddb512e4` | 1 | 1 | 1 | 1 | 1 | 5 |
| `250b993e966a` | 1 | 1 | 1 | 1 | 1 | 5 |
| `3407fc59d959` | 1 | 1 | 1 | 1 | 1 | 5 |
| `4d51e6026f31` | 1 | 1 | 1 | 1 | 1 | 5 |
| `4de643c1d5f0` | 1 | 1 | 1 | 1 | 1 | 5 |
| `67cf0ccd09cd` | 1 | 1 | 1 | 1 | 1 | 5 |
| `798c6f334f0d` | 1 | 1 | 1 | 1 | 1 | 5 |
| `7adc9602162f` | 1 | 1 | 1 | 1 | 1 | 5 |
| `7e3ed4f70fe4` | 1 | 1 | 1 | 1 | 1 | 5 |
| `886e16483a85` | 1 | 1 | 1 | 1 | 1 | 5 |
| `900a701121c0` | 1 | 1 | 1 | 1 | 1 | 5 |
| `a5c679ed948b` | 1 | 1 | 1 | 1 | 1 | 5 |
| `b6973b75da0a` | 1 | 1 | 1 | 1 | 1 | 5 |
| `c49303512905` | 1 | 1 | 1 | 1 | 1 | 5 |
| `d650ecce2d5e` | 1 | 1 | 1 | 1 | 1 | 5 |
| `d65d10448c1d` | 1 | 1 | 1 | 1 | 1 | 5 |
| `eca556c76baa` | 1 | 1 | 1 | 1 | 1 | 5 |
| `f83e37209cff` | 1 | 1 | 1 | 1 | 1 | 5 |

## Shapes JSON de topo

| Escopo | Objetos | Arrays | Outros | Parse errors |
| --- | ---: | ---: | ---: | ---: |
| `registry/reiq` | 98 | 0 | 0 | 0 |
| `loan_modification/fl` | 97 | 0 | 0 | 0 |
| `loan_modification/fl/data` manifests | 19 | 0 | 0 | 0 |
| `loan_modification/fl/data/date_payload` | 1 | 0 | 0 | 0 |
| `loan_modification/fl/contracts` | 19 | 0 | 0 | 0 |
| `loan_modification/fl/analysis/*` | 57 | 0 | 0 | 0 |
| `loan_modification/fl/context.json` | 1 | 0 | 0 | 0 |

[RAW_CLASSIFICATION]

Categorias candidatas identificadas, sem valores brutos:

1. Manifestos de fonte/sessão (`data/session_*_source_manifest.json`)
   - Artefatos de linhagem e superfície de fonte.
   - Bons candidatos para ingestão JSONB como `artifact_kind = source_manifest` ou classe equivalente.
   - Baixo risco operacional se permanecerem em tabela lab com acesso restrito; ainda podem conter metadados de sessão e fonte.

2. Payload bruto datado (`data/<YYYY-MM-DD>/...json`)
   - Registro bruto pontual do provedor/lista.
   - Contém famílias de dados sensíveis: metadados internos/processuais, partes/pessoas, propriedade/endereço, características do imóvel, instituição/financiamento e estimativas financeiras.
   - Deve ser ingerido como JSONB bruto em área lab restrita, sem projeções públicas e sem logs de payload.

3. Contratos de sessão (`contracts/session_*.json`)
   - Snapshots/refs de contrato semântico entre sessão, baseline e contratos publicados.
   - Candidatos para tabela de `transformation_artifacts`/`mapping_artifacts`, com JSONB preservado e colunas derivadas mínimas.

4. Análise baseline-only (`analysis/baseline-only/session_*.json`)
   - Artefatos grandes de snapshots de dicionário, cobertura, drift e evidências semânticas.
   - Maior volume do corpus; requer JSONB com TOAST normal, checksum e ingestão idempotente.

5. Análise contextual (`analysis/contextual/session_*.json`)
   - Artefatos de contexto Matrix/workspace e análise de campos.
   - Úteis para reconstruir decisões de mapeamento sem depender de runtime Django.

6. Análise discrepancy (`analysis/discrepancy/session_*.json`)
   - Artefatos de perfil/discrepâncias de dataset e padrões entre campos.
   - Há pelo menos um arquivo mínimo de 3 bytes, provavelmente objeto vazio; tratar como artefato válido, não como erro.

7. Contexto local (`context.json`)
   - Regras/assunções de contexto da família/estado.
   - Deve ser ingerido como artefato de contexto separado ou como parent artifact ligado a família/lista/estado.

## Recomendações de ingestão JSONB lab

[INGESTION_RECOMMENDATION]

1. Ingestão raw-first, sem tradução inicial
   - Criar/usar uma tabela lab de artefatos REIQ brutos com `raw_payload jsonb not null`.
   - Preservar o arquivo inteiro como JSONB e não decompor PII em colunas nesta fase.
   - Derivar somente metadados seguros: provider/list_type/state, artifact_class, source_relpath, source_date quando existir, byte_size, content_sha256, ingested_at.

2. Idempotência e lineage
   - Chave natural recomendada para lab: `(source_relpath, content_sha256)` ou `(provider, list_type, state, artifact_class, session_hash/source_date, content_sha256)`.
   - Guardar hash completo no banco, mas logs/provas devem usar hash curto.
   - Não usar nome bruto de sessão como identificador público; usar hash/pseudônimo interno quando necessário em relatórios.

3. Separar payload bruto de artefatos Matrix
   - `data/date_payload` deve ser classificado como raw provider record.
   - `data/session_*_source_manifest`, `contracts` e `analysis/*` devem ser classificados como Matrix/sourcehub artifacts.
   - O DDL deve permitir ambos no mesmo envelope JSONB, mas com `artifact_class`/`artifact_kind` explícitos.

4. Segurança e RLS
   - Tabelas lab devem ficar em schema não exposto ao PostgREST público.
   - Sem grants para `anon`/cliente.
   - Sem views públicas sobre `raw_payload`.
   - Qualquer projeção posterior deve mascarar ou excluir campos pessoais/endereço/financeiros.

5. Validação de ingestão
   - Validar parse JSON e contagem de linhas esperada: 98 no corpus REIQ total ou 97 no foco FL, conforme escopo do script.
   - Validar `object` como shape esperado em todos os arquivos atuais.
   - Validar soma por classe: manifests 19, contracts 19, analyses 57, payload datado 1, context local 1 no foco FL.

6. Performance/armazenamento
   - O maior custo atual está em `analysis/baseline-only` (~5,93 MB de 7,03 MB do foco).
   - JSONB puro é aceitável para lab; adiar índices GIN até existir consulta real.
   - Inicialmente indexar somente metadados escalares seguros e checksum.

[GAPS]

- O corpus local REIQ contém apenas `loan_modification/fl` mais um `context.json`; não há, nesta árvore `registry/reiq`, dados brutos locais para outros estados/listas.
- Existe somente 1 payload bruto datado em `data/<YYYY-MM-DD>`; os demais 19 itens em `data` são manifestos de sessão, não registros provider brutos.
- Não foi validada correspondência semântica contra banco de dados ou migrações em execução; este inventário é filesystem-only.
- Não foi feita leitura/dump de valores internos do payload, por desenho de segurança.
- Um arquivo `analysis/discrepancy` tem 3 bytes e parseia como objeto JSON; recomendação é ingerir como artefato válido e marcar tamanho mínimo para revisão posterior, não falhar a carga.
- Se o script de ingestão T5 mirar somente `data/**/*.json`, ele perderá contratos/análises; se mirar todo `loan_modification/fl/**/*.json`, ele deve classificar corretamente `context.json`, manifests, payload datado, contracts e analysis.

## Checklist para T5

- [ ] Escopo explícito: corpus REIQ total (98) ou foco FL (97).
- [ ] Sem logs de `raw_payload`.
- [ ] Contagens esperadas parametrizadas por classe.
- [ ] `content_sha256` calculado antes de inserir.
- [ ] Insert idempotente por path+hash.
- [ ] Teste/prova mostra somente contagens, shapes, tamanhos e hashes curtos.
