USE SSISDB
GO

DECLARE @PackageName NVARCHAR(256) = 'REF_DIP_CustomerAccount_BSL PT001.dtsx'
DECLARE @DateSince DATE = GETDATE() - 30

SELECT
    ei.execution_id,
    ei.folder_name,
    ei.project_name,
    ei.package_name,
    ei.environment_folder_name,
    ei.environment_name,
    CAST(ei.start_time AS datetime) AS start_time,
    DATEDIFF(MINUTE, ei.start_time, ei.end_time) AS [execution_time (min)],
    ei.executed_as_name,
    ei.use32bitruntime,
    ei.operation_type,
    ei.created_time,
    ei.object_type,
    ei.status

FROM SSISDB.internal.execution_info ei
WHERE
        ei.package_name = @PackageName AND
        ei.start_time >= @DateSince --AND

-- status:
-- 4 = FAILED
-- 2 = RUNNING
-- 3 = CANCELLED
-- 5 = ABOUT TO BE RUN

/*
created (1), running (2), canceled (3), failed (4), pending (5), ended unexpectedly (6), succeeded (7), stopping (8), and completed (9).
*/

ORDER BY ei.start_time DESC