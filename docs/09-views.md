# Etapa 8 — Views

## O que é uma View

Uma View é um "apelido nomeado" para uma consulta SQL já existente. Ela não
armazena dados fisicamente — toda vez que é consultada, o banco executa a
consulta original por trás dela e devolve o resultado atualizado. É útil para
evitar reescrever consultas complexas repetidamente, especialmente quando
essas consultas precisam ser acessadas por outras ferramentas (como o Power
BI, na Etapa 9).

## Critério de decisão: quais consultas viraram View

Nem toda consulta da Etapa 7 se tornou uma View. O critério utilizado foi:

> Essa consulta representa um **resultado final**, interpretável por si só e
> potencialmente reutilizável como fonte de dashboard? Ou ela é apenas uma
> **etapa intermediária de cálculo**, que outras consultas já reaproveitam
> internamente?

Consultas do primeiro tipo viraram View. Consultas do segundo tipo
permaneceram apenas documentadas em `sql/07-consultas-analise.sql`.

## Consultas que NÃO viraram View (e por quê)

- **Classificação individual de cada episódio de VM** (Falha/Sucesso/Não se
  Aplica): lista detalhada, linha por linha, sem agregação. Serve de base de
  cálculo para outras consultas, mas não é um resultado interpretável isolado.
- **Contagem de episódios de VM por paciente traqueostomizado**: da mesma
  forma, é uma etapa de cálculo que fundamenta a View `vw_desfecho_tqt`.

## Views de análise agregada

| View | Consulta de origem (Etapa 7) | O que representa |
|---|---|---|
| `vw_tempo_permanencia` | 1 | Tempo médio geral de permanência na UTI |
| `vw_tempo_permanencia_mobilizacao` | 2 | Tempo de permanência por participação em mobilização |
| `vw_taxa_sucesso_extubacao` | 3b | Taxa geral de sucesso/falha de extubação |
| `vw_tempo_vm_mobilizacao` | 4 | Tempo em VM por participação em mobilização |
| `vw_sucesso_extubacao_mobilizacao` | 5 | Falha de extubação x participação em mobilização |
| `vw_total_participacao_protocolo` | 6 | Contagem de participação no protocolo |
| `vw_desfecho_tqt` | 7b | Traqueostomia: com falha prévia vs VM prolongada |

---

## Views de Jornada Individual do Paciente

Durante o desenvolvimento desta etapa, surgiu a ideia de complementar a
análise populacional (agregada) com uma segunda perspectiva: a jornada
completa de **um único paciente**, navegável por número de prontuário/
internação. A ideia foi validada informalmente com uma colega fisioterapeuta,
que confirmou dois usos práticos reais: melhoria de processos e apresentação
de resultados (ênfase no impacto da fisioterapia na internação).

### Decisões de escopo

- **Sem nome do paciente**: por LGPD e por já ter sido uma decisão consciente
  desde a Etapa 3 (o banco não armazena nomes).
- **Sem MRC individual na jornada**: o MRC foi gerado aleatoriamente na
  simulação (ver docs/08-perguntas-revisadas.md), sem lógica de evolução —
  expô-lo em uma jornada individual (onde a ausência de coerência fica mais
  evidente do que em uma média agregada) traria mais confusão do que valor.
- **Mobilização resumida, não evento a evento**: como um paciente pode ter
  dezenas de avaliações de mobilização (a cada 48h), incluir cada uma na
  linha do tempo poluiria a visão dos eventos clínicos mais relevantes
  (intubação, falha, TQT). A participação em mobilização aparece de forma
  resumida no cabeçalho (quantidade de avaliações realizadas).
- **Comparação entre internações do mesmo paciente (histórico de
  reinternações) foi definida como fora de escopo do V1** — exigiria retomar
  a decisão, já adiada na Etapa 3, de separar as entidades Pessoa e
  Internação, além de regenerar todo o dataset. Fica registrada como ideia
  de V2.

### Correção de regra de negócio identificada durante a construção

Ao testar a `vw_cabecalho`, foi identificada uma inconsistência entre a
documentação original (mobilização "a cada 48h", sem especificar o início) e
a implementação real do gerador de dados (primeira avaliação no dia da
internação). Optou-se por manter o comportamento do código — que reflete
melhor a prática real de uma avaliação fisioterapêutica admissional — e
corrigir a documentação das Etapas 1 e 6 para refletir essa regra de forma
explícita, ao invés de alterar e reprocessar o dataset já gerado.

### Views criadas

**`vw_cabecalho`**: uma linha por internação, consolidando idade (calculada
na data da internação, não na data atual), sexo, tempo de permanência,
indicadores resumidos de mobilização e VM/TQT.

**`vw_linha_tempo_paciente`**: lista de eventos clínicos (Internação,
Intubação, Extubação, Traqueostomia, Desfecho) de cada internação, construída
unificando 5 consultas de tabelas diferentes através de `UNION ALL`, e
ordenada cronologicamente por paciente. É a primeira View do projeto a
utilizar essa técnica — ver resumo de estudo para detalhes técnicos do
`UNION`.

As duas Views foram testadas com múltiplos pacientes representando diferentes
caminhos da árvore de decisão (não intubado, intubado sem complicação,
intubado com falha e TQT), confirmando resultados coerentes com o restante do
projeto.
