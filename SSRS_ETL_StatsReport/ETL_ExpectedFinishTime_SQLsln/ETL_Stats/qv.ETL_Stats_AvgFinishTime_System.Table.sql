USE [DWHSupport_Audit]
GO
/****** Object:  Table [qv].[ETL_Stats_AvgFinishTime_System]    Script Date: 12/07/2019 10:34:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [qv].[ETL_Stats_AvgFinishTime_System](
	[SystemKey] [int] NOT NULL,
	[TimeRecorded] [datetime] NOT NULL,
	[7-DayAverage] [time](7) NULL,
	[14-DayAverage] [time](7) NULL,
	[30-DayAverage] [time](7) NULL
) ON [PRIMARY]
GO
