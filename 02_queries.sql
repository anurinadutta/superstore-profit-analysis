-- =====================================================================
-- Project : Superstore Profitability Analysis
-- Dataset : Sample Superstore (9,994 order lines, Jan 2014 - Dec 2017)
-- Database: MySQL 8.0 | Table: superstore (built by yytttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt)
-- Goal    : Find where the business loses money and why.
-- Check   : Totals reconcile with the Excel model
--           (sales 2,297,201 | profit 286,397 | margin 12.5%)
-- =====================================================================

-- Q1. Did the data load correctly, and does it match the Excel model?

-- Expected: 9,994 lines | 5,009 orders | 793 customers
--           sales 2,297,200.86 | profit 286,397.02
--           dates 2014-01-03 to 2017-12-30

select count(*) 				as order_line,
	count(distinct order_id) 	as orders,
	count(distinct customer_id) as customers,
	round(sum(sales),2) 		as total_sales,
	round(sum(profit),2)		as total_profit,
	min(order_date)				as first_order,
	max(order_date)				as last_order
from superstore_clean;

-- =====================================================================
-- B. OVERVIEW
-- =====================================================================
 
-- Q2. Which regions earn the most, and at what margin?

-- Finding: West has the best margin (14.9%); Central the worst (7.9%).

select region,
	round(sum(sales),2) as sales,
    round(sum(profit),2) as profit,
    round(100* sum(profit)/sum(sales), 1) as margin_profit 
from superstore_clean
group by region
order by profit DESC;


-- Q3. How fast are sales growing month over month?

with monthly as (
	select date_format(order_date, '%y-%m') as ym,
    sum(sales) as sales
from superstore_clean
group by ym
)
select ym as month_label,
round(sales,0) as sales,
round(100*(sales - lag(sales) over (order by ym))
/lag(sales) over (order by ym), 1) as month_growth_pct
from monthly
order by ym;

-- Note: monthly sales are seasonal (strong Nov/Dec), so the percentages
--       swing a lot. Read this as a trend, not a target.


-- =====================================================================
-- C. DISCOUNT IMPACT (main finding)
-- =====================================================================
 
-- Q4. How does profit change as the discount gets bigger?

-- Finding: bands D and E (discount above 20%) lose money.
--          Band E (30%+) has a margin of -48.2%.

select case when discount = 0 then 'A. No discount'
			when discount <= 0.1 then 'B. 1-10%'
            when discount <= 0.2 then 'C. 11-20%'
            when discount <= 0.3 then 'D. 21-30%'
            else 'E. 30%+'end as discount_band,
	count(*) 						as order_line,
    round(sum(sales), 0)			as sales,
    round(sum(profit), 0)			as profit,
    round(100 * sum(profit)/sum(sales), 1) as margin_pct
from superstore_clean
group by discount_band
order by discount_band;

-- Finding: bands D and E (discount above 20%) lose money.
-- Band E (30%+) has a margin of -48.2%.


-- Q5. Where do deep discounts (above 20%) hurt most by region?

select region,
		round(sum(case when discount > 0.2 then profit else 0 end), 0) as 
profit_deep_discount,
		round(sum(case when discount <= 0.2 then profit else 0 end), 0) as
profit_other_discount,
		round(sum(profit), 0) as total_profit
from superstore_clean
group by region
order by profit_deep_discount asc;

-- Finding: every region loses money on deep discounts; Central loses most.

-- Q6. Which sub-categories lose the most on orders discounted above 20%?

select sub_category,
		count(*) as order_line,
		round(sum(case when discount > 0.2 then profit else 0 end), 0) as profit_above_20
from superstore_clean
group by sub_category
order by profit_above_20;

-- Finding: Binders, Tables and Machines lose the most.
-- Expected: Binders -38,510 | Tables -30,698 | Machines -29,555 | Bookcases -11,098


-- =====================================================================
-- D. PRODUCTS AND CUSTOMERS
-- =====================================================================
 
-- Q7. Which 10 products lose the most money?

select product_name, sub_category,
		round(sum(sales), 0) as sales,
        round(sum(profit), 0)as profit,
        round(avg(discount), 2) as avg_discount
from superstore_clean
group by product_name, sub_category
order by sum(profit) asc
limit 10;

-- Finding: the worst product is the Cubify CubeX 3D Printer Double Head Print
--          (-8,880 profit, average discount 53%).


-- Q8. What are the three most profitable products in each category?

with product_profit as (
	select category, product_name,
			sum(profit) as profit
    from superstore_clean
    group by category, product_name
),
ranked as (
	select category, product_name, profit,
    rank() over (partition by category order by profit desc) as rnk
    from product_profit
)
select category, product_name, round(profit, 0) as profit, rnk
	from ranked
    where rnk<=3
    order by category, rnk;

-- Finding: Canon imageCLASS 2200 Advanced Copier is the top product (25,200).
        
 -- Q9. What share of customers order more than once?       

with customer_order as (
		select customer_id,
        count(distinct order_id) as orders
	from superstore_clean
	group by customer_id
)
select count(*) as customer,
		sum(case when orders > 1 then 1 else 0 end) as repeated_customer,
        round(100 * sum(case when orders > 1 then 1 else 0 end)/count(*), 0) as repeated_customer_rate
from customer_order;


        
-- Finding: 793 total customer, 781 returing customer with 98% repeated rate

--  Q10. Which large customers are unprofitable, and is deep discounting the cause?


WITH customer_totals AS (
    SELECT customer_id,
           SUM(sales)  AS sales,
           SUM(profit) AS profit
    FROM superstore_clean
    GROUP BY customer_id
),
customer_deep AS (
    SELECT customer_id,
           SUM(profit) AS profit_deep_discount
    FROM superstore_clean
    WHERE discount > 0.2
    GROUP BY customer_id
)
SELECT c.customer_id,
       ROUND(c.sales, 0)  AS sales,
       ROUND(c.profit, 0) AS profit,
       ROUND(COALESCE(d.profit_deep_discount, 0), 0) AS profit_on_deep_discount_orders
FROM customer_totals c
LEFT JOIN customer_deep d ON d.customer_id = c.customer_id
WHERE c.profit < 0
ORDER BY c.sales DESC
limit 10;

-- Finding: 155 customers have negative total profit. For most of the top ones,
-- The loss on orders above 20% discount is as large as their total loss.
        
        