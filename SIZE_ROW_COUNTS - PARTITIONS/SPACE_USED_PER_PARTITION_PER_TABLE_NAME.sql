SELECT 
	ISNULL(quotename(ix.name),'Heap') as IndexName 
	, ix.type_desc as type
	, prt.partition_number
	, prt.data_compression_desc
	, ps.name as PartitionScheme
	, pf.name as PartitionFunction
	, fg.name as FilegroupName
	, case when ix.index_id < 2 then prt.rows else 0 END as Rows
	, au.TotalMB
	, au.UsedMB
	, st.name AS [TableName]
	, c.name AS [ColumnName]
	, case when pf.boundary_value_on_right = 1 then 'less than' when pf.boundary_value_on_right is null then '' else 'less than or equal to' End as Comparison
	, rv.value
FROM 
	sys.partitions prt
	inner join sys.indexes ix on ix.object_id = prt.object_id and ix.index_id = prt.index_id
	
	INNER JOIN sys.tables st ON prt.object_id = st.object_id
	INNER JOIN sys.index_columns ic ON (ic.partition_ordinal > 0 AND ic.index_id = ix.index_id AND ic.object_id = st.object_id)
	INNER JOIN sys.columns c ON (c.object_id = ic.object_id AND c.column_id = ic.column_id)
	
	inner join sys.data_spaces ds on ds.data_space_id = ix.data_space_id
	left join sys.partition_schemes ps on ps.data_space_id = ix.data_space_id
	left join sys.partition_functions pf on pf.function_id = ps.function_id
	left join sys.partition_range_values rv on rv.function_id = pf.function_id AND rv.boundary_id = prt.partition_number
	left join sys.destination_data_spaces dds on dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = prt.partition_number
	left join sys.filegroups fg on fg.data_space_id = ISNULL(dds.data_space_id,ix.data_space_id) 
	inner join (
					select 
						str(sum(total_pages)*8./1024,10,2) as [TotalMB],str(sum(used_pages)*8./1024,10,2) as [UsedMB]
						,container_id
					from sys.allocation_units
					group by container_id
				) au
				on au.container_id = prt.partition_id

WHERE st.name IN ('YourTableName')
ORDER BY ix.type_desc;