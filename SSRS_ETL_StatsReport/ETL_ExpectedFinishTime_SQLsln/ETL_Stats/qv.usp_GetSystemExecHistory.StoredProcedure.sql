USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_GetSystemExecHistory]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [qv].[usp_GetSystemExecHistory]
@SystemKey INT, @RunID INT
AS
BEGIN

-- ALL SYSTEMS ON AON_MI_DWH:
-- //////////////////// @SystemName = 'Broaksure'				=> SystemKey = 115
-- //////////////////// @SystemName = 'Pure'					=> SystemKey = 110
-- //////////////////// @SystemName = 'MGA'						=> SystemKey = 122
-- //////////////////// @SystemName = 'ActivityTracker'			=> SystemKey = 1003

IF ((@SystemKey = 115) OR (@SystemKey = 110) OR (@SystemKey = 122) OR (@SystemKey = 1003))
	BEGIN
		SELECT
			  lt.[LogID]
			, lt.[SystemKey]
			, lt.[ProcessName]
			, lt.[ProcessStartTime]
			, lt.[ProcessEndTime]
			, CONVERT(TIME(0),[ProcessDuration],0)						AS [ProcessDuration]
			, CONVERT(BIGINT, DATEDIFF(ss, 0, lt.[ProcessDuration]))	AS [ProcessDurationSec]
			, lt.[InsertCount]
			, lt.[UpdateCount]
			, lt.[DeleteCount]

			, CASE CONVERT(BIGINT, DATEDIFF(ss, 0, lt.[ProcessDuration]))
			  WHEN 0 THEN NULL 
			  ELSE (COALESCE(lt.[InsertCount], 0)+COALESCE(lt.[UpdateCount], 0)+COALESCE(lt.[DeleteCount], 0))/CONVERT(BIGINT, DATEDIFF(ss, 0, lt.[ProcessDuration]))
			  END														AS [RecordsPerSecond]
		
		FROM 
			[qv].[LogTable] lt
		WHERE RunID = @RunID AND ProcessName IN 
		(
			SELECT 
					[ProcessName]
			FROM	[qv].[ETL_Stats_LastRunTaskList] 
			WHERE	RunID = @RunID
			AND		ChildTaskName IS NOT NULL
		)
		ORDER BY lt.[LogID]
	END
ELSE
	BEGIN
		SELECT
			  lt.[LogID]
			, lt.[SystemKey]
			, lt.[ProcessName]
			, lt.[ProcessStartTime]
			, lt.[ProcessEndTime]
			, CONVERT(TIME(0),[ProcessDuration],0)					   AS [ProcessDuration]
			, CONVERT(BIGINT, DATEDIFF(ss, 0, lt.[ProcessDuration]))   AS [ProcessDurationSec]
			--, lt.[ProcessDuration]
			, lt.[InsertCount]
			, lt.[UpdateCount]
			, lt.[DeleteCount]

			, CASE CONVERT(BIGINT, DATEDIFF(ss, 0, lt.[ProcessDuration]))
			  WHEN 0 THEN NULL 
			  ELSE (COALESCE(lt.[InsertCount], 0)+COALESCE(lt.[UpdateCount], 0)+COALESCE(lt.[DeleteCount], 0))/CONVERT(BIGINT, DATEDIFF(ss, 0, lt.[ProcessDuration]))
			  END														AS [RecordsPerSecond]
		FROM 
			[qv].[LogTable_ACIA] lt
		WHERE RunID = @RunID AND ProcessName IN 
		(
			SELECT 
					[ProcessName]
			FROM	[qv].[ETL_Stats_LastRunTaskList] 
			WHERE	RunID = @RunID
			AND		ChildTaskName IS NOT NULL
		)
		ORDER BY lt.[LogID]
	END
END
GO
