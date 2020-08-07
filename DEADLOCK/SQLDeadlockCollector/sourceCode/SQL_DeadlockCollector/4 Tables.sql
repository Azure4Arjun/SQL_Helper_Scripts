
USE [SQL_Analysis_Data]
GO

CREATE SCHEMA Locking
GO

DROP TABLE Locking.DeadLock
GO

DROP FUNCTION Locking.sel_xml_List
GO


CREATE FUNCTION Locking.sel_xml_List(
		@DeadlockGraph	xml
	,	@ReturnNode		varchar(10)
)
RETURNS xml
	WITH SCHEMABINDING
AS
/*
=============================================
Author:			Andreas Wolter, Sarpedon Quality Lab
Create date:	11-2013
Revision History:

Project:		System Monitoring
Description:	reads out a node from the deadlock graph

Depends on:
Locking.DeadLock

Execution sample:

SELECT
	Locking.sel_xml_List(Complete_DeadlockGraph, 'victim')
FROM Locking.DeadLock

=============================================
*/
BEGIN

    IF @ReturnNode = 'victim'
	BEGIN
	    RETURN @DeadlockGraph.query('/deadlock/victim-list') 
	END
	
	IF @ReturnNode = 'process'
	BEGIN
	    RETURN @DeadlockGraph.query('/deadlock/process-list') 
	END

	IF @ReturnNode = 'resource'
	BEGIN
	    RETURN @DeadlockGraph.query('/deadlock/resource-list') 
	END

	RETURN NULL
END
GO


CREATE TABLE Locking.DeadLock
(
		ID_DeadLock int identity(1,1)	NOT NULL
	,	Event_DateTime datetime2(0) NULL
	,	ServerInstance nvarchar(256) NULL DEFAULT @@Servername
	,	Notes			nvarchar(1000)	NULL
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

	,	Victim_List AS Locking.sel_xml_List(Complete_DeadlockGraph, 'victim') 
	,	Process_List_ExecutionStack AS Locking.sel_xml_List(Complete_DeadlockGraph, 'process')
	,	Resource_List AS Locking.sel_xml_List(Complete_DeadlockGraph, 'resource') 

	,	QueryPlan_1 xml NULL
	,	QueryPlan_2 xml NULL

	,	Complete_DeadlockGraph xml NULL
	
	,	SQLHandle_1 varbinary(64) NULL
	,	SQLHandle_2 varbinary(64) NULL
	,	PlanHandle_1 varbinary(64) NULL
	,	PlanHandle_2 varbinary(64) NULL
	,	DeadlockHash varbinary(42) NULL
)
GO



EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Contains Deadlocks collected from system health session' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'TABLE'
	,	@level1name	=N'DeadLock'
GO


EXEC sys.sp_addextendedproperty
		@name		=N'Author'
	,	@value		=N'Andreas Wolter, Sarpedon Quality Lab' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'TABLE'
	,	@level1name	=N'DeadLock'
GO


ALTER TABLE Locking.DeadLock
	ADD CONSTRAINT PKNCL_DeadLock_ID_DeadLock PRIMARY KEY NONCLUSTERED
		(ID_DeadLock)
GO

CREATE CLUSTERED INDEX CL_DeadLock_Event_DateTime
ON Locking.DeadLock
(
	Event_DateTime
)
GO

CREATE UNIQUE NONCLUSTERED INDEX UQNCL_DeadLock_DeadlockHash
ON Locking.DeadLock
(
	DeadlockHash
)

GO
