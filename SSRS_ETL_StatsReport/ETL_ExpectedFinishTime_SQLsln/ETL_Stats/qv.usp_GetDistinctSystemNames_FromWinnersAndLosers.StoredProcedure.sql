USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_GetDistinctSystemNames_FromWinnersAndLosers]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [qv].[usp_GetDistinctSystemNames_FromWinnersAndLosers] 
@DaysBack INT, @SystemKey INT = NULL, @StartDate DATETIME = NULL, @EndDate DATETIME = NULL
AS
BEGIN
SET NOCOUNT ON;

DECLARE @SystemName NVARCHAR(64),
		@ErMessage NVARCHAR(2048),
		@ErSeverity INT,
		@ErState INT

IF ((@DaysBack IS NULL) AND (@StartDate IS NULL OR @EndDate IS NULL))
BEGIN
		SELECT
		   @ErMessage = 'You have to supply either @DaysBack parameter or both @StartDate and @EndDate.',
		   @ErSeverity = 15, --ERROR_SEVERITY(),
		   @ErState = ERROR_STATE()
		 
		RAISERROR (@ErMessage, @ErSeverity, @ErState)
		RETURN
END

IF ((@DaysBack IS NOT NULL) AND (@StartDate IS NULL OR @EndDate IS NULL))
BEGIN
	SET @StartDate	= DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())+@DaysBack, 0)
	SET @EndDate	= DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())+1, 0)
END

SELECT  
			DISTINCT
			CASE s.[systemname] 
			  	WHEN 'Xpress' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))	
			  	WHEN 'eGlobal' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))
				WHEN 'MGA' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))
				WHEN 'BMW' THEN	CONCAT(s.[systemname], CONCAT('_', s.[systemcountrycode]))
			ELSE s.[systemname] END AS [SystemName]
FROM 
			[qv].[ETL_Stats_WinnersAndLosers] wl
INNER JOIN	[qv].[dim_aon_system] s ON s.[dim_aon_system_key] = wl.[SystemKey]
OUTER APPLY [qv].[ufn_GetLastRunID_PerSystemKey](wl.SystemKey)
WHERE 
			wl.[TimeRecorded] >= @StartDate	AND	--DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())-1, 0) AND
			wl.[TimeRecorded] <= @EndDate		--DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE())+1, 0)
ORDER BY
			[SystemName]
END
GO
