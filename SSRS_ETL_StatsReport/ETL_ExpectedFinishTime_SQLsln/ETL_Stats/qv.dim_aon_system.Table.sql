USE [DWHSupport_Audit]
GO
/****** Object:  Table [qv].[dim_aon_system]    Script Date: 12/07/2019 10:34:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [qv].[dim_aon_system](
	[dim_aon_system_key] [int] NOT NULL,
	[systemcountrycodecrd] [varchar](3) NULL,
	[systemnamecrd] [varchar](30) NULL,
	[systemname] [varchar](30) NOT NULL,
	[systemcountrycode] [char](2) NOT NULL,
	[systemcountryname] [varchar](30) NOT NULL,
	[systemregion] [varchar](50) NOT NULL,
	[reportingcurrency] [char](3) NOT NULL,
	[comments1] [varchar](200) NOT NULL,
	[comments2] [varchar](200) NULL,
	[salt] [varchar](36) NOT NULL,
	[feedto_acia] [char](1) NOT NULL,
	[feedto_crd] [char](1) NOT NULL,
	[clientmoneyflag] [char](1) NULL,
	[dss_update_time] [datetime] NULL,
	[productlanguagecode] [char](2) NULL,
	[cleanupstagetablesflag] [char](1) NULL,
	[isbuildonssdt] [bit] NOT NULL,
	[balancesheetratetype] [varchar](3) NOT NULL,
	[balancesheetratemonthincrement] [int] NOT NULL,
	[revenueratetype] [varchar](3) NOT NULL,
	[revenueratemonthincrement] [int] NOT NULL,
	[ActiveForStats] [bit] NULL
) ON [PRIMARY]
GO
