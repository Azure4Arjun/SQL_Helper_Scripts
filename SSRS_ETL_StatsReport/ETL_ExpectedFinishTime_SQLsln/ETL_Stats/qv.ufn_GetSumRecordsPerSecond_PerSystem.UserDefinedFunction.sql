USE [DWHSupport_Audit]
GO
/****** Object:  UserDefinedFunction [qv].[ufn_GetSumRecordsPerSecond_PerSystem]    Script Date: 12/07/2019 10:34:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [qv].[ufn_GetSumRecordsPerSecond_PerSystem] (@SystemKey INT, @RunID BIGINT) 
RETURNS @results TABLE
(
	SumInserts BIGINT
	, SumUpdates BIGINT
	, SumDeletes BIGINT
	, SumAllRecords BIGINT
)
AS
BEGIN;
		IF ((@SystemKey = 115) OR (@SystemKey = 110) OR (@SystemKey = 122) OR (@SystemKey = 1003))
		BEGIN
			INSERT INTO @results (SumInserts, SumUpdates, SumDeletes, SumAllRecords)
			SELECT
				SUM(InsertCount)
				, SUM(UpdateCount)
				, SUM(DeleteCount)
				, (COALESCE(SUM(InsertCount), 0)+COALESCE(SUM(DeleteCount), 0)+COALESCE(SUM(UpdateCount), 0))
			FROM qv.LogTable
			WHERE
				SystemKey = @SystemKey
				AND RunID = @RunID
			GROUP BY qv.LogTable.RunID
		END
		ELSE
		BEGIN
			INSERT INTO @results (SumInserts, SumUpdates, SumDeletes, SumAllRecords)
			SELECT
				SUM(InsertCount)
				, SUM(UpdateCount)
				, SUM(DeleteCount)
				, (COALESCE(SUM(InsertCount), 0)+COALESCE(SUM(DeleteCount), 0)+COALESCE(SUM(UpdateCount), 0))
			FROM qv.LogTable_ACIA
			WHERE
				SystemKey = @SystemKey
				AND RunID = @RunID
			GROUP BY qv.LogTable_ACIA.RunID
		END
RETURN;
END;
GO
