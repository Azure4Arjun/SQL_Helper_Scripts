USE [DWHSupport_Audit]
GO
/****** Object:  UserDefinedFunction [qv].[ufn_GetTaskAvg_PerSystemKey]    Script Date: 12/07/2019 10:34:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [qv].[ufn_GetTaskAvg_PerSystemKey] (@SystemKey INT) 
RETURNS TABLE 
AS
RETURN 
(
SELECT 
			[SystemKey]
		,	[TimeRecorded]
		,	[ProcessName]
		,	[7-DayAverage]
		,	[14-DayAverage]
		,	[30-DayAverage]
FROM 
		[qv].[ETL_Stats_AvgFinishTime_Task]
WHERE	[SystemKey] = @SystemKey
AND		[TimeRecorded] = (SELECT MAX([TimeRecorded]) FROM [qv].[ETL_Stats_AvgFinishTime_Task] WHERE [SystemKey] = @SystemKey)
)

GO
