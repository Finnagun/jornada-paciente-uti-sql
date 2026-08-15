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
permaneceram apenas documentadas em `sql/07-consultas-analise.sql`, sem
Views próprias, evitando poluir o banco com objetos que não têm uso direto
como fonte de dashboard ou relatório.

## Consultas que NÃO viraram View (e por quê)

- **3a — Classificação individual de cada episódio de VM** (Falha/Sucesso/Não
  se Aplica): é uma lista detalhada, linha por linha, sem agregação. Serve de
  base de cálculo para as consultas 3b e 5, mas não é, por si só, um
  resultado interpretável como card ou gráfico de dashboard.
- **7a — Contagem de episódios de VM por paciente traqueostomizado**: da
  mesma forma, é uma etapa de cálculo que fundamenta a consulta 7b (que virou
  a View `vw_desfecho_tqt`), não um resultado final autônomo.

## Views criadas

| View | Consulta de origem (Etapa 7) | O que representa |
|---|---|---|
| `vw_tempo_permanencia` | 1 | Tempo médio geral de permanência na UTI |
| `vw_tempo_permanencia_mobilizacao` | 2 | Tempo de permanência por participação em mobilização |
| `vw_taxa_sucesso_extubacao` | 3b | Taxa geral de sucesso/falha de extubação |
| `vw_tempo_vm_mobilizacao` | 4 | Tempo em VM por participação em mobilização |
| `vw_sucesso_extubacao_mobilizacao` | 5 | Falha de extubação x participação em mobilização |
| `vw_total_participacao_protocolo` | 6 | Contagem de participação no protocolo |
| `vw_desfecho_tqt` | 7b | Traqueostomia: com falha prévia vs VM prolongada |

Todas as Views foram testadas individualmente após a criação, confirmando que
os resultados retornados são idênticos aos já validados na Etapa 7.
