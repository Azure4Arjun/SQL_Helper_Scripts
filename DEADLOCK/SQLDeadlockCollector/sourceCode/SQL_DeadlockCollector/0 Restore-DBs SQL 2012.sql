USE [master]
GO
RESTORE DATABASE [SQL_Analysis_Code]
FROM  DISK = N'D:\SQLData\SQLBackup\SQL_Analysis_Code_2012.bak'
WITH
MOVE N'SQL_Analysis_Code' TO N'D:\SQLData\SQLData1\SQLData1\SQL_Analysis_Code_2012.mdf'
,  MOVE N'SQL_Analysis_Code_log' TO N'D:\SQLData\SQLLog1\SQLLog1\SQL_Analysis_Code_log_2012.ldf'
, STATS = 20

GO

USE [master]
GO
RESTORE DATABASE [SQL_Analysis_Data]
FROM  DISK = N'D:\SQLData\SQLBackup\SQL_Analysis_Data_2012.bak'
WITH
MOVE N'SQL_Analysis_Data' TO N'D:\SQLData\SQLData1\SQLData1\SQL_Analysis_Data_2012.mdf'
,  MOVE N'SQL_Analysis_Data_log' TO N'D:\SQLData\SQLLog1\SQLLog1\SQL_Analysis_Data_log_2012.ldf'
, STATS = 20

GO


USE [master]
GO
RESTORE DATABASE [SQL_Analysis_Reporting]
FROM  DISK = N'D:\SQLData\SQLBackup\SQL_Analysis_Reporting_2012.bak'
WITH
MOVE N'SQL_Analysis_Reporting' TO N'D:\SQLData\SQLData1\SQLData1\SQL_Analysis_Reporting_2012.mdf'
,  MOVE N'SQL_Analysis_Reporting_log' TO N'D:\SQLData\SQLLog1\SQLLog1\SQL_Analysis_Reporting_log_2012.ldf'
, STATS = 20

GO

ALTER AUTHORIZATION
    ON DATABASE::[SQL_Analysis_Code] 
    TO sa

GO

ALTER AUTHORIZATION
    ON DATABASE::[SQL_Analysis_Data] 
    TO sa

GO

ALTER AUTHORIZATION
    ON DATABASE::[SQL_Analysis_Reporting] 
    TO sa

GO