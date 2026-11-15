
USE Ecommerce_Analytics;
GO

/* =====================================================
   E-COMMERCE DATA ANALYTICS
   FILE: 04_Final_Validation.sql
   PURPOSE: Final KPI and data quality validation
   ===================================================== */

/* 1. VALIDATE TOTAL REVENUE
   Completed orders only
*/

SELECT
    CAST(
        SUM(
            oi.quantity *
            COALESCE(oi.unit_price, p.list_price)
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(18,2)
    ) AS Total_Revenue
FROM dbo.order_items oi
INNER JOIN dbo.orders_cleaned o
    ON oi.order_id = o.order_id
INNER JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE o.status = 'completed';

/* 2. VALIDATE ESTIMATED PRODUCT PROFIT */

SELECT
    CAST(
        SUM(
            oi.quantity *
            (
                COALESCE(oi.unit_price, p.list_price)
                - p.unit_cost
            )
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(18,2)
    ) AS Estimated_Product_Profit
FROM dbo.order_items oi
INNER JOIN dbo.orders_cleaned o
    ON oi.order_id = o.order_id
INNER JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE o.status = 'completed';

/* 3. VALIDATE COMPLETED ORDERS */

SELECT
    COUNT(DISTINCT order_id) AS Completed_Orders
FROM dbo.orders_cleaned
WHERE status = 'completed';

/* 4. VALIDATE REGISTERED CUSTOMERS */

SELECT
    COUNT(DISTINCT customer_id) AS Registered_Customers
FROM dbo.customers;

/* 5. VALIDATE REPEAT CUSTOMERS */

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

/* 6. VALIDATE ONE-TIME CUSTOMERS */

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

/* 7. VALIDATE CUSTOMER REPEAT RATE */

WITH CustomerOrders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM dbo.orders_cleaned
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT
    CAST(
        100.0 *
        COUNT(CASE WHEN Total_Orders > 1 THEN 1 END)
        / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Customer_Repeat_Rate_Percentage
FROM CustomerOrders;

/* 8. VALIDATE AVERAGE ORDER VALUE */

WITH Revenue AS (
    SELECT
        SUM(
            oi.quantity *
            COALESCE(oi.unit_price, p.list_price)
            - COALESCE(oi.discount_amount, 0)
        ) AS Total_Revenue
    FROM dbo.order_items oi
    INNER JOIN dbo.orders_cleaned o
        ON oi.order_id = o.order_id
    INNER JOIN dbo.products p
        ON oi.product_id = p.product_id
    WHERE o.status = 'completed'
),
Orders AS (
    SELECT
        COUNT(DISTINCT order_id) AS Total_Orders
    FROM dbo.orders_cleaned
    WHERE status = 'completed'
)
SELECT
    CAST(
        Total_Revenue / NULLIF(Total_Orders, 0)
        AS DECIMAL(18,2)
    ) AS Average_Order_Value
FROM Revenue
CROSS JOIN Orders;

/* 9. VALIDATE ORDER STATUS COUNTS */

SELECT
    status AS Order_Status,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM dbo.orders_cleaned
GROUP BY status
ORDER BY Total_Orders DESC;

/* 10. VALIDATE ORDER ITEMS DATA QUALITY */

SELECT
    COUNT(*) AS Total_Order_Items,

    SUM(
        CASE
            WHEN unit_price IS NULL THEN 1
            ELSE 0
        END
    ) AS Missing_Unit_Prices,

    SUM(
        CASE
            WHEN unit_price <= 0 THEN 1
            ELSE 0
        END
    ) AS Invalid_Unit_Prices,

    SUM(
        CASE
            WHEN quantity IS NULL OR quantity <= 0 THEN 1
            ELSE 0
        END
    ) AS Invalid_Quantities,

    SUM(
        CASE
            WHEN discount_amount < 0 THEN 1
            ELSE 0
        END
    ) AS Negative_Discounts

FROM dbo.order_items;

/* 11. CHECK DUPLICATE ORDER IDs IN CLEANED TABLE */

SELECT
    order_id,
    COUNT(*) AS Duplicate_Count
FROM dbo.orders_cleaned
GROUP BY order_id
HAVING COUNT(*) > 1;

/* 12. CHECK MISSING CUSTOMER RELATIONSHIPS */

SELECT
    COUNT(*) AS Orders_With_Missing_Customers
FROM dbo.orders_cleaned o
LEFT JOIN dbo.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

/* 13. CHECK MISSING PRODUCT RELATIONSHIPS */

SELECT
    COUNT(*) AS Order_Items_With_Missing_Products
FROM dbo.order_items oi
LEFT JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

/* 14. CHECK MISSING ORDER RELATIONSHIPS */

SELECT
    COUNT(*) AS Order_Items_With_Missing_Orders
FROM dbo.order_items oi
LEFT JOIN dbo.orders_cleaned o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

/* END OF FINAL VALIDATION */