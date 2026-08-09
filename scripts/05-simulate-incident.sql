:r .\scripts\config.sql

USE [$(LabDatabase)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.Orders WHERE OrderId = 1005)
    THROW 51050, 'O pedido crítico não existe. Execute a cadeia anterior na ordem indicada.', 1;

IF EXISTS (SELECT 1 FROM dbo.RecoveryCheckpoint)
    THROW 51051, 'O checkpoint do incidente já foi registrado.', 1;

DECLARE @RecoveryPoint datetime2(3) = SYSDATETIME();

INSERT dbo.RecoveryCheckpoint (RecoveryPoint, Description)
VALUES (@RecoveryPoint, N'Point immediately before accidental deletion');

WAITFOR DELAY '00:00:02';

DELETE dbo.Orders
WHERE OrderId = 1005;

IF @@ROWCOUNT <> 1
    THROW 51052, 'A simulação não excluiu exatamente uma linha.', 1;

SELECT
    @RecoveryPoint AS recovery_point,
    COUNT(*) AS rows_after_incident,
    SUM(CASE WHEN OrderId = 1005 THEN 1 ELSE 0 END) AS critical_order_rows
FROM dbo.Orders;
GO

USE [master];
GO

SET NOCOUNT ON;

DECLARE @IncidentLogBackup nvarchar(4000) = N'$(IncidentLogBackup)';

BACKUP LOG [$(LabDatabase)]
TO DISK = @IncidentLogBackup
WITH
    INIT,
    CHECKSUM,
    COMPRESSION,
    STATS = 10,
    NAME = N'$(LabDatabase) - Log containing incident';

SELECT
    @IncidentLogBackup AS backup_file,
    N'Incident captured in transaction log.' AS result;
GO
