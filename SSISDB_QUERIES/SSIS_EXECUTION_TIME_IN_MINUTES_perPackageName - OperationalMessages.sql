DECLARE @PackageName NVARCHAR(256) = 'PackageName.dtsx'
DECLARE @ProcName NVARCHAR(256) = '%sp_ProcName%'
DECLARE @DateSince DATETIME = DATEADD(day, -7, GETDATE())

SELECT DISTINCT 

      O.start_time AS Start_Time
      , O.end_time AS End_Time
      , E.Project_name AS Project_Name
    --, E.Environment_Name
      , EM.Package_Name
    --, EM.Package_Path
      , O.Operation_Id
      , OM.operation_message_id
      , OM.message
      , O.status
      , DATEDIFF(second, o.start_time, o.end_time) AS duration_sec
      , DATEDIFF(minute, o.start_time, o.end_time) AS duration_min

    --, OM.message AS [Error_Message]
    --, EM.Event_Name
    --, EM.Message_Source_Name AS Component_Name
    --, EM.Subcomponent_Name AS Sub_Component_Name


FROM                [SSISDB].[internal].[operations] (NOLOCK) AS O
INNER JOIN          [SSISDB].[internal].[event_messages] (NOLOCK) AS EM ON EM.operation_id = O.operation_id
INNER JOIN          [SSISDB].[internal].[operation_messages] (NOLOCK) AS OM ON EM.operation_id = OM.operation_id
INNER JOIN          [SSISDB].[internal].[executions] (NOLOCK) AS E ON OM.Operation_id = E.EXECUTION_ID
WHERE 1 = 1
AND                 O.start_time >= @DateSince
AND                 EM.Package_Name = @PackageName 
--AND                 OM.[message] LIKE @ProcName
--AND               EM.event_name = 'OnError'
--AND               OM.Message_Type = 120 -- Error 
--AND               EM.event_name = 'OnError'
--AND               OM.message LIKE '%duplicate%'
--AND               OM.message LIKE '%lock%'
ORDER BY 

            O.operation_id DESC, OM.operation_message_id DESC
            --CONVERT(DATETIME, O.start_time) DESC;


--SELECT * FROM SSISDB.internal.operation_messages WHERE operation_id = 1026540