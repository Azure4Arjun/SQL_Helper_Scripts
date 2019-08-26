-- based on: https://www.mssqltips.com/sqlservertip/3445/using-the-sql-server-default-trace-to-audit-events/

DECLARE @NewestTraceFilePath NVARCHAR(1000), @TraceDirPath NVARCHAR(1000), @OldestTraceFilePath NVARCHAR(1000)

SET @NewestTraceFilePath = (SELECT [path] FROM sys.traces WHERE is_default = 1)
SELECT @TraceDirPath = SUBSTRING(@NewestTraceFilePath, 1, LEN(@NewestTraceFilePath) - CHARINDEX('\', reverse(@NewestTraceFilePath)))
DECLARE @cmd NVARCHAR(256) = 'DIR '+@TraceDirPath+'\*.trc /TA'
PRINT '@cmd: '+@cmd

IF OBJECT_ID('tempdb..#cmdShellResults') IS NOT NULL
      DROP TABLE #cmdShellResults;
CREATE TABLE #cmdShellResults
		(
			[row] NVARCHAR(400)
		)
INSERT	#cmdShellResults
		(
			[row]
		)
EXEC master..xp_cmdshell @cmd
--SELECT * FROM #cmdShellResults

; WITH FileListing AS
(
SELECT [FileName] = SUBSTRING([row], 37, 400) FROM #cmdShellResults WHERE SUBSTRING([row], 37, 400) LIKE '%.trc'
) 
SELECT @OldestTraceFilePath = @TraceDirPath+'\'+(SELECT TOP 1 [FileName] FROM FileListing)


--Auto Stats, Indicates an automatic updating of index statistics has occurred.
/*
The Default trace does not include information on Auto Statistics event, 
but you can add this event to be captured by using the sp_trace_setevent stored procedure. 
The trace event id is 58. It important to say that the information for this event can also be queried 
from the sys.dm_db_stats_properties DMF or Extended Events. 
Checking event details of Auto Statistics indicates automatic updating of index statistics that have occurred.

DECLARE @rc INT 
DECLARE @TraceID INT 
DECLARE @maxFileSize bigint 
DECLARE @fileName NVARCHAR(128) 
DECLARE @on bit 
-- Set values 
SET @maxFileSize = 5 
SET @fileName = @NewestTraceFilePath
SET @on = 1 

EXEC @rc = sp_trace_create @TraceID output, 0, @fileName, @maxFileSize, NULL 
EXEC sp_trace_setevent @TraceID, 58,  1, @on 

*/

SELECT TextData, ObjectID, ObjectName, IndexID, Duration, StartTime, EndTime, 
SPID, ApplicationName, LoginName  
FROM sys.fn_trace_gettable(@OldestTraceFilePath, DEFAULT)
--FROM sys.fn_trace_gettable(@NewestTraceFilePath, DEFAULT) -- <= for comparison if we search only the newest trace file
WHERE EventClass IN (58)
ORDER BY StartTime DESC