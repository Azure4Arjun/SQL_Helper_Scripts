USE SQL_Analysis_Code
GO

CREATE SCHEMA Locking
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Locking.[ins_DeadLock]') AND type in (N'P', N'PC'))
DROP PROCEDURE Locking.[ins_DeadLock]
GO

CREATE PROC Locking.ins_DeadLock
	   @XESource			  nvarchar(260)   = 'RingBuffer'	   -- File import only supported from SQL Server 2012 onwards
    ,   @DeadlocksCollected	  int		   OUTPUT
AS
/*
=============================================
Author:			Andreas Wolter, Sarpedon Quality Lab
Licence:		Microsoft Public License (Ms-PL)
Source:			https://sqldeadlockcollector.codeplex.com

Create date:		04-2012
Revision History:
				09-2013 1. Insert TempTable
				11-3013 adapted 2012, removed redundant XML,	corrected plan_handle, sql_handle for 2nd process
					   dismissed ObjectName because depending on Lock-Type will reside in differen node
				02-2015 added import file-option

Project:			System Monitoring
Description:		Inserts Deadlocks collected from system health session

Depends on:
Locking.DeadLock

Execution samples:

DECLARE @DeadlocksCollected int;
EXECUTE Locking.ins_DeadLock
    @DeadlocksCollected = @DeadlocksCollected OUTPUT;
SELECT @DeadlocksCollected AS [Number of new Deadlocks collected:];


DECLARE @DeadlocksCollected int;
EXECUTE Locking.ins_DeadLock
	   @XESource = 'D:\SQLData\SQLData1\SQLData1\MSSQL11.SQL2012DEV\MSSQL\Log\system_health_*.xel'
    ,   @DeadlocksCollected = @DeadlocksCollected OUTPUT;
SELECT @DeadlocksCollected AS [Number of new Deadlocks collected:];

=============================================
*/

SET NOCOUNT ON;
SET DATEFORMAT dmy;

-- === Start internal Variables === -- 

-- System
	
-- User

DECLARE @XMLSourceTab	TABLE
(
	   DeadlockGraph   xml
    ,   Event_DateTime  datetime2(0) NULL
)
	
-- initialize Variables

-- === End internal Variables === -- 

-- === Start Variable Checks === --

IF (@XESource <> 'RingBuffer')
BEGIN
    IF (SELECT CAST(CAST(SERVERPROPERTY('ProductVersion') AS char(2)) AS tinyint) ) < 11
    BEGIN
	   RAISERROR('I am sorry, but importing Files is only supported from SQL Server 2012 upwards. SQL Server 2008/R2 requires a metadata file, which I have not integrated into these routines (yet?).', 14, 1)	 WITH NOWAIT
	   RETURN -1
    END;

END;

-- === End Variable Checks === -- 

-- === Start Fill Table Variables === -- 

IF (@XESource = 'RingBuffer')
BEGIN

    INSERT INTO @XMLSourceTab (DeadlockGraph, Event_DateTime)

    SELECT
	    -- Everything:
	    --	XEvent.query('.') AS DeadlockGraph
	    --,
		    ---- Pre- SQL 2008 SP2: 
		    --CAST(
		    --	REPLACE(
		    --		REPLACE(XEventData.XEvent.value('(data/value)[1]', 'varchar(max)'), 
		    --		'<victim-list>', '<deadlock><victim-list>'),
		    --	'<process-list>','</victim-list><process-list>')
		    --	AS xml) 
		    --AS DeadlockGraph

			--> SQL 2008 / R2 SP2 (10.50.2500):
		    CAST(
		    	XEventData.XEvent.value('(data/value)[1]', 'varchar(max)') 
		    	AS xml)
		    AS DeadlockGraph

		    -- > SQL 2012 CU3 (11.0.2332):
		    --CAST(
		    --	XEventData.XEvent.query('.')
		    --	AS xml)
		    --AS DeadlockGraph

			--> SQL 2012 SP1:
		    --CAST(
			   -- XEventData.XEvent.query('(data/value/deadlock)[1]') 
			   -- AS xml)
		    --AS DeadlockGraph

	    -- TimeStamp			
	    --,	XEventData.XEvent.value('(@timestamp)[1]', 'varchar(max)')	 AS timestamp
	    -- adjust timezone
	   ,	  DATEADD(mi, DATEPART(TZ, SYSDATETIMEOFFSET()), XEventData.XEvent.value('(@timestamp)[1]', 'DATETIME2'))  AS Event_DateTime

    FROM (
	    SELECT CAST(target_data as xml)		AS TargetData
	    FROM sys.dm_xe_session_targets		AS dm_xe_session_targets

		    INNER JOIN sys.dm_xe_sessions AS dm_xe_sessions
			    ON dm_xe_session_targets.event_session_address = dm_xe_sessions.address

	    WHERE
		    dm_xe_sessions.name = 'system_health'
	    ) AS Data

    CROSS APPLY TargetData.nodes ('//RingBufferTarget/event[@name="xml_deadlock_report"]') AS XEventData (XEvent)

END;

IF (@XESource <> 'RingBuffer')
BEGIN

    INSERT INTO @XMLSourceTab (DeadlockGraph, Event_DateTime)
    SELECT 
		  CAST(XEFile.event_data AS XML).query('//data/value/deadlock[1]')	AS DeadlockGraph
	   -- adjust timezone
	   ,	  DATEADD(mi, DATEPART(TZ, SYSDATETIMEOFFSET()),  CAST(XEFile.event_data AS XML).value('(/event/@timestamp)[1]', 'DATETIME2'))  AS Event_DateTime
    FROM sys.fn_xe_file_target_read_file(@XESource, NULL, NULL, NULL) AS XEFile    
	   WHERE object_name = 'xml_deadlock_report';

END;

-- === End Fill Table Variables === -- 

-- === Start Main Work === -- 

-- TempTable with parsed deadlocks - direct insert would be too slow
DECLARE @Deadlock table
(
		Event_DateTime datetime2(0) NULL
	,	AffectedProcesses int NULL
	,	DatabaseName_1 nvarchar(128) NULL
	,	DatabaseName_2 nvarchar(128) NULL
	,	SQLText_1 nvarchar(max) NULL
	,	SQLText_2 nvarchar(max) NULL
	,	ProcedureName_1 nvarchar(386) NULL
	,	ProcedureName_2 nvarchar(386) NULL
	,	LoginName_1 sysname NULL
	,	LoginName_2 sysname NULL
	,	SPID_1 int NULL
	,	SPID_2 int NULL
	,	InputBuffer_1 varchar(max) NULL
	,	InputBuffer_2 varchar(max) NULL
	,	App_Name_1 sysname NULL
	,	App_Name_2 sysname NULL
	,	HostName_1 sysname NULL
	,	HostName_2 sysname NULL
	,	WaitResource_1 varchar(500) NULL
	,	WaitResource_2 varchar(500) NULL
	,	LockMode_1 varchar(10) NULL
	,	LockMode_2 varchar(10) NULL
	,	IsolationLevel_1 varchar(100) NULL
	,	IsolationLevel_2 varchar(100) NULL

	--,	Victim_List filled in Table-Default
	--,	Process_List_ExecutionStack filled in Table-Default
	--,	Resource_List  filled in Table-Default

	,	QueryPlan_1 xml NULL
	,	QueryPlan_2 xml NULL

	,	Complete_DeadlockGraph xml NULL

	,	SQLHandle_1 varbinary(64) NULL
	,	SQLHandle_2 varbinary(64) NULL
	,	PlanHandle_1 varbinary(64) NULL
	,	PlanHandle_2 varbinary(64) NULL
	,	DeadlockHash varbinary(42) NULL
)


-- insert
INSERT INTO @DeadLock

-- parse
SELECT 

		CAST(Event_DateTime AS datetime2(0))								AS Event_DateTime

	-- Pre- SQL 2008 SP2: /deadlock-list/deadlock/ instead of /deadlock/

	,	DeadlockGraph.value('count((/deadlock/process-list/process))', 'int')		AS AffectedProcesses
	--,	DeadlockGraph.value('count((/deadlock/victim-list))', 'int')		    AS Victims

	,	DB_NAME(DeadlockGraph.value('(/deadlock/process-list/process)[1]/@currentdb', 'int')	)	AS DatabaseName_1
	,	DB_NAME(DeadlockGraph.value('(/deadlock/process-list/process)[2]/@currentdb', 'int')	)	AS DatabaseName_2

	,	dm_exec_sql_text_1.text											AS SQLText_1
	,	dm_exec_sql_text_2.text											AS SQLText_2

	,	DeadlockGraph.query('(/deadlock/process-list/process/executionStack)[1]').value('(/executionStack/frame)[1]/@procname', 'nvarchar(386)')		AS ProcedureName_1
		-- more complex for 2nd ExecutionStack
	,	DeadlockGraph.query('(/deadlock/process-list/process/executionStack)[2]').value('(/executionStack/frame)[1]/@procname', 'nvarchar(386)')		AS ProcedureName_2

	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@loginname', 'sysname')		AS LoginName_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@loginname', 'sysname')		AS LoginName_2

	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@spid', 'int')		AS SPID_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@spid', 'int')		AS SPID_2

	,	DeadlockGraph.value('(/deadlock/process-list/process/inputbuf)[1]', 'varchar(max)')		AS InputBuffer_1
	-- works because inputbuf is 1 per Process
	,	DeadlockGraph.value('(/deadlock/process-list/process/inputbuf)[2]', 'varchar(max)')		AS InputBuffer_2
	
	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@clientapp', 'sysname')		AS App_Name_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@clientapp', 'sysname')		AS App_Name_2

	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@hostname', 'sysname')		AS HostName_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@hostname', 'sysname')		AS HostName_2

	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@waitresource', 'varchar(500)')		AS WaitResource_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@waitresource', 'varchar(500)')		AS WaitResource_2

	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@lockMode', 'varchar(10)')		AS LockMode_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@lockMode', 'varchar(10)')		AS LockMode_2
	
	,	DeadlockGraph.value('(/deadlock/process-list/process)[1]/@isolationlevel', 'varchar(100)')		AS IsolationLevel_1
	,	DeadlockGraph.value('(/deadlock/process-list/process)[2]/@isolationlevel', 'varchar(100)')		AS IsolationLevel_2

	-- now done in table default
	-- Victim_List
	-- Process_List
	-- Resource_List

	,	dm_exec_query_plan_1.query_plan									AS QueryPlan_1
	,	dm_exec_query_plan_2.query_plan									AS QueryPlan_2

	,	DeadlockGraph													AS Complete_DeadlockGraph

	,  COALESCE(dm_exec_query_stats_1.sql_handle, 0xFF /* when plan_handle not found in cache (maybe trivial plan) */)																						  AS SQLHandle_1
	-- (now only done once in join),	CONVERT(varbinary(64), DeadlockGraph.value('(/deadlock/process-list/process/executionStack/frame)[1]/@sqlhandle', 'varchar(90)'), 1)

	,  COALESCE(dm_exec_query_stats_2.sql_handle, 0xFF /* when plan_handle not found in cache (maybe trivial plan) */)
																	   AS SQLHandle_2
	-- (now only done once in join),	CONVERT(varbinary(64), DeadlockGraph.query('(/deadlock/process-list/process/executionStack)[2]').value('(/executionStack/frame)[1]/@sqlhandle', 'varchar(90)'), 1)

	,	dm_exec_query_stats_1.plan_handle								    AS PlanHandle_1
	,	dm_exec_query_stats_2.plan_handle								    AS PlanHandle_2

	-- for loading only new deadlock - has to be same as in  WHERE!
	-- TS + 4000 characters (after "<deadlock><victim-list>")
	,	CAST(
		HASHBYTES('SHA'
		, CONVERT(char(28), Event_DateTime, 127) + CAST(SUBSTRING(CAST(DeadlockGraph AS varchar(max)), 24, 4000) AS varchar(4000))	)	
		AS varbinary(42))											AS DeadlockHash

FROM
(	

SELECT
	   DeadlockGraph
    ,   Event_DateTime
	FROM @XMLSourceTab

) AS System_Healt_Session_Data

-- for SQL Text
-- @sqlhandle in plan changed from 64 bytes -> 90 from SQL 2008 R2 -> 2012
OUTER APPLY sys.dm_exec_sql_text(
CONVERT(varbinary(64), DeadlockGraph.value('(/deadlock/process-list/process/executionStack/frame)[1]/@sqlhandle', 'varchar(90)'), 1 /* style! */ )
)	AS dm_exec_sql_text_1

-- the 2. has to be searched more complex via .query AND .value
OUTER APPLY sys.dm_exec_sql_text(
	CONVERT(varbinary(64), 
	DeadlockGraph.query('(/deadlock/process-list/process/executionStack)[2]').value('(/executionStack/frame)[1]/@sqlhandle', 'varchar(90)')
	, 1)
)	AS dm_exec_sql_text_2


-- for Query Plan Handle

--LEFT OUTER JOIN sys.dm_exec_query_stats	AS dm_exec_query_stats_1
--	ON CONVERT(varbinary(64), DeadlockGraph.value('(/deadlock/process-list/process/executionStack/frame)[1]/@sqlhandle', 'varchar(90)'), 1) = dm_exec_query_stats_1.sql_handle

-- but constrained to 1 row:

LEFT OUTER JOIN 
	(
		SELECT TOP 100 PERCENT
			sql_handle
		,	plan_handle
		,	MIN(last_execution_time)	AS last_execution_time
		FROM sys.dm_exec_query_stats
		GROUP BY
			sql_handle
		,	plan_handle

		ORDER BY
			last_execution_time  ASC

	)	AS dm_exec_query_stats_1
	ON CONVERT(varbinary(64), DeadlockGraph.value('(/deadlock/process-list/process/executionStack/frame)[1]/@sqlhandle', 'varchar(64)'), 1) = dm_exec_query_stats_1.sql_handle


-- the 2. has to be searched more complex via .query AND .value
LEFT OUTER JOIN 
	(
		SELECT TOP 100 PERCENT
			sql_handle
		,	plan_handle
		,	MIN(last_execution_time)	AS last_execution_time
		FROM sys.dm_exec_query_stats
		GROUP BY
			sql_handle
		,	plan_handle

		ORDER BY
			last_execution_time  ASC

	)	AS dm_exec_query_stats_2
	-- .query + .value
	ON CONVERT(varbinary(64), DeadlockGraph.query('(/deadlock/process-list/process/executionStack)[2]').value('(/executionStack/frame)[1]/@sqlhandle', 'varchar(64)'), 1) = dm_exec_query_stats_2.sql_handle


---- and in the next step only return the 1.st row
---- huge runtime decrease :-(
--OUTER APPLY
--        (
--        SELECT  TOP 1 plan_handle
--        FROM    sys.dm_exec_query_stats	AS dm_exec_query_stats_inner
--        WHERE   CONVERT(varbinary(64), DeadlockGraph.query('(/deadlock/process-list/process/executionStack)[2]').value('(/executionStack/frame)[1]/@sqlhandle', 'varchar(90)'), 1)
--		= dm_exec_query_stats_inner.sql_handle
--        ORDER BY
--                last_execution_time  ASC
--        ) AS dm_exec_query_stats_2


-- für Query Plan
OUTER APPLY sys.dm_exec_query_plan(dm_exec_query_stats_1.plan_handle) AS dm_exec_query_plan_1

OUTER APPLY sys.dm_exec_query_plan(dm_exec_query_stats_2.plan_handle) AS dm_exec_query_plan_2

;

-- === End Main Work === -- 

-- ================
-- Final Insert
-- ================

INSERT INTO SQL_Analysis_Data.[Locking].[DeadLock]
           ([Event_DateTime]
           ,[AffectedProcesses]
           ,[DatabaseName_1]
           ,[DatabaseName_2]
           ,[SQLText_1]
           ,[SQLText_2]
           ,[ProcedureName_1]
           ,[ProcedureName_2]
           ,[LoginName_1]
           ,[LoginName_2]
           ,[SPID_1]
           ,[SPID_2]
           ,[InputBuffer_1]
           ,[InputBuffer_2]
           ,[App_Name_1]
           ,[App_Name_2]
           ,[HostName_1]
           ,[HostName_2]
           ,[WaitResource_1]
           ,[WaitResource_2]
           ,[LockMode_1]
           ,[LockMode_2]
           ,[IsolationLevel_1]
           ,[IsolationLevel_2]
           ,[QueryPlan_1]
           ,[QueryPlan_2]
           ,[Complete_DeadlockGraph]
           ,[SQLHandle_1]
           ,[SQLHandle_2]
           ,[PlanHandle_1]
           ,[PlanHandle_2]
           ,[DeadlockHash])

SELECT * FROM @Deadlock

WHERE
-- for loading only new deadlock - has to be same as in  WHERE!
	DeadlockHash

NOT IN
	(
		SELECT DISTINCT DeadlockHash
		FROM SQL_Analysis_Data.Locking.DeadLock
	)

;

SET @DeadlocksCollected = @@ROWCOUNT

GO



EXEC sys.sp_addextendedproperty
@name=N'Description'
, @value=N'Inserts Deadlocks collected from system health session'
 , @level0type=N'SCHEMA',@level0name=N'Locking', @level1type=N'PROCEDURE'
,@level1name=N'ins_DeadLock'
GO


EXEC sys.sp_addextendedproperty @name=N'Author', @value=N'Andreas Wolter' , @level0type=N'SCHEMA',@level0name=N'Locking', @level1type=N'PROCEDURE',@level1name=N'ins_DeadLock'
GO



IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Locking.[del_DeadLock]') AND type in (N'P', N'PC'))
DROP PROCEDURE Locking.[del_DeadLock]
GO

CREATE PROC Locking.del_DeadLock
	   @DeleteOlderThanDateX	  date	    --YYYY-MM-DD
    ,   @DeadlocksRemoved int	  OUTPUT
AS
/*
=============================================
Author:			Andreas Wolter, Sarpedon Quality Lab
Licence:		Microsoft Public License (Ms-PL)
Source:			https://sqldeadlockcollector.codeplex.com

Revision History: 

Project:		System Monitoring
Description:	Removes (old) collected Deadlocks from Table

Depends on:
Locking.DeadLock

Execution sample:

DECLARE @DeleteOlderThanDate date, @DeadlocksRemoved int;
SET @DeleteOlderThanDate = DATEADD(dd, -60, SYSDATETIME())
SELECT @DeleteOlderThanDate AS [LatestDateToKeep:]

Execute Locking.del_DeadLock
	   @DeleteOlderThanDateX	  = @DeleteOlderThanDate
    ,   @DeadlocksRemoved	  = @DeadlocksRemoved	 OUTPUT;
SELECT @DeadlocksRemoved AS [Number of removed deadlocks/rows from table:];

=============================================
*/

SET NOCOUNT ON;

DELETE FROM [SQL_Analysis_Data].[Locking].[DeadLock]
      WHERE [Event_DateTime] < @DeleteOlderThanDateX;

SET @DeadlocksRemoved = @@ROWCOUNT;

GO



EXEC sys.sp_addextendedproperty
@name=N'Description'
, @value=N'Removes (old) collected Deadlocks from Table'
 , @level0type=N'SCHEMA',@level0name=N'Locking', @level1type=N'PROCEDURE'
,@level1name=N'del_DeadLock'
GO


EXEC sys.sp_addextendedproperty @name=N'Author', @value=N'Andreas Wolter' , @level0type=N'SCHEMA',@level0name=N'Locking', @level1type=N'PROCEDURE',@level1name=N'del_DeadLock'
GO

