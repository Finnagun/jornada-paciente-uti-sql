# Etapa 5/6 — Matriz de Calibração do Dataset Fictício

## Sobre este documento

Este projeto nasceu da vivência prática do autor como fisioterapeuta intensivista com
mais de 10 anos de atuação em UTI. As proporções e regras de coerência clínica
utilizadas na geração do dataset fictício foram validadas e calibradas com base em
literatura científica brasileira, garantindo rigor estatístico ao mesmo tempo em que
mantêm plausibilidade clínica real.

Nenhum dado real de paciente, de instituição específica, ou identificável foi
utilizado neste projeto. Todos os artigos citados são fontes públicas e verificáveis.

## Matriz de calibração — proporções clínicas

| Variável | Tabela | Valor adotado | Referência |
|---|---|---|---|
| Sexo masculino | `internacao` | ~58% | Aguiar et al., 2021 |
| Idade | `internacao` | Predomínio de idosos (50+ anos) | Aguiar et al., 2021 |
| Ventilação mecânica | `episodio_vm` | 55,6% dos internados | Damasceno et al., 2006 |
| Tempo de VM | `episodio_vm` | Mediana ~11 dias | Damasceno et al., 2006 |
| Falha de extubação (critério 48h) | `episodio_vm` | 20% dos intubados | Estudo de falha de extubação, SC, 2021-2024 |
| Traqueostomia — Caminho 2 (VM prolongada) | `traqueostomia` | 16,84% dos pacientes em VM | Aranha et al., 2007 |
| Tempo até TQT | `traqueostomia` | Média ~13,5 dias em VM | Aranha et al., 2007 |
| Traqueostomia — Caminho 1 (pós-falha) | `traqueostomia` | ~55,8% dos que falharam extubação | Estudo de falência de extubação em TCE (JBP) |
| Primeira mobilização | `avaliacao_mobilizacao` | A partir de 48h de internação | Protocolo próprio + Diretrizes Brasileiras de Mobilização Precoce, 2019 |

## Matriz de calibração — mortalidade por gravidade do caminho clínico

| Grupo | Taxa de óbito adotada | Referência |
|---|---|---|
| Não intubado | ~5% | Aproximação conservadora, baseada no grupo de sucesso do estudo de falha de extubação (mortalidade de 4,5%) |
| Intubado, extubado com sucesso (sem falha) | ~10-15% | Valor intermediário entre a mortalidade geral de UTI (21-24%) e a do grupo de sucesso de extubação (4,5%) |
| Intubado, com falha de extubação e/ou traqueostomia | ~20-25% | Alinhado à mortalidade do grupo de falência de extubação (20,9%, estudo JBP) e à mortalidade de pacientes graves em UTI (até 66% em subgrupos mais críticos, Projeto UTIs Brasileiras/AMIB-Epimed) |

**Racional:** a mortalidade foi diferenciada por caminho clínico percorrido, refletindo a
gravidade crescente associada a cada desfecho intermediário (não intubado → intubado
com sucesso → intubado com complicação/falha), de forma consistente com o observado na
literatura.

## Referências completas

1. **Aguiar LMM, Martins GS, Valduga R, Gerez AP, Carmo EC, Cunha KC, Cipriano GFB,
   Silva ML.** Perfil de unidades de terapia intensiva adulto no Brasil: revisão
   sistemática de estudos observacionais. *Revista Brasileira de Terapia Intensiva*.
   2021;33(4):624-634. DOI: https://doi.org/10.5935/0103-507X.20210088
   *(Revisão sistemática — 27 estudos, 113 UTIs, 75.280 pacientes)*

2. **Damasceno MPCD, David CMN, Souza PCSP, Chiavone PA, Cardoso LTQ, Amaral JLG,
   Tasanato E, Silva NB, Luiz RR.** Ventilação mecânica no Brasil: aspectos
   epidemiológicos. *Revista Brasileira de Terapia Intensiva*. 2006;18(3):219-228.
   DOI: https://doi.org/10.1590/S0103-507X2006000300002
   *(Estudo VMB — prevalência de 1 dia, 40 UTIs brasileiras, 390 pacientes)*

3. **Aranha SC, Mataloun SE, Moock M, Ribeiro R.** Estudo comparativo entre
   traqueostomia precoce e tardia em pacientes sob ventilação mecânica. *Revista
   Brasileira de Terapia Intensiva*. 2007;19(4):444-449.
   *(Estudo de coorte retrospectivo, 190 pacientes)*

4. **Diretrizes Brasileiras de Mobilização Precoce em Unidade de Terapia Intensiva.**
   *Revista Brasileira de Terapia Intensiva*. 2019;31(4):434-443.
   *(Diretriz nacional, revisão sistemática com estratégia PICO)*

5. Estudo sobre incidência de falha de extubação em 48h em UTI de hospital público do
   norte de Santa Catarina (2021-2024) — frequência de falha de extubação em 48h: 20%.

6. Estudo sobre falência da extubação e desfechos clínicos/funcionais em pacientes
   com traumatismo cranioencefálico, publicado no *Jornal Brasileiro de Pneumologia*
   — associação entre falência de extubação e maior frequência de traqueostomia
   (55,8% vs. grupo de sucesso) e maior mortalidade hospitalar (20,9% vs. 4,5%).

7. Projeto UTIs Brasileiras (Associação de Medicina Intensiva Brasileira — AMIB, em
   parceria com Epimed Solutions) — levantamento em 450 hospitais brasileiros,
   ~13.600 leitos de UTI — mortalidade geral de UTI de 21%, chegando a 66% entre
   pacientes mais graves.

8. Estudo epidemiológico retrospectivo, UTI do Hospital Geral de Fortaleza (2016) —
   taxa de óbito geral de 24,48% em 137 pacientes analisados.

## Limitações reconhecidas

- Os artigos utilizados representam diferentes populações de UTI (geral, neurocrítica,
  perfis variados de gravidade), o que pode gerar alguma heterogeneidade ao combinar
  proporções de fontes distintas em um único dataset sintético.
- O estudo de Damasceno et al. (2006), embora seja uma das referências nacionais mais
  amplas disponíveis sobre o tema, tem quase 20 anos — é possível que os padrões de
  uso de ventilação mecânica tenham evoluído desde então.
- As taxas de mortalidade por caminho clínico foram estimadas por aproximação e
  triangulação entre estudos com desenhos diferentes, não extraídas de uma única
  fonte com essa segmentação exata — refletem uma gradação plausível, não um dado
  direto e único da literatura.
- As proporções adotadas representam médias/medianas populacionais; a variabilidade
  individual entre pacientes reais é maior do que a capturada por uma única taxa.
- Dados de mortalidade específicos da pandemia de COVID-19 foram deliberadamente
  excluídos da calibração, por representarem um cenário de gravidade excepcional não
  generalizável à rotina padrão de uma UTI.