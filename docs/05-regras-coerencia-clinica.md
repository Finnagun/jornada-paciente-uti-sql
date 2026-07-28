# Etapa 5 — Regras de Coerência Clínica

Este documento consolida as regras de negócio que garantem que o dataset fictício,
mesmo sendo gerado artificialmente, respeite a lógica clínica real de uma UTI. Essas
regras servem como especificação para o script de geração de dados (Etapa 6) e como
verificações de consistência que podem ser auditadas via SQL após a geração.

## Sobre as proporções utilizadas

As proporções abaixo foram calibradas com base na experiência profissional do autor
como fisioterapeuta intensivista, com mais de 10 anos de atuação em UTI — não
representam dados oficiais, auditados ou publicados de nenhuma instituição específica.
São estimativas pessoais, usadas apenas para dar plausibilidade estatística ao
dataset fictício.

## Regras de coerência — Ventilação Mecânica e Traqueostomia

1. **Intubação:** aproximadamente 20% dos pacientes internados são submetidos à
   ventilação mecânica invasiva (gera a primeira linha em `episodio_vm`).

2. **Falha de extubação:** dos pacientes intubados, aproximadamente 37,5% apresentam
   falha de extubação (definida como reintubação em até 48h), gerando uma nova linha
   em `episodio_vm` para o mesmo `id_internacao`.

3. **Traqueostomia — dois caminhos possíveis:**
   - **Caminho 1 (pós-falha):** de quem falhou a extubação, aproximadamente 50%
     evolui para traqueostomia (ao invés de conseguir extubar com sucesso em uma
     tentativa posterior).
   - **Caminho 2 (VM prolongada sem falha prévia):** pacientes que permanecem
     intubados continuamente por volta de 14 dias ou mais, sem nunca terem sido
     extubados, também podem evoluir para traqueostomia, mesmo sem episódio de falha
     registrado.

4. **Traqueostomia não é extubação:** quando um paciente é traqueostomizado, ele
   permanece dependente de suporte ventilatório. Portanto, o episódio de VM
   correspondente mantém `data_extubacao = NULL`, mesmo após a TQT — a saída do
   suporte ventilatório não é registrada como extubação nesses casos.

5. **Interpretação do NULL em `data_extubacao`:** um valor nulo nessa coluna pode
   significar dois cenários distintos, diferenciáveis por cruzamento com outras
   tabelas:
   - Existe registro correspondente em `traqueostomia` → paciente foi traqueostomizado
     ainda dependente de VM.
   - Não existe registro em `traqueostomia` → só é clinicamente coerente se
     `desfecho = 'obito'` na tabela `internacao` (paciente foi a óbito ainda
     intubado, sem chegar a extubar ou realizar TQT).

6. **Inconsistência a ser evitada na geração de dados:** nunca deve existir um
   registro com `data_extubacao = NULL`, sem traqueostomia associada, e
   `desfecho = 'alta'` — esse cenário não é clinicamente possível (nenhum paciente
   recebe alta da UTI ainda intubado, sem extubação ou TQT prévias).