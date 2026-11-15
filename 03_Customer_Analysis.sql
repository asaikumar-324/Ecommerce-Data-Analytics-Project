

/* 1. TOTAL REGISTERED CUSTOMERS */

SELECT
    COUNT(DISTINCT customer_id) AS Total_Registered_Customers
FROM dbo.customers;


/* 2. CUSTOMERS WITH COMPLETED ORDERS */

SELECT
    COUNT(DISTINCT o.customer_id) AS Customers_With_Completed_Orders
FROM dbo.orders_cleaned o
WHERE o.status = 'completed';


/* 3. REPEAT CUSTOMERS
   Customers with more than one completed order
*/

WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM dbo.orders_cleaned
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS Repeat_Customers
FROM CustomerOrders
WHERE Total_Orders > 1;


/* 4. ONE-TIME CUSTOMERS
   Customers with exactly one completed order
*/

WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM dbo.orders_cleaned
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS One_Time_Customers
FROM CustomerOrders
WHERE Total_Orders = 1;


/* 5. CUSTOMER REPEAT RATE */

WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM dbo.orders_cleaned
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    COUNT(CASE WHEN Total_Orders > 1 THEN 1 END)
        AS Repeat_Customers,
    COUNT(*) AS Customers_With_Completed_Orders,
    CAST(
        100.0 *
        COUNT(CASE WHEN Total_Orders > 1 THEN 1 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Customer_Repeat_Rate_Percentage
FROM CustomerOrders;


/* 6. CUSTOMERS BY ACQUISITION CHANNEL */

SELECT
    acquisition_channel,
    COUNT(DISTINCT customer_id) AS Total_Customers
FROM dbo.customers
GROUP BY acquisition_channel
ORDER BY Total_Customers DESC;


/* 7. CUSTOMERS BY STATE */

SELECT
    state,
    COUNT(DISTINCT customer_id) AS Total_Customers
FROM dbo.customers
GROUP BY state
ORDER BY Total_Customers DESC;


/* 8. MONTHLY NEW CUSTOMER ACQUISITION */

SELECT
    YEAR(signup_date) AS Signup_Year,
    MONTH(signup_date) AS Signup_Month,
    FORMAT(signup_date, 'yyyy-MM') AS Signup_Year_Month,
    COUNT(DISTINCT customer_id) AS New_Customers
FROM dbo.customers
GROUP BY
    YEAR(signup_date),
    MONTH(signup_date),
    FORMAT(signup_date, 'yyyy-MM')
ORDER BY
    Signup_Year,
    Signup_Month;


/* 9. CUSTOMER ACQUISITION BY CHANNEL AND STATE */

SELECT
    acquisition_channel,
    state,
    COUNT(DISTINCT customer_id) AS Total_Customers
FROM dbo.customers
GROUP BY
    acquisition_channel,
    state
ORDER BY
    acquisition_channel,
    Total_Customers DESC;


/* 10. CUSTOMER ORDER FREQUENCY */

SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id) AS Completed_Orders
FROM dbo.orders_cleaned o
WHERE o.status = 'completed'
GROUP BY o.customer_id
ORDER BY Completed_Orders DESC;


/* 11. TOP 10 CUSTOMERS BY REVENUE
    Completed orders only
*/

SELECT TOP 10
    o.customer_id,
    CAST(
        SUM(
            oi.quantity *
            COALESCE(oi.unit_price, p.list_price)
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(18,2)
    ) AS Total_Revenue
FROM dbo.orders_cleaned o
INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id
INNER JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY o.customer_id
ORDER BY Total_Revenue DESC;


/* 12. CUSTOMER RETENTION SUMMARY */

WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM dbo.orders_cleaned
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN Total_Orders = 1 THEN 'One-Time Customer'
        WHEN Total_Orders > 1 THEN 'Repeat Customer'
    END AS Customer_Type,
    COUNT(*) AS Total_Customers,
    CAST(
        100.0 * COUNT(*) /
        NULLIF((SELECT COUNT(*) FROM CustomerOrders), 0)
        AS DECIMAL(10,2)
    ) AS Customer_Percentage
FROM CustomerOrders
GROUP BY
    CASE
        WHEN Total_Orders = 1 THEN 'One-Time Customer'
        WHEN Total_Orders > 1 THEN 'Repeat Customer'
    END;


/* END OF CUSTOMER ANALYSIS */
