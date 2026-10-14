-- =====================================================================
-- Retail Business Performance & Profitability Analysis
-- Dataset : Global Superstore (cleaned in Python, loaded as retail.orders_clean)
-- Engine  : Google BigQuery
-- Question: Where does the store lose money, and why?
-- =====================================================================


-- 1. Load check: row count, date range, total sales and profit
--    Result: 51,290 rows | 2011-01-01 to 2014-12-31 | sales ~12.64M | profit ~1.47M
SELECT COUNT(*) AS total_rows,
       MIN(order_date) AS first_order,
       MAX(order_date) AS last_order,
       ROUND(SUM(sales),0) AS total_sales,
       ROUND(SUM(profit),0) AS total_profit
FROM `retail.orders_clean`;


-- 2. View used by the Power BI dashboard (adds discount bands and a sort key)
CREATE OR REPLACE VIEW `retail.v_dashboard` AS
SELECT
  order_id, order_date, order_year, order_month, season,
  market, country, segment, category, sub_category, product_name,
  ship_mode, sales, quantity, discount, profit, shipping_cost, profit_margin,
  CASE WHEN discount = 0 THEN 'No discount'
       WHEN discount <= 0.20 THEN '1-20%'
       WHEN discount <= 0.40 THEN '21-40%'
       ELSE 'Above 40%' END AS discount_band,
  CASE WHEN discount = 0 THEN 1
       WHEN discount <= 0.20 THEN 2
       WHEN discount <= 0.40 THEN 3
       ELSE 4 END AS discount_band_order
FROM `retail.orders_clean`;


-- 3. Profit by sub-category (worst first)
--    Result: Tables is the only sub-category losing money
--            (sales 757K, profit -64K, margin -8.5%, avg discount 29.1%)
SELECT category, sub_category,
       ROUND(SUM(sales), 0) AS sales,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(SAFE_DIVIDE(SUM(profit), SUM(sales)) * 100, 1) AS margin_pct,
       ROUND(AVG(discount) * 100, 1) AS avg_discount_pct
FROM `retail.orders_clean`
GROUP BY category, sub_category
ORDER BY profit ASC;


-- 4. Tables only: margin by discount band
--    Result: +23.1% (no discount), +5.0% (1-20%), -18.1% (21-40%), about -77% (above 40%)
SELECT discount_band,
       COUNT(*) AS order_lines,
       ROUND(SUM(sales), 0) AS sales,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(SAFE_DIVIDE(SUM(profit), SUM(sales)) * 100, 1) AS margin_pct
FROM `retail.v_dashboard`
WHERE sub_category = 'Tables'
GROUP BY discount_band, discount_band_order
ORDER BY discount_band_order;


-- 5. Whole store: margin by discount band
--    Result: +25.3% (none), +13.7% (1-20%), -17.3% (21-40%), about -74% (above 40%)
SELECT discount_band,
       COUNT(*) AS order_lines,
       ROUND(SUM(sales), 0) AS sales,
       ROUND(SUM(profit), 0) AS profit,
       ROUND(SAFE_DIVIDE(SUM(profit), SUM(sales)) * 100, 1) AS margin_pct
FROM `retail.v_dashboard`
GROUP BY discount_band, discount_band_order
ORDER BY discount_band_order;


-- 6. Share of order lines that lose money
--    Result: 12,544 of 51,290 lines = 24.5%
SELECT COUNTIF(profit < 0) AS losing_lines,
       COUNT(*) AS total_lines,
       ROUND(COUNTIF(profit < 0) / COUNT(*) * 100, 1) AS pct_losing
FROM `retail.orders_clean`;


-- 7. Losing lines by discount band
--    Result: 0% losing with no discount, 21.6% at 1-20%, 76.2% at 21-40%, 98.4% above 40%
SELECT discount_band,
       COUNTIF(profit < 0) AS losing_lines,
       COUNT(*) AS total_lines,
       ROUND(COUNTIF(profit < 0) / COUNT(*) * 100, 1) AS pct_losing
FROM `retail.v_dashboard`
GROUP BY discount_band, discount_band_order
ORDER BY discount_band_order;
