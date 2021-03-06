USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_GetExpectedFinishTime_PerSystem_2]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
    
    
CREATE PROCEDURE [qv].[usp_GetExpectedFinishTime_PerSystem_2] @SystemName NVARCHAR(64) = NULL, @SystemKey INT = NULL    
AS    
BEGIN    
--DECLARE @SystemName NVARCHAR(64) = 'AllData'    
SET NOCOUNT ON;    
    
DECLARE @ErMessage NVARCHAR(2048),    
  @ErSeverity INT,    
  @ErState INT    
    
IF (@SystemName IS NULL AND @SystemKey IS NULL)    
BEGIN    
  SELECT    
     @ErMessage = 'You have to supply either @SystemName or @SystemKey - they can''t be both NULL!',    
     @ErSeverity = 15, --ERROR_SEVERITY(),    
     @ErState = ERROR_STATE()    
  RAISERROR (@ErMessage, @ErSeverity, @ErState)    
  RETURN    
END    
    
IF (@SystemName IS NOT NULL AND @SystemKey IS NOT NULL)    
BEGIN    
  SELECT    
     @ErMessage = 'You have to supply either @SystemName or @SystemKey - don''t supply both!',    
     @ErSeverity = 15, --ERROR_SEVERITY(),    
     @ErState = ERROR_STATE()    
  RAISERROR (@ErMessage, @ErSeverity, @ErState)    
  RETURN    
END    
    
DECLARE @CheckParameterResult BIT = 0 --, @SystemKey INT    
IF (@SystemKey IS NULL)    
BEGIN    
 EXEC [qv].[usp_GetSystemKeyFromName] @_SystemName = @SystemName, @_CallingProcName = 'usp_GetExpectedFinishTime_PerSystem', @_CheckResult = @CheckParameterResult OUTPUT, @_SystemKey = @SystemKey OUTPUT    
 IF (@CheckParameterResult = 0) RETURN    
END    
    
/*    
EXEC [qv].[usp_CheckSystemName] @_SystemName = @SystemName, @_CallingProcName = 'usp_GetExpectedFinishTime_PerSystem', @_CheckResult = @CheckParameterResult OUTPUT    
IF (@CheckParameterResult = 0)    
BEGIN    
 RETURN    
END    
*/    
    
  --DECLARE @SystemKey INT    
  --SELECT @SystemKey = s.[dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName    
      
  --/////////////////////////  Brokasure AND Pure (on [AON_MI_DWH]): /////////////////////////      
  IF ((@SystemName = 'Brokasure') OR (@SystemName = 'Pure') OR (@SystemKey = 115) OR (@SystemKey = 110)) 
  BEGIN    
   ; WITH     
   AvgSystem AS     
   (    
    SELECT   TOP 1     
         s.[SystemKey]    
        , s.[7-DayAverage]    
        , s.[14-DayAverage]    
        , s.[30-DayAverage]    
    FROM       
        [qv].[ETL_Stats_AvgFinishTime_System] s    
    WHERE    
        s.[SystemKey] = 115 --(SELECT s.[dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName)    
    ORDER BY  s.[TimeRecorded] DESC    
   )    
       
   SELECT     
       s.[SystemName]    
      , s.[dim_aon_system_key]    
      , l.[ProcessName]    
      , CONVERT(TIME(0),l.[ProcessStartTime],0)    AS [Task Start Time]    
    
      ,   DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[7-DayAverage])) AS [Task_7DAv_Diff]    
      ,   DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[14-DayAverage])) AS [Task_14DAv_Diff]    
      ,   DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[30-DayAverage])) AS [Task_30DAv_Diff]    
    
      --, CONVERT(TIME(0),a.[7-DayAverage] ,0)    AS [System_7D_ExpectedFinish]    
      --, CONVERT(TIME(0),a.[14-DayAverage] ,0)    AS [System_14D_ExpectedFinish]    
      --, CONVERT(TIME(0),a.[30-DayAverage] ,0)    AS [System_30D_ExpectedFinish]    
    
   , CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[7-DayAverage])) ), a.[7-DayAverage] ), 0) AS [System_7D_ExpectedFinish]    
   , CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[14-DayAverage]))), a.[14-DayAverage] ), 0) AS [System_14D_ExpectedFinish]    
   , CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[30-DayAverage]))), a.[30-DayAverage] ), 0) AS [System_30D_ExpectedFinish]    
    
   FROM     
      [AON_MI_DWH].[dbo].LogTable   l  WITH (NOLOCK)    
   INNER JOIN [qv].[dim_aon_system]         s  ON s.[dim_aon_system_key] = l.[SystemKey]    
   INNER JOIN  [qv].[ufn_GetTaskAvg_PerSystemKey](115)   t  ON t.[ProcessName]   = l.[ProcessName]    
   INNER JOIN  AvgSystem            a  ON a.[SystemKey]   = l.[SystemKey]    
       
   WHERE  l.ProcessStartTime > (SELECT CAST(GETDATE()-1 AS DATE)) AND l.[Status] = 'RUNNING' --'SUCCESS'    
  END    
  ELSE --/////////////////////////  All Non-Brokasure Systems (on [ACIA_DWH]): /////////////////////////      
  BEGIN    
   ; WITH     
   AvgSystem AS     
   (    
    SELECT   TOP 1     
         s.[SystemKey]    
        , s.[7-DayAverage]    
        , s.[14-DayAverage]    
        , s.[30-DayAverage]    
    FROM       
        [qv].[ETL_Stats_AvgFinishTime_System] s    
    WHERE    
        s.[SystemKey] = 115 --(SELECT s.[dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName)    
    ORDER BY  s.[TimeRecorded] DESC    
   )    
       
   SELECT     
       s.[SystemName]    
      , s.[dim_aon_system_key]    
      , l.[ProcessName]    
      , CONVERT(TIME(0),l.[ProcessStartTime],0)    AS [Task Start Time]    
    
      ,   DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[7-DayAverage]))  AS [Task_7DAv_Diff]    
      ,   DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[14-DayAverage])) AS [Task_14DAv_Diff]    
      ,   DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[30-DayAverage])) AS [Task_30DAv_Diff]    
    
      --, CONVERT(TIME(0),a.[7-DayAverage] ,0)    AS [System_7D_ExpectedFinish]    
      --, CONVERT(TIME(0),a.[14-DayAverage] ,0)    AS [System_14D_ExpectedFinish]    
      --, CONVERT(TIME(0),a.[30-DayAverage] ,0)    AS [System_30D_ExpectedFinish]    
    
   , CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[7-DayAverage])) ), a.[7-DayAverage] ), 0) AS [System_7D_ExpectedFinish]    
   , CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[14-DayAverage]))), a.[14-DayAverage] ), 0) AS [System_14D_ExpectedFinish]    
   , CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),l.[ProcessStartTime],0), CONVERT(TIME(0),t.[30-DayAverage]))), a.[30-DayAverage] ), 0) AS [System_30D_ExpectedFinish]    
    
   FROM     
      [ACIA_DWH].[dbo].LogTable    l  WITH (NOLOCK)    
   INNER JOIN [qv].[dim_aon_system]         s  ON s.[dim_aon_system_key] = l.[SystemKey]    
   INNER JOIN  [qv].[ufn_GetTaskAvg_PerSystemKey](115)   t  ON t.[ProcessName]   = l.[ProcessName]    
   INNER JOIN  AvgSystem            a  ON a.[SystemKey]   = l.[SystemKey]    
       
   WHERE  l.ProcessStartTime > (SELECT CAST(GETDATE()-1 AS DATE)) AND l.[Status] = 'RUNNING' --'SUCCESS'    
  END    
END 
GO
