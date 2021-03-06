--https://sqlperformance.com/2014/02/sql-statistics/2014-incremental-statistics


USE [master]
GO

ALTER DATABASE [AdventureWorks2012]  REMOVE FILE [AdventureWorks2012_PartitionedData]
GO
ALTER DATABASE [AdventureWorks2012] ADD FILE ( NAME = N'AdventureWorks2012_PartitionedData', FILENAME = N'C:\MSSQL12.DEV2014\DATA\AdventureWorks2012_PartitionedData.ndf' , SIZE = 5120KB , FILEGROWTH = 1024KB ) TO FILEGROUP [SECONDARY]
GO
ALTER DATABASE [AdventureWorks2012] SET AUTO_CREATE_STATISTICS ON(INCREMENTAL = ON)
GO
ALTER DATABASE [AdventureWorks2012] SET COMPATIBILITY_LEVEL = 100
GO

USE [AdventureWorks2012]
GO

CREATE PARTITION FUNCTION TransactionRangePF1 (DATETIME)
AS RANGE RIGHT FOR VALUES 
(
   '20071001', '20071101', '20071201', '20080101', 
   '20080201', '20080301', '20080401', '20080501', 
   '20080601', '20080701', '20080801'
);
GO

CREATE PARTITION SCHEME TransactionsPS1 AS PARTITION TransactionRangePF1 TO 
(
  [SECONDARY], [SECONDARY], [SECONDARY], [SECONDARY], [SECONDARY], 
  [SECONDARY], [SECONDARY], [SECONDARY], [SECONDARY], [SECONDARY], 
  [SECONDARY], [SECONDARY], [SECONDARY]
);
GO

--DROP TABLE Production.TransactionHistory_Partitioned
CREATE TABLE Production.TransactionHistory_Partitioned
(
  TransactionID        INT      NOT NULL, -- not bothering with IDENTITY here
  ProductID            INT      NOT NULL,
  ReferenceOrderID     INT      NOT NULL,
  ReferenceOrderLineID INT      NOT NULL DEFAULT (0),
  TransactionDate      DATETIME NOT NULL DEFAULT (GETDATE()),
  TransactionType      NCHAR(1) NOT NULL,
  Quantity             INT      NOT NULL,
  ActualCost           MONEY    NOT NULL,
  ModifiedDate         DATETIME NOT NULL DEFAULT (GETDATE()),
  CONSTRAINT CK_TransactionType 
    CHECK (UPPER(TransactionType) IN (N'W', N'S', N'P'))
) 
ON TransactionsPS1 (TransactionDate);
GO

TRUNCATE TABLE Production.TransactionHistory_Partitioned

INSERT INTO Production.TransactionHistory_Partitioned
SELECT * FROM Production.TransactionHistory
WHERE TransactionDate < '2008-08-01';

SELECT * FROM Production.TransactionHistory_Partitioned
WHERE TransactionDate < '2008-05-01';
GO


SELECT * FROM sys.partitions WHERE object_id = OBJECT_ID('Production.TransactionHistory_Partitioned');

--DROP STATISTICS Production.TransactionHistory_Partitioned._WA_Sys_00000005_536D5C82
CREATE STATISTICS incrstats ON Production.TransactionHistory_Partitioned(TransactionDate) WITH FULLSCAN, INCREMENTAL = ON;
DBCC SHOW_STATISTICS('Production.TransactionHistory_Partitioned', _WA_Sys_00000005_536D5C82)
GO

SELECT 
	[sch].[name] + '.' + [so].[name] AS [TableName] ,
	[ss].[name] AS [Statistic],
	[sp].[last_updated] AS [StatsLastUpdated] ,
	[sp].[rows] AS [RowsInTable] ,
	[sp].[rows_sampled] AS [RowsSampled] ,
	[sp].[modification_counter] AS [RowModifications],
	[so].[type],
	[sp].[modification_counter]
FROM 
	[sys].[stats] [ss]
	JOIN [sys].[objects] [so] ON [ss].[object_id] = [so].[object_id]
	JOIN [sys].[schemas] [sch] ON [so].[schema_id] = [sch].[schema_id]
	OUTER APPLY [sys].[dm_db_stats_properties]([so].[object_id],
	[ss].[stats_id]) sp
WHERE 
	--[ss].[name] LIKE '_WA_%'
	[sch].[name] + '.' + [so].[name] IN ('Production.TransactionHistory_Partitioned');
GO


INSERT INTO Production.TransactionHistory_Partitioned 
SELECT * FROM Production.TransactionHistory 
WHERE TransactionDate >= '2008-08-01'
GO

DBCC SHOW_STATISTICS('Production.TransactionHistory_Partitioned', _WA_Sys_00000005_536D5C82) WITH HISTOGRAM
UPDATE STATISTICS Production.TransactionHistory_Partitioned(_WA_Sys_00000005_536D5C82) WITH RESAMPLE ON PARTITIONS(12);
DBCC SHOW_STATISTICS('Production.TransactionHistory_Partitioned', _WA_Sys_00000005_536D5C82) WITH HISTOGRAM
GO
