:r .\scripts\config.sql

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @ConfirmCleanup bit = 0;

IF @ConfirmCleanup <> 1
    THROW 51099, 'Limpeza bloqueada. Revise o script e altere @ConfirmCleanup para 1 conscientemente.', 1;

IF DB_ID(N'$(RestoreDatabase)') IS NOT NULL
BEGIN
    ALTER DATABASE [$(RestoreDatabase)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(RestoreDatabase)];
END;

IF DB_ID(N'$(LabDatabase)') IS NOT NULL
BEGIN
    ALTER DATABASE [$(LabDatabase)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$(LabDatabase)];
END;

SELECT N'Lab databases removed. Backup files were not deleted.' AS result;
GO
