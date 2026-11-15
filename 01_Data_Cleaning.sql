

/* 1. CHECK RAW ORDERS RECORD COUNT */

SELECT
    COUNT(*) AS Total_Raw_Orders
FROM dbo.orders;


/* 2. CHECK DUPLICATE ORDER IDs */

SELECT
    order_id,
    COUNT(*) AS Duplicate_Count
FROM dbo.orders
GROUP BY order_id
HAVING COUNT(*) > 1
ORDER BY Duplicate_Count DESC;


/* 3. CHECK NULL VALUES IN RAW ORDERS */

SELECT
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END)
        AS Missing_Order_ID,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS Missing_Customer_ID,

    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)
        AS Missing_Order_Date,

    SUM(CASE WHEN status IS NULL THEN 1 ELSE 0 END)
        AS Missing_Order_Status
FROM dbo.orders;


/* 4. CREATE CLEANED ORDERS TABLE
   Keep one row per order_id.
   Raw table remains unchanged.
*/

IF OBJECT_ID('dbo.orders_cleaned', 'U') IS NULL
BEGIN
    ;WITH DeduplicatedOrders AS
    (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY order_id
                ORDER BY order_date DESC
            ) AS Row_Num
        FROM dbo.orders
        WHERE order_id IS NOT NULL
    )
    SELECT
        order_id,
        customer_id,
        order_date,
        status,
        payment_method,
        discount_code,
        shipping_fee
    INTO dbo.orders_cleaned
    FROM DeduplicatedOrders
    WHERE Row_Num = 1;

    PRINT 'Cleaned orders table created successfully.';
END
ELSE
BEGIN
    PRINT 'orders_cleaned already exists. Existing table was not changed.';
END;
GO


/* 5. CHECK CLEANED ORDERS RECORD COUNT */

SELECT
    COUNT(*) AS Total_Cleaned_Orders
FROM dbo.orders_cleaned;


/* 6. CHECK DUPLICATES IN CLEANED TABLE */

SELECT
    order_id,
    COUNT(*) AS Duplicate_Count
FROM dbo.orders_cleaned
GROUP BY order_id
HAVING COUNT(*) > 1;


/* 7. CHECK NULL ORDER IDs IN CLEANED TABLE */

SELECT
    COUNT(*) AS Missing_Order_IDs
FROM dbo.orders_cleaned
WHERE order_id IS NULL;


/* 8. CHECK MISSING CUSTOMER REFERENCES */

SELECT
    COUNT(*) AS Missing_Customer_References
FROM dbo.orders_cleaned o
LEFT JOIN dbo.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


/* 9. COMPARE RAW AND CLEANED RECORD COUNTS */

SELECT
    (SELECT COUNT(*) FROM dbo.orders) AS Raw_Order_Count,

    (SELECT COUNT(*) FROM dbo.orders_cleaned)
        AS Cleaned_Order_Count,

    (SELECT COUNT(*) FROM dbo.orders)
    -
    (SELECT COUNT(*) FROM dbo.orders_cleaned)
        AS Removed_Records;


/* 10. FINAL CLEANING SUMMARY */

SELECT
    'Raw Orders' AS Table_Name,
    COUNT(*) AS Total_Records
FROM dbo.orders

UNION ALL

SELECT
    'Cleaned Orders' AS Table_Name,
    COUNT(*) AS Total_Records
FROM dbo.orders_cleaned;


/* END OF DATA CLEANING */
