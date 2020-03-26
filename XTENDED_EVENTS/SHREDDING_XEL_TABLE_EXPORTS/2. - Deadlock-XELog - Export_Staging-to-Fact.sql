USE DeadlockHistory
GO

SET NOCOUNT ON
GO

DROP TABLE IF EXISTS [dbo].[DeadlockFact];
GO

CREATE TABLE [dbo].[DeadlockFact] (    
      [DeadlockID] BIGINT NOT NULL
	, [DeadlockTime] DATETIME NOT NULL
    , [TransactionTime] DATETIME NULL
    , [LastBatchStarted] DATETIME NULL
    , [LastBatchCompleted] DATETIME NULL
    , [PagelockObject] VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [DeadlockObject] VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [KeyLockObject] VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [KeyLockIndex] VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [IsVictim] INT NOT NULL
    , [ProcessID] VARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
    , [Procedure] VARCHAR(200) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [LockMode] CHAR(5) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [SqlCode] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [HostName] VARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [LoginName] VARCHAR(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [InputBuffer] VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [DatabaseName_1] VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [DatabaseName_2] VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [WaitResource_1] VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [WaitResource_2] VARCHAR(500) COLLATE SQL_Latin1_General_CP1_CI_AS NULL
    , [xml_report] XML NULL
)
GO


DROP TABLE IF EXISTS [#DeadlockStaging]

CREATE TABLE [#DeadlockStaging] (
	 [name]                                  NVARCHAR(MAX) NULL
	,[timestamp]                             DATETIMEOFFSET(7) NULL
	,[timestamp (UTC)]                       DATETIMEOFFSET(7) NULL
	,[resource_type]                         NVARCHAR(MAX) NULL
	,[mode]                                  NVARCHAR(MAX) NULL
	,[owner_type]                            NVARCHAR(MAX) NULL
	,[transaction_id]                        BIGINT NULL
	,[database_id]                           BIGINT NULL
	,[lockspace_workspace_id]                DECIMAL(20, 0) NULL
	,[lockspace_sub_id]                      BIGINT NULL
	,[lockspace_nest_id]                     BIGINT NULL
	,[resource_0]                            BIGINT NULL
	,[resource_1]                            BIGINT NULL
	,[resource_2]                            BIGINT NULL
	,[deadlock_id]                           BIGINT NULL
	,[object_id]                             INT NULL
	,[associated_object_id]                  DECIMAL(20, 0) NULL
	,[session_id]                            SMALLINT NULL
	,[resource_owner_type]                   NVARCHAR(MAX) NULL
	,[resource_description]                  NVARCHAR(MAX) NULL
	,[database_name]                         NVARCHAR(MAX) NULL
	,[username]                              NVARCHAR(MAX) NULL
	,[nt_username]                           NVARCHAR(MAX) NULL
	,[duration]                              DECIMAL(20, 0) NULL
	,[sql_text]                              NVARCHAR(MAX) NULL
	,[xml_report]                            XML NULL
	,[deadlock_cycle_id]                     DECIMAL(20, 0) NULL
	,[server_name]                           NVARCHAR(MAX) NULL
) ON [PRIMARY]
GO

DECLARE @deadlock_timestamp DATETIME2, @counter INT = 1, @deadlock_id BIGINT, @object_id BIGINT, @associated_object_id DECIMAL(20,0), @xml_report XML, @rowcount INT

DECLARE my_cursor CURSOR FOR
        
        SELECT DISTINCT
               CONVERT(DATETIME2(0), [timestamp]) AS [timestamp_NoMilliSec]
        FROM   [dbo].[DeadlockStaging]
        
OPEN my_cursor   
FETCH NEXT FROM my_cursor INTO @deadlock_timestamp
WHILE @@FETCH_STATUS = 0   
BEGIN
--------------------------------------------------------------------------
        
        TRUNCATE TABLE [#DeadlockStaging]
        
        INSERT INTO [#DeadlockStaging] 
            (
                [name]                       
               ,[timestamp]                  
               ,[timestamp (UTC)]            
               ,[resource_type]              
               ,[mode]                       
               ,[owner_type]                 
               ,[transaction_id]             
               ,[database_id]                
               ,[lockspace_workspace_id]     
               ,[lockspace_sub_id]           
               ,[lockspace_nest_id]          
               ,[resource_0]                 
               ,[resource_1]                 
               ,[resource_2]                 
               ,[deadlock_id]                
               ,[object_id]                  
               ,[associated_object_id]       
               ,[session_id]                 
               ,[resource_owner_type]        
               ,[resource_description]       
               ,[database_name]              
               ,[username]                   
               ,[nt_username]                
               ,[duration]                   
               ,[sql_text]
               ,[xml_report]          
               ,[deadlock_cycle_id]   
               ,[server_name]         
            )

        SELECT 
             [name]                       
            ,[timestamp]                  
            ,[timestamp (UTC)]            
            ,[resource_type]              
            ,[mode]                       
            ,[owner_type]                 
            ,[transaction_id]             
            ,[database_id]                
            ,[lockspace_workspace_id]     
            ,[lockspace_sub_id]           
            ,[lockspace_nest_id]          
            ,[resource_0]                 
            ,[resource_1]                 
            ,[resource_2]                 
            ,[deadlock_id]                
            ,[object_id]                  
            ,[associated_object_id]       
            ,[session_id]                 
            ,[resource_owner_type]        
            ,[resource_description]       
            ,[database_name]              
            ,[username]                   
            ,[nt_username]                
            ,[duration]                   
            ,[sql_text]
            ,[xml_report]          
            ,[deadlock_cycle_id]   
            ,[server_name]         
            
        FROM dbo.[DeadlockStaging] 
        WHERE CONVERT(DATETIME2(0), [timestamp]) = @deadlock_timestamp
        SELECT @rowcount = @@ROWCOUNT

        PRINT(CONCAT(@deadlock_timestamp, ' ', @counter, ' Rowcount: ', @rowcount))
        
        IF (@rowcount > 0)
        BEGIN
            IF (SELECT COUNT(DISTINCT deadlock_id) FROM [#DeadlockStaging]) = 1
            BEGIN
                SELECT @deadlock_id = deadlock_id FROM [#DeadlockStaging] WHERE deadlock_id > 0
            END
            ----------------------------------------------------------------------------------------------------------
            DECLARE xml_report_cursor CURSOR FOR
            
                                SELECT CAST(xml_report AS XML) 
                                FROM dbo.[#DeadlockStaging]
                                WHERE xml_report IS NOT NULL

            OPEN xml_report_cursor   
            FETCH NEXT FROM xml_report_cursor INTO @xml_report  
            WHILE @@FETCH_STATUS = 0   
                    BEGIN

							MERGE [dbo].[DeadlockFact] AS trg
							USING (
									SELECT
                                                [DeadlockID] = COALESCE(@deadlock_id, 0),
									            [DeadlockTime] = COALESCE(Deadlock.Process.value('@lasttranstarted', 'datetime'), Deadlock.Process.value('@lastbatchstarted', 'datetime')),
                                                [TransactionTime] = Deadlock.Process.value('@lasttranstarted', 'datetime'),
                                                [LastBatchStarted] = Deadlock.Process.value('@lastbatchstarted', 'datetime'),
                                                [LastBatchCompleted] = Deadlock.Process.value('@lastbatchcompleted', 'datetime'),
                                                [PagelockObject] = @xml_report.value('/deadlock[1]/resource-list[1]/pagelock[1]/@objectname', 'varchar(200)'),
                                                [DeadlockObject] = @xml_report.value('/deadlock[1]/resource-list[1]/objectlock[1]/@objectname', 'varchar(200)'),
                                                [KeyLockObject] = @xml_report.value('/deadlock[1]/resource-list[1]/keylock[1]/@objectname', 'varchar(200)'),
                                                [KeyLockIndex] = @xml_report.value('/deadlock[1]/resource-list[1]/keylock[1]/@indexname', 'varchar(200)'),
                                                [IsVictim] = CASE WHEN Deadlock.Process.value('@id', 'varchar(50)') = @xml_report.value('/deadlock[1]/victim-list[1]/victimProcess[1]/@id', 'varchar(50)') THEN 1 ELSE 0 END,
                                                [ProcessID] = Deadlock.Process.value('@id', 'varchar(50)'),
                                                [Procedure] = Deadlock.Process.value('executionStack[1]/frame[1]/@procname[1]', 'varchar(200)'),
                                                [LockMode] = Deadlock.Process.value('@lockMode', 'char(5)'),
                                                [SqlCode] = Deadlock.Process.value('executionStack[1]/frame[1]', 'varchar(1000)'),
                                                [HostName] = Deadlock.Process.value('@hostname', 'varchar(20)'),
                                                [LoginName] = Deadlock.Process.value('@loginname', 'varchar(20)'),
                                                [InputBuffer] = Deadlock.Process.value('inputbuf[1]', 'varchar(1000)'),
                                                [DatabaseName_1] = Deadlock.Process.value('/deadlock[1]/process-list[1]/process[1]/@currentdbname', 'varchar(500)'),
                                                [DatabaseName_2] = Deadlock.Process.value('/deadlock[1]/process-list[1]/process[2]/@currentdbname', 'varchar(500)'),
                                                [WaitResource_1] = Deadlock.Process.value('/deadlock[1]/process-list[1]/process[1]/@waitresource', 'varchar(500)'),
                                                [WaitResource_2] = Deadlock.Process.value('/deadlock[1]/process-list[1]/process[2]/@waitresource', 'varchar(500)'),
                                                [XmReport] = @xml_report
									FROM        @xml_report.nodes('/deadlock/process-list/process') as Deadlock(Process)) AS src
								            ON (   trg.[DeadlockID]   = src.[DeadlockID]
								            	AND trg.[DeadlockTime] = src.[DeadlockTime]
								            	AND trg.[ProcessID]    = src.[ProcessID]
								            	AND trg.[IsVictim]     = src.[IsVictim]
								)
								WHEN MATCHED THEN
								UPDATE SET
						    		   trg.[DeadlockTime]           = src.[DeadlockTime]
						    		 , trg.[TransactionTime]        = src.[TransactionTime]
						    		 , trg.[LastBatchStarted]		= src.[LastBatchStarted]
						    		 , trg.[LastBatchCompleted]     = src.[LastBatchCompleted]
						    		 , trg.[PagelockObject]			= src.[PagelockObject]
						    		 , trg.[DeadlockObject]			= src.[DeadlockObject]
						    		 , trg.[KeyLockObject]			= src.[KeyLockObject]
						    		 , trg.[KeyLockIndex]			= src.[KeyLockIndex]
						    	--	 , trg.[IsVictim]				= src.[IsVictim]
						    	--	 , trg.[ProcessID]				= src.[ProcessID]
						    		 , trg.[Procedure]				= src.[Procedure]
						    		 , trg.[LockMode]				= src.[LockMode]
						    		 , trg.[SqlCode]				= src.[SqlCode]
						    		 , trg.[HostName]				= src.[HostName]
						    		 , trg.[LoginName]				= src.[LoginName]
						    		 , trg.[InputBuffer]			= src.[InputBuffer]
						    		 , trg.[DatabaseName_1]			= src.[DatabaseName_1]
						    		 , trg.[DatabaseName_2]			= src.[DatabaseName_2]
						    		 , trg.[WaitResource_1]			= src.[WaitResource_1]
						    		 , trg.[WaitResource_2]			= src.[WaitResource_2]
						    		 , trg.[xml_report]				= src.[XmReport]
								WHEN NOT MATCHED THEN
								INSERT (
								          [DeadlockID]
								        , [DeadlockTime]
								        , [TransactionTime]
								        , [LastBatchStarted]
								        , [LastBatchCompleted]
								        , [PagelockObject]
								        , [DeadlockObject]
								        , [KeyLockObject]
								        , [KeyLockIndex]
								        , [IsVictim]
								        , [ProcessID]
								        , [Procedure]
								        , [LockMode]
								        , [SqlCode]
								        , [HostName]
								        , [LoginName]
								        , [InputBuffer]
								        , [DatabaseName_1]
								        , [DatabaseName_2]
								        , [WaitResource_1]
								        , [WaitResource_2]
								        , [xml_report] )
								VALUES (
									      src.[DeadlockID]
								          , src.[DeadlockTime]
								          , src.[TransactionTime]
								          , src.[LastBatchStarted]
								          , src.[LastBatchCompleted]
								          , src.[PagelockObject]
								          , src.[DeadlockObject]
								          , src.[KeyLockObject]
								          , src.[KeyLockIndex]
								          , src.[IsVictim]
								          , src.[ProcessID]
								          , src.[Procedure]
								          , src.[LockMode]
								          , src.[SqlCode]
								          , src.[HostName]
								          , src.[LoginName]
								          , src.[InputBuffer]
								          , src.[DatabaseName_1]
								          , src.[DatabaseName_2]
								          , src.[WaitResource_1]
								          , src.[WaitResource_2]
								          , src.[XmReport] );

                    FETCH NEXT FROM xml_report_cursor INTO @xml_report  
                    END   

            CLOSE xml_report_cursor  
            DEALLOCATE xml_report_cursor
            ----------------------------------------------------------------------------------------------------------
        END
        SET @counter = @counter + 1
--------------------------------------------------------------------------
    FETCH NEXT FROM my_cursor INTO @deadlock_timestamp
END   
CLOSE my_cursor   
DEALLOCATE my_cursor
----------------------------------


SELECT * FROM dbo.DeadlockFact ORDER BY DeadlockTime DESC