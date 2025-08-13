
--Creating orders table 
CREATE TABLE orders(order_id VARCHAR(500),customer_id VARCHAR(500),order_status VARCHAR(50),order_purchase_date DATE,
order_approval_date DATE,order_delivered_carrier_date DATE,order_delivered_customer_date DATE,order_estimated_delivery_date DATE
);

--Importing orders table
COPY 
orders(order_id, customer_id, order_status, order_purchase_date, order_approval_date,
            order_delivered_carrier_date, order_delivered_customer_date, order_estimated_delivery_date)
FROM 'C:\Users\DELL\Downloads\Olist_Orders Table.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM orders;


--Creating products table
CREATE TABLE products(product_id VARCHAR(500),product_category_name VARCHAR(200),product_name_length INT,product_description_length INT,
product_photos_qty INT,product_weight_g INT,product_length_cm INT,product_height_cm INT,product_width_cm INT
);

--Importing products table
COPY
products(product_id,product_category_name,product_name_length,product_description_length,product_photos_qty,
product_weight_g,product_length_cm,product_height_cm,product_width_cm)
FROM 'C:\Users\DELL\Downloads\Olist_Products Table.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM products;

--Creating orderitems table 
CREATE TABLE orderitems(order_id VARCHAR(500),order_item_id VARCHAR(500),product_id VARCHAR(500),
seller_id VARCHAR(500),shipping_limit_date DATE,price NUMERIC(10,2),freight_value NUMERIC(10,2)
);

--Importing orderitems table 
COPY
orderitems(order_id,order_item_id,product_id,seller_id,shipping_limit_date,price,freight_value)
FROM 'C:\Users\DELL\Downloads\Olist_OrderItems Table.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM orderitems;

--Creating customers table 
CREATE TABLE customers(customer_id VARCHAR(500),customer_unique_id VARCHAR(500),
customer_zip_code_prefix INT,customer_city VARCHAR(100),customer_state VARCHAR(10)
);

--Importing customers table 
COPY
customers(customer_id,customer_unique_id,customer_zip_code_prefix,customer_city,customer_state)
FROM 'C:\Users\DELL\Downloads\Olist_Customers Table.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM customers;

--Creating payments table 
CREATE TABLE payments(order_id VARCHAR(500),payment_sequential INT,payment_type VARCHAR(100),
payment_installments INT,payment_value NUMERIC(10,2)
);

--Importing payments table 
COPY
payments(order_id,payment_sequential,payment_type,payment_installments,payment_value)
FROM 'C:\Users\DELL\Downloads\Olist_Payments Table.csv'
DELIMITER ','
CSV HEADER;

SELECT * FROM payments;

--CLEANING IMPORTED DATA

--Deleting unnecessary columns
ALTER TABLE products
DROP COLUMN product_name_length
DROP COLUMN product_description_length,
DROP COLUMN  product_photos_qty;

ALTER TABLE orders
DROP COLUMN order_approval_date,
DROP COLUMN order_delivered_carrier_date;

ALTER TABLE products
DROP COLUMN product_weight_g,
DROP COLUMN product_length_cm,
DROP COLUMN product_height_cm,
DROP COLUMN product_width_cm;

--Edit Column names
ALTER TABLE orders
RENAME COLUMN order_purchase_date TO purchase_date;

ALTER TABLE orders
RENAME COLUMN order_delivered_customer_date TO delivery_date;

ALTER TABLE orders
RENAME COLUMN order_estimated_delivery_date TO estimated_delivery_date;

ALTER TABLE customers
RENAME COLUMN customer_zip_code_prefix TO customer_zip_code;

--Show duplicates if any
SELECT *,COUNT(*)
FROM orders
GROUP BY order_id,customer_id ,order_status ,purchase_date,
delivery_date,estimated_delivery_date
HAVING COUNT(*)>1;

--To check if there's a Null
SELECT * FROM orders
WHERE purchase_date IS NULL;

--Trimming spaces
SELECT 
 TRIM(product_id) AS cleaned_product_id,
 TRIM(product_category_name) AS cleaned_product_category_name
FROM products;

--UPPER CASE order status
UPDATE orders
SET order_status = UPPER(order_status);

------------------------------------------

--Total orders, Total items sold, Total Revenue Per Month
SELECT DATE_TRUNC('month',o.purchase_date)::date AS order_month, COUNT(DISTINCT(o.order_id)) AS Total_orders, 
COUNT(oi.order_item_id) AS Total_items_sold,ROUND(SUM(py.payment_value),2) AS Total_revenue
FROM orders o
JOIN orderitems oi ON o.order_id=oi.order_id
JOIN payments py ON oi.order_id=py.order_id
WHERE o.order_status='DELIVERED'
GROUP BY order_month
ORDER BY order_month DESC;

--Top 10 Revenue generating products
SELECT p.product_id,p.product_category_name,ROUND(SUM(py.payment_value),2) AS Total_revenue
FROM orders o
JOIN orderitems oi ON o.order_id=oi.order_id
JOIN payments py ON oi.order_id=py.order_id
JOIN products p ON p.product_id=oi.product_id
GROUP BY p.product_id,p.product_category_name
ORDER BY Total_revenue DESC
LIMIT 10;

--Revenue by State
SELECT c.customer_state,ROUND(SUM(py.payment_value),2) AS Total_revenue
FROM products p
JOIN orderitems oi ON oi.product_id=p.product_id
JOIN payments py ON oi.order_id=py.order_id
JOIN orders o ON py.order_id=o.order_id
JOIN customers c ON o.customer_id=c.customer_id
WHERE o.order_status='DELIVERED'
GROUP BY c.customer_state
ORDER BY Total_revenue DESC;

--Revenue By City
SELECT c.customer_city,ROUND(SUM(py.payment_value),2) AS Total_revenue
FROM products p
JOIN orderitems oi ON oi.product_id=p.product_id
JOIN payments py ON oi.order_id=py.order_id
JOIN orders o ON py.order_id=o.order_id
JOIN customers c ON o.customer_id=c.customer_id
WHERE o.order_status='DELIVERED'
GROUP BY c.customer_city
ORDER BY Total_revenue DESC;

--Daily Average Order Value
SELECT DATE(o.purchase_date) AS Order_Date, 
ROUND(SUM(oi.price)/COUNT(DISTINCT o.order_id),2) AS avg_order_value
FROM orders o
JOIN orderitems oi ON o.order_id=oi.order_id
WHERE o.order_status='DELIVERED'
GROUP BY order_date
ORDER BY order_date;

--Customer Repeat Rate
SELECT ROUND(
 COUNT(*)*100.0/(SELECT COUNT(DISTINCT customer_id) FROM orders),2) AS repeat_customer_rate
FROM(
 SELECT customer_id
 FROM orders 
 WHERE order_status='DELIVERED'
 GROUP BY customer_id
 HAVING COUNT(order_id)>1);

--Total Revenue Per Customer
SELECT c.customer_id,SUM(py.payment_value) AS Total_revenue
FROM orders o
JOIN payments py ON o.order_id=py.order_id
JOIN customers c ON o.customer_id=c.customer_id
WHERE o.order_status='DELIVERED'
GROUP BY c.customer_id
ORDER BY Total_revenue DESC;

--The most selling category
SELECT p.product_category_name, SUM(py.payment_value) AS Top_category_revenue
FROM orders o
JOIN payments py ON o.order_id=py.order_id
JOIN orderitems oi ON py.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.order_status='DELIVERED'
GROUP BY p.product_category_name
ORDER BY Top_category_revenue DESC
LIMIT 1;

--The least selling category
SELECT p.product_category_name, SUM(py.payment_value) AS Least_category_revenue
FROM orders o
JOIN payments py ON o.order_id=py.order_id
JOIN orderitems oi ON py.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE order_status='DELIVERED'
GROUP BY p.product_category_name
ORDER BY Least_category_revenue ASC
LIMIT 1;


-- Total canceled orders Per Product
SELECT p.product_id,COUNT(*) AS canceled_orders
FROM orders o
JOIN orderitems oi ON o.order_id=oi.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.order_status = 'CANCELED'
GROUP BY p.product_id
ORDER BY canceled_orders DESC;

--Average Delivery Time
SELECT AVG(delivery_date-purchase_date) AS avg_delivery_time
FROM orders
WHERE delivery_date IS NOT NULL;

--Average Delivery Time By State
SELECT c.customer_state, AVG(o.delivery_date-o.purchase_date) AS avg_delivery_time
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
WHERE o.delivery_date IS NOT NULL
GROUP BY c.customer_state;

--Late Delivery %
SELECT AVG(CASE WHEN delivery_date>estimated_delivery_date THEN 1 ELSE 0 END)*100 AS late_delivery_percent
FROM orders
WHERE delivery_date IS NOT NULL;

--Payment Preference 
SELECT payment_type, SUM(payment_value) AS Total_revenue
FROM payments
GROUP BY payment_type
ORDER BY SUM(payment_value) DESC;

--Revenue By Installments
SELECT Payment_installments, COUNT(*) AS Total_payments,AVG(payment_value) AS Average_Revenue
FROM payments
GROUP BY payment_installments
ORDER BY payment_installments DESC;

--Top product Revenue By RANK()
SELECT p.product_id,SUM(py.payment_value) AS Total_revenue,
RANK() OVER(ORDER BY SUM(py.payment_value) DESC) AS revenue_rank
FROM orders o
JOIN orderitems oi ON o.order_id=oi.order_id
JOIN payments py ON oi.order_id=py.order_id
JOIN products p ON oi.product_id=p.product_id
GROUP BY p.product_id;



