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
