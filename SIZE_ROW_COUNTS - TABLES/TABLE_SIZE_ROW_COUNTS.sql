USE YourDbName
GO

-- Get Table names, row counts, and compression status for clustered index or heap  (Query 56) (Table Sizes)
SELECT 
                  s.name AS [SchemaName]
                , OBJECT_NAME(p.object_id) AS [ObjectName]
                , SUM(p.Rows) AS [RowCount]
                , p.data_compression_desc AS [CompressionType]

FROM 
                sys.tables t
INNER JOIN      sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN      sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN      sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id

WHERE           p.index_id < 2 --ignore the partitions from the non-clustered index if any
AND             OBJECT_NAME(p.object_id) IN 
(
'TableName'
)

GROUP BY p.object_id, p.data_compression_desc, s.name
ORDER BY SUM(p.Rows) DESC 
OPTION (RECOMPILE);