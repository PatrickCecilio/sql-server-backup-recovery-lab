:r .\scripts\config.sql

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @MajorVersion int = TRY_CONVERT(int, SERVERPROPERTY('ProductMajorVersion'));
DECLARE @Edition nvarchar(128) = CONVERT(nvarchar(128), SERVERPROPERTY('Edition'));
DECLARE @BackupDirectory nvarchar(4000) = N'$(BackupDirectory)';

IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
    THROW 51000, 'Execute o laboratório com um login sysadmin em uma instância isolada.', 1;

IF @MajorVersion IS NULL OR @MajorVersion < 15
    THROW 51001, 'Este laboratório requer SQL Server 2019 ou superior.', 1;

IF @Edition LIKE N'%Express%'
    THROW 51005, 'Use Developer, Standard ou Enterprise; o laboratório demonstra backup compression.', 1;

IF DB_ID(N'$(LabDatabase)') IS NOT NULL
    THROW 51002, 'A base de laboratório já existe. Nenhuma alteração foi realizada.', 1;

IF DB_ID(N'$(RestoreDatabase)') IS NOT NULL
    THROW 51003, 'A base de restore já existe. Nenhuma alteração foi realizada.', 1;

IF NULLIF(LTRIM(RTRIM(@BackupDirectory)), N'') IS NULL
    THROW 51004, 'Configure o diretório de backup antes de continuar.', 1;

SELECT
    @@SERVERNAME AS server_name,
    SERVERPROPERTY('ProductVersion') AS product_version,
    @Edition AS edition,
    @BackupDirectory AS configured_backup_directory,
    N'Preflight aprovado. Confirme manualmente o acesso da conta de serviço ao diretório.' AS result;
GO
