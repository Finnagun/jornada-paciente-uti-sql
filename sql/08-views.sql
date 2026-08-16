-- ============================================================================
-- ETAPA 8 — VIEWS
-- ============================================================================
-- Este arquivo consolida as Views criadas a partir das consultas de análise
-- já validadas na Etapa 7 (ver sql/07-consultas-analise.sql), além de duas
-- Views novas criadas especificamente para dar suporte à página de "Jornada
-- Individual do Paciente" do dashboard (Etapa 9).
--
-- Critério de seleção: apenas consultas que representam um RESULTADO FINAL,
-- interpretável e reutilizável (potenciais fontes de dashboard) viraram
-- Views. Consultas que serviam apenas como etapa intermediária de cálculo
-- para outras consultas não foram transformadas em View.
-- ============================================================================


-- ----------------------------------------------------------------------------
-- vw_tempo_permanencia
-- Tempo médio de permanência na UTI, considerando todos os pacientes.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_tempo_permanencia AS
SELECT
    ROUND(AVG(julianday(data_desfecho) - julianday(data_internacao)), 0) AS media_dias_internacao
FROM internacao;


-- ----------------------------------------------------------------------------
-- vw_tempo_permanencia_mobilizacao
-- Tempo médio de permanência, comparado entre pacientes que participaram e
-- não participaram do protocolo de mobilização precoce.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_tempo_permanencia_mobilizacao AS
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


-- ----------------------------------------------------------------------------
-- vw_taxa_sucesso_extubacao
-- Taxa geral de sucesso/falha de extubação (por episódio), com percentual.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_taxa_sucesso_extubacao AS
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


-- ----------------------------------------------------------------------------
-- vw_tempo_vm_mobilizacao
-- Tempo médio total em ventilação mecânica, comparado entre pacientes que
-- participaram e não participaram do protocolo de mobilização precoce.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_tempo_vm_mobilizacao AS
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


-- ----------------------------------------------------------------------------
-- vw_sucesso_extubacao_mobilizacao
-- Cruzamento entre participação no protocolo de mobilização e desfecho de
-- extubação (Falha/Sucesso), consolidado por internação.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_sucesso_extubacao_mobilizacao AS
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


-- ----------------------------------------------------------------------------
-- vw_total_participacao_protocolo
-- Contagem total de pacientes que participaram ou não do protocolo de
-- mobilização precoce.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_total_participacao_protocolo AS
SELECT
    sub.aderencia_mobilizacao_precoce,
    COUNT(*) AS total_pacientes
FROM (
    SELECT
        i.id_internacao,
        CASE
            WHEN id_avaliacao IS NOT NULL THEN 'Participou'
            ELSE 'Não participou'
        END AS aderencia_mobilizacao_precoce
    FROM internacao i
    LEFT JOIN avaliacao_mobilizacao m
        ON i.id_internacao = m.id_internacao
    GROUP BY i.id_internacao
) AS sub
GROUP BY sub.aderencia_mobilizacao_precoce;


-- ----------------------------------------------------------------------------
-- vw_desfecho_tqt
-- Classificação de pacientes traqueostomizados: com falha de extubação
-- prévia (2 episódios de VM) ou por ventilação mecânica prolongada sem
-- falha (1 episódio de VM).
-- ----------------------------------------------------------------------------
CREATE VIEW vw_desfecho_tqt AS
SELECT
    x.realizado_tqt,
    COUNT(*) AS total_pacientes
FROM (
    SELECT
        t.id_internacao,
        CASE
            WHEN COUNT(ev.id_episodio_vm) = 1 THEN 'Sem falha prévia / VM prolongada'
            ELSE 'Com falha prévia'
        END AS realizado_tqt
    FROM traqueostomia t
    INNER JOIN episodio_vm ev
        ON t.id_internacao = ev.id_internacao
    GROUP BY t.id_internacao
) x
GROUP BY x.realizado_tqt;


-- ----------------------------------------------------------------------------
-- vw_cabecalho
-- Resumo consolidado (uma linha por internação) para a página de Jornada
-- Individual do Paciente: dados fixos, tempo de permanência, indicadores de
-- mobilização e VM/TQT. Não inclui nome (LGPD) nem MRC individual (ver
-- docs/09-views.md para a justificativa dessa decisão).
-- ----------------------------------------------------------------------------
CREATE VIEW vw_cabecalho AS
SELECT
    i.id_internacao,
    i.prontuario,
    CAST((julianday(i.data_internacao) - julianday(i.data_nascimento)) / 365.25 AS INTEGER) AS idade,
    i.genero,
    i.data_internacao,
    i.data_desfecho,
    i.desfecho,
    ROUND(julianday(i.data_desfecho) - julianday(i.data_internacao), 0) AS tempo_internacao,
    COALESCE(am.qtd_avaliacoes_mobilizacao, 0) AS qtd_avaliacoes_mobilizacao,
    COALESCE(vm.qtd_episodios_vm, 0) AS qtd_episodios_vm,
    t.data_traqueostomia
FROM internacao i

-- Subquery 1: Avaliações de Mobilização
LEFT JOIN (
    SELECT
        id_internacao,
        COUNT(DISTINCT id_avaliacao) AS qtd_avaliacoes_mobilizacao
    FROM avaliacao_mobilizacao
    GROUP BY id_internacao
) am ON i.id_internacao = am.id_internacao

-- Subquery 2: Episódios de Ventilação Mecânica (VM)
LEFT JOIN (
    SELECT
        id_internacao,
        COUNT(id_episodio_vm) AS qtd_episodios_vm
    FROM episodio_vm
    GROUP BY id_internacao
) vm ON i.id_internacao = vm.id_internacao

-- Subquery 3: Traqueostomia
LEFT JOIN (
    SELECT
        id_internacao,
        data_traqueostomia
    FROM traqueostomia
) t ON i.id_internacao = t.id_internacao;


-- ----------------------------------------------------------------------------
-- vw_linha_tempo_paciente
-- Linha do tempo de eventos clínicos de cada internação (Internação,
-- Intubação, Extubação, Traqueostomia, Desfecho), unificados via UNION ALL
-- e ordenados cronologicamente por paciente. Usada junto com vw_cabecalho
-- para compor a página de Jornada Individual do Paciente.
-- ----------------------------------------------------------------------------
CREATE VIEW vw_linha_tempo_paciente AS
-- 1. Internação
SELECT
    id_internacao,
    data_internacao AS data_evento,
    'Internação' AS tipo_evento,
    'Paciente foi internado' AS descricao_evento
FROM internacao
UNION ALL
-- 2. Intubação
SELECT
    id_internacao,
    data_intubacao AS data_evento,
    'Intubação' AS tipo_evento,
    'Paciente foi intubado' AS descricao_evento
FROM episodio_vm
WHERE data_intubacao IS NOT NULL
UNION ALL
-- 3. Extubação
SELECT
    id_internacao,
    data_extubacao AS data_evento,
    'Extubação' AS tipo_evento,
    'Paciente foi extubado' AS descricao_evento
FROM episodio_vm
WHERE data_extubacao IS NOT NULL
UNION ALL
-- 4. Traqueostomia
SELECT
    id_internacao,
    data_traqueostomia AS data_evento,
    'Traqueostomia' AS tipo_evento,
    'Paciente foi traqueostomizado' AS descricao_evento
FROM traqueostomia
WHERE data_traqueostomia IS NOT NULL
UNION ALL
-- 5. Desfecho
SELECT
    id_internacao,
    data_desfecho AS data_evento,
    CASE
        WHEN desfecho = 'alta' THEN 'Alta'
        WHEN desfecho = 'obito' THEN 'Óbito'
    END AS tipo_evento,
    CASE
        WHEN desfecho = 'alta' THEN 'Paciente recebeu alta hospitalar'
        WHEN desfecho = 'obito' THEN 'Paciente evoluiu para óbito'
    END AS descricao_evento
FROM internacao
WHERE data_desfecho IS NOT NULL
ORDER BY id_internacao, data_evento ASC;
