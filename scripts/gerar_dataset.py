import sqlite3
import random
from datetime import date

from gerar_internacao import gerar_idade, gerar_sexo, gerar_data_internacao
from gerar_vm import gerar_episodios_vm
from gerar_mobilizacao import decidir_participacao_mobilizacao, gerar_avaliacoes_mobilizacao
from gerar_desfecho import decidir_desfecho

NUMERO_DE_PACIENTES = 1000
CAMINHO_BANCO = "../data/uti.db"


def gerar_prontuario(indice):
    """
    Gera um número de prontuário fictício e sequencial, apenas para dar
    unicidade visual ao paciente (não representa um prontuário real).

    Retorna: int
    """
    return 100000 + indice


def calcular_data_desfecho(data_internacao, episodios, data_tqt):
    """
    Calcula a data de desfecho (alta ou óbito) do paciente, com base no
    caminho percorrido: tempo de internação simples, ou tempo adicional
    após o último evento registrado (extubação ou traqueostomia).

    Parâmetros:
        data_internacao (date): data de internação
        episodios (list): lista de episódios de VM do paciente
        data_tqt (date ou None): data da traqueostomia, se houver

    Retorna: date (data de desfecho)
    """
    from datetime import timedelta

    if not episodios:
        # Não intubado: internação curta, entre 2 e 7 dias
        return data_internacao + timedelta(days=random.randint(2, 7))

    if data_tqt is not None:
        # Traqueostomizado: permanece internado por mais um tempo após a TQT
        return data_tqt + timedelta(days=random.randint(5, 15))

    # Extubado com sucesso: usa a data de extubação do último episódio
    ultimo_episodio = episodios[-1]
    data_extubacao = ultimo_episodio['data_extubacao']
    return data_extubacao + timedelta(days=random.randint(2, 5))


def gerar_paciente(indice):
    """
    Gera todos os dados de um paciente fictício, percorrendo a árvore de
    decisão completa (internação, VM, TQT, mobilização, desfecho).

    Retorna: dicionário com todas as informações do paciente, prontas
    para inserção no banco
    """
    idade = gerar_idade()
    sexo = gerar_sexo()
    data_internacao = gerar_data_internacao()
    data_nascimento = date(data_internacao.year - idade, data_internacao.month, data_internacao.day)

    episodios, teve_complicacao, data_tqt = gerar_episodios_vm(data_internacao)
    foi_intubado = len(episodios) > 0

    data_desfecho = calcular_data_desfecho(data_internacao, episodios, data_tqt)
    desfecho = decidir_desfecho(foi_intubado, teve_complicacao)

    avaliacoes = []
    if decidir_participacao_mobilizacao(foi_intubado, teve_complicacao):
        avaliacoes = gerar_avaliacoes_mobilizacao(data_internacao, data_desfecho)

    return {
        'prontuario': gerar_prontuario(indice),
        'data_nascimento': data_nascimento,
        'genero': sexo,
        'data_internacao': data_internacao,
        'data_desfecho': data_desfecho,
        'desfecho': desfecho,
        'episodios': episodios,
        'data_tqt': data_tqt,
        'avaliacoes': avaliacoes
    }


def inserir_paciente(cursor, paciente):
    """
    Insere um paciente completo no banco: internação, episódios de VM,
    traqueostomia (se houver) e avaliações de mobilização (se houver).
    """
    cursor.execute(
        """INSERT INTO internacao 
           (prontuario, data_nascimento, genero, data_internacao, data_desfecho, desfecho) 
           VALUES (?, ?, ?, ?, ?, ?)""",
        (paciente['prontuario'], paciente['data_nascimento'], paciente['genero'],
         paciente['data_internacao'], paciente['data_desfecho'], paciente['desfecho'])
    )
    id_internacao = cursor.lastrowid

    for episodio in paciente['episodios']:
        cursor.execute(
            """INSERT INTO episodio_vm (id_internacao, data_intubacao, data_extubacao)
               VALUES (?, ?, ?)""",
            (id_internacao, episodio['data_intubacao'], episodio['data_extubacao'])
        )

    if paciente['data_tqt'] is not None:
        cursor.execute(
            """INSERT INTO traqueostomia (id_internacao, data_traqueostomia)
               VALUES (?, ?)""",
            (id_internacao, paciente['data_tqt'])
        )

    for avaliacao in paciente['avaliacoes']:
        cursor.execute(
            """INSERT INTO avaliacao_mobilizacao (id_internacao, data_avaliacao, codigo_nivel, mrc)
               VALUES (?, ?, ?, ?)""",
            (id_internacao, avaliacao['data_avaliacao'], avaliacao['codigo_nivel'], avaliacao['mrc'])
        )


def popular_dominio_niveis(cursor):
    """
    Insere os 4 níveis fixos da escala de mobilização, caso ainda não
    existam na tabela de domínio.
    """
    niveis = [
        (1, 'Paciente Inconsciente ou Acamado'),
        (2, 'Interação e Atividade no Leito'),
        (3, 'Transferência para Fora da Cama'),
        (4, 'Postura de Pé e Caminhada')
    ]
    cursor.executemany(
        "INSERT OR IGNORE INTO dominio_nivel_mobilizacao (codigo_nivel, descricao) VALUES (?, ?)",
        niveis
    )


def main():
    """
    Função principal: conecta ao banco, popula a tabela de domínio,
    gera e insere os pacientes fictícios, e confirma a gravação.
    """
    conn = sqlite3.connect(CAMINHO_BANCO)
    conn.execute("PRAGMA foreign_keys = ON;")
    cursor = conn.cursor()

    popular_dominio_niveis(cursor)

    for i in range(NUMERO_DE_PACIENTES):
        paciente = gerar_paciente(i)
        inserir_paciente(cursor, paciente)

    conn.commit()
    conn.close()

    print(f"{NUMERO_DE_PACIENTES} pacientes gerados e inseridos com sucesso em {CAMINHO_BANCO}")


if __name__ == "__main__":
    main()
