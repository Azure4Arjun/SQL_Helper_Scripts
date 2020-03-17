-- SQL Server 2012 SSISDB Catalog query
-- https://msdn.microsoft.com/en-us/library/hh479588(v=sql.110).aspx
-- Phil Streiff, MCDBA, MCITP, MCSA
-- 09/08/2016
USE [SSISDB];
GO

DECLARE @ProjectName NVARCHAR(256) = 'ProjectName'

SELECT TOP 20 
	pk.project_id,
	pj.name 'folder', 
	pk.name, 
	pj.deployed_by_name 'deployed_by' ,
	pj.created_time,
	pj.last_deployed_time,
	pj.object_version_lsn,
    pk.version_major,
    pk.version_minor,
    pk.version_build

FROM
	catalog.packages pk JOIN catalog.projects pj 
	ON (pk.project_id = pj.project_id)
WHERE 
	pj.name IN (@ProjectName)
	--pj.[last_deployed_time] > DATEADD(DAY, -7, GETDATE())
ORDER BY
	pj.last_deployed_time DESC
    , pk.version_build  DESC
	--folder,
	--pk.name