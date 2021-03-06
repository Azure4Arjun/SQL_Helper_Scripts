USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_Populate_ETL_Stats_WinnersAndLosers]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [qv].[usp_Populate_ETL_Stats_WinnersAndLosers] 
--DECLARE
@SystemName NVARCHAR(64), @displayOnly BIT = 0
AS
BEGIN

SET NOCOUNT ON;
SET XACT_ABORT OFF;

DECLARE @CheckParameterResult BIT = 0, @SystemKey INT

EXEC [qv].[usp_GetSystemKeyFromName] @_SystemName = @SystemName, @_CallingProcName = 'usp_Populate_ETL_Stats_WinnersAndLosers', @_CheckResult = @CheckParameterResult OUTPUT, @_SystemKey = @SystemKey OUTPUT
IF (@CheckParameterResult = 0)
BEGIN
	RETURN
END


	DECLARE @_SystemName NVARCHAR(64), @_ProcessName NVARCHAR(1024), @_DaysBack INT, @_MaxRunID_FromWinLosTable INT
	SET @_SystemName = @SystemName

	IF OBJECT_ID('TempDb..#RunIDsPerSystem') IS NOT NULL DROP TABLE #RunIDsPerSystem
	CREATE TABLE #RunIDsPerSystem (SystemKey INT, RunID BIGINT, ProcessName NVARCHAR(1024), NumDaysBack INT)

	INSERT INTO #RunIDsPerSystem
	
					SELECT DISTINCT
								s.[dim_aon_system_key],
								wl.[RunID],
								wl.[ProcessName],
								wl.[NumDaysBack]
					FROM
								[qv].[dim_aon_system] s 
					JOIN		[qv].[ETL_Stats_WinnersAndLosers] wl
					ON			wl.[SystemKey] = s.[dim_aon_system_key]
					WHERE		s.[dim_aon_system_key] = @SystemKey
	--SELECT * FROM #RunIDsPerSystem

	IF OBJECT_ID('TempDb..#ETL_Stats_WinnersAndLosers') IS NOT NULL DROP TABLE #ETL_Stats_WinnersAndLosers
		CREATE TABLE #ETL_Stats_WinnersAndLosers
		(
			[SystemKey]				INT NOT NULL,
			[RunID]					BIGINT NOT NULL,
			[LogID]					BIGINT NOT NULL,
			[TimeRecorded]			DATETIME NOT NULL,
			[ProcessName]			NVARCHAR(1024) NOT NULL,
			[NumDaysBack]			INT NOT NULL,
			[TaskDuration]			TIME(7) NULL,
			[AvgDuration]			TIME(7) NULL,
			[StDevInMinutes]		INT NULL,
			[DiffFromStdDev]		INT NULL,
			[RecordsPerSecond]		BIGINT NULL
		)
		/*
		ALTER TABLE #ETL_Stats_WinnersAndLosers ADD  CONSTRAINT PK_SysKey_RunID_LogID_temp PRIMARY KEY CLUSTERED 
		(
			[SystemKey] ASC,
			[RunID] ASC,
			[LogID] ASC,
			[TimeRecorded] ASC,
			[NumDaysBack] ASC
		)
		*/

	DECLARE ProcessNames_Cursor CURSOR FOR
	SELECT DISTINCT([ProcessName]) 
	FROM 
		[qv].[ETL_Stats_LastRunTaskList] tl
		INNER JOIN [qv].[dim_aon_system] s ON s.[dim_aon_system_key] = tl.[SystemKey]
	WHERE
		s.[dim_aon_system_key] = @SystemKey --s.[systemname] = @SystemName
		AND tl.[RunID] > (SELECT COALESCE(MAX(RunID), 0) FROM #RunIDsPerSystem)
		AND tl.[ChildTaskName] IS NOT NULL 
		AND ((tl.[ProcessName] NOT LIKE 'ManualProcess%') AND (tl.[ProcessName] NOT LIKE 'DailyProcess_Only_Revenue_Split%'))

	DECLARE @TimeRecorded DATETIME = GETDATE()
	
	IF OBJECT_ID('TempDb..#DaysBackTable') IS NOT NULL DROP TABLE #DaysBackTable
	CREATE TABLE #DaysBackTable (NumDaysBack INT)

	OPEN ProcessNames_Cursor
	FETCH NEXT FROM ProcessNames_Cursor INTO @_ProcessName
	WHILE @@FETCH_STATUS = 0
	
	BEGIN
	
		TRUNCATE TABLE #DaysBackTable
		INSERT INTO #DaysBackTable (NumDaysBack) VALUES (-7)
		INSERT INTO #DaysBackTable (NumDaysBack) VALUES (-14)
		INSERT INTO #DaysBackTable (NumDaysBack) VALUES (-30)
	
			DECLARE DaysBack_Cursor CURSOR FOR
			SELECT NumDaysBack FROM #DaysBackTable
	
				OPEN DaysBack_Cursor
				FETCH NEXT FROM DaysBack_Cursor INTO @_DaysBack
				WHILE @@FETCH_STATUS = 0 
				BEGIN
				SELECT @_MaxRunID_FromWinLosTable = COALESCE(MAX(RunID), 0) FROM #RunIDsPerSystem WHERE NumDaysBack = @_DaysBack AND ProcessName = @_ProcessName
				--PRINT @_MaxRunID_FromWinLosTable
				
				BEGIN TRY
					INSERT INTO #ETL_Stats_WinnersAndLosers EXEC [qv].[usp_CalculateWinnersAndLosersPerProcess] @SystemName = @_SystemName, @ProcessName = @_ProcessName, @DaysBack = @_DaysBack, @MaxRunID_FromWinLosTable = @_MaxRunID_FromWinLosTable
				END TRY
				BEGIN CATCH
				    SELECT ERROR_NUMBER(), ERROR_SEVERITY(), ERROR_STATE(), ERROR_PROCEDURE(), ERROR_MESSAGE()
				END CATCH
				
				FETCH NEXT FROM DaysBack_Cursor INTO @_DaysBack
				END
			CLOSE DaysBack_Cursor  
			DEALLOCATE DaysBack_Cursor
	
	FETCH NEXT FROM ProcessNames_Cursor INTO @_ProcessName
	END
	CLOSE ProcessNames_Cursor  
	DEALLOCATE ProcessNames_Cursor

IF (@displayOnly = 1) SELECT * FROM #ETL_Stats_WinnersAndLosers ORDER BY [DiffFromStdDev] DESC
ELSE
				BEGIN			
						MERGE INTO [qv].[ETL_Stats_WinnersAndLosers] AS TargetTable 
						USING	(
									SELECT
										  [SystemKey]		
										, [RunID]			
										, [LogID]			
										, [TimeRecorded]	
										, [ProcessName]		
										, [NumDaysBack]		
										, [TaskDuration]	
										, [AvgDuration]		
										, [StDevInMinutes]	
										, [DiffFromStdDev]	
										, [RecordsPerSecond]
									FROM
									    #ETL_Stats_WinnersAndLosers
									/*
									WHERE
										[SystemKey] = @SystemKey
										AND [ProcessName] = @_ProcessName
										AND [NumDaysBack] = @_DaysBack
										AND [RunID] > @_MaxRunID_FromWinLosTable
									*/
																			
								)	AS SourceTable
						ON 
							TargetTable.[SystemKey]			= SourceTable.[SystemKey] 
						AND TargetTable.[RunID]				= SourceTable.[RunID]		
						AND TargetTable.[LogID]				= SourceTable.[LogID]		 
						AND TargetTable.[NumDaysBack]		= SourceTable.[NumDaysBack]
						
						WHEN MATCHED AND

							TargetTable.[TaskDuration]		<> SourceTable.[TaskDuration] 
						OR	TargetTable.[AvgDuration]		<> SourceTable.[AvgDuration]		
						OR	TargetTable.[StDevInMinutes]	<> SourceTable.[StDevInMinutes]		 
						OR	TargetTable.[DiffFromStdDev]	<> SourceTable.[DiffFromStdDev]
						OR	TargetTable.[RecordsPerSecond]	<> SourceTable.[RecordsPerSecond]

						THEN UPDATE SET

						  TargetTable.[TaskDuration]		= SourceTable.[TaskDuration] 
						, TargetTable.[AvgDuration]			= SourceTable.[AvgDuration]		
						, TargetTable.[StDevInMinutes]		= SourceTable.[StDevInMinutes]		 
						, TargetTable.[DiffFromStdDev]		= SourceTable.[DiffFromStdDev]
						, TargetTable.[RecordsPerSecond]	= SourceTable.[RecordsPerSecond]
						
						WHEN NOT MATCHED BY TARGET THEN

						INSERT (
								  [SystemKey]		
								, [RunID]			
								, [LogID]			
								, [TimeRecorded]	
								, [ProcessName]		
								, [NumDaysBack]		
								, [TaskDuration]	
								, [AvgDuration]		
								, [StDevInMinutes]	
								, [DiffFromStdDev]	
								, [RecordsPerSecond]
						)
						VALUES (
									  SourceTable.[SystemKey]		
									, SourceTable.[RunID]			
									, SourceTable.[LogID]			
									, SourceTable.[TimeRecorded]	
									, SourceTable.[ProcessName]		
									, SourceTable.[NumDaysBack]		
									, SourceTable.[TaskDuration]	
									, SourceTable.[AvgDuration]		
									, SourceTable.[StDevInMinutes]	
									, SourceTable.[DiffFromStdDev]	
									, SourceTable.[RecordsPerSecond]
								);

				END
END
GO
