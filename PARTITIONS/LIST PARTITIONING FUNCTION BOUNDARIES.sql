USE [PartitionTesting]
GO

SELECT          spp.parameter_id                AS [ParameterID]
                ,baset.[name]                   AS [FunctionDataType]
FROM            sys.partition_functions         AS [spf]
INNER JOIN      sys.partition_parameters        AS [spp]    ON spp.function_id=spf.function_id
INNER JOIN      sys.types                       AS [st]     ON st.system_type_id = st.user_type_id and spp.system_type_id = st.system_type_id
LEFT OUTER JOIN sys.types                       AS [baset]  ON (baset.user_type_id = spp.system_type_id and baset.user_type_id = baset.system_type_id) or ((baset.system_type_id = spp.system_type_id) and (baset.user_type_id = spp.user_type_id) and (baset.is_user_defined = 0) and (baset.is_assembly_type = 1)) 
WHERE           (spf.name = N'pf_daily_date')
ORDER BY [ParameterID] ASC

SELECT          sprv.boundary_id            AS [RangeID]
                ,sprv.value                 AS [RangeValue]
                --,LEFT(CONVERT(VARCHAR, sprv.value, 112),6)
FROM            sys.partition_functions AS spf
INNER JOIN      sys.partition_range_values sprv ON sprv.function_id=spf.function_id
WHERE           (spf.name = N'pf_daily_date')
ORDER BY        [RangeID] ASC