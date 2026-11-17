/*
	SQL Server index fragmentation report
	Run in the database you want to inspect. This query is read-only.
*/

SELECT
	DB_NAME(ips.database_id) AS database_name,
	OBJECT_SCHEMA_NAME(ips.object_id, ips.database_id) AS schema_name,
	OBJECT_NAME(ips.object_id, ips.database_id) AS table_name,
	i.name AS index_name,
	ips.index_type_desc,
	ips.partition_number,
	ips.page_count,
	CAST(ips.avg_fragmentation_in_percent AS decimal(6, 2)) AS fragmentation_percent,
	CASE
		WHEN ips.avg_fragmentation_in_percent >= 30 THEN 'Consider REBUILD'
		WHEN ips.avg_fragmentation_in_percent >= 5 THEN 'Consider REORGANIZE'
		ELSE 'No action usually needed'
	END AS recommendation
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') AS ips
JOIN sys.indexes AS i
	ON i.object_id = ips.object_id
   AND i.index_id = ips.index_id
WHERE ips.index_id > 0             -- Exclude heaps
  AND ips.page_count >= 100        -- Ignore small indexes; adjust as needed
  AND i.name IS NOT NULL
ORDER BY DB_NAME(ips.database_id) DESC;

/* Sample result (values vary by database):

database_name  schema_name  table_name  index_name       index_type_desc  partition_number  page_count  fragmentation_percent  recommendation
-------------- ------------ ----------- ---------------- ---------------- ----------------- ----------  ----------------------  -------------------
SalesDB        dbo          Orders      IX_Orders_Date   NONCLUSTERED     1                 1250        34.72                  Consider REBUILD
SalesDB        dbo          Products    PK_Products      CLUSTERED        1                 420         12.15                  Consider REORGANIZE

The recommendation is informational only; this script does not alter indexes.
*/
