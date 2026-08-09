:r .\scripts\config.sql

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'$(LabDatabase)') IS NOT NULL
    THROW 51010, 'A base de laboratório já existe. O script não sobrescreve bases existentes.', 1;
GO

CREATE DATABASE [$(LabDatabase)];
GO

ALTER DATABASE [$(LabDatabase)] SET RECOVERY FULL;
GO

USE [$(LabDatabase)];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

CREATE TABLE dbo.Orders
(
    OrderId int NOT NULL CONSTRAINT PK_Orders PRIMARY KEY,
    Description nvarchar(200) NOT NULL,
    Amount decimal(12, 2) NOT NULL,
    CreatedAt datetime2(3) NOT NULL
        CONSTRAINT DF_Orders_CreatedAt DEFAULT SYSDATETIME()
);

CREATE TABLE dbo.RecoveryCheckpoint
(
    CheckpointId int IDENTITY(1, 1) NOT NULL
        CONSTRAINT PK_RecoveryCheckpoint PRIMARY KEY,
    RecoveryPoint datetime2(3) NOT NULL,
    Description nvarchar(200) NOT NULL,
    RecordedAt datetime2(3) NOT NULL
        CONSTRAINT DF_RecoveryCheckpoint_RecordedAt DEFAULT SYSDATETIME()
);

INSERT dbo.Orders (OrderId, Description, Amount)
VALUES
    (1001, N'Baseline order 1', 125.00),
    (1002, N'Baseline order 2', 250.00),
    (1003, N'Baseline order 3', 375.00);

SELECT
    DB_NAME() AS database_name,
    CAST(DATABASEPROPERTYEX(DB_NAME(), 'Recovery') AS nvarchar(60)) AS recovery_model,
    (SELECT COUNT(*) FROM dbo.Orders) AS initial_rows;
GO
