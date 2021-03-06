USE [DWHSupport_Audit]
GO
/****** Object:  UserDefinedFunction [qv].[ufn_CalculateExpectedFinishTime]    Script Date: 12/07/2019 10:34:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [qv].[ufn_CalculateExpectedFinishTime] (@ProcessStartTime TIME, @N_DayAvg_Task TIME, @N_DayAvg_System TIME) RETURNS TIME
AS
BEGIN
	RETURN (SELECT CONVERT(TIME(0), DATEADD(MINUTE, (-1* DATEDIFF(MINUTE, CONVERT(TIME(0),@ProcessStartTime,0), CONVERT(TIME(0), @N_DayAvg_Task)) ), @N_DayAvg_System), 0))
END
GO
