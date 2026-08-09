:r .\scripts\config.sql

USE [master];
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'$(LabDatabase)') IS NULL OR DB_ID(N'$(RestoreDatabase)') IS NULL
    THROW 51070, 'As bases afetada e recuperada devem existir para a validação.', 1;

CREATE TABLE #Validation
(
    DatabaseName sysname NOT NULL,
    TotalOrders int NOT NULL,
    CriticalOrderRows int NOT NULL
);

DECLARE @Sql nvarchar(max) =
    N'SELECT N''$(LabDatabase)'', COUNT(*), '
    + N'SUM(CASE WHEN OrderId = 1005 THEN 1 ELSE 0 END) '
    + N'FROM ' + QUOTENAME(N'$(LabDatabase)') + N'.dbo.Orders '
    + N'UNION ALL '
    + N'SELECT N''$(RestoreDatabase)'', COUNT(*), '
    + N'SUM(CASE WHEN OrderId = 1005 THEN 1 ELSE 0 END) '
    + N'FROM ' + QUOTENAME(N'$(RestoreDatabase)') + N'.dbo.Orders;';

INSERT #Validation (DatabaseName, TotalOrders, CriticalOrderRows)
EXEC sys.sp_executesql @Sql;

IF NOT EXISTS
(
    SELECT 1
    FROM #Validation
    WHERE DatabaseName = N'$(LabDatabase)'
      AND TotalOrders = 4
      AND CriticalOrderRows = 0
)
    THROW 51071, 'A base afetada não representa o incidente esperado.', 1;

IF NOT EXISTS
(
    SELECT 1
    FROM #Validation
    WHERE DatabaseName = N'$(RestoreDatabase)'
      AND TotalOrders = 5
      AND CriticalOrderRows = 1
)
    THROW 51072, 'A base restaurada não recuperou o pedido crítico esperado.', 1;

SELECT
    DatabaseName,
    TotalOrders,
    CriticalOrderRows,
    CASE
        WHEN DatabaseName = N'$(LabDatabase)' THEN N'Affected state retained for comparison'
        ELSE N'Point-in-time recovery validated'
    END AS validation_result
FROM #Validation
ORDER BY DatabaseName;

SELECT
    name,
    state_desc,
    recovery_model_desc
FROM sys.databases
WHERE name IN (N'$(LabDatabase)', N'$(RestoreDatabase)')
ORDER BY name;
GO
