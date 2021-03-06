USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_Populate_ETL_Stats_LastRunTaskList]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [qv].[usp_Populate_ETL_Stats_LastRunTaskList] 
	-- Add the parameters for the stored procedure here
@SystemName NVARCHAR(64)
, @RunID INT = NULL
AS
BEGIN

SET NOCOUNT ON;

DECLARE @CheckParameterResult BIT = 0, @SystemKey INT

EXEC [qv].[usp_GetSystemKeyFromName] @_SystemName = @SystemName, @_CallingProcName = 'usp_Populate_ETL_Stats_LastRunTaskList', @_CheckResult = @CheckParameterResult OUTPUT, @_SystemKey = @SystemKey OUTPUT
IF (@CheckParameterResult = 0)
BEGIN
	RETURN
END
/*
EXEC [qv].[usp_CheckSystemName] @_SystemName = @SystemName, @_CallingProcName = 'usp_Populate_ETL_Stats_LastRunTaskList', @_CheckResult = @CheckParameterResult OUTPUT
IF (@CheckParameterResult = 0)
BEGIN
	RETURN
END
*/

	DECLARE @KeyTable TABLE (SystemKey INT)
	INSERT INTO @KeyTable SELECT @SystemKey --s.[dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName
	
	DECLARE @_SystemName NVARCHAR(64),  @_LastRunID INT, @_SystemKey INT
	SET @_SystemName = @SystemName --'Brokasure'
	
	-- ALL SYSTEMS ON AON_MI_DWH:
	-- //////////////////// @SystemName = 'Broaksure'				=> SystemKey = 115
	-- //////////////////// @SystemName = 'Pure'					=> SystemKey = 110
	-- //////////////////// @SystemName = 'MGA'						=> SystemKey = 122
	-- //////////////////// @SystemName = 'ActivityTracker'			=> SystemKey = 1003

	IF ((SELECT COUNT(SystemKey) FROM @KeyTable WHERE SystemKey IN (115, 110, 122, 1003)) > 0)
		BEGIN
		
			--TRUNCATE TABLE [qv].[ETL_Stats_LastRunTaskList] 
			SELECT 
							--@_LastRunID = COALESCE(@RunID, MAX(lt.RunID)) -- if @RunID is not supplied get the latest one
							@_LastRunID = COALESCE(@RunID, (SELECT TOP 1 RunID FROM qv.[LogTable] (NOLOCK) WHERE [SystemKey] = @SystemKey AND [ProcessName] = 'DailyProcess' AND [Status] = 'SUCCESS' ORDER BY RunID DESC)) -- if @RunID is not supplied get the latest SUCCESSFULL one
							
							, @_SystemKey = lt.[SystemKey]
			FROM			[qv].[LogTable] lt WITH(NOLOCK)
			INNER JOIN		[qv].[dim_aon_system] s WITH(NOLOCK)
			ON				s.[dim_aon_system_key] = lt.[SystemKey]
			WHERE
							s.[dim_aon_system_key] = @SystemKey
							--s.[systemname] = @SystemName
							AND (lt.[ProcessName] NOT LIKE 'ManualProcess%') AND (lt.[ProcessName] NOT LIKE 'DailyProcess_Only_Revenue_Split%')
			GROUP BY		lt.[SystemKey]
			
			; WITH XmlList AS(
			SELECT DISTINCT
			    L_1 = T.c.value('(/H/r)[1]', 'VARCHAR(100)'),
			    L_2 = T.c.value('(/H/r)[2]', 'VARCHAR(100)'),
			    L_3 = T.c.value('(/H/r)[3]', 'VARCHAR(100)'),
			    L_4 = T.c.value('(/H/r)[4]', 'VARCHAR(100)'),
			    L_5 = T.c.value('(/H/r)[5]', 'VARCHAR(100)'),
			    x.LogID,
			    x.RunID,
			    x.ProcessName,
			    x.TargetTableName
			FROM
			    (
			        SELECT
			            *,
			            vals = CAST ('<H><r>' + replace(ProcessName, '.', '</r><r>')  + '</r></H>' AS XML)
			        FROM
			            [qv].[LogTable] (NOLOCK)
			        WHERE
			            SystemKey = @_SystemKey
			            AND RunID = @_LastRunID
			    ) x
			    CROSS APPLY x.vals.nodes('/H/r') T(c)
			)
			
			MERGE INTO [qv].[ETL_Stats_LastRunTaskList] AS TargetTable 
			USING	(
						SELECT
							   @_SystemKey			AS [SystemKey]
							 , LogID				AS [LogID]
							 , @_LastRunID			AS [RunID]
							 , GETDATE()			AS [TimeRecorded]
							 , ChildTaskName = 
						        CASE
						            WHEN L_5 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_5 = XmlList.L_5 and Lvl.L_4 = XmlList.L_4 and Lvl.LogID <> XmlList.LogID) THEN L_5
						            WHEN L_4 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_4 = XmlList.L_4 and Lvl.L_3 = XmlList.L_3 and Lvl.LogID <> XmlList.LogID) THEN L_4
						            WHEN L_3 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_3 = XmlList.L_3 and Lvl.L_2 = XmlList.L_2 and Lvl.LogID <> XmlList.LogID) THEN L_3
						            WHEN L_2 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_2 = XmlList.L_2 and Lvl.L_1 = XmlList.L_1 and Lvl.LogID <> XmlList.LogID) THEN L_2
						            WHEN L_1 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_1 = XmlList.L_1 and                           Lvl.LogID <> XmlList.LogID) THEN L_1
								END,
							 ProcessName
						FROM
						    XmlList
						
					)	AS SourceTable
			ON TargetTable.[SystemKey] = @_SystemKey AND TargetTable.[LogID] = SourceTable.[LogID] AND TargetTable.[RunID] = @_LastRunID
			
			WHEN MATCHED THEN UPDATE SET
					TargetTable.[TimeRecorded] = GETDATE(),
					TargetTable.[ChildTaskName] = SourceTable.[ChildTaskName],
					TargetTable.[ProcessName] = SourceTable.[ProcessName]
			WHEN NOT MATCHED THEN
			INSERT VALUES (SourceTable.[SystemKey], SourceTable.[LogID], SourceTable.[RunID], SourceTable.[TimeRecorded], SourceTable.[ChildTaskName], SourceTable.[ProcessName]);
	
		END

	-- ALL SYSTEMS ON ACIA_DWH:
	ELSE
		BEGIN
		
			SELECT 
							--@_LastRunID = COALESCE(@RunID, MAX(lt.RunID)) -- if @RunID is not supplied get the latest one
							@_LastRunID = COALESCE(@RunID, (SELECT TOP 1 RunID FROM qv.[LogTable_ACIA] (NOLOCK) WHERE [SystemKey] = @SystemKey AND [ProcessName] = 'DailyProcess' AND [Status] = 'SUCCESS' ORDER BY RunID DESC)) -- if @RunID is not supplied get the latest SUCCESSFULL one

							, @_SystemKey = lt.[SystemKey]
			FROM			[qv].[LogTable_ACIA] lt WITH(NOLOCK)
			INNER JOIN		[qv].[dim_aon_system] s WITH(NOLOCK)
			ON				s.[dim_aon_system_key] = lt.[SystemKey]
			WHERE
							s.[dim_aon_system_key] = @SystemKey
							AND lt.[ProcessName] NOT LIKE 'ManualProcess%'
			GROUP BY		lt.[SystemKey]
			
			
			; WITH XmlList AS(
			SELECT DISTINCT
			    L_1 = T.c.value('(/H/r)[1]', 'VARCHAR(100)'),
			    L_2 = T.c.value('(/H/r)[2]', 'VARCHAR(100)'),
			    L_3 = T.c.value('(/H/r)[3]', 'VARCHAR(100)'),
			    L_4 = T.c.value('(/H/r)[4]', 'VARCHAR(100)'),
			    L_5 = T.c.value('(/H/r)[5]', 'VARCHAR(100)'),
			    x.LogID,
			    x.RunID,
			    x.ProcessName,
			    x.TargetTableName
			FROM
			    (
			        SELECT
			            *,
			            vals = CAST ('<H><r>' + replace(ProcessName, '.', '</r><r>')  + '</r></H>' AS XML)
			        FROM
			            [qv].[LogTable_ACIA] (NOLOCK)
			        WHERE
			            SystemKey = @_SystemKey
			            AND RunID = @_LastRunID
			    ) x
			    CROSS APPLY x.vals.nodes('/H/r') T(c)
			)
			
			MERGE INTO [qv].[ETL_Stats_LastRunTaskList] AS TargetTable 
			USING	(
						SELECT
							   @_SystemKey			AS [SystemKey]
							 , LogID				AS [LogID]
							 , @_LastRunID			AS [RunID]
							 , GETDATE()			AS [TimeRecorded]
							 , ChildTaskName = 
						        CASE
						            WHEN L_5 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_5 = XmlList.L_5 and Lvl.L_4 = XmlList.L_4 and Lvl.LogID <> XmlList.LogID) THEN L_5
						            WHEN L_4 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_4 = XmlList.L_4 and Lvl.L_3 = XmlList.L_3 and Lvl.LogID <> XmlList.LogID) THEN L_4
						            WHEN L_3 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_3 = XmlList.L_3 and Lvl.L_2 = XmlList.L_2 and Lvl.LogID <> XmlList.LogID) THEN L_3
						            WHEN L_2 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_2 = XmlList.L_2 and Lvl.L_1 = XmlList.L_1 and Lvl.LogID <> XmlList.LogID) THEN L_2
						            WHEN L_1 is not null and not exists (SELECT * FROM XmlList AS Lvl WHERE Lvl.L_1 = XmlList.L_1 and                           Lvl.LogID <> XmlList.LogID) THEN L_1
								END,
							 ProcessName
						FROM
						    XmlList
						
					)	AS SourceTable
			ON TargetTable.[SystemKey] = @_SystemKey AND TargetTable.[LogID] = SourceTable.[LogID] AND TargetTable.[RunID] = @_LastRunID
			
			WHEN MATCHED THEN UPDATE SET
					TargetTable.[TimeRecorded] = GETDATE(),
					TargetTable.[ChildTaskName] = SourceTable.[ChildTaskName],
					TargetTable.[ProcessName] = SourceTable.[ProcessName]
			WHEN NOT MATCHED THEN
			INSERT VALUES (SourceTable.[SystemKey], SourceTable.[LogID], SourceTable.[RunID], SourceTable.[TimeRecorded], SourceTable.[ChildTaskName], SourceTable.[ProcessName]);
		END
END
GO
