USE [PartitionTesting]
GO

SELECT      sps.name AS [Name]
            ,sps.data_space_id AS [ID]
            ,spf.name AS [PartitionFunction]
            ,ISNULL((case when spf.fanout < (select count(*) from sys.destination_data_spaces sdd where sps.data_space_id = sdd.partition_scheme_id) then (select sf.name from sys.filegroups sf, sys.destination_data_spaces sdd where sf.data_space_id = sdd.data_space_id and sps.data_space_id = sdd.partition_scheme_id and sdd.destination_id > spf.fanout) else null end),N'') AS [NextUsedFileGroup]
FROM        sys.partition_schemes AS sps
INNER JOIN sys.partition_functions AS spf ON sps.function_id = spf.function_id 
WHERE       (sps.name = N'ps_daily_date')

SELECT      sdd.destination_id AS [ID]
            ,sf.name AS [Name]
FROM        sys.partition_schemes AS sps
INNER JOIN  sys.partition_functions AS spf ON sps.function_id = spf.function_id 
INNER JOIN  sys.destination_data_spaces AS sdd ON sdd.partition_scheme_id = sps.data_space_id and sdd.destination_id <= spf.fanout
INNER JOIN  sys.filegroups AS sf ON sf.data_space_id = sdd.data_space_id
WHERE       (sps.name = N'ps_daily_date')
ORDER BY    [ID] ASC