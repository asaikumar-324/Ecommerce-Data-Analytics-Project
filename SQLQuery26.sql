
WITH DeduplicatedOrders AS
(
    SELECT
        order_id,
        customer_id,
        order_date,
        status,
        payment_method,
        discount_code,
        shipping_fee,

        ROW_NUMBER() OVER
        (
            PARTITION BY order_id
            ORDER BY order_date
        ) AS rn

    FROM dbo.orders
),

ProductAveragePrice AS
(
    SELECT
        product_id,
        AVG(CAST(unit_price AS DECIMAL(18,2)))
            AS Average_Unit_Price

    FROM dbo.order_items

    WHERE unit_price > 0

    GROUP BY product_id
),

SalesAnalysis AS
(
    SELECT
        o.order_id,
        o.status,
        oi.product_id,
        oi.quantity,

        COALESCE(
            oi.unit_price,
            p.Average_Unit_Price
        ) AS Cleaned_Unit_Price,

        ISNULL(oi.discount_amount, 0)
            AS Discount_Amount

    FROM DeduplicatedOrders o

    INNER JOIN dbo.order_items oi
        ON o.order_id = oi.order_id

    LEFT JOIN ProductAveragePrice p
        ON oi.product_id = p.product_id

    WHERE o.rn = 1
)

SELECT
    status,

    COUNT(DISTINCT order_id)
        AS Total_Orders,

    COUNT(*)
        AS Total_Order_Items,

    SUM(quantity)
        AS Total_Quantity_Sold,

    CAST(
        SUM(quantity * Cleaned_Unit_Price)
        AS DECIMAL(14,2)
    ) AS Gross_Revenue,

    CAST(
        SUM(Discount_Amount)
        AS DECIMAL(14,2)
    ) AS Total_Discounts,

    CAST(
        SUM(
            quantity * Cleaned_Unit_Price
            - Discount_Amount
        )
        AS DECIMAL(14,2)
    ) AS Estimated_Net_Revenue

FROM SalesAnalysis

GROUP BY status

ORDER BY Estimated_Net_Revenue DESC;


























-- TASK 2: MONTHLY SALES TREND ANALYSIS

SELECT
    YEAR(o.order_date) AS Sales_Year,

    MONTH(o.order_date) AS Sales_Month,

    DATENAME(MONTH, o.order_date) AS Month_Name,

    COUNT(DISTINCT o.order_id) AS Total_Orders,

    SUM(oi.quantity) AS Total_Quantity_Sold,

    CAST(
        SUM(oi.quantity * COALESCE(oi.unit_price, p.list_price))
        AS DECIMAL(14,2)
    ) AS Gross_Revenue,

    CAST(
        SUM(COALESCE(oi.discount_amount, 0))
        AS DECIMAL(14,2)
    ) AS Total_Discounts,

    CAST(
        SUM(
            (oi.quantity * COALESCE(oi.unit_price, p.list_price))
            - COALESCE(oi.discount_amount, 0)
        )
        AS DECIMAL(14,2)
    ) AS Net_Revenue

FROM dbo.orders o

INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id



















    
WITH MonthlySales AS
(
    SELECT
        YEAR(o.order_date) AS Sales_Year,
        MONTH(o.order_date) AS Sales_Month,

        SUM(
            (oi.quantity *
             COALESCE(oi.unit_price, p.list_price))
             - COALESCE(oi.discount_amount, 0)
        ) AS Monthly_Revenue

    FROM dbo.orders o

    INNER JOIN dbo.order_items oi
        ON o.order_id = oi.order_id

    INNER JOIN dbo.products p
        ON oi.product_id = p.product_id

    WHERE o.status = 'completed'

    GROUP BY
        YEAR(o.order_date),
        MONTH(o.order_date)
)

SELECT TOP 1
    Sales_Year,
    Sales_Month,
    Monthly_Revenue

FROM MonthlySales

ORDER BY Monthly_Revenue DESC;


INNER JOIN dbo.products p
    ON oi.product_id = p.product_id

WHERE o.status = 'completed'

GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    DATENAME(MONTH, o.order_date)















    
-- TASK 2: HIGHEST REVENUE MONTH

SELECT TOP 1

    YEAR(o.order_date) AS Sales_Year,

    MONTH(o.order_date) AS Sales_Month,

    DATENAME(MONTH, o.order_date) AS Month_Name,

    CAST(
        SUM(
            (oi.quantity * COALESCE(oi.unit_price, p.list_price))
            - COALESCE(oi.discount_amount, 0)
        )
        AS DECIMAL(14,2)
    ) AS Monthly_Revenue

FROM dbo.orders o

INNER JOIN dbo.order_items oi
    ON o.order_id = oi.order_id

INNER JOIN dbo.products p
    ON oi.product_id = p.product_id

WHERE o.status = 'completed'

GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    DATENAME(MONTH, o.order_date)

ORDER BY Monthly_Revenue DESC;

ORDER BY Monthly_Revenue DESC;























-- HIGHEST REVENUE MONTH

SELECT TOP 1
    YEAR(o.order_date) AS Sales_Year,
    MONTH(o.order_date) AS Sales_Month,
    DATENAME(MONTH, o.order_date) AS Month_Name,

    CAST(
        SUM(
            (oi.quantity * COALESCE(oi.unit_price, p.list_price))
            - COALESCE(oi.discount_amount, 0)
        ) AS DECIMAL(14,2)
    ) AS Monthly_Revenue

FROM dbo.orders AS o

INNER JOIN dbo.order_items AS oi
    ON o.order_id = oi.order_id

INNER JOIN dbo.products AS p
    ON oi.product_id = p.product_id

WHERE o.status = 'completed'

GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    DATENAME(MONTH, o.order_date)

ORDER BY Monthly_Revenue DESC;

