USE [YourDbName]
GO

---------------------------------------------------------------
---- FIND THE FREE SPACE ON EACH FILE WITHIN A DATABASE: ------
---------------------------------------------------------------

SELECT 
                [TYPE] = A.TYPE_DESC
                ,[FILE_Name] = A.name
                ,[FILEGROUP_NAME] = fg.name
                ,[File_Location] = A.PHYSICAL_NAME
                ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
                ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0))
                ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
                ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)
                ,[AutoGrow] = 'By ' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + ' MB -' 
                    WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '% -' ELSE '' END 
                    + CASE max_size WHEN 0 THEN 'DISABLED' WHEN -1 THEN ' Unrestricted' 
                        ELSE ' Restricted to ' + CAST(max_size/(128*1024) AS VARCHAR(10)) + ' GB' END 
                    + CASE is_percent_growth WHEN 1 THEN ' [autogrowth by percent, BAD setting!]' ELSE '' END
FROM 
                sys.filegroups fg 
LEFT OUTER JOIN sys.database_files A ON A.data_space_id = fg.data_space_id 
ORDER BY [TYPE] DESC, [FILE_Name];


---------------------------------------------------------------
---- SHRINK FILES TO REDUCE UNUSED SPACE:               -------
---------------------------------------------------------------

/*
CHECKPOINT;
GO

DBCC DROPCLEANBUFFERS;
GO

DBCC FREEPROCCACHE;
GO

DBCC FREESYSTEMCACHE ('ALL');
GO

DBCC FREESESSIONCACHE
GO

*/

USE [YourDbName]
GO
DBCC SHRINKFILE (tempdevXX, 16384); --SIZE IN MB
GO