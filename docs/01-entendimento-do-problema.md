# Etapa 1 — Entendimento do Problema

## Contexto
Projeto autoral de portfólio, criado por um fisioterapeuta intensivista em transição para 
Análise de Dados. O banco é totalmente fictício (não usa dados reais do hospital, por LGPD),
mas modelado com base em situações clínicas reais de UTI.

## Problema de negócio
Indicadores de UTI (mobilização precoce, ventilação mecânica, desmame, extubação,
traqueostomia, funcionalidade) normalmente são analisados de forma isolada, em planilhas
separadas. Isso impede reconstruir a jornada completa do paciente e entender relações entre
esses indicadores.

## Pergunta clínica central
A mobilização precoce está associada a menor tempo de ventilação mecânica e maior sucesso
de extubação?

## Perguntas adicionais mapeadas
1. Existe associação entre MRC baixo e histórico de IOT?
   ⚠️ Ressalva: não implica causalidade — múltiplos fatores de confusão (comorbidades,
   gravidade de base, tipo de doença, etc.) não são capturados no escopo deste projeto.
   A literatura também não costuma analisar essa relação de forma isolada.
2. Quantos pacientes participaram do protocolo de mobilização precoce? Quantos não
   participaram por terem tido alta antes da primeira avaliação (48h)?
3. Pacientes traqueostomizados tiveram falha de extubação prévia? Quantas tentativas de
   VM tiveram antes da TQT?

## Regra de negócio definida
**Falha de extubação** = reintubação em até 48 horas após a extubação.

## Escopo do projeto (V1) — 5 entidades

| # | Entidade | Observação |
|---|----------|------------|
| 1 | Internação | Tabela principal. PK: `id_internacao`. Contém `prontuario` como atributo (não é único na tabela — permite representar futuras reinternações da mesma pessoa, mesmo que essa relação não seja explorada no V1). |
| 2 | Episódios de Ventilação Mecânica | Tabela filha — pode haver múltiplas linhas por internação (reintubações). |
| 3 | Avaliações de Mobilização/Funcionalidade | Tabela filha — repete a cada 48h (nível de mobilização, MRC, marcos como sentar/ficar em pé). |
| 4 | Domínio: Níveis de Mobilização | Tabela de referência (lookup), evita repetição de descrição dos níveis. |
| 5 | Traqueostomia | Tabela filha — só existe registro para quem realizou o procedimento. |

## Decisões de modelagem já justificadas
- **Pai/filho:** dados que se repetem ao longo da internação (VM, mobilização) viram
  tabelas filhas, ligadas por `id_internacao`, evitando redundância e excesso de NULLs.
- **Internação vs. Pessoa:** optou-se por simplificar tratando cada linha como uma
  internação (não uma pessoa), aceitando a limitação de não representar reinternações
  no V1. O campo `prontuario` fica guardado como atributo para uso futuro.
- **Chave primária:** `id_internacao` foi escolhida como PK por ser sempre única na
  tabela — diferente de `prontuario`, que é único no mundo real mas pode se repetir
  na tabela caso a mesma pessoa interne mais de uma vez.
- **Tabela de domínio (níveis de mobilização):** separada da tabela de avaliação para
  facilitar manutenção — se a definição de um nível mudar, corrige-se em um único lugar.

## Fora de escopo — ideias para V2
- Motivo de não progressão na mobilização (instabilidade, sedação, recusa, etc.)
- Protocolo de cardio
- CNAF
- PAV (pneumonia associada à ventilação)
- EOT acidental
- Quedas
- Separação Pessoa x Internação (para representar reinternações de fato)
- Detalhamento do momento do óbito (durante VM, pós-TQT, etc.)