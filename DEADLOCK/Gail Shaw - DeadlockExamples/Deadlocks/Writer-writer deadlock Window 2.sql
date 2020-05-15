USE AdventureWorks2017
GO

-- basic reader-writer deadlock. Window 2

BEGIN TRANSACTION

SET LOCK_TIMEOUT 300000 -- 5 minutes

UPDATE  Person.Person
SET     LastName = 'No one'
WHERE   FirstName = 'John'

-- run to here then switch back to Window 1 and run the second half

UPDATE  person.Address
SET     SpatialLocation = NULL

ROLLBACK TRANSACTION
