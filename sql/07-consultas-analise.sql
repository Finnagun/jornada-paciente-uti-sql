-- ============================================================================
-- ETAPA 7 — CONSULTAS SQL DE ANÁLISE
-- ============================================================================
-- Este arquivo é construído incrementalmente ao longo da Etapa 7, respondendo
-- às perguntas de negócio definidas na Etapa 1 (ver docs/01-entendimento-do-
-- problema.md), com queries de complexidade crescente.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- 1. Qual o tempo médio de permanência na UTI (todos os pacientes)?
-- ----------------------------------------------------------------------------
SELECT
    ROUND(AVG(julianday(data_desfecho) - julianday(data_internacao)), 0) AS media_dias_internacao
FROM internacao;

-- Resultado: 13 dias (média geral, considerando todos os 1000 pacientes)


-- ----------------------------------------------------------------------------
-- 2. Existe diferença no tempo de permanência entre pacientes que
--    participaram da mobilização precoce e os que não participaram?
-- ----------------------------------------------------------------------------
SELECT
    participacao_protocolo,
    ROUND(AVG(tempo_internacao), 0) AS media_tempo_internacao
FROM (
    SELECT
        internacao.id_internacao,
        avaliacao_mobilizacao.id_avaliacao,
        julianday(data_desfecho) - julianday(data_internacao) AS tempo_internacao,
        CASE
            WHEN id_avaliacao IS NULL THEN 'Não Participou'
            ELSE 'Participou'
        END AS participacao_protocolo
    FROM internacao
    LEFT JOIN avaliacao_mobilizacao
        ON internacao.id_internacao = avaliacao_mobilizacao.id_internacao
    GROUP BY internacao.id_internacao
) AS subquery_pacientes
GROUP BY participacao_protocolo;

-- Resultado: Não participou = 18 dias | Participou = 15 dias
--
-- Interpretação: pacientes que participaram do protocolo de mobilização
-- precoce apresentaram tempo médio de permanência menor (15 dias) comparado
-- aos que não participaram (18 dias).
--
-- RESSALVA IMPORTANTE: a decisão de participação no protocolo, nesta base de
-- dados, está associada à gravidade clínica do paciente — pacientes mais
-- graves/instáveis tendem a não participar — o que pode representar uma
-- variável de confusão. Portanto, essa diferença não deve ser interpretada
-- como uma relação causal direta (mobilização → alta mais rápida), mas sim
-- como uma associação que reflete, ao menos em parte, a gravidade de base
-- dos pacientes.
--
-- Nota técnica: a subquery interna agrupa por id_internacao antes do cálculo
-- da média, evitando que internações com múltiplas avaliações (uma linha por
-- avaliação de 48h) sejam contadas repetidamente e distorçam a média final.


-- ----------------------------------------------------------------------------
-- 3. Qual a taxa de sucesso/falha de extubação (por episódio de VM)?
--    Regra de negócio: falha = reintubação em até 48h (2 dias) após extubação.
-- ----------------------------------------------------------------------------

-- 3a. Classificação individual de cada episódio como Falha, Sucesso ou
--     Não se Aplica (quando o paciente nunca chegou a ser extubado):
SELECT
    id_internacao,
    data_extubacao,
    data_reintubacao,
    CASE
        WHEN data_extubacao IS NULL THEN 'Não se Aplica'
        WHEN data_reintubacao IS NULL THEN 'Sucesso'
        WHEN julianday(data_reintubacao) - julianday(data_extubacao) <= 2 THEN 'Falha'
        ELSE 'Sucesso'
    END AS resultado_extubacao
FROM (
    SELECT
        id_internacao,
        data_extubacao,
        LEAD(data_intubacao) OVER (PARTITION BY id_internacao ORDER BY data_intubacao) AS data_reintubacao
    FROM episodio_vm
) AS subquery_episodios;

-- 3b. Taxa percentual de falha, sobre o total de episódios elegíveis
--     (excluindo "Não se Aplica"):
SELECT
    SUM(CASE WHEN resultado_extubacao = 'Falha' THEN 1 ELSE 0 END) AS total_falhas,
    SUM(CASE WHEN resultado_extubacao = 'Sucesso' THEN 1 ELSE 0 END) AS total_sucessos,
    ROUND(
        100.0 * SUM(CASE WHEN resultado_extubacao = 'Falha' THEN 1 ELSE 0 END)
        / (SUM(CASE WHEN resultado_extubacao = 'Falha' THEN 1 ELSE 0 END) + SUM(CASE WHEN resultado_extubacao = 'Sucesso' THEN 1 ELSE 0 END)),
        1
    ) AS percentual_falha
FROM (
    SELECT
        id_internacao,
        data_extubacao,
        data_reintubacao,
        CASE
            WHEN data_extubacao IS NULL THEN 'Não se Aplica'
            WHEN data_reintubacao IS NULL THEN 'Sucesso'
            WHEN julianday(data_reintubacao) - julianday(data_extubacao) <= 2 THEN 'Falha'
            ELSE 'Sucesso'
        END AS resultado_extubacao
    FROM (
        SELECT
            id_internacao,
            data_extubacao,
            LEAD(data_intubacao) OVER (PARTITION BY id_internacao ORDER BY data_intubacao) AS data_reintubacao
        FROM episodio_vm
    ) AS subquery_episodios
) AS subquery_resultado;

-- Resultado: 84 falhas, 454 sucessos → 15,6% de taxa de falha
-- (próximo dos 20% calibrados na matriz de literatura; variação estatística
-- natural da simulação)
--
-- Nota técnica: esta consulta introduz a window function LEAD(), que permite
-- "espiar" o valor de data_intubacao da PRÓXIMA linha (próximo episódio da
-- mesma internação), sem necessidade de JOIN. Combinada com julianday() para
-- calcular a diferença em dias, permite aplicar diretamente a regra de
-- negócio de 48h.


-- ----------------------------------------------------------------------------
-- 4. Mobilização precoce está associada a menor tempo de ventilação mecânica?
-- ----------------------------------------------------------------------------
SELECT
    participacao.participacao_protocolo,
    ROUND(AVG(vm.tempo_total_vm), 1) AS media_tempo_vm
FROM (
    SELECT
        internacao.id_internacao,
        CASE
            WHEN avaliacao_mobilizacao.id_avaliacao IS NULL THEN 'Não Participou'
            ELSE 'Participou'
        END AS participacao_protocolo
    FROM internacao
    LEFT JOIN avaliacao_mobilizacao
        ON internacao.id_internacao = avaliacao_mobilizacao.id_internacao
    GROUP BY internacao.id_internacao
) AS participacao

INNER JOIN (
    SELECT
        episodio_vm.id_internacao,
        SUM(julianday(COALESCE(data_extubacao, data_desfecho)) - julianday(data_intubacao)) AS tempo_total_vm
    FROM episodio_vm
    LEFT JOIN internacao ON episodio_vm.id_internacao = internacao.id_internacao
    GROUP BY episodio_vm.id_internacao
) AS vm
    ON participacao.id_internacao = vm.id_internacao

GROUP BY participacao.participacao_protocolo;

-- Resultado: Não participou = 16 dias | Participou = 13 dias
--
-- Interpretação: pacientes que participaram do protocolo de mobilização
-- apresentaram tempo médio em ventilação mecânica menor. O uso de INNER JOIN
-- restringe a análise apenas aos pacientes que foram efetivamente intubados
-- (não faz sentido comparar "tempo de VM" para quem nunca esteve em VM).
--
-- Nota técnica: para pacientes em VM prolongada (nunca extubados,
-- data_extubacao = NULL), o cálculo usa COALESCE(data_extubacao,
-- data_desfecho) — ou seja, considera que o paciente permaneceu em VM até o
-- desfecho da internação. Sem esse tratamento, esses casos (justamente os
-- mais graves) seriam incorretamente excluídos do cálculo.
--
-- RESSALVA: aplica-se a mesma ressalva de variável de confusão da consulta 2
-- — a gravidade do paciente influencia tanto a participação no protocolo
-- quanto o tempo de VM, independentemente de uma causar a outra.


-- ----------------------------------------------------------------------------
-- 5. Mobilização precoce está associada a maior sucesso de extubação?
-- ----------------------------------------------------------------------------
SELECT
    p.participacao_protocolo,
    d.desfecho_extubacao,
    COUNT(*) AS quantidade
FROM (
    SELECT
        i.id_internacao,
        CASE
            WHEN am.id_avaliacao IS NULL THEN 'Não Participou'
            ELSE 'Participou'
        END AS participacao_protocolo
    FROM internacao i
    LEFT JOIN avaliacao_mobilizacao am
        ON i.id_internacao = am.id_internacao
    GROUP BY i.id_internacao
) p

INNER JOIN (
    SELECT
        id_internacao,
        CASE
            WHEN teve_falha > 0 THEN 'Falha'
            ELSE 'Sucesso'
        END AS desfecho_extubacao
    FROM (
        SELECT
            id_internacao,
            SUM(CASE WHEN resultado_extubacao = 'Falha' THEN 1 ELSE 0 END) AS teve_falha
        FROM (
            SELECT
                t.id_internacao,
                CASE
                    WHEN t.data_extubacao IS NULL THEN 'Não se Aplica'
                    WHEN t.data_reintubacao IS NULL THEN 'Sucesso'
                    WHEN julianday(t.data_reintubacao) - julianday(t.data_extubacao) <= 2 THEN 'Falha'
                    ELSE 'Sucesso'
                END AS resultado_extubacao
            FROM (
                SELECT
                    id_internacao,
                    data_extubacao,
                    LEAD(data_intubacao) OVER (
                        PARTITION BY id_internacao
                        ORDER BY data_intubacao
                    ) AS data_reintubacao
                FROM episodio_vm
            ) t
        )
        GROUP BY id_internacao
    )
) d
    ON p.id_internacao = d.id_internacao

GROUP BY
    p.participacao_protocolo,
    d.desfecho_extubacao;

-- Resultado:
--   Não Participou + Falha:   62  (22,1% de falha dentro do grupo)
--   Não Participou + Sucesso: 218
--   Participou + Falha:       22  (8,8% de falha dentro do grupo)
--   Participou + Sucesso:     227
--
-- Interpretação: a investigação identificou uma diferença expressiva na taxa
-- de falha de extubação entre os grupos: pacientes que participaram do
-- protocolo de mobilização precoce apresentaram taxa de falha de 8,8%,
-- contra 22,1% entre os que não participaram. É importante notar, porém,
-- que a probabilidade de participação no protocolo, nesta base de dados,
-- está associada à gravidade clínica do paciente — pacientes mais graves
-- participam menos e, ao mesmo tempo, têm maior propensão à falha de
-- extubação, independentemente da mobilização. Assim, essa diferença
-- provavelmente reflete, ao menos em parte, a gravidade de base dos
-- pacientes, e não deve ser interpretada como um efeito causal isolado da
-- mobilização.
--
-- Nota técnica: esta consulta consolida a classificação por EPISÓDIO (feita
-- na consulta 3) em uma classificação única por INTERNAÇÃO, usando a regra
-- "se houve qualquer falha nos episódios daquela internação, ela é
-- classificada como Falha". Essa simplificação foi uma decisão deliberada:
-- não diferencia "sucesso na primeira tentativa" de "sucesso após uma falha
-- prévia" — essa granularidade temporal mais detalhada (incluindo a
-- possível influência de mobilização contínua entre uma falha e uma
-- segunda tentativa bem-sucedida) fica registrada como ideia para uma
-- futura V2 do projeto.
