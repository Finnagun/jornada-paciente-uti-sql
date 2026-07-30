from utils import sortear_evento


def decidir_desfecho(foi_intubado, teve_complicacao):
    """
    Decide se o paciente evolui para alta ou óbito, com base no grupo de
    gravidade a que pertence (definido pelo caminho percorrido na árvore
    de decisão de VM). As taxas utilizadas representam o ponto médio das
    faixas de mortalidade estimadas na matriz de calibração (ver
    docs/06-matriz-calibracao.md).

    Parâmetros:
        foi_intubado (bool): True se o paciente foi submetido à VM
        teve_complicacao (bool): True se houve falha de extubação e/ou
        traqueostomia (indicando maior gravidade)

    Retorna: str ('alta' ou 'obito')
    """
    if not foi_intubado:
        probabilidade_obito = 0.05
    elif not teve_complicacao:
        probabilidade_obito = 0.125  # ponto médio da faixa 10-15%
    else:
        probabilidade_obito = 0.225  # ponto médio da faixa 20-25%

    if sortear_evento(probabilidade_obito):
        return 'obito'
    else:
        return 'alta'


# ---------------------------------------------------------------------
# Bloco de teste: gera 15 exemplos de cada cenário para conferência visual
# ---------------------------------------------------------------------
if __name__ == "__main__":
    print("Desfechos - não intubado (15 tentativas):")
    for i in range(15):
        print(decidir_desfecho(foi_intubado=False, teve_complicacao=False))

    print("\nDesfechos - intubado, sem complicação (15 tentativas):")
    for i in range(15):
        print(decidir_desfecho(foi_intubado=True, teve_complicacao=False))

    print("\nDesfechos - intubado, com complicação (15 tentativas):")
    for i in range(15):
        print(decidir_desfecho(foi_intubado=True, teve_complicacao=True))
