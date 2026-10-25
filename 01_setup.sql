-- 1. Database and raw table

create database if not exists superstore;
use superstore;
CREATE TABLE superstore_raw (
  row_id INT, order_id VARCHAR(30), order_date VARCHAR(20), ship_date VARCHAR(20),
  ship_mode VARCHAR(30), customer_id VARCHAR(20), segment VARCHAR(30), country VARCHAR(50),
  city VARCHAR(60), state VARCHAR(60), region VARCHAR(20), product_id VARCHAR(30),
  category VARCHAR(30), sub_category VARCHAR(30), product_name VARCHAR(255),
  sales DECIMAL(12,4), quantity INT, discount DECIMAL(4,2), profit DECIMAL(12,4)
);

-- 2. #Load the CSV (dates are text: the file mixes 11-08-2016 and 6/16/2016)

LOAD DATA LOCAL INFILE 'C:/data/Sample_ Superstore.csv'
INTO TABLE superstore_raw
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(row_id, order_id, order_date, ship_date, ship_mode, customer_id, segment, country,
 city, state, region, product_id, category, sub_category, product_name,
 sales, quantity, discount, profit);
select count(*), round(sum(sales),2), round(sum(profit),2) from superstore_raw;

-- 3.#Clean table: dates converted from month-day-year text to DATE

create table superstore_clean as
select row_id, order_id, STR_TO_DATE(REPLACE(order_date,'/','-'),'%m-%d-%Y') AS order_date,
  STR_TO_DATE(REPLACE(ship_date,'/','-'),'%m-%d-%Y') AS ship_date,
  ship_mode, customer_id, segment, country, city, state, region,
  product_id, category, sub_category, product_name,
  sales, quantity, discount, profit
FROM superstore_raw;

-- 4.# Check the dates. Expected: 0 null dates | 2014-01-03 to 2017-12-30

select sum(order_date is null or ship_date is null) as null_dates,
min(order_date) as first_order, max(order_date) as last_order from superstore_clean;


 