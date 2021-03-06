USE AdventureWorks2017
GO

-- basic serialisable range deadlock, window 1

SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

BEGIN TRANSACTION

SET LOCK_TIMEOUT 300000 -- 5 minutes

SELECT * FROM Production.Product AS p WHERE ProductNumber LIKE 'H%'

-- run up to here, then switch back to window 1 and run the second half

INSERT INTO Production.Product (Name, ProductNumber, SafetyStockLevel, ReorderPoint, StandardCost, ListPrice, DaysToManufacture, SellStartDate, SellEndDate)
VALUES ('fake', 'HM-0001', 1, 1, 1, 1, 1, GETDATE(), GETDATE());

ROLLBACK TRANSACTION

