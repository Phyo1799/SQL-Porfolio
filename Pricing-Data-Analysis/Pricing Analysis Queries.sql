
-- 1. How many pubs are located in each country??
SELECT
	country, 
	count(pub_name) 'Pubs Per Country'
FROM pubs
GROUP BY country
;

---2. What is the total sales amount for each pub, including the beverage price and quantity sold?
SELECT 
	p.pub_name,
	sum(b.price_per_unit) total_beverage_price,
	sum (s.quantity) quantity_sold,
	sum (b.price_per_unit*s.quantity) total_sales
FROM sales s
	JOIN pubs p ON s.pub_id = p.pub_id
	JOIN beverages b ON s.beverage_id = b.beverage_id
GROUP BY pub_name;

---3. Which pub has the highest average rating?
SELECT TOP 1
	p.pub_name,
	ROUND(avg(r.rating),1) AS pubs_avg_rating
FROM pubs p
	JOIN ratings r ON p.pub_id = r.pub_id
GROUP BY p.pub_name
ORDER by pubs_avg_rating DESC;

---4. What are the top 5 beverages by sales quantity across all pubs?
SELECT TOP 5
	b.beverage_name,
	sum(s.quantity) total_quantity
FROM sales s
	JOIN beverages b ON s.beverage_id = b.beverage_id
	JOIN pubs p ON s.pub_id = p.pub_id
GROUP BY beverage_name
ORDER BY total_quantity DESC;

---5. How many sales transactions occurred on each date?
SELECT
	transaction_date,
	count(sale_id) AS countofsales
FROM sales
GROUP BY transaction_date;

---6. Find the name of someone that had cocktails and which pub they had it in.
SELECT 
	r.customer_name,
	p.pub_name
FROM ratings r
	JOIN pubs p ON r.pub_id = p.pub_id
WHERE r.review LIKE '%cocktails%';

---7. What is the average price per unit for each category of beverages, excluding the category 'Spirit'?
SELECT
	category,
	avg(price_per_unit) avg_priceperunit_ex_spirit
FROM 
	(SELECT *
	FROM beverages
	WHERE category != 'Spirit') priceperunit_exclude_spirit
GROUP BY category;

---8. Which pubs have a rating higher than the average rating of all pubs?
WITH pub_rating AS
(SELECT
	p.pub_name,
	r.rating,
	avg(r.rating) over() AS avg_rating
FROM pubs p
	JOIN ratings r ON r.pub_id = p.pub_id) 

SELECT *
FROM pub_rating
Where rating > avg_rating;


---9. What is the running total of sales amount for each pub, ordered by the transaction date?
WITH total_sales_bydate AS (
SELECT 
	s.transaction_date,
	p.pub_name,
	sum (b.price_per_unit*s.quantity) total_sales_perday
FROM sales s
	JOIN pubs p ON s.pub_id = s.pub_id
	JOIN beverages b ON s.beverage_id = p.pub_id
GROUP BY transaction_date,pub_name)

SELECT 
	transaction_date,
    pub_name,
    total_sales_perday,
	sum(total_sales_perday) over(PARTITION BY pub_name ORDER BY transaction_date) AS running_total_sales_for_each_pub
FROM total_sales_bydate
ORDER BY pub_name,transaction_date;


---10. For each country, what is the average price per unit of beverages in each category, and what is the overall average price per unit of beverages across all categories?
WITH overall_avg_price AS (
    SELECT 
        AVG(price_per_unit) AS avg_price_acrossallcat
    FROM beverages
),
country_category_avg AS (
    SELECT 
        p.country,
        b.category,
        AVG(b.price_per_unit) AS avg_price_perunit
    FROM 
        sales s
    JOIN beverages b ON s.beverage_id = b.beverage_id
    JOIN pubs p ON s.pub_id = p.pub_id
    GROUP BY p.country, b.category
)

SELECT 
    cca.country,
    cca.category,
    cca.avg_price_perunit,
    oavg.avg_price_acrossallcat
FROM 
    country_category_avg cca
CROSS JOIN
    overall_avg_price oavg
ORDER BY cca.country, cca.category;

--- 11. For each pub, what is the percentage contribution of each category of beverages to the total sales amount, and what is the pub's overall sales amount?
WITH pub_total_sales AS (
SELECT
	p.pub_id,
	p.pub_name,
	sum(b.price_per_unit*s.quantity) AS total_sales
FROM
	sales s
    JOIN beverages b ON s.beverage_id = b.beverage_id
	JOIN pubs p ON s.pub_id = p.pub_id
GROUP BY p.pub_id,p.pub_name
),

category_sales_per_pub AS (
SELECT
    p.pub_id,
    p.pub_name,
    b.category,
    sum(b.price_per_unit*s.quantity) AS category_sales
FROM
    sales s
JOIN
    pubs p ON s.pub_id = p.pub_id
JOIN
    beverages b ON s.beverage_id = b.beverage_id
GROUP BY
    p.pub_id, p.pub_name, b.category
)

SELECT 
	csp.pub_name,
    csp.category,
    csp.category_sales,
    pts.total_sales,
    (csp.category_sales / pts.total_sales) * 100 AS percentage_contribution
FROM pub_total_sales pts
	JOIN category_sales_per_pub csp ON pts.pub_id = csp.pub_id
ORDER BY csp.pub_name, csp.category;