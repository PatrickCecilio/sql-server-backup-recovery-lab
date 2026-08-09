# Troubleshooting

## Operating system error 5: Access is denied

O caminho existe, mas a conta de serviço do SQL Server não possui permissão de leitura ou escrita. Conceda acesso à identidade que executa o mecanismo de banco de dados, não apenas ao usuário conectado ao Windows.

## Cannot open backup device

Revise o caminho em `scripts/config.sql`. O arquivo é acessado pelo host do SQL Server. Em uma conexão remota, um caminho local da estação do operador não representa o filesystem do servidor.

## BACKUP LOG cannot be performed because there is no current database backup

O recovery model foi alterado para `FULL`, mas a cadeia ainda não foi iniciada. Execute `02-full-backup.sql` antes dos backups de log.

## The log in this backup set begins at an LSN too recent

A cadeia foi aplicada fora de ordem ou algum arquivo não pertence ao mesmo ciclo. Recrie o laboratório e aplique full, diferencial, primeiro log e log do incidente exatamente nessa sequência.

## STOPAT is too early

O instante selecionado não está contido nos logs aplicados. Confirme o checkpoint registrado em `dbo.RecoveryCheckpoint` e o intervalo dos backups em `msdb.dbo.backupset`.

## Exclusive access could not be obtained

A base restaurada já existe ou possui conexões ativas. O laboratório foi projetado para falhar quando a base de destino existe. Revise o ambiente e use o script de limpeza somente após confirmar que se trata das bases isoladas do projeto.

## RESTORE VERIFYONLY foi bem-sucedido, mas o restore falhou

`RESTORE VERIFYONLY` valida a legibilidade e a estrutura do backup, mas não substitui um teste completo de restore. Verifique espaço em disco, permissões, caminhos de destino e toda a cadeia de logs.

## SQLCMD variables are not substituted

No SQL Server Management Studio, habilite **Query > SQLCMD Mode**. Pela linha de comando, execute os scripts com `sqlcmd -i` a partir da raiz do repositório.
