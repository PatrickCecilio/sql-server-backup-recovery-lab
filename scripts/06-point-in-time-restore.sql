:r .\scripts\config.sql

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'$(LabDatabase)') IS NULL
    THROW 51060, 'A base de origem do laboratório não existe.', 1;

IF DB_ID(N'$(RestoreDatabase)') IS NOT NULL
    THROW 51061, 'A base de restore já existe. O script não usa REPLACE.', 1;

DECLARE @RecoveryPoint datetime2(3);
DECLARE @CheckpointSql nvarchar(max) =
    N'SELECT @Point = MAX(RecoveryPoint) FROM '
    + QUOTENAME(N'$(LabDatabase)')
    + N'.dbo.RecoveryCheckpoint;';

EXEC sys.sp_executesql
    @CheckpointSql,
    N'@Point datetime2(3) OUTPUT',
    @Point = @RecoveryPoint OUTPUT;

IF @RecoveryPoint IS NULL
    THROW 51062, 'Nenhum ponto de recuperação foi registrado.', 1;

DECLARE @FullBackup nvarchar(4000) = N'$(FullBackup)';
DECLARE @DifferentialBackup nvarchar(4000) = N'$(DifferentialBackup)';
DECLARE @FirstLogBackup nvarchar(4000) = N'$(FirstLogBackup)';
DECLARE @IncidentLogBackup nvarchar(4000) = N'$(IncidentLogBackup)';
DECLARE @RestoreDatabase sysname = N'$(RestoreDatabase)';
DECLARE @SourceDatabase sysname = N'$(LabDatabase)';
DECLARE @SourceDataLogical sysname;
DECLARE @SourceLogLogical sysname;

SELECT @SourceDataLogical = name
FROM sys.master_files
WHERE database_id = DB_ID(@SourceDatabase)
  AND type = 0
  AND file_id = 1;

SELECT @SourceLogLogical = name
FROM sys.master_files
WHERE database_id = DB_ID(@SourceDatabase)
  AND type = 1
  AND file_id = 2;

IF @SourceDataLogical IS NULL OR @SourceLogLogical IS NULL
    THROW 51063, 'Não foi possível determinar os nomes lógicos dos arquivos de origem.', 1;

DECLARE @DataPath nvarchar(4000) = CONVERT(nvarchar(4000), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @LogPath nvarchar(4000) = CONVERT(nvarchar(4000), SERVERPROPERTY('InstanceDefaultLogPath'));

IF @DataPath IS NULL OR @LogPath IS NULL
    THROW 51064, 'A instância não informou os diretórios padrão de dados e log.', 1;

DECLARE @Separator nchar(1) = CASE WHEN CHARINDEX(N'/', @DataPath) > 0 THEN N'/' ELSE N'\' END;

IF RIGHT(@DataPath, 1) NOT IN (N'\', N'/')
    SET @DataPath += @Separator;

IF RIGHT(@LogPath, 1) NOT IN (N'\', N'/')
    SET @LogPath += @Separator;

DECLARE @RestoreDataFile nvarchar(4000) = @DataPath + @RestoreDatabase + N'.mdf';
DECLARE @RestoreLogFile nvarchar(4000) = @LogPath + @RestoreDatabase + N'_log.ldf';
DECLARE @Sql nvarchar(max);

SET @Sql =
    N'RESTORE DATABASE ' + QUOTENAME(@RestoreDatabase)
    + N' FROM DISK = N''' + REPLACE(@FullBackup, N'''', N'''''') + N''''
    + N' WITH MOVE N''' + REPLACE(@SourceDataLogical, N'''', N'''''') + N''' TO N'''
    + REPLACE(@RestoreDataFile, N'''', N'''''') + N''','
    + N' MOVE N''' + REPLACE(@SourceLogLogical, N'''', N'''''') + N''' TO N'''
    + REPLACE(@RestoreLogFile, N'''', N'''''') + N''','
    + N' NORECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @Sql;

SET @Sql =
    N'RESTORE DATABASE ' + QUOTENAME(@RestoreDatabase)
    + N' FROM DISK = N''' + REPLACE(@DifferentialBackup, N'''', N'''''') + N''''
    + N' WITH NORECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @Sql;

SET @Sql =
    N'RESTORE LOG ' + QUOTENAME(@RestoreDatabase)
    + N' FROM DISK = N''' + REPLACE(@FirstLogBackup, N'''', N'''''') + N''''
    + N' WITH NORECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @Sql;

SET @Sql =
    N'RESTORE LOG ' + QUOTENAME(@RestoreDatabase)
    + N' FROM DISK = N''' + REPLACE(@IncidentLogBackup, N'''', N'''''') + N''''
    + N' WITH STOPAT = N''' + CONVERT(nvarchar(30), @RecoveryPoint, 126) + N''','
    + N' RECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @Sql;

SELECT
    @RestoreDatabase AS restored_database,
    @RecoveryPoint AS stop_at,
    @RestoreDataFile AS restored_data_file,
    @RestoreLogFile AS restored_log_file,
    DATABASEPROPERTYEX(@RestoreDatabase, 'Status') AS database_status;
GO
