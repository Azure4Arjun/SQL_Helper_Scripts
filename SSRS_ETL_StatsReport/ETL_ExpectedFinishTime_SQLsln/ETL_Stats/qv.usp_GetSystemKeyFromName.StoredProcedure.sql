USE [DWHSupport_Audit]
GO
/****** Object:  StoredProcedure [qv].[usp_GetSystemKeyFromName]    Script Date: 12/07/2019 10:34:43 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [qv].[usp_GetSystemKeyFromName] @_SystemName NVARCHAR(64), @_CallingProcName NVARCHAR(64), @_CheckResult BIT OUTPUT, @_SystemKey INT OUTPUT
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

IF ((UPPER(LEFT(@SystemName, 7)) = 'EGLOBAL') OR (UPPER(LEFT(@SystemName, 6)) = 'XPRESS') OR (UPPER(LEFT(@SystemName, 3)) = 'MGA') OR (UPPER(LEFT(@SystemName, 3)) = 'BMW'))
BEGIN
	--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	--  eGlobal:
	--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	IF (UPPER(LEFT(@SystemName, 7)) = 'EGLOBAL')
	BEGIN
		IF ((SUBSTRING(@SystemName, 8, 1) <> '_') OR (LEN(@SystemName) <> 10) OR (SUBSTRING(@SystemName, 9, 2) NOT LIKE '[a-zA-Z][a-zA-Z]'))
		BEGIN
			SET @_CheckResult = 0
			SELECT
			   @ErMessage = 'For '+LEFT(@SystemName, 7)+' a valid 2-letter country code prefixed by ''_'' charachter must be supplied.',
			   @ErSeverity = 15, --ERROR_SEVERITY(),
			   @ErState = ERROR_STATE()
			 
			RAISERROR (@ErMessage, @ErSeverity, @ErState)
			RETURN
		END
		IF ((SELECT COUNT(s.[systemcountrycode]) FROM [qv].[dim_aon_system] s WHERE s.[systemname] = LEFT(@SystemName, 7) AND s.[systemcountrycode] = SUBSTRING(@SystemName, 9, 2)) = 0)
		BEGIN
			SET @_CheckResult = 0
			SELECT
			   @ErMessage = 'Could not find country code '''+SUBSTRING(@SystemName, 9, 2)+''' for '+LEFT(@SystemName, 7)+' in [qv].[dim_aon_system] table .',
			   @ErSeverity = 15, --ERROR_SEVERITY(),
			   @ErState = ERROR_STATE()
			RAISERROR (@ErMessage, @ErSeverity, @ErState)
			RETURN
		END
		ELSE
		BEGIN
			SET @_CheckResult = 1
			SELECT @_SystemKey = [dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = LEFT(@SystemName, 7) AND s.[systemcountrycode] = SUBSTRING(@SystemName, 9, 2)
		END
	END

	--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	--  Xpress:
	--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	IF (UPPER(LEFT(@SystemName, 6)) = 'XPRESS')
	BEGIN
		IF ((SUBSTRING(@SystemName, 7, 1) <> '_') OR (LEN(@SystemName) <> 9) OR (SUBSTRING(@SystemName, 8, 2) NOT LIKE '[a-zA-Z][a-zA-Z]'))
		BEGIN
			SET @_CheckResult = 0
			SELECT
			   @ErMessage = 'For '+LEFT(@SystemName, 6)+' a valid 2-letter country code prefixed by ''_'' charachter must be supplied.',
			   @ErSeverity = 15, --ERROR_SEVERITY(),
			   @ErState = ERROR_STATE()
			 
			RAISERROR (@ErMessage, @ErSeverity, @ErState)
			RETURN
		END
		IF ((SELECT COUNT(s.[systemcountrycode]) FROM [qv].[dim_aon_system] s WHERE s.[systemname] = LEFT(@SystemName, 6) AND s.[systemcountrycode] = SUBSTRING(@SystemName, 8, 2)) = 0)
		BEGIN
			SET @_CheckResult = 0
			SELECT
			   @ErMessage = 'Could not find country code '''+SUBSTRING(@SystemName, 8, 2)+''' for '+LEFT(@SystemName, 6)+' in [qv].[dim_aon_system] table .',
			   @ErSeverity = 15, --ERROR_SEVERITY(),
			   @ErState = ERROR_STATE()
			RAISERROR (@ErMessage, @ErSeverity, @ErState)
			RETURN
		END
		ELSE
		BEGIN
			SET @_CheckResult = 1
			SELECT @_SystemKey = [dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = LEFT(@SystemName, 6) AND s.[systemcountrycode] = SUBSTRING(@SystemName, 8, 2)
		END
	END

	--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	--  MGA or BMW:
	--/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	IF ((UPPER(LEFT(@SystemName, 3)) = 'MGA') OR (UPPER(LEFT(@SystemName, 3)) = 'BMW'))
	BEGIN
		IF ((SUBSTRING(@SystemName, 4, 1) <> '_') OR (LEN(@SystemName) <> 6) OR (SUBSTRING(@SystemName, 5, 2) NOT LIKE '[a-zA-Z][a-zA-Z]'))
		BEGIN
			SET @_CheckResult = 0
			SELECT
			   @ErMessage = 'For '+LEFT(@SystemName, 3)+' a valid 2-letter country code prefixed by ''_'' charachter must be supplied.',
			   @ErSeverity = 15, --ERROR_SEVERITY(),
			   @ErState = ERROR_STATE()
			 
			RAISERROR (@ErMessage, @ErSeverity, @ErState)
			RETURN
		END
		IF ((SELECT COUNT(s.[systemcountrycode]) FROM [qv].[dim_aon_system] s WHERE s.[systemname] = LEFT(@SystemName, 3) AND s.[systemcountrycode] = SUBSTRING(@SystemName, 5, 2)) = 0)
		BEGIN
			SET @_CheckResult = 0
			SELECT
			   @ErMessage = 'Could not find country code '''+SUBSTRING(@SystemName, 5, 2)+''' for '+LEFT(@SystemName, 3)+' in [qv].[dim_aon_system] table .',
			   @ErSeverity = 15, --ERROR_SEVERITY(),
			   @ErState = ERROR_STATE()
			RAISERROR (@ErMessage, @ErSeverity, @ErState)
			RETURN
		END
		ELSE
		BEGIN
			SET @_CheckResult = 1
			SELECT @_SystemKey = [dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = LEFT(@SystemName, 3) AND s.[systemcountrycode] = SUBSTRING(@SystemName, 5, 2)
		END
	END
END

ELSE IF ((SELECT COUNT(s.[dim_aon_system_key]) FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName) <> 1)
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
		SELECT @_SystemKey = [dim_aon_system_key] FROM [qv].[dim_aon_system] s WHERE s.[systemname] = @SystemName
	END
END
GO
