
USE SQL_Analysis_Reporting
GO


CREATE SCHEMA Locking
GO

CREATE VIEW Locking.v_DeadlockInfos
/*

Base view for others

*/
AS

SELECT [ID_DeadLock]
      ,[Event_DateTime]
	  , Notes
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
      ,[Victim_List]
      ,[Process_List_ExecutionStack]
      ,[Resource_List]
      ,[QueryPlan_1]
      ,[QueryPlan_2]
      ,[Complete_DeadlockGraph]
      ,[SQLHandle_1]
      ,[SQLHandle_2]
      ,[PlanHandle_1]
      ,[PlanHandle_2]

FROM SQL_Analysis_Data.[Locking].[DeadLock]
GO



EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Contains Deadlocks collected from a Server. Base view.' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'VIEW'
	,	@level1name	=N'v_DeadLockInfos'
GO


CREATE VIEW Locking.v_DeadLockCombinationBySQLText
AS

SELECT 
		[AffectedProcesses]      
	,	[SQLText_1]
	,	[SQLText_2]
	,	COUNT(*)			AS NumOccurances
     
FROM [Locking].[v_DeadlockInfos]

WHERE
	[SQLText_1] is not null
AND	[SQLText_2] is not null

GROUP BY 
		[AffectedProcesses]      
	,	[SQLText_1]
	,	[SQLText_2]

GO

EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Contains Deadlocks collected from a Server' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'VIEW'
	,	@level1name	=N'v_DeadLockCombinationBySQLText'
GO


CREATE VIEW Locking.v_DeadLockByDayHour
AS

SELECT
		CAST([Event_DateTime] AS date)			AS Date
	,	DATEPART(hh, [Event_DateTime])			AS [Hour]
	,	COUNT(*)								AS NumOccurances
	,	SUM([AffectedProcesses])				AS Sum_AffectedProcesses    
	,	SUM([AffectedProcesses]) - COUNT(*)		AS Sum_Victims   
     
FROM [Locking].[v_DeadlockInfos]

GROUP BY 
		CAST([Event_DateTime] AS date)	
	,	DATEPART(hh, [Event_DateTime])	
  

GO

EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Contains Deadlocks collected from a Server Grouped by Day and Hour' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'VIEW'
	,	@level1name	=N'v_DeadLockByDayHour'
GO



CREATE VIEW Locking.v_DeadLockByDay
AS

SELECT
		CAST([Event_DateTime] AS date)			AS Date
	,	DATENAME(dw, [Event_DateTime])			AS Day
	,	COUNT(*)								AS NumOccurances
	,	SUM([AffectedProcesses])				AS Sum_AffectedProcesses    
	,	SUM([AffectedProcesses]) - COUNT(*)		AS Sum_Victims   
     
FROM [Locking].[v_DeadlockInfos]

GROUP BY 
		CAST([Event_DateTime] AS date)
	,	DATENAME(dw, [Event_DateTime])
  

GO

EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Contains Deadlocks collected from a Server Grouped by Day' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'VIEW'
	,	@level1name	=N'v_DeadLockByDay'
GO




CREATE VIEW [Locking].[v_DeadLockByDayAndDatabase]
AS


SELECT
		CAST(Event_DateTime AS date) AS date
	,	COUNT(*)		AS NumDeadlocks
	,	DatabaseName_1
	,	DatabaseName_2

FROM SQL_Analysis_Data.Locking.DeadLock
GROUP BY
	CAST(Event_DateTime AS date)
	,	DatabaseName_1
	,	DatabaseName_2


GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Contains Deadlocks collected from a Server' , @level0type=N'SCHEMA',@level0name=N'Locking', @level1type=N'VIEW',@level1name=N'v_DeadLockByDayAndDatabase'
GO

-- ======= Procedures (with ordering result sets)



CREATE PROCEDURE [Locking].NumberOfAffectedProcessesStatistics
AS

SELECT 
		[AffectedProcesses]      
	,	COUNT(*)			AS NumOccurances
     
FROM [Locking].[v_DeadlockInfos]

GROUP BY 
		[AffectedProcesses]      

ORDER BY NumOccurances DESC

GO

EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Provides statistics over how many processes were affected per Deadlock' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'PROCEDURE'
	,	@level1name	=N'NumberOfAffectedProcessesStatistics'
GO



CREATE PROCEDURE [Locking].[Top20InvolvedResources]
AS

SELECT TOP (20)
	   DatabaseName_1
    ,   ProcedureName_1
    ,   WaitResource_1
    ,   COUNT(*)	    AS NumberOf
FROM Locking.v_DeadlockInfos
GROUP BY
	   WaitResource_1
    ,   DatabaseName_1
    ,   ProcedureName_1
ORDER BY
	   NumberOf DESC
    ,   DatabaseName_1 ASC

GO

EXEC sys.sp_addextendedproperty
		@name		=N'Description'
	,	@value		=N'Most often involved wait resources' 
	,	@level0type	=N'SCHEMA'
	,	@level0name	=N'Locking'
	,	@level1type	=N'PROCEDURE'
	,	@level1name	=N'Top20InvolvedResources'
GO
