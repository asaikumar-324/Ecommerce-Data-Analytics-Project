


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


/* 2. ESTIMATED PRODUCT PROFIT
   Excludes shipping and operating costs
*/

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


/* 3. COMPLETED ORDERS */

SELECT
    COUNT(DISTINCT order_id) AS Completed_Orders
FROM dbo.orders_cleaned
WHERE status = 'completed';


/* 4. AVERAGE ORDER VALUE */

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
    SELECT COUNT(DISTINCT order_id) AS Total_Orders
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


/* 5. TOTAL QUANTITY SOLD
   Completed orders only
*/

SELECT
    SUM(oi.quantity) AS Total_Quantity_Sold
FROM dbo.order_items oi
INNER JOIN dbo.orders_cleaned o
    ON oi.order_id = o.order_id
WHERE o.status = 'completed';


/* 6. REVENUE BY ORDER STATUS
   Includes completed, returned and canceled orders
*/

SELECT
    o.status AS Order_Status,
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
GROUP BY o.status
ORDER BY Total_Revenue DESC;


/* 7. ORDER COUNT BY STATUS */

SELECT
    status AS Order_Status,
    COUNT(DISTINCT order_id) AS Total_Orders
FROM dbo.orders_cleaned
GROUP BY status
ORDER BY Total_Orders DESC;


/* 8. REVENUE BY STATE
   Completed orders only
*/

SELECT
    c.state,
    CAST(
        SUM(
            oi.quantity *
            COALESCE(oi.unit_price, p.list_price)
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(18,2)
    ) AS Total_Revenue
FROM dbo.customers c
INNER JOIN dbo.orders_cleaned o
    ON c.customer_id = o.customer_id
INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id
INNER JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY c.state
ORDER BY Total_Revenue DESC;


/* 9. REVENUE BY PRODUCT CATEGORY
   Completed orders only
*/

SELECT
    p.category,
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
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY Total_Revenue DESC;


/* 10. MONTHLY REVENUE TREND
    Completed orders only
*/

SELECT
    YEAR(o.order_date) AS Order_Year,
    MONTH(o.order_date) AS Order_Month,
    FORMAT(o.order_date, 'yyyy-MM') AS Year_Month,
    CAST(
        SUM(
            oi.quantity *
            COALESCE(oi.unit_price, p.list_price)
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(18,2)
    ) AS Monthly_Revenue
FROM dbo.orders_cleaned o
INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id
INNER JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    FORMAT(o.order_date, 'yyyy-MM')
ORDER BY
    Order_Year,
    Order_Month;


/* 11. REVENUE BY ACQUISITION CHANNEL
    Completed orders only
*/

SELECT
    c.acquisition_channel,
    CAST(
        SUM(
            oi.quantity *
            COALESCE(oi.unit_price, p.list_price)
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(18,2)
    ) AS Total_Revenue
FROM dbo.customers c
INNER JOIN dbo.orders_cleaned o
    ON c.customer_id = o.customer_id
INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id
INNER JOIN dbo.products p
    ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY c.acquisition_channel
ORDER BY Total_Revenue DESC;


/* 12. TOP 10 PRODUCTS BY REVENUE
    Completed orders only
*/

SELECT TOP 10
    p.product_id,
    p.product_name,
    p.category,
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
WHERE o.status = 'completed'
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY Total_Revenue DESC;


/* END OF SALES ANALYSIS */
