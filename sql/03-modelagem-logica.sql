CREATE TABLE internacao (
    id_internacao   INTEGER PRIMARY KEY,
    prontuario      INTEGER NOT NULL,
    data_nascimento DATE NOT NULL,
    genero          TEXT NOT NULL CHECK (genero IN ('masculino', 'feminino')),
    data_internacao DATE NOT NULL,
    data_desfecho   DATE NOT NULL,
    desfecho        TEXT NOT NULL CHECK (desfecho IN ('alta', 'obito'))
);

CREATE TABLE episodio_vm (
    id_episodio_vm  INTEGER PRIMARY KEY,
    id_internacao   INTEGER NOT NULL,
    data_intubacao  DATE NOT NULL,
    data_extubacao  DATE,
    FOREIGN KEY (id_internacao) REFERENCES internacao(id_internacao),
    CHECK (data_extubacao IS NULL OR data_extubacao > data_intubacao)
);

CREATE TABLE avaliacao_mobilizacao (
    id_avaliacao    INTEGER PRIMARY KEY,
    id_internacao   INTEGER NOT NULL,
    data_avaliacao  DATE NOT NULL,
    codigo_nivel    INTEGER,
    mrc             INTEGER CHECK (mrc >= 0 AND mrc <= 60),
    FOREIGN KEY (id_internacao) REFERENCES internacao(id_internacao),
    FOREIGN KEY (codigo_nivel) REFERENCES dominio_nivel_mobilizacao(codigo_nivel)
);

CREATE TABLE dominio_nivel_mobilizacao (
    codigo_nivel  INTEGER PRIMARY KEY,
    descricao     TEXT NOT NULL
);

CREATE TABLE traqueostomia (
    id_tqt              INTEGER PRIMARY KEY,
    id_internacao       INTEGER NOT NULL,
    data_traqueostomia  DATE NOT NULL,
    FOREIGN KEY (id_internacao) REFERENCES internacao(id_internacao)
);