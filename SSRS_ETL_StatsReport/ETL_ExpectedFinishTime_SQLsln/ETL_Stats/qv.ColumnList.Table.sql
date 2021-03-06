USE [DWHSupport_Audit]
GO
/****** Object:  Table [qv].[ColumnList]    Script Date: 12/07/2019 10:34:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [qv].[ColumnList](
	[ReportName] [nvarchar](255) NOT NULL,
	[ColumnName] [nvarchar](255) NOT NULL,
	[IsChecked] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [qv].[ColumnList] SET (LOCK_ESCALATION = AUTO)
GO
ALTER TABLE [qv].[ColumnList] ADD  CONSTRAINT [IsChecked_0]  DEFAULT ((0)) FOR [IsChecked]
GO
