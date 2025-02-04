CREATE SCHEMA dannys_diner;

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

  SELECT * FROM sales;
  SELECT * FROM menu;
  SELECT * FROM members;


  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

select s.customer_id, sum(price)as total_amount_spent from sales s
inner join menu m on s.product_id = m.product_id
group by s.customer_id;

-- 2. How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date)as number_of_days from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with CTE as
(
select s.customer_id, m.product_name,
ROW_NUMBER() over (partition by s.customer_id order by order_date) as row_number
from sales s join menu m
on s.product_id= m.product_id
)
select customer_id, product_name from CTE where row_number=1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name, count(m.product_name)as numbers_of_product_sold
from sales s
inner join menu m on  m.product_id=s.product_id
group by m.product_name;

-- 5. Which item was the most popular for each customer?
with CTE as
(
select s.customer_id, m.product_name,
count(*) order_count,
dense_rank() over (PARTITION BY s.customer_id ORDER BY count(*) desc) as rnk
from sales s 
inner join menu m
on s.product_id= m.product_id
GROUP BY s.customer_id, m.product_name
)
select customer_id, product_name from CTE where rnk=1;

-- 6. Which item was purchased first by the customer after they became a member?
with CTE as
(
select s.customer_id, m.product_name, mb.join_date,
dense_rank() over (PARTITION BY s.customer_id ORDER BY order_date) as rnk
from menu m 
join sales s
on m.product_id =s.product_id
join members mb
on s.customer_id= mb.customer_id
where s.order_date> mb.join_date
)
select customer_id, product_name from CTE where rnk=1;

-- 7. Which item was purchased just before the customer became a member?

with CTE as
(
select s.customer_id, m.product_name, mb.join_date,
dense_rank() over (PARTITION BY s.customer_id ORDER BY order_date desc) as rnk
from menu m 
join sales s
on m.product_id =s.product_id
join members mb
on s.customer_id= mb.customer_id
where s.order_date< mb.join_date
)
select customer_id, product_name from CTE where rnk=1;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id,
count(m.product_id) as total_items_ordered,
sum (price)  as total_amount_spent
from menu m
join sales s on
m.product_id=s.product_id
join members mb on
mb.customer_id=s.customer_id
where s.order_date<mb.join_date
group by s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

with CTE as
(
  select s.customer_id, m.product_name, m.price,
  case 
      when m.product_name= 'sushi' then m.price*10*2
	  else m.price*10
	  end as points
  from sales s join menu m
  on s.product_id = m.product_id
)
select customer_id, sum(points) as total_points from CTE
group by customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
