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
    Sum(sales.product_id * menu.price) AS TotalSpent -- Multiply product number by its price and then sum all the values.
FROM dannys_diner.menu
INNER JOIN dannys_diner.sales
ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
GROUP BY sales.customer_id
ORDER BY  sales.customer_id, TotalSpent DESC;

---- Q2: How many days has each customer visited the restaurant?

SELECT
    sales.customer_id,
    COUNT(DISTINCT sales.order_date)
FROM dannys_diner.sales
GROUP BY sales.customer_id

---- Q3. What was the first item from the menu purchased by each customer?

WITH first_orders_cte AS
(
   SELECT customer_id, order_date, product_name,
      DENSE_RANK() OVER(PARTITION BY a.customer_id
      ORDER BY a.order_date) AS ranked_products
   FROM dannys_diner.sales AS a
   JOIN dannys_diner.menu AS b
      ON a.product_id = b.product_id
)

SELECT customer_id, product_name
FROM first_orders_cte
WHERE ranked_products = 1
GROUP BY customer_id, product_name;


