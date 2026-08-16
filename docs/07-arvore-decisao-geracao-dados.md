# Etapa 6 — Árvore de Decisão para Geração dos Dados

## Primeira versão — estrutura lógica (sem percentuais)

Antes de aplicar os percentuais calibrados pela literatura, a lógica de decisão foi
estruturada apenas com a sequência de perguntas e dependências entre elas:

1. Gerar dados fixos da internação (idade, sexo, data_internacao)

2. Decidir participação no protocolo de mobilização (independente de VM)
   - se sim: gerar avaliação inicial no dia da internação, seguida de
     reavaliações a cada 48h até a alta/óbito (com possíveis NULLs em
     mrc/nivel se paciente RASS baixo)

3. Decidir se foi intubado
   - **SE NÃO INTUBADO:** segue direto para desfecho final (alta ou óbito)
   - **SE INTUBADO** (gera episódio 1 de VM):

     4. Consegue extubar dentro de ~14 dias, ou fica em VM prolongada sem nunca extubar?

        - **SE NUNCA EXTUBOU (VM prolongada):**
          - gera TQT (Caminho 2, ~14 dias após intubação)
          - episódio 1 permanece com data_extubacao = NULL
          - segue para desfecho (alta ou óbito, ainda dependente de VM/TQT)

        - **SE EXTUBOU** (dentro do episódio 1):

          5. Extubação teve sucesso ou falhou (reintubação em 48h)?

             - **SE SUCESSO:** segue direto para desfecho final (alta ou óbito)

             - **SE FALHOU** (gera episódio 2 de VM):

               6. Depois da falha, faz TQT ou tenta extubar novamente (2ª tentativa)?

                  - **SE TQT (Caminho 1):**
                    - episódio 2 permanece com data_extubacao = NULL
                    - segue para desfecho (alta ou óbito, ainda dependente de VM/TQT)

                  - **SE TENTA NOVAMENTE:**
                    - episódio 2 recebe data_extubacao preenchida
                    - resultado definido como sucesso (limite de 2 tentativas, sem
                      gerar 3º episódio)
                    - segue para desfecho final (alta ou óbito)

## Cálculo derivado: proporção de VM prolongada

O estudo de Aranha et al. (2007) informa que 16,84% de todos os pacientes ventilados
evoluem para traqueostomia — número que engloba os dois caminhos possíveis (falha de
extubação e VM prolongada) somados. Para decompor esse valor e isolar cada caminho,
foi feito o seguinte cálculo (base: 1.000 pacientes ventilados, para facilitar a
visualização):

1. Total de pacientes que fazem TQT (16,84% de 1.000): **~168**
2. Total de pacientes que falham a extubação (20% de 1.000): **~200**
3. Desses que falharam, quantos fazem TQT por causa da falha (55,8% de 200): **~112**
4. Como só existem dois caminhos possíveis para a TQT (falha ou VM prolongada), o
   número de TQT por VM prolongada é obtido por subtração: 168 − 112 = **~56**
5. Convertendo para percentual sobre o total de ventilados: 56 ÷ 1.000 = **~5,6%**

**Conclusão:** aproximadamente 5,6% dos pacientes ventilados entram no caminho de VM
prolongada (nunca extubam, evoluindo diretamente para TQT por volta de 14 dias).
Este valor é derivado matematicamente da matriz de calibração, não extraído
diretamente de um único artigo.

## Árvore de decisão final (com percentuais aplicados)

1. Decide se foi intubado (55,6% — Damasceno et al., 2006)

   - **SE NÃO INTUBADO:** desfecho direto (mortalidade ~5%)

   - **SE INTUBADO** (gera episódio 1 de VM):

     2. Decide se entra em VM prolongada, sem nunca extubar (5,6% — calculado)

        - **SE SIM (VM prolongada):**
          - faz TQT (considerado garantido para este grupo, por simplificação
            deliberada — é o próprio critério que define o grupo)
          - episódio 1 permanece com data_extubacao = NULL
          - desfecho (mortalidade ~20-25%)

        - **SE NÃO** (foi extubado dentro do episódio 1):

          3. Decide se houve falha de extubação (20% — estudo SC, 2021-2024)

             - **SE NÃO (sucesso):** desfecho direto (mortalidade ~10-15%)

             - **SE SIM** (falhou, gera episódio 2 de VM):

               4. Decide se faz TQT após a falha (55,8% — estudo JBP)

                  - **SE SIM:**
                    - episódio 2 permanece com data_extubacao = NULL
                    - desfecho (mortalidade ~20-25%)

                  - **SE NÃO** (tenta extubar novamente — 2ª e última tentativa
                    permitida):
                    - resultado definido como sucesso (simplificação: sem 3º
                      episódio)
                    - desfecho (mortalidade ~10-15%)

## Decisões de simplificação documentadas

- O número máximo de episódios de VM por internação foi limitado a 2 (uma eventual
  segunda falha não é modelada), por ser um cenário clinicamente raro e para manter
  a complexidade do gerador de dados sob controle.
- Todo paciente classificado no caminho de "VM prolongada" é considerado como tendo
  realizado traqueostomia, sem sorteio adicional — simplificação coerente com o
  próprio critério que define a entrada nesse grupo (14+ dias sem tentativa de
  extubação).
