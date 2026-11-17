# Registro de evidências de execução

Este repositório contém scripts e validação estática. Preencha este registro
somente após executar o laboratório em uma instância SQL Server isolada. Não
publique hostnames internos, caminhos sensíveis, credenciais ou dados reais.

## Ambiente

| Campo | Registro |
|---|---|
| Versão e edição do SQL Server | Não registrado |
| Sistema operacional | Não registrado |
| Data e fuso horário do teste | Não registrado |
| Bases de laboratório | `DBARecoveryLab` e `DBARecoveryLab_Restore` (nomes padrão) |
| Caminho de backup | Não registrado |
| Recovery model confirmado | Não registrado |

## Linha do tempo

| Evento | Horário observado e fuso |
|---|---|
| Início do backup full | Não registrado |
| Fim do backup full | Não registrado |
| Fim do backup diferencial | Não registrado |
| Fim do backup de log pré incidente | Não registrado |
| Exclusão simulada | Não registrado |
| Início do restore | Não registrado |
| Fim do restore e validação | Não registrado |

## Validação

- Registrar `backup_set_id`, tipos, datas e verificações consultadas em
  `msdb.dbo.backupset`, sem expor caminhos internos.
- Registrar o valor efetivo de `STOPAT` e confirmar que está antes da
  transação de exclusão simulada.
- Anexar a saída sanitizada de `07-validate-recovery.sql` e
  `08-audit-history.sql`.
- Confirmar que a base original foi preservada e que não houve `REPLACE`.

## Indicadores

- **RPO observado:** não medido. Calcular a diferença entre o último dado
  desejado e o último dado recuperado, conforme o cenário de teste.
- **RTO observado:** não medido. Definir início do incidente e fim da
  validação de serviço antes de calcular.
- **Resultado funcional:** ainda não publicado. A tabela do README descreve
  o resultado **esperado** pelos scripts, não uma execução comprovada.

Mantenha logs e capturas fora do repositório até revisar privacidade e
proveniência. A validação estática não substitui restore de teste.
