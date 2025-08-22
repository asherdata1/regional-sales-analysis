CREATE DATABASE regional_sales_db;
USE regional_sales_db;

-- Use Import Wizard for .cvs file
-- Create New Table regional_sales_tb

SELECT * FROM regional_sales_tb;

CREATE TABLE dim_order(
	orderID INT auto_increment PRIMARY KEY,
    OrderNumber VARCHAR(20)
    );

CREATE TABLE dim_salestype(
	salestypeID INT auto_increment PRIMARY KEY,
    SalesType VARCHAR(20)
	);

CREATE TABLE dim_salesteam(
	salesteamID INT PRIMARY KEY,
    SalesTeam VARCHAR(50)
    );

CREATE TABLE dim_store(
	storeID INT PRIMARY KEY,
    StoreName VARCHAR(50),
    StoreZip VARCHAR(10)
    );

CREATE TABLE dim_product(
	productID INT PRIMARY KEY,
    ProductName VARCHAR(50)
    );
    
CREATE TABLE dim_date(
	dateID INT auto_increment PRIMARY KEY,
    Date DATE,
    Year INT,
    Month INT,
    MonthName VARCHAR(20),
    Day INT,
    Quarter INT,
    IsWeekend BOOLEAN
    );
    
CREATE TABLE fact_sales(
	orderID INT PRIMARY KEY,
	dateID INT,
    salestypeID INT,
    salesteamID INT,
    storeID INT,
    productID INT,
    OrderQuantity INT,
    Discount DECIMAL(4,3),
    UnitCost DECIMAL (10,2),
    UnitPrice DECIMAL (10,2),
    FOREIGN KEY (orderID) REFERENCES dim_order(orderID),
    FOREIGN KEY (salestypeID) REFERENCES dim_salestype(salestypeID),
    FOREIGN KEY (salesteamID) REFERENCES dim_salesteam(salesteamID),
    FOREIGN KEY (storeID) REFERENCES dim_store(storeID),
    FOREIGN KEY (productID) REFERENCES dim_product(productID),
    FOREIGN KEY (dateID) REFERENCES dim_date(dateID)
);


INSERT INTO dim_order (OrderNumber)
	SELECT DISTINCT(OrderNumber)
    FROM regional_sales_tb;

INSERT INTO dim_salestype (SalesType)
	SELECT DISTINCT(`Sales Channel`)
    FROM regional_sales_tb;

INSERT INTO dim_salesteam (salesteamID)
	SELECT DISTINCT(_SalesTeamID)
    FROM regional_sales_tb;
    
INSERT INTO dim_store (storeID)
	SELECT DISTINCT(_StoreID)
    FROM regional_sales_tb;
    
INSERT INTO dim_product (productID)
	SELECT DISTINCT(_ProductID)
    FROM regional_sales_tb;

UPDATE regional_sales_tb
SET OrderDate = DATE_FORMAT(STR_TO_DATE(OrderDate, '%d/%m/%y'), '%y-%m-%d')
WHERE OrderDate LIKE '%/%';

UPDATE regional_sales_tb
SET OrderDate = CONCAT('20', SUBSTRING(OrderDate, 1, 2), SUBSTRING(OrderDate, 3))
WHERE OrderDate LIKE '__-__-__';


CREATE VIEW Distinct_Dates AS
	SELECT DISTINCT OrderDate AS Date
		FROM regional_sales_tb;

SELECT Date FROM distinct_dates;

INSERT INTO dim_date (Date, Year, Month, MonthName, Day, Quarter, IsWeekend)
SELECT
	Date,
    Year(Date),
    Month(Date),
    MonthName(Date),
    Day(Date),
    Quarter(Date),
    CASE
		WHEN DAYOFWEEK(Date) IN (1,7) THEN 1 -- Where 1 = Sunday, 7 = Saturday
		ELSE 0
	END AS IsWeekend
FROM Distinct_Dates;

SELECT * FROM dim_date;

SELECT * FROM fact_sales;

UPDATE regional_sales_tb
SET `Unit Cost` = REPLACE(REPLACE(`Unit Cost`,',',''), ' ','');

UPDATE regional_sales_tb
SET `Unit Price` = REPLACE(REPLACE(`Unit Price`,',',''), ' ','');

INSERT INTO fact_sales(orderID, dateID, salestypeID, salesteamID, storeID, productID, OrderQuantity, Discount, UnitCost, UnitPrice)
SELECT
	o.orderID,
    d.dateID,
    s.salestypeID,
    t.salesteamID,
    st.storeID,
    p.productID,
	r.`Order Quantity`,
    r.`Discount Applied`,
    r.`Unit Cost`,
    r.`Unit Price`
FROM regional_sales_tb r
JOIN dim_order o ON o.OrderNumber = r.OrderNumber
JOIN dim_date d ON d.date = r.OrderDate
JOIN dim_product p ON p.productID = r._ProductID
JOIN dim_salesteam t ON t.salesteamID = r._SalesTeamID
JOIN dim_salestype s ON s.SalesType = r.`Sales Channel`
JOIN dim_store st ON st.storeID = r._StoreID;

SELECT * FROM fact_sales;
