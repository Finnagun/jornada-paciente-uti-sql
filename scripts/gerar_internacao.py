import random
from datetime import date, timedelta


def gerar_idade():
    """
    Gera uma idade aleatória para um paciente fictício, com concentração
    em faixas etárias mais avançadas (refletindo o perfil predominante
    de idosos em UTI geral, conforme literatura).

    Retorna: int (idade em anos, limitada entre 18 e 95)
    """
    idade = int(random.gauss(66, 15))
    idade = max(18, min(95, idade))
    return idade


def gerar_sexo():
    """
    Sorteia o sexo biológico do paciente, com base na proporção de
    58% masculino observada na literatura (Aguiar et al., 2021).

    Retorna: str ('masculino' ou 'feminino')
    """
    if random.random() < 0.58:
        return 'masculino'
    else:
        return 'feminino'


def gerar_data_internacao():
    """
    Sorteia uma data de internação aleatória dentro do período de 2 anos
    (01/01/2023 a 31/12/2024), simulando uma distribuição uniforme de
    internações ao longo do tempo.

    Retorna: date (objeto de data do Python)
    """
    data_inicio = date(2023, 1, 1)
    data_fim = date(2024, 12, 31)

    dias_no_periodo = (data_fim - data_inicio).days
    dias_aleatorios = random.randint(0, dias_no_periodo)

    data_internacao = data_inicio + timedelta(days=dias_aleatorios)
    return data_internacao


# ---------------------------------------------------------------------
# Bloco de teste: gera 10 exemplos de cada função para conferência visual
# ---------------------------------------------------------------------
if __name__ == "__main__":
    print("Idades geradas:")
    for i in range(10):
        print(gerar_idade())

    print("\nSexos gerados:")
    for i in range(10):
        print(gerar_sexo())

    print("\nDatas de internação geradas:")
    for i in range(10):
        print(gerar_data_internacao())
