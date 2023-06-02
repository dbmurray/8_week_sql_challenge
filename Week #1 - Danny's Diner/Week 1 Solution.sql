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

-------------------------------------------------------------------------
---- Q1: What is the total amount each customer spent at the restaurant?
-------------------------------------------------------------------------

SELECT
    sales.customer_id,
    -- Multiply product number by its price and then sum all the values.
    Sum(menu.price) AS TotalSpent 
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
ORDER BY  sales.customer_id, TotalSpent DESC

-------------------------------------------------------------------------
---- Q2: How many days has each customer visited the restaurant?
-------------------------------------------------------------------------

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

-------------------------------------------------------------------------
---- Q3. What was the first item from the menu purchased by each customer?
-------------------------------------------------------------------------

-- There are probably a number of ways to do this, but CTEs is one useful way.
-- Common Table Expressions (CTEs) work as virtual tables (with records and columns), created during the execution of a query, used by the query, and eliminated after query execution.
-- In our solution we want to create a temporary table that ranks the products bought by each customer in terms of the DATE it was bought. 

WITH ranked_orders_cte AS
(
SELECT
    customer_id, 
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
GROUP BY customer_id, product_name, product_id

----------------------------------------------------------------------------------------------------------
---- Q4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-----------------------------------------------------------------------------------------------------------

-- This is a fairly straightforward query. We just need to count the number of sales of eahc product and order
-- them correctly. We'll also bring in the product name so the output is a bit more comprehensible. 

SELECT
  	b.product_name, 
    -- Let's use a COUNT aggregate function to get a count of eahc products sale.
    count(a.product_id) AS product_sales
FROM dannys_diner.sales a
INNER JOIN dannys_diner.menu b
ON a.product_id = b.product_id
GROUP BY b.product_name, a.product_id
-- Order the data descendingly
ORDER BY product_sales desc
-- Only need the top row, so we can use a LIMIT function.
LIMIT 1

-----------------------------------------------------------
---- Q5. Which item was the most popular for each customer?
-----------------------------------------------------------


-- AGain, a Common Table Expression comes in very handy for completeing this task. We use the CTE to find the rank of menu item counts per customer. 
-- Remmeber, Common Table Expressions (CTEs) work as virtual tables (with records and columns), created during the execution of a query, used by the query, and eliminated after query execution.
-- In our solution we want to create a temporary table that ranks the products bought by each customer in terms of the DATE it was bought. 


WITH customer_favourite AS (
  SELECT 
    sales.customer_id, 
    menu.product_name, 
    -- count the number of orders by menu item for each customer and rank them in terms of most popular (with rank 1 = most ordered)
    COUNT(menu.product_id) AS order_count,
    DENSE_RANK() OVER(
      PARTITION BY sales.customer_id 
      ORDER BY COUNT(sales.customer_id) DESC) AS rank
  FROM dannys_diner.menu
  JOIN dannys_diner.sales
    ON menu.product_id = sales.product_id
  GROUP BY sales.customer_id, menu.product_name
)

-- now we just select the required fields where rank = 1. Note that some customers have some products with equal rank. 
SELECT 
  customer_id, 
  product_name, 
  order_count
FROM customer_favourite 
WHERE rank = 1;

-----------------------------------------------------------------------------------
---- Q6. Which item was purchased first by the customer after they became a member?
-----------------------------------------------------------------------------------
-- Again, we're in CTE world. 

WITH purchased_post_membership AS (
  SELECT 
    members.customer_id, 
    sales.product_id,
    ROW_NUMBER() OVER(
       PARTITION BY members.customer_id
       ORDER BY sales.order_date DESC) AS rank
  FROM dannys_diner.members
  JOIN dannys_diner.sales
    ON members.customer_id = sales.customer_id
    AND sales.order_date < members.join_date
)


-- Now we can use this CTE in a join expression. 
SELECT 
  p_member.customer_id, 
  menu.product_name 
FROM purchased_post_membership AS p_member
JOIN dannys_diner.menu
  ON p_member.product_id = menu.product_id
WHERE rank = 1
ORDER BY p_member.customer_id ASC;
