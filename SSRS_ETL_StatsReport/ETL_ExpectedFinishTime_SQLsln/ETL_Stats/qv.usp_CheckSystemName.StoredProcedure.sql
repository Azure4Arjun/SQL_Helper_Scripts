USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_CheckSystemName]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [qv].[usp_CheckSystemName] @_SystemName NVARCHAR(64), @_CallingProcName NVARCHAR(64), @_CheckResult BIT OUTPUT
AS
BEGIN
DECLARE @SystemName NVARCHAR(64),
		@ErMessage NVARCHAR(2048),
		@ErSeverity INT,
		@ErState INT
SET @SystemName = @_SystemName
IF ((@SystemName IS NULL) OR (@SystemName = ''))
BEGIN
		SET @_CheckResult = 0
		SELECT
		   @ErMessage = 'Parameter @SystemName can not be NULL or empty.',
		   @ErSeverity = 15, --ERROR_SEVERITY(),
		   @ErState = ERROR_STATE()
		 
		RAISERROR (@ErMessage, @ErSeverity, @ErState)
		RETURN
END

IF ((SELECT COUNT(s.[dim_aon_system_key]) FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName) <> 1)
	BEGIN
		SET @_CheckResult = 0
		SELECT
		   @ErMessage = 'Proc: '+@_CallingProcName+' could not find '''+@SystemName+''' in [qv].[dim_aon_system] table, or more than one '''+@SystemName+''' was found.',
		   @ErSeverity = 15, --ERROR_SEVERITY(),
		   @ErState = ERROR_STATE()
		 
		RAISERROR (@ErMessage, @ErSeverity, @ErState)
		RETURN
	END
	ELSE
	BEGIN
		SET @_CheckResult = 1
	END
END
GO
