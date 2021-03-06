USE [DWHSupport_Audit]
GO
/****** Object:  Table [qv].[LogTable_ACIA]    Script Date: 12/07/2019 10:34:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [qv].[LogTable_ACIA](
	[LogID] [bigint] NOT NULL,
	[SystemKey] [int] NOT NULL,
	[RunID] [bigint] NOT NULL,
	[ProcessName] [nvarchar](255) NOT NULL,
	[ExecutedBy] [sysname] NULL,
	[ProcessStartTime] [datetime] NOT NULL,
	[ProcessEndTime] [datetime] NULL,
	[ProcessDuration] [time](7) NULL,
	[RetriesCount] [int] NULL,
	[Status] [nvarchar](10) NULL,
	[ErrorMessage] [nvarchar](max) NULL,
	[Message1] [nvarchar](255) NULL,
	[Message2] [nvarchar](255) NULL,
	[Message3] [nvarchar](255) NULL,
	[Count1] [bigint] NULL,
	[Count2] [bigint] NULL,
	[Count3] [bigint] NULL,
	[SourceTableName] [nvarchar](255) NULL,
	[TargetTableName] [nvarchar](255) NULL,
	[InsertCount] [bigint] NULL,
	[DeleteCount] [bigint] NULL,
	[UpdateCount] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [qv].[LogTable_ACIA] SET (LOCK_ESCALATION = AUTO)
GO
