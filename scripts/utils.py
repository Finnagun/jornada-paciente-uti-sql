import random


def sortear_evento(probabilidade):
    """
    Sorteia se um evento ocorre, com base numa probabilidade informada.
    Função genérica reutilizada por todas as decisões binárias da árvore
    de geração de dados (intubação, falha, TQT, VM prolongada, etc.).

    Parâmetros:
        probabilidade (float): valor entre 0 e 1, representando a chance
        do evento ocorrer (ex: 0.556 para 55,6%)

    Retorna: bool (True se o evento ocorreu, False caso contrário)
    """
    return random.random() < probabilidade
