:r .\scripts\config.sql

USE [$(LabDatabase)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF EXISTS (SELECT 1 FROM dbo.Orders WHERE OrderId = 1004)
    THROW 51030, 'A alteração anterior ao backup diferencial já foi aplicada.', 1;

INSERT dbo.Orders (OrderId, Description, Amount)
VALUES (1004, N'Order captured by differential backup', 500.00);
GO

USE [master];
GO

SET NOCOUNT ON;

DECLARE @DifferentialBackup nvarchar(4000) = N'$(DifferentialBackup)';

BACKUP DATABASE [$(LabDatabase)]
TO DISK = @DifferentialBackup
WITH
    DIFFERENTIAL,
    INIT,
    CHECKSUM,
    COMPRESSION,
    STATS = 10,
    NAME = N'$(LabDatabase) - Differential';

SELECT
    @DifferentialBackup AS backup_file,
    N'Differential backup created.' AS result;
GO
