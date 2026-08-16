import random
from datetime import timedelta
from utils import sortear_evento


def decidir_participacao_mobilizacao(foi_intubado, teve_complicacao):
    """
    Decide se o paciente participa do protocolo de mobilização precoce,
    com base no grupo de gravidade a que pertence. Pacientes mais graves
    (intubados com complicação) tendem a estar mais sedados/instáveis,
    participando menos do protocolo. Esta é uma simplificação: a
    possibilidade de avaliação parcial por RASS baixo dentro de uma
    sequência de avaliações foi modelada estruturalmente na tabela
    (permite NULL em mrc/codigo_nivel), mas não é explorada nesta
    versão do gerador de dados (ver docs/07-arvore-decisao-geracao-dados.md).

    Parâmetros:
        foi_intubado (bool): True se o paciente foi submetido à VM
        teve_complicacao (bool): True se houve falha de extubação e/ou
        traqueostomia

    Retorna: bool (True se participa do protocolo de mobilização)
    """
    if not foi_intubado:
        probabilidade_participacao = 0.85
    elif not teve_complicacao:
        probabilidade_participacao = 0.55
    else:
        probabilidade_participacao = 0.25

    return sortear_evento(probabilidade_participacao)


def gerar_avaliacoes_mobilizacao(data_internacao, data_desfecho):
    """
    Gera uma lista de avaliações de mobilização, com a primeira ocorrendo no
    dia da internação (avaliação inicial/admissional) e as seguintes a cada
    48h, até a data de desfecho (inclusive).

    Parâmetros:
        data_internacao (date): data de início da internação
        data_desfecho (date): data de alta ou óbito, usada como limite
        final do loop de avaliações

    Retorna:
        lista de dicionários, cada um com 'data_avaliacao',
        'codigo_nivel' e 'mrc' (níveis sorteados de 1 a 4, MRC de 0 a 60)
    """
    avaliacoes = []
    data_atual = data_internacao

    while data_atual <= data_desfecho:
        nivel = random.randint(1, 4)
        mrc = random.randint(0, 60)

        avaliacoes.append({
            'data_avaliacao': data_atual,
            'codigo_nivel': nivel,
            'mrc': mrc
        })

        data_atual = data_atual + timedelta(days=2)

    return avaliacoes


# ---------------------------------------------------------------------
# Bloco de teste
# ---------------------------------------------------------------------
if __name__ == "__main__":
    from datetime import date

    print("Testando decisão de participação (15 tentativas por grupo):")
    print("Não intubado:")
    for i in range(15):
        print(decidir_participacao_mobilizacao(foi_intubado=False, teve_complicacao=False))

    print("\nIntubado sem complicação:")
    for i in range(15):
        print(decidir_participacao_mobilizacao(foi_intubado=True, teve_complicacao=False))

    print("\nIntubado com complicação:")
    for i in range(15):
        print(decidir_participacao_mobilizacao(foi_intubado=True, teve_complicacao=True))

    print("\nTestando geração de avaliações (internação de 10 dias):")
    avaliacoes = gerar_avaliacoes_mobilizacao(date(2024, 1, 1), date(2024, 1, 10))
    for a in avaliacoes:
        print(a)
