/* SQL Server database health summary (read-only). */
SELECT
	d.name AS database_name,
    db_id(d.name) AS database_id,
	d.state_desc AS database_state,
	d.user_access_desc AS user_access,
	d.recovery_model_desc AS recovery_model,
	d.page_verify_option_desc AS page_verification,
	d.is_read_only,
	CAST(COALESCE(f.total_size_mb, 0) AS decimal(18, 2)) AS total_size_mb,
	b.last_full_backup,
	CASE
		WHEN b.last_full_backup IS NULL THEN 'No full backup recorded'
		WHEN b.last_full_backup < DATEADD(DAY, -7, GETDATE()) THEN 'Full backup older than 7 days'
		ELSE 'Full backup within 7 days'
	END AS backup_health
FROM sys.databases AS d
LEFT JOIN (
	SELECT database_id, SUM(size) * 8.0 / 1024 AS total_size_mb
	FROM sys.master_files
	GROUP BY database_id
) AS f ON f.database_id = d.database_id
OUTER APPLY (
	SELECT MAX(backup_finish_date) AS last_full_backup
	FROM msdb.dbo.backupset
	WHERE database_name = d.name
	  AND type = 'D'
) AS b


/* Run separately during a maintenance window to check one database's integrity:
   DBCC CHECKDB ([YourDatabaseName]) WITH NO_INFOMSGS;
*/
