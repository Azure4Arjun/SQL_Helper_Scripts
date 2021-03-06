USE [DWHSupport_Audit]
GO
/****** Object:  UserDefinedFunction [qv].[ufn_GetLastRunID_PerSystemKey_OnDay]    Script Date: 12/07/2019 10:34:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [qv].[ufn_GetLastRunID_PerSystemKey_OnDay] (@SystemKey INT, @OnDay DATE) 
RETURNS TABLE 
AS
RETURN 
		SELECT 
					SystemKey,
					MAX([RunID]) AS [MaxRunID]
		FROM		[qv].[LogTable]
		WHERE 
					[SystemKey] = @SystemKey
		AND			[ProcessEndTime] > DATEADD(DAY, DATEDIFF(DAY, 0, @OnDay), 0)
		AND			[ProcessEndTime]  < DATEADD(DAY, DATEDIFF(DAY, -1, @OnDay), 0)
		GROUP BY	SystemKey
		UNION
		SELECT 
					SystemKey,
					MAX([RunID])
		FROM		[qv].[LogTable_ACIA] AS [MaxRunID]
		WHERE 
					[SystemKey] = @SystemKey
		AND			[ProcessEndTime] > DATEADD(DAY, DATEDIFF(DAY, 0, @OnDay), 0)
		AND			[ProcessEndTime]  < DATEADD(DAY, DATEDIFF(DAY, -1, @OnDay), 0)
		GROUP BY	SystemKey
GO
