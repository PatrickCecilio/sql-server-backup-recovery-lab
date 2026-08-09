:r .\scripts\config.sql

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'$(LabDatabase)') IS NULL
    THROW 51020, 'A base de laboratório não existe.', 1;

DECLARE @FullBackup nvarchar(4000) = N'$(FullBackup)';

BACKUP DATABASE [$(LabDatabase)]
TO DISK = @FullBackup
WITH
    INIT,
    CHECKSUM,
    COMPRESSION,
    STATS = 10,
    NAME = N'$(LabDatabase) - Full';

RESTORE VERIFYONLY
FROM DISK = @FullBackup
WITH CHECKSUM;

SELECT
    @FullBackup AS backup_file,
    N'Full backup created and verified.' AS result;
GO
