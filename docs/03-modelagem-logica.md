# Etapa 3 — Modelagem Lógica

## Convenções gerais do projeto

- **Datas:** todas as colunas de data são declaradas como `DATE` (por legibilidade e
  clareza para quem for ler o código), sempre armazenadas no formato ISO 8601
  (`AAAA-MM-DD`). O SQLite não possui um tipo `DATE` nativo (trata como afinidade de
  tipo), então essa consistência de formato é responsabilidade da aplicação/scripts
  de inserção, não do banco.
- **Texto sem acento/minúsculo:** campos categóricos (`genero`, `desfecho`) são
  armazenados em minúsculo e sem acento, para evitar inconsistências de comparação
  (`'Alta' != 'alta'`) e problemas de encoding. A formatação "bonita" para exibição
  fica a cargo da camada de visualização (BI).
- **Chaves primárias:** todas as tabelas transacionais (`internacao`, `episodio_vm`,
  `avaliacao_mobilizacao`, `traqueostomia`) usam `INTEGER PRIMARY KEY` com
  auto-incremento automático do SQLite, evitando erros manuais de numeração e
  duplicidade. A exceção é a tabela de domínio (`dominio_nivel_mobilizacao`), cujos
  códigos são atribuídos manualmente, pois representam uma escala clínica fixa e
  conhecida (4 níveis), sem previsão de crescimento dinâmico.
- **Foreign Keys no SQLite:** o suporte a chaves estrangeiras vem desativado por
  padrão no SQLite. Será necessário executar `PRAGMA foreign_keys = ON;` antes de
  qualquer inserção de dados (formalizado na Etapa 4).

---

## Tabela: internacao

```sql
CREATE TABLE internacao (
    id_internacao   INTEGER PRIMARY KEY,
    prontuario      INTEGER NOT NULL,
    data_nascimento DATE NOT NULL,
    genero          TEXT NOT NULL CHECK (genero IN ('masculino', 'feminino')),
    data_internacao DATE NOT NULL,
    data_desfecho   DATE NOT NULL,
    desfecho        TEXT NOT NULL CHECK (desfecho IN ('alta', 'obito'))
);
```

**Decisões e justificativas:**

- `prontuario` é mantido como atributo comum (não único na tabela), já que representa
  a pessoa, enquanto `id_internacao` representa o evento de internação em si. Uma
  mesma pessoa pode ter múltiplas internações ao longo do tempo — cenário fora do
  escopo do V1, mas preservado como possibilidade futura.
- `data_nascimento` foi escolhida no lugar de uma coluna de "idade" pronta, pois idade
  é um valor derivado que muda com o tempo, enquanto data de nascimento é um fato
  fixo. `NOT NULL`, pois é um dado de segurança do paciente, checado fisicamente
  (pulseira) antes de qualquer procedimento hospitalar.
- `genero` foi simplificado para masculino/feminino no V1 (representando sexo
  biológico, relevante para referências clínicas), reconhecendo que não contempla
  toda a diversidade de identidade de gênero. Ampliação prevista para uma futura V2.
- `data_internacao`, `data_desfecho` e `desfecho` são `NOT NULL` porque o escopo do
  projeto (V1) representa um **corte fechado**: todas as internações já possuem
  desfecho definido, refletindo a realidade de trabalho do autor, em que pacientes
  só entram na análise de indicadores após o desfecho já ter ocorrido.
  **Limitação documentada:** uma versão futura poderia incluir internações em
  andamento (sem desfecho), exigindo tratamento de valores nulos nos cálculos de
  tempo de permanência.
- `desfecho` possui `CHECK` restringindo os valores a `'alta'` ou `'obito'`, evitando
  inconsistências de digitação (ex: "Óbito", "obito", "morreu").

---

## Tabela: episodio_vm

```sql
CREATE TABLE episodio_vm (
    id_episodio_vm  INTEGER PRIMARY KEY,
    id_internacao   INTEGER NOT NULL,
    data_intubacao  DATE NOT NULL,
    data_extubacao  DATE,
    FOREIGN KEY (id_internacao) REFERENCES internacao(id_internacao),
    CHECK (data_extubacao IS NULL OR data_extubacao > data_intubacao)
);
```

**Decisões e justificativas:**

- Tabela filha: cada reintubação gera uma **nova linha**, permitindo múltiplos
  episódios de VM por internação. O sucesso/falha da extubação **não é armazenado**
  como campo — será calculado via SQL na Etapa 7, comparando a data de extubação de
  um episódio com a data de intubação do episódio seguinte da mesma internação
  (regra de negócio: falha = reintubação em até 48h).
- `id_internacao` é `NOT NULL`, pois um episódio de VM sem internação associada seria
  um registro "órfão", inútil para qualquer análise.
- `data_extubacao` **não** é `NOT NULL`, pois representa a possibilidade real de um
  paciente ainda estar em ventilação mecânica no momento do corte dos dados.
- O `CHECK` garante coerência temporal (extubação sempre após intubação), mas trata
  explicitamente o caso de `NULL` (`data_extubacao IS NULL OR ...`). Isso é
  necessário porque, embora o SQL trate comparações com `NULL` como `UNKNOWN` (o que
  já faria o `CHECK` aceitar a linha "por padrão"), depender desse comportamento
  implícito seria má prática — a condição explícita deixa a regra de negócio clara
  para qualquer leitor do código.
- Planeja-se criar índices em `data_intubacao` e `data_extubacao` na Etapa 4,
  principalmente para fins didáticos (demonstrar conhecimento de otimização de
  consultas), já que o volume de dados do projeto (~100 pacientes) não exige ganho
  real de performance.

---

## Tabela: avaliacao_mobilizacao

```sql
CREATE TABLE avaliacao_mobilizacao (
    id_avaliacao    INTEGER PRIMARY KEY,
    id_internacao   INTEGER NOT NULL,
    data_avaliacao  DATE NOT NULL,
    codigo_nivel    INTEGER,
    mrc             INTEGER CHECK (mrc >= 0 AND mrc <= 60),
    FOREIGN KEY (id_internacao) REFERENCES internacao(id_internacao),
    FOREIGN KEY (codigo_nivel) REFERENCES dominio_nivel_mobilizacao(codigo_nivel)
);
```

**Decisões e justificativas:**

- Tabela filha: cada avaliação (realizada a cada 48h) gera uma nova linha, refletindo
  a variação natural do tempo de internação de cada paciente.
- `mrc` (escala MRC-sum, de 0 a 60) possui `CHECK` limitando a faixa de valores
  válidos.
- Nem `codigo_nivel` nem `mrc` são `NOT NULL`: clinicamente, um paciente com RASS
  abaixo de 0/-1 não consegue ser avaliado quanto à força muscular ou nível de
  mobilização, mesmo participando do protocolo. Nesses casos, a linha existe
  (representando a tentativa de avaliação), mas os campos ficam `NULL`,
  representando genuinamente "não avaliado" — e não um valor zero forçado, que
  distorceria análises estatísticas (ex: médias de MRC).
- Pacientes que **nunca** participaram do protocolo de mobilização (não elegíveis)
  simplesmente **não possuem nenhuma linha** nesta tabela — a ausência de registro
  já representa a ausência de participação, evitando ambiguidade em consultas com
  `LEFT JOIN`.

---

## Tabela: dominio_nivel_mobilizacao

```sql
CREATE TABLE dominio_nivel_mobilizacao (
    codigo_nivel  INTEGER PRIMARY KEY,
    descricao     TEXT NOT NULL
);
```

**Decisões e justificativas:**

- Tabela de domínio/referência (lookup), evitando repetição de texto descritivo em
  toda linha da tabela de avaliações e centralizando qualquer futura correção de
  descrição em um único lugar.
- Códigos atribuídos manualmente (1 a 4), pois representam uma escala clínica
  estabelecida (Escala de Mobilidade em UTI), sem previsão de novos níveis.
- O detalhamento completo de cada nível (os itens que compõem cada categoria) fica
  documentado separadamente como dicionário de dados, podendo ser reaproveitado
  futuramente como tooltip explicativo no dashboard de BI.

---

## Tabela: traqueostomia

```sql
CREATE TABLE traqueostomia (
    id_tqt              INTEGER PRIMARY KEY,
    id_internacao       INTEGER NOT NULL,
    data_traqueostomia  DATE NOT NULL,
    FOREIGN KEY (id_internacao) REFERENCES internacao(id_internacao)
);
```

**Decisões e justificativas:**

- Tabela filha, mas com cardinalidade opcional do lado da internação (0 ou 1 TQT por
  internação — nunca mais que uma, na realidade atual do autor, em que pacientes não
  são decanulados ainda na UTI). Apenas internações que de fato realizaram o
  procedimento possuem linha nesta tabela.
- `data_traqueostomia` é suficiente para responder à pergunta de negócio sobre
  histórico de falha de extubação prévia à TQT, ao ser comparada com as datas de
  `episodio_vm` da mesma internação.