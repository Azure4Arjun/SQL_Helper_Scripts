--https://sqlperformance.com/2015/05/sql-statistics/improving-maintenance-incremental-statistics

-- first create a new db [AdventureWorks2014_Partition] as copy of [AdventureWorks2014]

USE [AdventureWorks2014_Partition];
GO
 
/* add filesgroups */
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILEGROUP [FG2011];
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILEGROUP [FG2012];
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILEGROUP [FG2013];
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILEGROUP [FG2014];
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILEGROUP [FG2015];

/* add files */
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILE 
( 
  FILENAME = N'C:\MSSQL12.DEV2014\DATA\AdventureWorks2014_Partition_2011.ndf',
  NAME = N'2011', SIZE = 1024MB, MAXSIZE = 4096MB, FILEGROWTH = 512MB
) TO FILEGROUP [FG2011];
 
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILE 
(
  FILENAME = N'C:\MSSQL12.DEV2014\DATA\AdventureWorks2014_Partition_2012.ndf',
  NAME = N'2012', SIZE = 512MB, MAXSIZE = 2048MB, FILEGROWTH = 512MB
) TO FILEGROUP [FG2012];
 
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILE 
(
  FILENAME = N'C:\MSSQL12.DEV2014\DATA\AdventureWorks2014_Partition_2013.ndf',
  NAME = N'2013', SIZE = 2048MB, MAXSIZE = 4096MB, FILEGROWTH = 512MB
) TO FILEGROUP [FG2013];
 
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILE
(
  FILENAME = N'C:\MSSQL12.DEV2014\DATA\AdventureWorks2014_Partition_2014.ndf',
  NAME = N'2014', SIZE = 2048MB, MAXSIZE = 4096MB, FILEGROWTH = 512MB
) TO FILEGROUP [FG2014];
 
ALTER DATABASE [AdventureWorks2014_Partition] ADD FILE 
(
  FILENAME = N'C:\MSSQL12.DEV2014\DATA\AdventureWorks2014_Partition_2015.ndf',
  NAME = N'2015', SIZE = 2048MB, MAXSIZE = 4096MB, FILEGROWTH = 512MB
) TO FILEGROUP [FG2015];


/* create partition function */
CREATE PARTITION FUNCTION [OrderDateRangePFN] ([datetime])
AS RANGE RIGHT FOR VALUES 
(
  '20110101',  -- everything in 2011
  '20120101',  -- everything in 2012
  '20130101',  -- everything in 2013
  '20140101',  -- everything in 2014
  '20150101'   -- everything in 2015
);
GO

/* create partition scheme */
CREATE PARTITION SCHEME [OrderDateRangePScheme]
AS PARTITION [OrderDateRangePFN] TO
  ([PRIMARY], [FG2011], [FG2012], [FG2013], [FG2014], [FG2015]);
GO

/* create the table */
CREATE TABLE [dbo].[Orders]
(
 [PurchaseOrderID] [int] NOT NULL,
 [EmployeeID] [int] NULL,
 [VendorID] [int] NULL,
 [TaxAmt] [money] NULL,
 [Freight] [money] NULL,
 [SubTotal] [money] NULL,
 [Status] [tinyint] NOT NULL,
 [RevisionNumber] [tinyint] NULL,
 [ModifiedDate] [datetime] NULL,
 [ShipMethodID] [tinyint] NULL,
 [ShipDate] [datetime] NOT NULL,
 [OrderDate] [datetime] NOT NULL,
 [TotalDue] [money] NULL
) ON [OrderDateRangePScheme] (OrderDate);

/* add the clustered index and enable incremental stats */
ALTER TABLE [dbo].[Orders] ADD CONSTRAINT [OrdersPK]
PRIMARY KEY CLUSTERED 
(
 [OrderDate],
 [PurchaseOrderID]
)
WITH (STATISTICS_INCREMENTAL = ON)
ON [OrderDateRangePScheme] ([OrderDate]);


/* load some data */
SET NOCOUNT ON;
DECLARE @Loops SMALLINT = 0;
DECLARE @Increment INT = 5000;
 
WHILE @Loops < 10000 -- adjust this to increase or decrease the number 
                     -- of rows in the table, 10000 = 40 millon rows
BEGIN
  INSERT [dbo].[Orders]
  ( [PurchaseOrderID]
   ,[EmployeeID]
   ,[VendorID]
   ,[TaxAmt]
   ,[Freight]
   ,[SubTotal]
   ,[Status]
   ,[RevisionNumber]
   ,[ModifiedDate]
   ,[ShipMethodID]
   ,[ShipDate]
   ,[OrderDate]
   ,[TotalDue] 
  )
  SELECT 
     [PurchaseOrderID] + @Increment
   , [EmployeeID]
   , [VendorID]
   , [TaxAmt]
   , [Freight]
   , [SubTotal]
   , [Status]
   , [RevisionNumber]
   , [ModifiedDate]
   , [ShipMethodID]
   , [ShipDate]
   , [OrderDate]
   , [TotalDue]
  FROM [AdventureWorks2014].[Purchasing].[PurchaseOrderHeader]
  CHECKPOINT;
 
  SET @Loops = @Loops + 1;
  SET @Increment = @Increment + 5000;
END

/* Check to see how much data exists per partition */
SELECT
  $PARTITION.[OrderDateRangePFN]([o].[OrderDate]) AS [Partition Number]
  , MIN([o].[OrderDate]) AS [Min_Order_Date]
  , MAX([o].[OrderDate]) AS [Max_Order_Date]
  , COUNT(*) AS [Rows In Partition]
FROM [dbo].[Orders] AS [o]
GROUP BY $PARTITION.[OrderDateRangePFN]([o].[OrderDate])
ORDER BY [Partition Number];
GO

DBCC SHOW_STATISTICS ('dbo.Orders',[OrdersPK]);

SELECT * FROM [sys].[dm_db_stats_properties_internal](OBJECT_ID('dbo.Orders'),1) ORDER BY [node_id];
GO

SET STATISTICS TIME ON;
 
SELECT 
  fs.database_id, fs.file_id, mf.name, mf.physical_name, 
  fs.num_of_bytes_read, fs.num_of_bytes_written
INTO #FirstCapture
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS fs
INNER JOIN sys.master_files AS mf 
ON fs.database_id = mf.database_id 
AND fs.file_id = mf.file_id;

UPDATE STATISTICS [dbo].[Orders]([OrdersPK]) WITH RESAMPLE ON PARTITIONS(6);
GO

SELECT 
  fs.database_id, fs.file_id, mf.name, mf.physical_name, 
  fs.num_of_bytes_read, fs.num_of_bytes_written
INTO #SecondCapture
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS fs
INNER JOIN sys.master_files AS mf 
ON fs.database_id = mf.database_id 
AND fs.file_id = mf.file_id;

SELECT f.file_id, f.name, f.physical_name, 
  (s.num_of_bytes_read - f.num_of_bytes_read)/1024 MB_Read,   
  (s.num_of_bytes_written - f.num_of_bytes_written)/1024 MB_Written
FROM #FirstCapture AS f
INNER JOIN #SecondCapture AS s 
ON f.database_id = s.database_id
GO

----------------
SET STATISTICS TIME ON;
--DROP TABLE #FirstCapture2
--DROP TABLE #SecondCapture2
SELECT 
  fs.database_id, fs.file_id, mf.name, mf.physical_name, 
  fs.num_of_bytes_read, fs.num_of_bytes_written
INTO #FirstCapture2
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS fs
INNER JOIN sys.master_files AS mf 
ON fs.database_id = mf.database_id 
AND fs.file_id = mf.file_id;
 
UPDATE STATISTICS [dbo].[Orders]([OrdersPK]) WITH FULLSCAN
 
SELECT 
  fs.database_id, fs.file_id, mf.name, mf.physical_name, 
  fs.num_of_bytes_read, fs.num_of_bytes_written
INTO #SecondCapture2
FROM sys.dm_io_virtual_file_stats(DB_ID(), NULL) AS fs
INNER JOIN sys.master_files AS mf 
ON fs.database_id = mf.database_id 
AND fs.file_id = mf.file_id;
 
SELECT 
  f.file_id, f.name, f.physical_name, 
  (s.num_of_bytes_read - f.num_of_bytes_read)/1024 MB_Read,   
  (s.num_of_bytes_written - f.num_of_bytes_written)/1024 MB_Written
FROM #FirstCapture2 AS f
INNER JOIN #SecondCapture2 AS s 
ON f.database_id = s.database_id 
AND f.file_id = s.file_id;