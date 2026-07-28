# Etapa 4 — Criação do Banco

## Ambiente

Banco criado com SQLite (versão 3.53.4), via linha de comando (`sqlite3`), a partir do
script `sql/03-modelagem-logica.sql`:

```bash
sqlite3 data/uti.db ".read sql/03-modelagem-logica.sql"
```

**Observação importante:** o suporte a Foreign Keys no SQLite vem desativado por
padrão, e essa configuração não é salva no arquivo do banco — precisa ser ativada em
toda nova sessão/conexão, antes de qualquer INSERT:

```sql
PRAGMA foreign_keys = ON;
```

## Testes de integridade realizados

Antes de popular o banco com o dataset real (Etapa 5/6), a modelagem foi validada na
prática com os seguintes testes manuais:

| # | Teste | Resultado esperado | Resultado obtido |
|---|-------|---------------------|-------------------|
| 1 | Inserir `episodio_vm` com `id_internacao` inexistente | Bloqueado (FK) | ✅ Bloqueado — `FOREIGN KEY constraint failed` |
| 2 | Inserir `internacao` com `genero = 'M'` | Bloqueado (CHECK) | ✅ Bloqueado — valor fora da lista permitida (`masculino`/`feminino`) |
| 3 | Inserir `episodio_vm` com `data_extubacao` anterior à `data_intubacao` | Bloqueado (CHECK) | ✅ Bloqueado — `CHECK constraint failed` |
| 4 | Inserir `episodio_vm` sem `data_extubacao` (paciente ainda intubado) | Aceito (NULL permitido) | ✅ Aceito normalmente |

Esses testes confirmam que:
- A integridade referencial entre tabelas está ativa e funcional.
- As regras de negócio (valores válidos de gênero/desfecho, coerência temporal entre
  intubação e extubação) estão corretamente implementadas via `CHECK`.
- O caso de paciente ainda em ventilação mecânica (dado incompleto por natureza, não
  por erro) é tratado corretamente, sem falso bloqueio.

Após os testes, os dados de exemplo foram removidos das tabelas (respeitando a ordem
filha → pai, por causa da FK) com `DELETE FROM episodio_vm;` seguido de
`DELETE FROM internacao;`, mantendo a estrutura das tabelas intacta para a inserção do
dataset definitivo.

## Índices

Criados dois índices na tabela `episodio_vm`, definidos em `sql/04-indices.sql`:

```sql
CREATE INDEX idx_episodio_vm_data_intubacao ON episodio_vm(data_intubacao);
CREATE INDEX idx_episodio_vm_data_extubacao ON episodio_vm(data_extubacao);
```

**Justificativa:** com um volume de dados de ~100 pacientes, o ganho de performance
real é praticamente imperceptível — a criação dos índices tem, neste projeto,
principalmente fins didáticos, demonstrando conhecimento de otimização de consultas em
colunas frequentemente utilizadas em filtros e cálculos (tempo em ventilação mecânica,
identificação de reintubações).