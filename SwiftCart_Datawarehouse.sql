CREATE DATABASE SwiftCartLogisticsDW;
GO

USE SwiftCartLogisticsDW;
GO

CREATE TABLE DIMCUSTOMER(
CustomerKey INT PRIMARY KEY,
CustomerID INT,
CustomerName VARCHAR(50),
CustomerSurname VARCHAR(50),
CustomerEmail VARCHAR(100),
CustomerPhone VARCHAR(10)
);

CREATE TABLE DIMPRODUCT(
ProductKey INT PRIMARY KEY,
Product_ID INT,
Product_Name VARCHAR(50),
Product_Description VARCHAR(100),
Product_Price DECIMAL(10, 2)
);

CREATE TABLE DIMDATE(
DateKey INT PRIMARY KEY,
FullDate DATE,
Day INT,
Month INT,
Quarter INT,
Year INT
);

CREATE TABLE DIMRETAILER(
RetailerKey INT PRIMARY KEY,
RetailerID INT,
RetailerName VARCHAR(50),
RetailerPhone VARCHAR(10),
RetailerEmail VARCHAR(100)
);

CREATE TABLE DIMDELIVERY(
DeliveryKey INT PRIMARY KEY,
DeliveryID INT,
DeliveryLocation VARCHAR(100),
DeliveryStatus VARCHAR(50),
DepartureDate DATE,
ArrivalDate DATE,
ArrivalTime TIME
);

CREATE TABLE FACTORDER(
OrderKey INT PRIMARY KEY,
CustomerKey INT,
ProductKey INT,
DateKey INT,
RetailerKey INT,
DeliveryKey INT,
Quantity INT,
ProductPrice DECIMAL(10, 2),
SalesAmount DECIMAL(10, 2),
PaymentAmount DECIMAL(10, 2),
DeliveryDays INT,

FOREIGN KEY(CustomerKey) REFERENCES DIMCUSTOMER(CustomerKey),
FOREIGN KEY(ProductKey) REFERENCES DIMPRODUCT(ProductKey),
FOREIGN KEY(DateKey) REFERENCES DIMDATE(DateKey),
FOREIGN KEY(RetailerKey) REFERENCES DIMRETAILER(RetailerKey),
FOREIGN KEY(DeliveryKey) REFERENCES DIMDELIVERY(DeliveryKey)
);

/*ETL process*/

/*Extraction stage*/

/*Transformation #1*/
--Clean customer name and surname using LTRIM() and RTRIM() to remove empty spaces


/*Loading DimCustomer*/
INSERT INTO DIMCUSTOMER
(
    CustomerKey,
    CustomerID,
    CustomerName,
    CustomerSurname,
    CustomerEmail,
    CustomerPhone
)
SELECT
    CLIENT_ID,
    CLIENT_ID,
    LTRIM(RTRIM(CLIENT_NAME)),
    LTRIM(RTRIM(CLIENT_SURNAME)),
    CLIENT_EMAIL,
    CLIENT_PHONE_NUMBER
FROM SwiftCartLogistics.dbo.CLIENT;

/*Verify that data is inserted or loaded to the data warehouse*/
SELECT * FROM DIMCUSTOMER;


/*Transformation #2*/
--Clean the product name and description using LTRIM() and RTRIM() to remove empty spaces
/*Load DimProduct*/
INSERT INTO DIMPRODUCT
(
    ProductKey,
    Product_ID,
    Product_Name,
    Product_Description,
    Product_Price
)
SELECT
    PRODUCT_ID,
    PRODUCT_ID,
    LTRIM(RTRIM(PRODUCT_NAME)),
    LTRIM(RTRIM(PRODUCT_DESCRIPTION)),
    PRODUCT_PRICE
FROM SwiftCartLogistics.dbo.PRODUCTS;

/*Verify data insertation*/
SELECT * FROM DIMPRODUCT;


/*Transformation #2*/
--Retailer names are cleaned using LTRIM() and RTRIM() removing empty spaces

/*Load DimRetailer*/
INSERT INTO DIMRETAILER
(
    RetailerKey,
    RetailerID,
    RetailerName,
    RetailerPhone,
    RetailerEmail
)
SELECT
    RETAILER_ID,
    RETAILER_ID,
    LTRIM(RTRIM(RETAILER_NAME)),
    RETAILER_PHONE_NUMBER,
    RETAILER_EMAIL
FROM SwiftCartLogistics.dbo.RETAILER;

/*Verification of data insertation*/
SELECT * FROM DIMRETAILER;

/*Transformation #3*/
--Standardisation: Delivery statuses are converted to uppercase using UPPER().

/*Loading DimDelivery*/
INSERT INTO DIMDELIVERY
(
    DeliveryKey,
    DeliveryID,
    DeliveryLocation,
    DeliveryStatus,
    DepartureDate,
    ArrivalDate,
    ArrivalTime
)
SELECT
    DELIVERY_ID,
    DELIVERY_ID,
    LTRIM(RTRIM(DELIVERY_LOCATION)),
    UPPER(LTRIM(RTRIM(DELIVERY_STATUS))),
    DEPARTURE_DATE,
    ARRIVAL_DATE,
    ARRIVAL_TIME
FROM SwiftCartLogistics.dbo.DELIVERY;

/*Verify that data is inserted into a warehouse*/
SELECT * FROM DIMDELIVERY;

/*Transformation #4*/
--Day extraction from ORDER_DATE using DAY().

/*Transformation #5*/
--Month extraction from ORDER_DATE using MONTH().

/*Transformation #6*/
--Quarter calculation using DATEPART

/*Transformation #7*/
--Year extraction using YEAR()

/*Transformation #8*/
--DateKey generation using CONVERT()

/*Loading DimDate*/
INSERT INTO DIMDATE
(
    DateKey,
    FullDate,
    Day,
    Month,
    Quarter,
    Year
)
SELECT DISTINCT
    CONVERT(INT, CONVERT(VARCHAR(8), ORDER_DATE, 112)),
    ORDER_DATE,
    DAY(ORDER_DATE),
    MONTH(ORDER_DATE),
    DATEPART(QUARTER, ORDER_DATE),
    YEAR(ORDER_DATE)
FROM SwiftCartLogistics.dbo.ORDERS;

/*Verify that date data is successfully loaded into a data warehouse*/
SELECT * FROM DIMDATE
ORDER BY FullDate;

/*Transformation #9*/
--Calculate sales amount by multiplying Quantity * ProductPrice

/*Transformation #10*/
--Compute delivery days by using DATEDIFF()

/*Loading FactOrder*/
INSERT INTO FACTORDER
(
    OrderKey,
    CustomerKey,
    ProductKey,
    DateKey,
    RetailerKey,
    DeliveryKey,
    Quantity,
    ProductPrice,
    SalesAmount,
    PaymentAmount,
    DeliveryDays
)
SELECT
    O.ORDER_ID AS OrderKey,
    C.CustomerKey,
    P.ProductKey,
    DTE.DateKey,
    R.RetailerKey,
    DLV.DeliveryKey,
    OI.QUANTITY AS Quantity,
    P.Product_Price AS ProductPrice,
    OI.QUANTITY * P.Product_Price AS SalesAmount,
    ISNULL(PAY.PAYMENT_AMOUNT, 0) AS PaymentAmount,
    DATEDIFF(
        DAY,
        DEL.DEPARTURE_DATE,
        DEL.ARRIVAL_DATE
    ) AS DeliveryDays

FROM SwiftCartLogistics.dbo.ORDERS O

INNER JOIN SwiftCartLogistics.dbo.ORDERITEM OI
    ON O.ORDER_ID = OI.ORDER_ID

INNER JOIN SwiftCartLogistics.dbo.CLIENT CL
    ON O.CLIENT_ID = CL.CLIENT_ID

INNER JOIN SwiftCartLogistics.dbo.PRODUCTS PR
    ON OI.PRODUCT_ID = PR.PRODUCT_ID

INNER JOIN SwiftCartLogistics.dbo.RETAILER RET
    ON O.RETAILER_ID = RET.RETAILER_ID

INNER JOIN SwiftCartLogistics.dbo.DELIVERY DEL
    ON O.DELIVERY_ID = DEL.DELIVERY_ID

LEFT JOIN SwiftCartLogistics.dbo.PAYMENT PAY
    ON O.ORDER_ID = PAY.ORDER_ID

INNER JOIN SwiftCartLogisticsDW.dbo.DIMCUSTOMER C
    ON CL.CLIENT_ID = C.CustomerID

INNER JOIN SwiftCartLogisticsDW.dbo.DIMPRODUCT P
    ON PR.PRODUCT_ID = P.Product_ID

INNER JOIN SwiftCartLogisticsDW.dbo.DIMRETAILER R
    ON RET.RETAILER_ID = R.RetailerID

INNER JOIN SwiftCartLogisticsDW.dbo.DIMDELIVERY DLV
    ON DEL.DELIVERY_ID = DLV.DeliveryID

INNER JOIN SwiftCartLogisticsDW.dbo.DIMDATE DTE
    ON O.ORDER_DATE = DTE.FullDate;

/*Verify that FactOrder data is successfully loaded into data warehouse*/
SELECT * 
FROM FACTORDER
ORDER BY OrderKey;

------- Question C ----------
/* SLICE
What was SwiftCart Logistics' total revenue generated during 2026?
*/
SELECT
    D.Year,
    SUM(F.SalesAmount) AS TotalRevenue
FROM FACTORDER F
JOIN DIMDATE D ON F.DateKey = D.DateKey
WHERE D.Year = 2026
GROUP BY D.Year;
/*Slice
Selects one value from a single dimension.*/

/* DICE
What were the total quantities and total sales of Phones and Laptops
sold by AkhoRetail and ThandoRetail during 2026?
*/
SELECT 
    R.RetailerName, 
    P.Product_Name, 
    SUM(F.Quantity) AS TotalQuantity, 
    SUM(F.SalesAmount) AS TotalSales 
FROM FACTORDER F
INNER JOIN DIMRETAILER R 
    ON F.RetailerKey = R.RetailerKey
INNER JOIN DIMPRODUCT P 
    ON F.ProductKey = P.ProductKey
INNER JOIN DIMDATE D 
    ON F.DateKey = D.DateKey
WHERE D.Year = 2026
AND P.Product_Name IN ('Phone', 'Laptop')
AND R.RetailerName IN ('AkhoRetail', 'ThandoRetail')
GROUP BY 
    R.RetailerName, 
    P.Product_Name
ORDER BY 
    R.RetailerName, 
    P.Product_Name;
/*Dice
Selects a subset using values from multiple dimensions.
*/


/* DRILL-DOWN
Revenue from year level to month and individual day
during 2026
*/

SELECT
    D.Year,
    D.Month,
    D.Day,
    SUM(F.SalesAmount) AS TotalRevenue
FROM FACTORDER F
JOIN DIMDATE D
    ON F.DateKey = D.DateKey
WHERE D.Year = 2026
GROUP BY
    D.Year,
    D.Month,
    D.Day
ORDER BY
    D.Year,
    D.Month,
    D.Day;
/*Drill down
Moves from summarised data to more detailed data.
*/

/* Roll-Up
How much revenue did each product generate,
and what was the total revenue generated by all products?*/
SELECT
    P.Product_Name,
    SUM(F.SalesAmount) AS TotalRevenue
FROM FACTORDER F
JOIN DIMPRODUCT P
    ON F.ProductKey = P.ProductKey
GROUP BY ROLLUP(P.Product_Name);
/*
Roll-up
Combines detailed data into a higherlevel summary.
*/


/*Pivot
How does the revenue of each product compare with the other products during 2026?
*/
SELECT * 
FROM 
(
    SELECT 
        P.Product_Name,
        F.SalesAmount
    FROM FACTORDER F
    JOIN DIMPRODUCT P 
        ON F.ProductKey = P.ProductKey
    JOIN DIMDATE D
        ON F.DateKey = D.DateKey
    WHERE D.Year = 2026
) AS SourceTable
PIVOT 
(
    SUM(SalesAmount) 
    FOR Product_Name IN 
    (
        [Phone],
        [Laptop],
        [Monitor],
        [Tablet],
        [Keyboard]
    )
) AS PivotTable;
/*Pivot
Rotates the data view to examine it from another perspective.
*/