-- CASE 1: Entering its third year of operation since 2003, the store owner wants to see annual sales and transaction trends.
SELECT EXTRACT(YEAR FROM paymentdate) AS year, SUM(amount) AS total_sales,
COUNT(checknumber) AS n_transaction
FROM payments
GROUP BY 1
ORDER BY 1;


-- CASE 2: From previous transactions, the store owner is interested in knowing how many customers have made payments above or below the average total payments.
WITH customer_amount AS (
	SELECT customernumber, SUM(amount) AS total_customer
	FROM payments
	GROUP BY 1
), customer_category AS (
	SELECT *,
	CASE
		WHEN total_customer > (SELECT AVG(total_customer) FROM customer_amount) THEN 'above_avg'
		WHEN total_customer = (SELECT AVG(total_customer) FROM customer_amount) THEN 'same'
		ELSE 'below_avg'
	END
	AS category_customer
	FROM customer_amount
)
SELECT category_customer, COUNT(customernumber) FROM customer_category
GROUP BY 1;


-- CASE 3: The store owner is planning a customer loyalty program and wants to categorize customers based on their order frequency.
-- If 1 order = One-time Customer
-- If 2 orders = Repeated Customer
-- If 3 orders = Frequent Customer
-- If 4 or more orders = Loyal Customer
WITH count_order AS(
	SELECT customernumber, COUNT(ordernumber) AS n_order
	FROM orders
	GROUP BY 1
), 
type_cust AS (
SELECT cs.customername, co.*,
CASE
	WHEN n_order = 1 THEN 'One-time'
	WHEN n_order = 2 THEN 'Repeated'
	WHEN n_order = 3 THEN 'Frequent'
	WHEN n_order >= 4 THEN 'Loyal'
END
AS cust_type
FROM count_order AS co
JOIN customers AS cs ON co.customernumber = cs.customernumber
ORDER BY 1
)
SELECT * FROM type_cust
WHERE cust_type = 'Loyal';


-- CASE 4: The store owner wants to understand product purchasing trends in each country.
-- They ask you to find the most ordered product category in each country.
-- Note: Create the query as a view.
WITH country_order AS (
	SELECT country, productline, SUM(quantityordered) AS sum_qty
	FROM customers
	JOIN orders USING(customernumber)
	JOIN orderdetails USING(ordernumber)
	JOIN products USING(productcode)
	GROUP BY 1,2
	ORDER BY 1 ASC, 3 DESC
),
favorite_category AS(
	SELECT *,
		FIRST_VALUE(productline) OVER(PARTITION BY country) AS fav
		FROM country_order
)
SELECT country, fav, sum_qty
FROM favorite_category
GROUP BY 1,2,3;


-- CASE 5: The store owner wants to know the average time customers take to place a repeat order.
WITH nextdate_cust AS (
	SELECT customernumber, orderdate,
	LEAD(orderdate) OVER(PARTITION BY customernumber ORDER BY orderdate) AS nextdate
	FROM orders
	ORDER BY 1, orderdate
),
duration_next_order AS (
	SELECT *,
	nextdate - orderdate AS duration
	FROM nextdate_cust
	WHERE nextdate IS NOT NULL
)
SELECT customername, AVG(duration)::int AS avg_duration
FROM duration_next_order
JOIN customers USING(customernumber)
GROUP BY 1
ORDER BY 2;


-- CASE 6: The store owner wants to see the date and amount of the first payment made by each customer.
WITH first_payment_date AS(
	SELECT customernumber, customername, paymentdate,
		FIRST_VALUE(paymentdate) OVER(PARTITION BY customernumber ORDER BY paymentdate) AS firstpaymentdate,
		amount,
		FIRST_VALUE(amount) OVER(PARTITION BY customernumber ORDER BY paymentdate) AS firstpaymentamount
	FROM customers
	JOIN payments
		USING(customernumber))
SELECT customername, firstpaymentdate, firstpaymentamount
FROM first_payment_date
GROUP BY 1,2,3
ORDER BY 2 ASC;


-- CASE 7: Kali ini pemilik toko ingin melihat customer yg melakukan order pertama dan terakhir di tiap negara.
WITH first_last_customer AS(
	SELECT country, customername, orderdate,
	FIRST_VALUE(customername) OVER(PARTITION BY country ORDER BY orderdate) AS first_customer,
	LAST_VALUE(customername) OVER(PARTITION BY country ORDER BY orderdate RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS last_customer
	FROM customers
	JOIN orders
		USING(customernumber))
	SELECT country, first_customer, last_customer
	FROM first_last_customer
	GROUP BY 1,2,3;

-- CASE 8: pemilik toko tertarik untuk mengetahui produk termahal ke-n yg diorder tiap customer. buatlah query tsb ke dalam procedure.
-- Produk termahal kedua
WITH customer_products_ordered AS(
	SELECT customername, productname, priceeach
	FROM customers
	JOIN orders
		USING(customernumber)
	JOIN orderdetails
		USING(ordernumber)
	JOIN products
		USING(productcode)),
second_most_expensive AS (
	SELECT *,
		NTH_VALUE(productname, 2) OVER(PARTITION BY customername ORDER BY priceeach DESC
		RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS second_most_expensive_products
		FROM customer_products_ordered
)
SELECT customername, second_most_expensive_products
FROM second_most_expensive
GROUP BY 1,2
ORDER BY 1;