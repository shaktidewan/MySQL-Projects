create database Online_Retail_UCI;

SELECT * FROM dbo.online_retail;

/*Total Revenue Analysis:
How can you calculate the total revenue generated each day and identify the highest revenue day in the dataset?
*/

WITH CTE AS (
    SELECT 
        SUM(Quantity * UnitPrice) AS total_revenue_generated, 
        CONVERT(DATE, InvoiceDate) AS SaleDate
    FROM 
        dbo.online_retail
    GROUP BY 
        CONVERT(DATE, InvoiceDate)
)
SELECT TOP 1 
    total_revenue_generated, 
    SaleDate 
FROM 
    CTE  
ORDER BY 
    total_revenue_generated DESC;

/*Customer Purchase Frequency:
How would you determine the number of purchases made by each customer and identify the most frequent buyers?
*/
DELETE  FROM dbo.online_retail WHERE CustomerID IS NULL OR CustomerID= ' ';

SELECT TOP 5 
    CustomerID, 
    COUNT(DISTINCT InvoiceNo) AS num_of_purchases
FROM 
    dbo.online_retail
GROUP BY 
    CustomerID
ORDER BY 
    num_of_purchases DESC;

/*
Product Category Performance:
How can you analyze the total sales for each product category and identify which category generates the most revenue?
*/

SELECT TOP 1 StockCode, SUM(Quantity*UnitPrice) as total_revenue_of_each_category
FROM dbo.online_retail
GROUP BY StockCode
ORDER BY total_revenue_of_each_category DESC;

/*
Geographic Sales Distribution:
What query would you use to calculate the sales distribution across different countries, and identify the top-performing countries?
*/
SELECT  Country, SUM(Quantity*UnitPrice) as total_revenue_of_country
FROM dbo.online_retail
GROUP BY Country
ORDER BY total_revenue_of_country DESC;

/*
Order Volume Analysis:
How would you calculate the average order volume (in units) for each customer and identify trends over time?
*/
SELECT InvoiceDate FROM dbo.online_retail;

SELECT 
    Month,  -- Group by Month
    AVG(TotalUnits) AS AvgOrderVolume
FROM (
    SELECT 
        CustomerID,
        FORMAT(InvoiceDate, 'yyyy-MM') AS Month,
        InvoiceNo,
        SUM(Quantity) AS TotalUnits
    FROM 
        dbo.online_retail
    GROUP BY 
        CustomerID,
        InvoiceNo,
        FORMAT(InvoiceDate, 'yyyy-MM')
) AS MonthlyOrderVolumes
GROUP BY 
    Month
ORDER BY 
    Month;

--OVER TIME;
SELECT 
     Year,
    AVG(TotalUnits) AS AvgOrderVolume
FROM (
    SELECT 
        CustomerID,
        YEAR(InvoiceDate) AS Year,
        InvoiceNo,
        SUM(Quantity) AS TotalUnits
    FROM 
        dbo.online_retail
    GROUP BY 
        CustomerID,
        InvoiceNo,
        YEAR(InvoiceDate)
) AS YearlyOrderVolumes
GROUP BY 
    Year
ORDER BY 
    Year;

/*Customer Segmentation for Marketing:
How would you segment customers based on their purchasing behavior (e.g., frequency, monetary value) to identify potential targets for marketing campaigns?
*/
SELECT * FROM dbo.online_retail;
--Step 1: Recency Calculation: Calculate the number of days since the last purchase for each customer.;

SELECT 
CustomerID,
DATEDIFF(DAY,MAX(InvoiceDate),GETDATE()) AS Recency
FROM
dbo.online_retail
GROUP BY CustomerID;

--Step 2: Frequency Calculation: Calculate the total number of purchases for each customer;
SELECT 
CustomerID,
COUNT(InvoiceNo) AS Frequency
FROM 
dbo.online_retail
GROUP BY
CustomerID;

--Step 3: Monetary Value Calculation:Calculate the total spending for each customer.;
SELECT
CustomerID,
SUM(Quantity*UnitPrice) AS MonetaryValue
FROM
dbo.online_retail
GROUP BY
CustomerID;

--STEP 4: Combine all above three steps with CTE;
WITH RFM_Calculation AS (
SELECT
CustomerID,
DATEDIFF(DAY,MAX(InvoiceDate),GETDATE()) AS Recency,
COUNT(InvoiceNo) AS Frequency,
SUM(Quantity*UnitPrice) AS MonetaryValue
FROM dbo.online_retail
GROUP BY 
CustomerID
)
SELECT 
    CustomerID,
    Recency,
    Frequency,
    MonetaryValue,
    -- You can assign scores based on quantiles or other methods
    NTILE(4) OVER (ORDER BY Recency ASC) AS RecencyScore,  -- 1 is most recent
    NTILE(4) OVER (ORDER BY Frequency DESC) AS FrequencyScore,  -- 1 is most frequent
    NTILE(4) OVER (ORDER BY MonetaryValue DESC) AS MonetaryValueScore  -- 1 is highest spending
FROM 
    RFM_Calculation;
--Note: SQL NTILE() function is a window function that distributes rows of an ordered partition into a pre-defined number of roughly equal groups.;

WITH RFM_Calculation AS (
    SELECT 
        CustomerID,
        DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) AS Recency,
        COUNT(InvoiceNo) AS Frequency,
        SUM(Quantity * UnitPrice) AS MonetaryValue,
        NTILE(4) OVER (ORDER BY DATEDIFF(DAY, MAX(InvoiceDate), GETDATE()) ASC) AS RecencyScore,
        NTILE(4) OVER (ORDER BY COUNT(InvoiceNo) DESC) AS FrequencyScore,
        NTILE(4) OVER (ORDER BY SUM(Quantity * UnitPrice) DESC) AS MonetaryValueScore
    FROM 
        dbo.online_retail
    GROUP BY 
        CustomerID
)
SELECT 
    CustomerID,
    Recency,
    Frequency,
    MonetaryValue,
    RecencyScore,
    FrequencyScore,
    MonetaryValueScore,
    -- Combine the scores to create an overall RFM score or segment
    CASE 
        WHEN RecencyScore = 1 AND FrequencyScore = 1 AND MonetaryValueScore = 1 THEN 'Best Customers'
        WHEN RecencyScore = 4 THEN 'Lost Customers'
        WHEN FrequencyScore = 1 THEN 'Frequent Customers'
        WHEN MonetaryValueScore = 1 THEN 'Big Spenders'
        ELSE 'Others'
    END AS CustomerSegment
FROM 
    RFM_Calculation;

/*
5. Interpret the Results
Best Customers: These customers score high on all three RFM metrics. They are your most valuable customers.
Lost Customers: These customers haven't purchased recently but were once frequent buyers.
Frequent Customers: These customers buy often but may not spend much per purchase.
Big Spenders: These customers spend a lot per purchase but may not buy frequently.
6. Use Segments for Targeted Marketing
Once you have these segments, you can tailor marketing strategies for each group:

Best Customers: Loyalty programs, early access to new products.
Lost Customers: Win-back campaigns with special discounts.
Frequent Customers: Promotions on frequently bought items.
Big Spenders: Upsell or cross-sell high-end products
*/

/*Product Bundling Opportunities:
What query would you use to identify products frequently purchased together, which could be used to create product bundles?
*/
SELECT * FROM dbo.online_retail;

--USING ASSOCIATION RULE MINING(APRIORI ALGORITHM);
--First, you need to identify all pairs of products from each transaction (Invoice).;
WITH ProductPairs AS (
SELECT 
A.InvoiceNo,
A.StockCode AS ProductA,
B.StockCode AS ProductB
FROM 
dbo.online_retail A
INNER JOIN
dbo.online_retail B
ON
A.InvoiceNo = B.InvoiceNo
AND A.StockCode < B.StockCode-- Avoid pairing the same product with itself and duplicate pairs;
)

--Next, count how often each pair of products is purchased together.;
SELECT 
ProductA,
ProductB,
COUNT(*) AS Frequency
FROM
ProductPairs
GROUP BY
ProductA,
ProductB
Order BY
Frequency DESC;

--You may want to filter pairs that are purchased together frequently, say at least 10 times.;
SELECT 
    ProductA,
    ProductB,
    Frequency
FROM (
    SELECT 
        ProductA,
        ProductB,
        COUNT(*) AS Frequency
    FROM 
        ProductPairs
    GROUP BY 
        ProductA, 
        ProductB
) AS PairFrequency
WHERE 
    Frequency >= 10 -- Adjust this threshold based on our data
ORDER BY 
    Frequency DESC;




