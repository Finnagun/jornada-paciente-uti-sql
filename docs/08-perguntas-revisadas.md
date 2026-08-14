# Perguntas Revisadas Durante o Processo

Este documento registra perguntas de negócio que foram formuladas, testadas com SQL, e
posteriormente reavaliadas de forma crítica ao longo do desenvolvimento do projeto.
A decisão de mantê-las documentadas (ao invés de removê-las silenciosamente) reflete o
princípio central deste projeto: o processo de investigação — incluindo perguntas que
se revelam mal formuladas — é parte legítima do trabalho de um analista de dados.

---

## Existe associação entre MRC (força muscular) e histórico de IOT?

### A pergunta original

Definida na Etapa 1, com a ressalva de que a literatura não costuma analisar essa
relação de forma isolada, por envolver múltiplos fatores de confusão. A intenção
original era investigar se pacientes com MRC mais baixo na base apresentavam maior
histórico de intubação — uma hipótese inspirada em casos reais de sarcopenia e
fraqueza muscular prolongada contribuindo para insuficiência respiratória.

### A consulta executada

```sql
SELECT
    vm.status_vm,
    ROUND(AVG(primeira_mrc.mrc), 0) AS media_mrc
FROM (
    SELECT
        primeira.id_internacao,
        primeira.primeira_avaliacao,
        avaliacao_mobilizacao.mrc
    FROM (
        SELECT
            id_internacao,
            MIN(data_avaliacao) AS primeira_avaliacao
        FROM avaliacao_mobilizacao
        GROUP BY id_internacao
    ) AS primeira
    JOIN avaliacao_mobilizacao
        ON primeira.id_internacao = avaliacao_mobilizacao.id_internacao
        AND primeira.primeira_avaliacao = avaliacao_mobilizacao.data_avaliacao
) AS primeira_mrc

INNER JOIN (
    SELECT
        internacao.id_internacao,
        CASE
            WHEN episodio_vm.data_intubacao IS NOT NULL THEN 'Entubado'
            ELSE 'Não entubado'
        END AS status_vm
    FROM internacao
    LEFT JOIN episodio_vm
        ON internacao.id_internacao = episodio_vm.id_internacao
    GROUP BY internacao.id_internacao
) AS vm
    ON primeira_mrc.id_internacao = vm.id_internacao

GROUP BY vm.status_vm;
```

### Resultado obtido

| Status VM | MRC médio (primeira avaliação) |
|---|---|
| Entubado | 30 |
| Não entubado | 29 |

Praticamente nenhuma diferença entre os grupos.

### Avaliação crítica do resultado

Ao analisar esse resultado, identifiquei **duas limitações distintas**, uma técnica
e uma conceitual:

**1. Limitação técnica (da simulação):** o campo `mrc`, na Etapa 6, foi gerado de
forma totalmente aleatória (`random.randint(0, 60)`), sem nenhuma lógica de associação
com o histórico de intubação do paciente — diferente de outras variáveis do projeto
(mortalidade, participação no protocolo de mobilização), que foram deliberadamente
calibradas por gravidade clínica. Um resultado sem diferença entre grupos era,
portanto, esperado, e não reflete uma investigação real.

**2. Limitação conceitual (da própria pergunta, independente dos dados):** mesmo se
os dados fossem reais e cuidadosamente coletados, o desenho da pergunta apresenta
problemas:

- O MRC medido na **primeira avaliação disponível** de uma internação pode estar
  comprometido por fatores não relacionados à força muscular real do paciente
  (rebaixamento do nível de consciência, confusão mental na admissão), tornando-o um
  valor pouco confiável como ponto de partida para essa análise.
- Na prática clínica, o MRC (que avalia força de membros de forma geral) não é a
  ferramenta padrão para estimar risco de insuficiência respiratória por fraqueza
  muscular. Medidas específicas de força da musculatura respiratória — como PImax e
  PEmax (pressões inspiratória e expiratória máximas), comumente utilizadas em
  quadros como ELA — são clinicamente mais apropriadas para esse propósito.

### Decisão

Optei por **manter esta pergunta documentada**, ao invés de removê-la
silenciosamente do projeto, por dois motivos:

1. Coerência com o restante do projeto, que documenta decisões, limitações e mudanças
   de rumo ao longo de todas as etapas anteriores (ver docs/06-matriz-calibracao.md e
   docs/07-arvore-decisao-geracao-dados.md, por exemplo).
2. O valor de registrar o processo de identificar que uma pergunta está mal
   formulada — antes mesmo de considerar limitações de dados — é, em si, parte
   relevante do raciocínio analítico que este projeto busca demonstrar.

Esta pergunta **não integra** a análise consolidada de resultados do projeto
(ver sql/07-consultas-analise.sql), mas permanece registrada aqui como parte
legítima do processo de investigação.
