PRINT N'Setup.sql started...';

CREATE DATABASE demo;
GO
USE demo;
GO
CREATE TABLE Products (ID int, ProductName nvarchar(max));
GO

PRINT N'Setup.sql complete.';