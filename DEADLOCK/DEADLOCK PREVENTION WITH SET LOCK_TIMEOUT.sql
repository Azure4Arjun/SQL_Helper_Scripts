DECLARE
        @counter INT = 1,
        @attempt_threshold INT = 10,
        @is_success BIT = 0,
        @CustomErrorMessage NVARCHAR(128),
        @SystemErrorMessage NVARCHAR(MAX),
        @ErrorSeverity INT,
        @ErrorState INT,
        @attempt_nr_str NVARCHAR(2);

SET @CustomErrorMessage = N'Transaction failed on %s attempt';

--------------------------------------
-- set parameters based on configuration table (to be prepared)
--------------------------------------

WHILE @counter <= @attempt_threshold AND @is_success = 0
BEGIN
  BEGIN TRY
	BEGIN
        BEGIN TRANSACTION
            SET LOCK_TIMEOUT 10000
            --------------------------------------
            -- place the transaction to be deadlock-protected in here:
            --------------------------------------
				
				EXEC sp_YourProcNameHere

            COMMIT TRANSACTION
            SET @is_success = 1 -- transaction succeeded, so exit the try-block and the while-loop
        END
  END TRY
  BEGIN CATCH

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION
        END
        IF ERROR_NUMBER() IN
           (
            1204, -- SQLOUTOFLOCKS
            1205, -- SQLDEADLOCKVICTIM
            1222  -- SQLREQUESTTIMEOUT
			--,2627  -- Violation of %ls constraint '%.*ls'. Cannot insert duplicate key in object '%.*ls'
           )
          AND @counter <= @attempt_threshold
          BEGIN
                  SET @counter = @counter + 1 -- increment the timeout counter
                  PRINT('Retrying the transaction in 5 seconds ...')
                  WAITFOR DELAY '00:00:05'
          END
        BEGIN
            SET @attempt_nr_str = CONVERT(NVARCHAR(2), @counter)
            SET @SystemErrorMessage = CONCAT(ERROR_MESSAGE(), ' ', @CustomErrorMessage)
            SET @ErrorSeverity = ERROR_SEVERITY()
            SET @ErrorState = ERROR_STATE(); 
            RAISERROR(
                        @SystemErrorMessage, -- @SystemErrorMessage text + @CustomErrorMessage text
                        @ErrorSeverity,  -- severity
                        @ErrorState,   -- state
                        @attempt_nr_str -- first argument to the message text
                     );
        END
  END CATCH
END