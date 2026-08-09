:r .\scripts\config.sql

USE [$(LabDatabase)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM dbo.Orders WHERE OrderId = 1005)
    THROW 51040, 'A transação crítica já existe.', 1;

INSERT dbo.Orders (OrderId, Description, Amount)
VALUES (1005, N'Critical order to recover', 999.99);
GO

USE [master];
GO

SET NOCOUNT ON;

DECLARE @FirstLogBackup nvarchar(4000) = N'$(FirstLogBackup)';

BACKUP LOG [$(LabDatabase)]
TO DISK = @FirstLogBackup
WITH
    INIT,
    CHECKSUM,
    COMPRESSION,
    STATS = 10,
    NAME = N'$(LabDatabase) - Log before incident';

SELECT
    @FirstLogBackup AS backup_file,
    N'Critical transaction committed and protected by log backup.' AS result;
GO
