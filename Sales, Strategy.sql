-- CASE 1: The store plans to implement a strategy to accelerate the sale of products that have never been sold at all through a discount scheme.
-- The store owner asks you to find products that have never been purchased by any customer.
SELECT p.*
FROM orderdetails as od
RIGHT JOIN products AS p USING(productcode)
WHERE ordernumber IS NULL;
-- 1985 Toyota Supra is a product that has never been purchased by any customer.


-- CASE 2: The store owner will also provide discounts for products where the percentage of units sold is below 30% of the available stock.
-- Find products where the sold percentage is below 30%.
-- Note: total_stock = quantityinstock + n_of_item_sold
-- sold_percentage = qtysold / (stock + qtysold) * 100
WITH product_sold AS (
	SELECT productcode, SUM(quantityordered) AS qtysold FROM orderdetails
	GROUP BY 1
)
SELECT pd.productcode, pd.productname, qtysold+quantityinstock AS total,
	qtysold::float / (qtysold+quantityinstock) * 100 AS percentage_sold
	FROM product_sold ps
	JOIN products pd on ps.productcode = pd.productcode
	WHERE (qtysold::float / (qtysold+quantityinstock) * 100) < 30
	ORDER BY 4;


-- CASE 3: The store’s new policy requires that the minimum selling price for each product is 20% below the MSRP.
-- The store owner wants to know if there are products sold below this minimum price.
SELECT productname, priceeach, msrp, msrp*0.8 AS minimum_price,
priceeach/msrp*100 as percentage
FROM products pd
JOIN orderdetails od on pd.productcode = od.productcode
WHERE priceeach < (msrp*0.8);
-- It is found that some products are sold below the minimum price, though not significantly lower.


-- CASE 4: From the sales results, the store owner wants to know which product categories have above-average revenue.
-- Find product categories with revenue above average.
WITH product_revenue AS(
	SELECT productcode, SUM(priceeach * quantityordered) AS total_sold
	FROM orderdetails
	GROUP BY 1
), 
productline_revenue AS (
	SELECT productline, SUM(total_sold) AS total_revenue
	FROM products pd
	JOIN product_revenue pv ON pd.productcode = pv.productcode
	GROUP BY 1
)
SELECT * FROM productline_revenue
WHERE total_revenue > (SELECT AVG(total_revenue) FROM productline_revenue);
-- There are two product categories above average: Classic Cars and Vintage Cars.


-- CASE 5: The store owner wants to understand customer behavior when making transactions in the store.
-- First, they want to know the average payment amount made by each customer.
SELECT customername, ROUND(AVG(amount), 3) AS average_payment
FROM payments py
JOIN customers cs on py.customernumber = cs.customernumber
GROUP BY 1
ORDER BY 2 DESC;


-- CASE 6: Next, the store owner wants to see which products were ordered by each customer and the quantity ordered.
SELECT c.customername, p.productname, SUM(quantityordered) AS qty_ordered
FROM customers AS c
JOIN orders AS o USING(customernumber)
JOIN orderdetails AS od USING(ordernumber)
JOIN products AS p USING(productcode)
GROUP BY 1,2
ORDER BY 1,2;


-- CASE 7: The store owner wants to assess sales performance in the Asia-Australia region.
-- They request a list of customers from New Zealand, Australia, Singapore, Japan, Hong Kong, Philippines, whose total payments exceed the average.
WITH total_payment AS (
SELECT customernumber, SUM(amount) AS total_amount
FROM payments
GROUP BY 1
)
SELECT customernumber, customername, country, total_amount
FROM customers
JOIN total_payment USING(customernumber)
WHERE country in ('New Zealand', 'Australia', 'Singapore', 'Japan', 'Hong Kong', 'Philippines')
AND total_amount > (SELECT AVG(total_amount) FROM total_payment);


-- CASE 8: To appreciate the store’s sales performance during 2004, the owner plans to give bonuses to the top 5 employees with the highest sales in 2004.
-- Note: Ensure product orders have a "shipped" status.
WITH topSales2004 AS (
	SELECT salesRepEmployeeNumber AS employeeNumber,
		SUM(priceeach * quantityordered) AS total_sales
	FROM customers
		JOIN orders
			USING(customernumber)
		JOIN orderdetails
			USING(ordernumber)
	WHERE EXTRACT (YEAR FROM orderdate) = 2004 AND status = 'Shipped'
	GROUP BY employeenumber
	ORDER BY 2 DESC
	LIMIT 5
)
SELECT CONCAT(firstname, ' ', lastname) AS employeename, total_sales
FROM topSales2004
	JOIN employees
		USING(employeenumber);