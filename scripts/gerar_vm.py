import random
from datetime import timedelta
from utils import sortear_evento


def decidir_se_foi_intubado():
    """
    Decide se o paciente foi submetido à ventilação mecânica invasiva,
    com base na taxa de 55,6% observada em UTIs brasileiras
    (Damasceno et al., 2006).

    Retorna: bool (True se foi intubado, False caso contrário)
    """
    return sortear_evento(0.556)


def decidir_se_vm_prolongada():
    """
    Decide se o paciente entra no caminho de ventilação mecânica
    prolongada (nunca chega a ser extubado), com base na proporção de
    5,6% calculada a partir da matriz de calibração (ver
    docs/07-arvore-decisao-geracao-dados.md).

    Retorna: bool (True se entra em VM prolongada, False caso contrário)
    """
    return sortear_evento(0.056)


def decidir_se_houve_falha_extubacao():
    """
    Decide se o paciente apresenta falha de extubação (reintubação em
    até 48h), com base na taxa de 20% observada em estudo de hospital
    público de Santa Catarina (2021-2024).

    Retorna: bool (True se houve falha, False se a extubação teve sucesso)
    """
    return sortear_evento(0.20)


def decidir_se_fez_tqt_pos_falha():
    """
    Decide se o paciente foi submetido à traqueostomia após falha de
    extubação, com base na taxa de 55,8% observada em estudo de
    falência de extubação (Jornal Brasileiro de Pneumologia).

    Retorna: bool (True se fez TQT após a falha, False se tenta extubar
    novamente)
    """
    return sortear_evento(0.558)


def gerar_episodios_vm(data_internacao):
    """
    Percorre a árvore de decisão de ventilação mecânica para um paciente,
    gerando 0, 1 ou 2 episódios de VM, conforme o caminho sorteado
    (ver docs/07-arvore-decisao-geracao-dados.md).

    Parâmetros:
        data_internacao (date): data de internação do paciente, usada
        como referência para calcular as datas dos episódios

    Retorna:
        tuple contendo:
        - lista de dicionários, cada um com 'data_intubacao' e
          'data_extubacao' (podendo ser None)
        - bool indicando se houve complicação (falha de extubação e/ou
          traqueostomia), usado depois para decidir o desfecho final
        - date ou None indicando a data da traqueostomia, se houver
    """
    episodios = []
    teve_complicacao = False
    data_tqt = None

    if not decidir_se_foi_intubado():
        return episodios, teve_complicacao, data_tqt

    data_intubacao_1 = data_internacao + timedelta(days=random.randint(0, 5))

    if decidir_se_vm_prolongada():
        # Episódio 1: nunca extubou, vai direto para TQT após ~14 dias
        data_tqt = data_intubacao_1 + timedelta(days=14)
        episodios.append({
            'data_intubacao': data_intubacao_1,
            'data_extubacao': None
        })
        teve_complicacao = True
        return episodios, teve_complicacao, data_tqt

    # Extubado dentro do episódio 1 (mediana de 11 dias de VM)
    data_extubacao_1 = data_intubacao_1 + timedelta(days=11)
    episodios.append({
        'data_intubacao': data_intubacao_1,
        'data_extubacao': data_extubacao_1
    })

    if not decidir_se_houve_falha_extubacao():
        return episodios, teve_complicacao, data_tqt

    # Falhou: gera episódio 2 (reintubação em até 48h)
    teve_complicacao = True
    data_intubacao_2 = data_extubacao_1 + timedelta(days=1)

    if decidir_se_fez_tqt_pos_falha():
        data_tqt = data_intubacao_2 + timedelta(days=14)
        episodios.append({
            'data_intubacao': data_intubacao_2,
            'data_extubacao': None
        })
    else:
        data_extubacao_2 = data_intubacao_2 + timedelta(days=8)
        episodios.append({
            'data_intubacao': data_intubacao_2,
            'data_extubacao': data_extubacao_2
        })

    return episodios, teve_complicacao, data_tqt


# ---------------------------------------------------------------------
# Bloco de teste: gera 10 pacientes fictícios e imprime seus episódios
# ---------------------------------------------------------------------
if __name__ == "__main__":
    from datetime import date

    for i in range(10):
        episodios, complicacao, data_tqt = gerar_episodios_vm(date(2024, 1, 1))
        print(f"Paciente {i+1}:")
        print(f"  Episódios: {episodios}")
        print(f"  Teve complicação: {complicacao}")
        print(f"  Data TQT: {data_tqt}")
        print()
