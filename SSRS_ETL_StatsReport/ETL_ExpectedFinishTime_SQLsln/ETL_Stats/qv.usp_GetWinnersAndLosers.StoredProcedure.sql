USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_GetWinnersAndLosers]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [qv].[usp_GetWinnersAndLosers] @StartDate DATETIME = NULL, @EndDate DATETIME = NULL
AS
BEGIN
SET NOCOUNT ON;

IF @StartDate IS NULL
BEGIN
	SET @StartDate = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())-1, 0)
END
IF @EndDate IS NULL
BEGIN
	SET @EndDate = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())+1, 0)
END

SELECT  
			  wl.[SystemKey]
			, CASE s.[systemname] 
			  	WHEN 'Xpress' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))	
			  	WHEN 'eGlobal' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))
				WHEN 'MGA' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))
				WHEN 'BMW' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))
			  ELSE s.[systemname] END AS [SystemName]
			, wl.[RunID]
			, wl.[LogID]
			, wl.[TimeRecorded]
			, wl.[ProcessName]
			, wl.[NumDaysBack] AS [Stats in Days]
			, CONVERT(VARCHAR(20), wl.[TaskDuration], 120)			AS [TaskDuration]
			, CONVERT(BIGINT,DATEDIFF(ss,0,wl.[TaskDuration]))		AS [TaskDurationSec]
			, CONVERT(VARCHAR(20), wl.[AvgDuration], 120)			AS [AvgDuration]
			, CONVERT(BIGINT,DATEDIFF(ss,0,wl.[AvgDuration]))		AS [AvgDurationSec]
			, wl.[StDevInMinutes]
			, wl.[DiffFromStdDev]
			, wl.[RecordsPerSecond]
FROM 
			[qv].[ETL_Stats_WinnersAndLosers] wl
INNER JOIN	[qv].[dim_aon_system] s ON s.[dim_aon_system_key] = wl.[SystemKey]
--OUTER APPLY [qv].[ufn_GetLastRunID_PerSystemKey](wl.SystemKey)
WHERE 
			wl.[TimeRecorded] >= @StartDate	AND	--DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())-1, 0) AND
			wl.[TimeRecorded] <= DATEADD(DAY, DATEDIFF(DAY, 0, @EndDate)+1, 0)		--DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())+1, 0)
ORDER BY
			CAST(wl.[TimeRecorded] AS DATE) DESC, wl.[DiffFromStdDev]
END
GO
