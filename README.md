# Jornada do Paciente na UTI

> ⚠️ **Dados fictícios.** Este projeto utiliza uma base de dados 100% sintética, gerada
> para fins acadêmicos e de portfólio. Nenhuma informação pertence a pacientes ou
> instituições de saúde reais. Ver seção [Sobre os dados](#sobre-os-dados) para
> detalhes de como a base foi calibrada.

📊 **[Acesse o dashboard interativo publicado](https://tinyurl.com/yysr35fr)**

---

## Sobre o autor e motivação

Meu nome é Carlos Henrique Freitas, sou fisioterapeuta intensivista com
mais de 10 anos de atuação em UTI, atualmente em transição de carreira para a área de
dados. Este é meu primeiro grande projeto de SQL — 100% autoral, desde a concepção da
ideia até a modelagem do banco, geração dos dados, análises e construção do dashboard.

A motivação nasceu da minha própria vivência profissional: em UTIs reais, indicadores
clínicos importantes (ventilação mecânica, mobilização precoce, sucesso de extubação,
traqueostomia) costumam ser analisados e registrados de forma isolada — muitas vezes
em planilhas ou sistemas diferentes que não "conversam" entre si. Isso impede
reconstruir a jornada completa de um paciente e entender como esses indicadores se
relacionam.

## O problema

Como perguntei a uma colega fisioterapeuta durante o desenvolvimento deste projeto:
*"você teria como responder, hoje, se pacientes que participam da mobilização
precoce têm menos falha de extubação, sem juntar várias planilhas manualmente?"* A
resposta foi não — *"temos os dados para isso, mas ainda não virou informação."*
Esse é exatamente o problema que este projeto se propõe a resolver.

## A solução

Um banco de dados relacional (SQLite), modelado do zero, que permite reconstruir a
jornada clínica completa de um paciente — desde a internação até o desfecho — e
responder, via SQL, perguntas de negócio que cruzam múltiplos indicadores
simultaneamente.

## Limitações do projeto

Antes de qualquer resultado, é importante deixar claras as limitações desta versão
(V1), para calibrar expectativas:

- **Dados fictícios**: gerados por simulação em Python, com proporções calibradas por
  literatura científica brasileira (não são dados reais de nenhuma instituição).
- **Sem histórico de reinternações**: cada linha do banco representa uma internação
  isolada; a mesma pessoa não é rastreada entre múltiplas internações nesta versão.
- **MRC gerado aleatoriamente**: o valor de força muscular (MRC) não possui lógica de
  evolução clínica nem associação com outras variáveis — uma pergunta de negócio
  sobre esse indicador foi formulada, testada e conscientemente descartada do escopo
  (ver `docs/08-perguntas-revisadas.md`).
- **Simplificações deliberadas de modelagem**: número máximo de 2 episódios de
  ventilação mecânica por internação, ausência de motivo de não-progressão na
  mobilização, entre outras — todas documentadas na pasta `docs/`.
- Uma lista completa de ideias fora do escopo atual está registrada como "V2" ao
  longo da documentação de cada etapa.

## Técnicas e tecnologias utilizadas

- **Modelagem relacional**: 5 entidades, com chaves primárias/estrangeiras,
  constraints (`CHECK`, `NOT NULL`), índices e justificativa documentada de cada
  decisão de design.
- **SQL avançado (SQLite)**: subqueries aninhadas, window functions (`LEAD() OVER`),
  `COALESCE`, agregação condicional (`SUM(CASE WHEN...)`), `UNION ALL`, Views.
- **Python**: geração de dataset sintético (1.000 internações) com árvore de decisão
  probabilística, calibrada por literatura científica.
- **Power BI**: dashboard com 3 páginas (capa de navegação, panorama assistencial
  agregado, e jornada individual navegável por prontuário), conectado ao banco via
  ODBC.
- **Git/GitHub**: versionamento incremental, com histórico de commits documentando
  cada etapa do desenvolvimento.

## Estrutura do repositório

```
├── docs/           → documentação de cada etapa (decisões, justificativas, limitações)
├── sql/            → scripts SQL (modelagem, consultas de análise, Views)
├── scripts/        → scripts Python de geração do dataset sintético
├── dashboard/       → arquivo do Power BI (.pbix)
├── data/           → banco de dados SQLite (uti.db)
```

Cada etapa do projeto está documentada em detalhe na pasta `docs/`, numerada
sequencialmente, incluindo o raciocínio por trás de cada decisão — desde a
modelagem conceitual até a construção do dashboard.

## Principais resultados

A pergunta central do projeto foi: **a mobilização precoce está associada a menor
tempo de ventilação mecânica e maior sucesso de extubação?**

| Indicador | Não participou do protocolo | Participou do protocolo |
|---|---|---|
| Tempo médio de permanência na UTI | 18 dias | 10 dias |
| Tempo médio em ventilação mecânica | 16 dias | 13 dias |
| Taxa de falha de extubação | 22,1% | 8,8% |

**Importante:** essas diferenças representam **associação**, não causalidade
comprovada. A probabilidade de participação no protocolo, nesta base, está
relacionada à gravidade clínica do paciente — pacientes mais graves participam menos
e, simultaneamente, têm maior propensão a desfechos desfavoráveis, independentemente
da mobilização. Essa ressalva é discutida em detalhe em `sql/07-consultas-analise.sql`
e no dashboard.

Outros achados:
- 66,4% dos pacientes participaram do protocolo de mobilização precoce.
- Entre os pacientes traqueostomizados, 64% chegaram a esse desfecho após uma falha
  de extubação prévia.

## Dashboard

O dashboard interativo, publicado no Power BI, está disponível em:
**[tinyurl.com/yysr35fr](https://tinyurl.com/yysr35fr)**

Estrutura:
1. **Capa** — navegação entre as duas páginas de análise.
2. **Panorama Assistencial** — indicadores agregados de 1.000 internações simuladas.
3. **Jornada Individual** — consulta da jornada clínica completa de um paciente
   específico, por número de prontuário, incluindo uma linha do tempo de eventos
   (internação, intubação, extubação, traqueostomia, desfecho).

## Sobre os dados

As proporções clínicas utilizadas na geração do dataset sintético (taxa de
ventilação mecânica, falha de extubação, traqueostomia, etc.) foram calibradas com
base em estudos científicos brasileiros publicados, listados com referência completa
em `docs/06-matriz-calibracao.md`. Isso inclui uma decisão consciente de não utilizar
dados observados na experiência profissional do autor, por prudência em relação à
identificação indireta do local de trabalho.

## Como reproduzir este projeto

```bash
# Clonar o repositório
git clone https://github.com/Finnagun/jornada-paciente-uti-sql.git
cd jornada-paciente-uti-sql

# Criar o banco a partir dos scripts SQL
sqlite3 data/uti.db ".read sql/03-modelagem-logica.sql"
sqlite3 data/uti.db ".read sql/04-indices.sql"
sqlite3 data/uti.db ".read sql/08-views.sql"

# Gerar o dataset sintético (1.000 pacientes)
cd scripts
py gerar_dataset.py
```

O arquivo do dashboard (`dashboard/jornada-paciente-uti.pbix`) pode ser aberto
diretamente no Power BI Desktop, com conexão ODBC ao banco `data/uti.db`.

---

*Projeto desenvolvido por Carlos Henrique Freitas como parte de estudos
independentes em SQL e análise de dados, com foco em aplicação prática na área da
saúde.*
