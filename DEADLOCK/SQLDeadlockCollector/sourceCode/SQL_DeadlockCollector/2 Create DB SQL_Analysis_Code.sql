
USE [master]
GO
DROP DATABASE [SQL_Analysis_Code]
GO

DECLARE @SQL_CreateDB	nvarchar(4000)
	,	@PathDataFile	nvarchar(128)
	,	@PathLogFile	nvarchar(128)
	,	@FileSuffix		nvarchar(10)

SELECT	@PathDataFile = 'D:\SQLData\SQLData1\SQLData1\'
	,	@PathLogFile = 'D:\SQLData\SQLLog1\SQLLog1\'
	,	@FileSuffix = CASE 
				REPLACE(
				CAST(SERVERPROPERTY('ProductVersion') AS char(4)) 
			, '.', '')
			WHEN 100 THEN '_2008'
			WHEN 105 THEN '_2008R2'
			WHEN 110 THEN '_20012'
			ELSE '???'
		END

SELECT @PathDataFile, @PathLogFile, @FileSuffix

SET @SQL_CreateDB = '
CREATE DATABASE [SQL_Analysis_Code]
ON  PRIMARY 
( NAME = N''SQL_Analysis_Code''
, FILENAME = N''' + @PathDataFile + 'SQL_Analysis_Code' + @FileSuffix + '.mdf''
, SIZE = 10MB , MAXSIZE = 50MB , FILEGROWTH = 5MB )
 LOG ON 
( NAME = N''SQL_Analysis_Code_log''
, FILENAME = N''' + @PathLogFile + 'SQL_Analysis_Code_log' + @FileSuffix + '.ldf''
, SIZE = 5MB , MAXSIZE = 20MB , FILEGROWTH = 5MB )
'

--PRINT @SQL_CreateDB

EXECUTE (@SQL_CreateDB)

ALTER DATABASE [SQL_Analysis_Code] SET COMPATIBILITY_LEVEL = 100
GO
ALTER DATABASE [SQL_Analysis_Code] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET ARITHABORT OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [SQL_Analysis_Code] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [SQL_Analysis_Code] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [SQL_Analysis_Code] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET  DISABLE_BROKER 
GO
ALTER DATABASE [SQL_Analysis_Code] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [SQL_Analysis_Code] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [SQL_Analysis_Code] SET  READ_WRITE 
GO
ALTER DATABASE [SQL_Analysis_Code] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [SQL_Analysis_Code] SET  MULTI_USER 
GO
ALTER DATABASE [SQL_Analysis_Code] SET PAGE_VERIFY CHECKSUM  
GO
USE [SQL_Analysis_Code]
GO
IF NOT EXISTS (SELECT name FROM sys.filegroups WHERE is_default=1 AND name = N'PRIMARY') ALTER DATABASE [SQL_Analysis_Code] MODIFY FILEGROUP [PRIMARY] DEFAULT
GO


ALTER AUTHORIZATION ON DATABASE::SQL_Analysis_Code TO sa

USE [master]
GO
EXEC [SQL_Analysis_Code].sys.sp_addextendedproperty @name=N'Description',
	@value=N'Database contains code to collect performance data' 
EXEC [SQL_Analysis_Code].sys.sp_addextendedproperty @name = N'Author',
    @value = N'Andreas Wolter, Sarpedon Quality Lab' 
EXEC [SQL_Analysis_Code].sys.sp_addextendedproperty @name = N'Source:',
    @value = N'https://sqldeadlockcollector.codeplex.com' 
EXEC [SQL_Analysis_Code].sys.sp_addextendedproperty @name = N'Project',
    @value = 'SQL Server Monitoring & Analysis'
EXEC [SQL_Analysis_Code].sys.sp_addextendedproperty @name = N'Version',
    @value = '1.0'
GO