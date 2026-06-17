# Review — temporalidade e modelagem do gap bridge + quality report

Status: delivered for Thor review.

## Escopo deste review

Este documento registra a separação temporal do slice `07-prop4you-leadfinder-gap-bridge-quality-report` e o limite de modelagem atual.

A decisão central é: neste momento estamos modelando evidência, lacunas e contratos de revisão. Os filtros LeadFinder entram como pressão de demanda para orientar quais campos/sinais precisam existir de forma canônica, mas não estamos implementando runtime LeadFinder Group/LFG, materialização final de leads, nem DTO público de SourceHub.

Guardrails mantidos neste review:

- sem código de aplicação;
- sem chamadas a provider/API;
- sem payloads ou valores raw;
- sem promoção automática para runtime operacional;
- sem colapsar Matrix, SourceHub e LeadFinder em uma única fase.

## Linha temporal canônica

```text
T0 Raw capture / observação bruta
  -> T1 Extraction / modeling evidence
    -> T2 LeadFinder gap/proposal bridge
      -> T3 Matrix quality_report separado
        -> T4 SourceHub DTO publication later
          -> T5 LeadFinder materialization later
```

Cada fase pode referenciar evidência da anterior, mas não deve assumir responsabilidades da próxima.

## T0 — Raw capture / observação bruta

T0 é a fase em que SourceHub/ingress preserva o fato bruto recebido/observado, sua origem e sua linhagem.

Responsabilidade:

- guardar o corpus raw e metadados de origem;
- preservar lineage, provider, classe de payload e janela de captura;
- manter payload bruto fora da superfície semântica/operacional;
- permitir auditoria posterior sem transformar observação em verdade canônica.

O que T0 não faz neste slice:

- não define campos canônicos LeadFinder;
- não decide se um path vira campo novo;
- não gera relatório de qualidade Matrix;
- não materializa leads ou grupos de leads;
- não publica DTO SourceHub traduzido.

## T1 — Extraction / modeling evidence

T1 transforma raw observado em evidência segura para modelagem: paths, tipos, contagens, frequência, presença por record e metadados agregados.

Responsabilidade:

- extrair evidência path/type/count sem expor valores escalares brutos;
- fornecer insumo de revisão para Matrix e LeadFinder;
- apoiar análise de cobertura, ausência e estabilidade estrutural;
- permitir comparação entre pressão de filtros e disponibilidade real de caminhos observados.

T1 é evidência, não semântica final. Um path frequente ainda não é campo canônico. Um path ausente ainda não é necessariamente gap de produto. A interpretação vem depois, em T2/T3.

## T2 — LeadFinder gap/proposal bridge

T2 é a ponte LeadFinder-owned entre evidência extraída e necessidade de modelagem.

Responsabilidade:

- registrar lacunas, candidatos e propostas a partir da evidência T1;
- suportar tanto match com `canonical_field_id` existente quanto proposta de novas chaves de família/campo quando não houver campo canônico;
- registrar a pressão vinda dos filtros LeadFinder como motivação de modelagem;
- manter fase, status e rastreabilidade explícitos para revisão humana/posterior.

Importante: T2 ainda não é runtime LeadFinder. Ele não deve criar tabela final de busca, ranking, listas operacionais, enriquecimento de proprietário, filas ou materializações de LFG. Ele só organiza a lacuna/proposta que pode levar a esses artefatos em uma fase posterior.

## T3 — Matrix quality_report separado

T3 é artifact/review da Matrix, não coluna embutida no bridge LeadFinder.

Responsabilidade:

- avaliar qualidade de evidência, cobertura, riscos semânticos e readiness de mapeamento;
- produzir um artifact separado `quality_report` ligado a evidência/revisão;
- preservar a Matrix como fronteira de significado, mapeamento e qualidade;
- evitar que o bridge LeadFinder vire o dono do julgamento semântico completo.

A separação T2/T3 é intencional:

- LeadFinder declara demanda e lacuna para o produto de busca/leads;
- Matrix avalia qualidade semântica e confiabilidade do mapeamento;
- SourceHub continua dono de ingress/linhagem/raw;
- nenhuma fase precisa copiar payload bruto para provar sua decisão.

## T4 — SourceHub DTO publication later

T4 é uma fase posterior, fora do escopo atual.

Responsabilidade futura:

- publicar DTO traduzido/normalizado a partir de raw + mapeamentos aprovados;
- expor contratos de integração derivados de decisões revisadas;
- servir consumidores sem forçá-los a conhecer payload raw de provider.

Neste slice, T4 deve permanecer como destino futuro. A existência de gap/proposal ou quality_report não autoriza publicação automática de DTO.

## T5 — LeadFinder materialization later

T5 é a materialização operacional LeadFinder: estruturas finais para busca, filtros, mapa, score, listas, presets, owner/contact views e fluxos de uso.

Responsabilidade futura:

- materializar dados canônicos e índices para filtros LeadFinder;
- sustentar consultas de mapa/list/detail e estados operacionais;
- aplicar ranking/classificação/score quando o modelo estiver aprovado;
- conectar workspace/listas/tags/presets sem misturar raw provider payload.

Neste slice, T5 é explicitamente não-goal. O bridge não deve ser usado como tabela final de runtime, e o quality_report não deve ser confundido com DTO ou materialização.

## Como os filtros LeadFinder entram agora

Os filtros LeadFinder funcionam como pressão de modelagem, não como runtime a implementar.

Eles indicam que o modelo precisará responder a famílias de necessidade como:

- geografia e área;
- tipo e atributos físicos de imóvel;
- situações/lead types ativos;
- occupancy e ownership;
- valuation/equity/listing/mortgage ranges;
- owner/contact availability/status;
- score, classificação e estados operacionais;
- busca de mapa, detalhe, listas e presets.

No slice atual, essa pressão deve ser registrada como razão para investigar gaps e propostas. Ela não implica:

- criar endpoints LeadFinder;
- reproduzir querysets do app legado;
- implementar cluster/map runtime;
- criar materialized views finais;
- enriquecer contatos;
- publicar dados sensíveis;
- promover campos automaticamente.

## Regras de passagem entre fases

1. T0 -> T1: raw pode gerar evidência estrutural segura, sem expor valores.
2. T1 -> T2: evidência pode alimentar gap/proposal LeadFinder quando houver pressão de demanda ou ausência/match de campo canônico.
3. T2 -> T3: gap/proposal pode ser avaliado por Matrix em `quality_report`, separado do bridge.
4. T3 -> T4: publicação DTO requer decisão posterior; quality_report não publica DTO sozinho.
5. T4 -> T5: LeadFinder materialization depende de DTO/modelo aprovado e continua fora do escopo deste slice.

## Riscos se a temporalidade for colapsada

- Tratar path raw como campo canônico antes de revisão semântica.
- Transformar filtro LeadFinder em schema final sem checar evidência/cobertura.
- Embutir qualidade Matrix no bridge e perder fronteira de responsabilidade.
- Publicar DTO SourceHub antes de aprovar mapeamento.
- Criar runtime LeadFinder sobre dados ainda em fase de modeling.
- Vazar valores raw ao tentar provar gap ou qualidade.

## Conclusão

A modelagem correta para este slice é uma ponte temporal e rastreável:

- T0 observa;
- T1 extrai evidência segura;
- T2 registra lacunas/propostas LeadFinder;
- T3 avalia qualidade via Matrix artifact separado;
- T4 publica DTO depois;
- T5 materializa LeadFinder depois.

Portanto, o trabalho atual deve permanecer no plano de evidence/modeling/review. Os filtros LeadFinder são a base de pressão para priorizar campos e gaps, mas LFG runtime, SourceHub DTO e LeadFinder materialization ficam deliberadamente para fases posteriores.
