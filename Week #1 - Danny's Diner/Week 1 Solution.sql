---- WEEK 1: DANNY'S DINER ----

CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

---- SOLUTIONS ----

---- Q1: What is the total amount each customer spent at the restaurant?

SELECT
    sales.customer_id,
    -- Multiply product number by its price and then sum all the values.
    Sum(sales.product_id * menu.price) AS TotalSpent 
-- join the menu and sales data tables together.
FROM dannys_diner.menu
INNER JOIN dannys_diner.sales
-- join using a common FOREIGN KEY (product_id)
ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
-- As we're using an aggregate function, we need a GROUP_BY
-- Think of GROUP_BY as meaning 'For Each'.
-- So we are summing up the TOTAL SPENT for each Customer_Id
GROUP BY sales.customer_id
-- Optional sort on the resultant data.
ORDER BY  sales.customer_id, TotalSpent DESC;

---- Q2: How many days has each customer visited the restaurant?

SELECT
    sales.customer_id,
    -- We want to count the UNIQUE number of days
    -- that a customer has visited.
    COUNT(DISTINCT sales.order_date) as days_visited
FROM dannys_diner.sales
-- Since we're aggregated at the CUSTOMER level, we group by the customer_id
GROUP BY sales.customer_id
-- Optional order the data by days_visited
ORDER BY days_visited DESC

---- Q3. What was the first item from the menu purchased by each customer?

-- There are probably a number of ways to do this, but CTEs is one useful way.
-- Common Table Expressions (CTEs) work as virtual tables (with records and columns), created during the execution of a query, used by the query, and eliminated after query execution.
-- In our solution we want to create a temporary table that ranks the products bought by each customer in terms of the DATE it was bought. 

WITH ranked_orders_cte AS
(
   SELECT	customer_id, 
  			order_date, 
  			product_name, 
  			a.product_id,
  
  -- DENSE_RANK is a windows function that ranks a SET of data by a set of ordering variables
  -- If a value is the same, they receive the same rank (key difference to a normal RANK())
  -- In our case we want to do a dense rank of customers by the date they made orders (ascending)
  -- PARTITION BY tells the DENSE_RANK function to calculate over Customer IDs. 
  
      		DENSE_RANK() OVER(PARTITION BY a.customer_id
              ORDER BY a.order_date) AS ranked_products
   FROM dannys_diner.sales AS a
   JOIN dannys_diner.menu AS b
      ON a.product_id = b.product_id
)

-- The CTE above essentially outputs order dates for each customer with 1 being the earliest order.
-- We can now query that CTE and simply select the ranked_product which is equal to 1 (earliest).

SELECT customer_id, product_id, product_name
FROM ranked_orders_cte
WHERE ranked_products = 1
GROUP BY customer_id, product_name, product_id;


