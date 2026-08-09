:r .\scripts\config.sql

USE [msdb];
GO

SET NOCOUNT ON;

SELECT
    bs.database_name,
    CASE bs.type
        WHEN 'D' THEN 'FULL'
        WHEN 'I' THEN 'DIFFERENTIAL'
        WHEN 'L' THEN 'LOG'
        ELSE bs.type
    END AS backup_type,
    bs.backup_start_date,
    bs.backup_finish_date,
    CAST(bs.backup_size / 1048576.0 AS decimal(18, 2)) AS backup_size_mb,
    CAST(bs.compressed_backup_size / 1048576.0 AS decimal(18, 2)) AS compressed_size_mb,
    bs.has_backup_checksums,
    bmf.physical_device_name
FROM dbo.backupset AS bs
INNER JOIN dbo.backupmediafamily AS bmf
    ON bmf.media_set_id = bs.media_set_id
WHERE bs.database_name = N'$(LabDatabase)'
ORDER BY bs.backup_finish_date;

SELECT
    rh.destination_database_name,
    rh.restore_date,
    rh.restore_type,
    rh.replace,
    rh.stop_at,
    bs.database_name AS source_database,
    bs.backup_start_date,
    bs.backup_finish_date
FROM dbo.restorehistory AS rh
INNER JOIN dbo.backupset AS bs
    ON bs.backup_set_id = rh.backup_set_id
WHERE rh.destination_database_name = N'$(RestoreDatabase)'
ORDER BY rh.restore_date;
GO
