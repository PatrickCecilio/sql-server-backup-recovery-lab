# Runbook do laboratório

## 1. Preparar o diretório de backup

Crie o caminho configurado em `scripts/config.sql` no host do SQL Server e conceda leitura e escrita à conta de serviço do mecanismo de banco de dados.

O caminho padrão para Windows é:

```text
C:\SQLBackups\DBARecoveryLab
```

Para SQL Server no Linux, altere todas as variáveis de caminho para um diretório acessível pelo serviço `mssql`, como:

```text
/var/opt/mssql/backups/DBARecoveryLab
```

## 2. Revisar a configuração

Confirme em `scripts/config.sql`:

- nome da base de laboratório;
- nome da base restaurada;
- caminhos dos arquivos full, diferencial e log;
- compatibilidade dos caminhos com o sistema operacional da instância.

## 3. Executar o preflight

```powershell
sqlcmd -S localhost -E -b -i scripts/00-preflight.sql
```

O preflight confirma a versão, a permissão administrativa e a ausência das bases que serão criadas.

## 4. Criar a base isolada

```powershell
sqlcmd -S localhost -E -b -i scripts/01-create-lab.sql
```

Resultado esperado:

- base em recovery model `FULL`;
- tabela `dbo.Orders` com três linhas iniciais;
- tabela `dbo.RecoveryCheckpoint` pronta para registrar o ponto de recuperação.

## 5. Construir a cadeia de backups

```powershell
sqlcmd -S localhost -E -b -i scripts/02-full-backup.sql
sqlcmd -S localhost -E -b -i scripts/03-differential-backup.sql
sqlcmd -S localhost -E -b -i scripts/04-log-backup.sql
```

Ao final, a cadeia contém:

1. backup full;
2. backup diferencial após a quarta linha;
3. backup de log contendo o pedido crítico `1005`.

## 6. Simular o incidente

```powershell
sqlcmd -S localhost -E -b -i scripts/05-simulate-incident.sql
```

O script registra um checkpoint, aguarda dois segundos, exclui o pedido crítico e cria o log que contém o incidente.

## 7. Recuperar para outra base

```powershell
sqlcmd -S localhost -E -b -i scripts/06-point-in-time-restore.sql
```

Sequência aplicada:

1. full com `NORECOVERY` e `MOVE`;
2. diferencial com `NORECOVERY`;
3. primeiro log com `NORECOVERY`;
4. log do incidente com `STOPAT` e `RECOVERY`.

## 8. Validar o resultado

```powershell
sqlcmd -S localhost -E -b -i scripts/07-validate-recovery.sql
sqlcmd -S localhost -E -b -i scripts/08-audit-history.sql
```

A validação exige que o pedido `1005` esteja ausente na origem afetada e presente na base recuperada.

## 9. Limpeza opcional

Abra `scripts/99-cleanup.sql`, revise os nomes e altere temporariamente:

```sql
DECLARE @ConfirmCleanup bit = 0;
```

para:

```sql
DECLARE @ConfirmCleanup bit = 1;
```

Execute o script e reverta a variável para `0` antes de qualquer commit.
