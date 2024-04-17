
--Q-1. How many customers do not have DOB information available? 

SELECT COUNT(cust_id) AS CustHaveNoDobInfo 
From customers$ 
WHERE customers$.dob IS NULL

--Q-2. How many customers are there in each pincode and gender combination? 

SELECT  primary_pincode ,gender,COUNT (*) AS NumberOfCustomers
From customers$
Group BY primary_pincode ,gender


--Q-3. Print product name and mrp for products which have more than 50000 MRP?  

SELECT product_name,mrp From products$ 
WHERE mrp >50000



--Q-4. How many delivery personal are there in each pincode? 

SELECT  pincode ,
COUNT(*) AS NumOfDelivPersonal
FROM delivery_person$
GROUP BY   pincode

--Q-5 For each Pin code, print the count of orders, sum of total amount paid, average amount 
--paid, maximum amount paid, minimum amount paid for the transactions which were 
--paid by 'cash'. Take only 'buy' order types 
 SELECT delivery_pincode, COUNT(order_id) AS CountofOrder ,
SUM(total_amount_paid)  AS SumOfTotalAmount ,
MIN(total_amount_paid)  AS MinOfTotalAmount ,
MAX(total_amount_paid)  AS MaxOfTotalAmount,
AVG(total_amount_paid)  AS AvgOfTotalAmount
FROM orders$ WHERE order_type  = 'buy' and payment_type = 'cash' 
GROUP BY delivery_pincode


--Q-6 For each delivery_person_id, print the count of orders and total amount paid for 
----product_id = 12350 or 12348 and total units > 8.
--Sort the output by total amount paid in 
--descending order. Take only 'buy' order types 

SELECT delivery_person_id,tot_units,order_type,product_id,
COUNT(order_id) AS TotalOrder,
SUM(total_amount_paid) AS TotalAmountPaid
FROM orders$
WHERE product_id IN (12350,12348)
AND tot_units >8
AND order_type ='buy'
GROUP BY delivery_person_id ,tot_units,order_type,product_id,total_amount_paid
ORDER BY total_amount_paid DESC

--7-Print the Full names (first name plus last name) for customers that have email on 
--"gmail.com"? 

  SELECT  email ,CONCAT(first_name , ' ',last_name )AS full_name FROM customers$
  WHERE email Like '%gmail.com'
  

--  Q-8 Which pincode has average amount paid more than 150,000? Take only 'buy' order 
--types

SELECT delivery_pincode ,AVG(total_amount_paid) as
AvgAmountPaid FROM orders$
WHERE order_type ='buy' 
GROUP BY delivery_pincode
HAVING AVG(total_amount_paid)>150000



-- Q-9-Create following columns from order_dim data - 
-- order_date 
-- Order day 
-- Order month 
-- Order year  

SELECT * from INFORMATION_SCHEMA.COLUMNS where table_name='order_dim2';
Create Table order_dim2(
order_id FLOAT ,
order_date Date , order_day VARCHAR , order_month VARCHAR ,
order_type nvarchar(255) NULL
);

SELECT convert(datetime  ,order_date ,121) from orders$;
INSERT into order_dim2(order_id,order_date ,order_day ,order_month ,
order_type) 
SELECT 
order_id , order_date,
Day(TRY_CAST(order_date AS DATE)) as order_day ,
Month(TRY_CAST(order_date as DATE)) as order_month,
order_type
from orders$; 
select * from order_dim2;

--Q-11- How many units have been sold by each brand? Also get total returned units for each 
--brand.

select order_dim2.order_month ,COUNT(*) as total_orders,
SUM(CASE WHEN order_type='return' THEN 1 ELSE 0 END) AS return_orders,
(100.0* SUM(CASE WHEN order_type='return' THEN 1 ELSE 0 END) /COUNT(*) ) As return_rate
    from order_dim2
Group By order_month
ORDER BY order_month
SELECT * FROM products$



--12--How many distinct customers and delivery boys are there in each state?

SELECT pincode$.state, COUNT(DISTINCT(customers$.cust_id)) AS total_customers ,
COUNT(DISTINCT(delivery_person$.delivery_person_id)) AS total_delivery_boys
from pincode$ INNER JOIN customers$ ON(pincode$.pincode=customers$.primary_pincode)
INNER JOIN delivery_person$ ON  (pincode$.pincode=delivery_person$.pincode)
GROUP BY pincode$.state;


--Q13- For every customer, print how many total units were ordered, how many units were 
--ordered from their primary_pincode and how many were ordered not from the 
--primary_pincode. Also calulate the percentage of total units which were ordered from 
--primary_pincode(remember to multiply the numerator by 100.0). Sort by the 
--percentage column in descending order. 


SELECT * FROM INFORMATION_SCHEMA.COLUMNS where table_name ='orders$';
SELECT  customers$.cust_id,
SUM(orders$.tot_units) as total_unit ,  
SUM(CASE  WHEN orders$.delivery_pincode = customers$.primary_pincode THEN 
orders$.tot_units ELSE 0 END) as total_units_from_primary_pincode,
SUM(CASE WHEN orders$.delivery_pincode != customers$.primary_pincode THEN
orders$.tot_units ELSE 0 END) as total_units_not_from_primary_pincode, 
(100.0* (SUM(CASE  WHEN orders$.delivery_pincode = customers$.primary_pincode THEN 
orders$.tot_units ELSE 0 END)) /SUM(orders$.tot_units)) as percentage_total_units_from_primary
from orders$ JOIN  customers$ on (orders$.cust_id=customers$.cust_id) 
GROUP BY customers$.cust_id 
ORDER BY percentage_total_units_from_primary DESC;
 

--Q14  For each product name, print the sum of number of units, total amount paid, total 
--displayed selling price, total mrp of these units, and finally the net discount from selling 
--price.  

SELECT products$.product_name,
SUM(orders$.tot_units) as number_of_units , 
SUM(orders$.total_amount_paid) as total_amount_paid ,
SUM(orders$.displayed_selling_price_per_unit) as total_displayed_selling_price ,
SUM(products$.mrp) total_mrp , (100.0-100.0 *SUM(orders$.total_amount_paid)/
SUM(orders$.displayed_selling_price_per_unit)) as net_discount_selling_price ,
(100.0-100.0*SUM(orders$.total_amount_paid)/
SUM(products$.mrp)) as net_discount_from_mrp
from orders$ JOIN  products$ ON(orders$.product_id=products$.F1) 
GROUP BY products$.product_name;

--Q15--For every order_id (exclude returns), get the product name and calculate the discount 
--percentage from selling price. Sort by highest discount and print only those rows where 
--discount percentage was above 10.10%. 

SELECT orders$.order_id,  products$.product_name, 
((100.0*(products$.mrp-orders$.displayed_selling_price_per_unit))/
products$.mrp)
AS discount_percentage
from orders$  JOIN products$ ON (orders$.product_id=products$.F1) 
WHERE orders$.order_type != 'return' 
 AND ((100.0*(products$.mrp-orders$.displayed_selling_price_per_unit))/
 products$.mrp)>10.10
ORDER BY discount_percentage DESC;

--Q16 Using the per unit procurement cost in product_dim, find which product category has 
--made 
--most profit in both absolute amount and percentage 
--Absolute 
--Profit 
--= 
--Total 
--Amt Sold - Total Procurement Cost 
--Percentage Profit = 100.0 * Total Amt Sold / Total Procurement Cost - 100.0  

SELECT TOP 1 products$.category,  SUM(orders$.total_amount_paid -orders$.tot_units * 
products$.procurement_cost_per_unit) as absolute_profits,
(100.0*SUM(orders$.total_amount_paid) /SUM(orders$.tot_units*
products$.procurement_cost_per_unit) -100)
as percentage_profit FROM orders$ JOIN products$ ON (orders$.product_id=products$.F1)
GROUP BY products$.category ORDER BY absolute_profits DESC  ;


--Q-17--For every delivery person(use their name), print the total number of order ids (exclude 
--returns) by month in separate columns i.e. there should be one row for each 
--delivery_person_id and 12 columns for every month in the year 


SELECT delivery_person$.name , MONTH(orders$.order_date) as order_month ,
SUM(CASE WHEN orders$.order_type !='return' THEN 1 ELSE  0 END)
as total_orders_not_returned
FROM orders$ JOIN delivery_person$ 
ON(orders$.delivery_person_id= delivery_person$.delivery_person_id)
GROUP BY delivery_person$.name ,
MONTH(orders$.order_date);

--Q-18 For each gender -
--male and female - find the absolute and percentage profit (like in 
--Q15) by product name 


SELECT products$.product_name, 
customers$.gender, 
SUM(orders$.total_amount_paid-(orders$.tot_units* 
products$.procurement_cost_per_unit))
AS absolute_profits,
(100.0*SUM(orders$.total_amount_paid)
/SUM(orders$.tot_units * products$.procurement_cost_per_unit)-100.0)
AS discount_percentage
from orders$ JOIN  customers$ ON (orders$.cust_id=customers$.cust_id)  
JOIN products$ ON (orders$.product_id=products$.F1)
WHERE orders$.order_type != 'return' 
 GROUP BY customers$.gender ,  products$.product_name


-- Q-19-Generally the more numbers of units you buy,
--the more discount seller will give you. For 
--'Dell AX420' is there a relationship between number of units ordered and average 
--discount from selling price? Take only 'buy' order types

SELECT orders$.tot_units ,
AVG(100.0- 100.0*(orders$.displayed_selling_price_per_unit/products$.mrp))
as avg_discount 
FROM orders$  JOIN products$ ON(orders$.product_id=products$.F1) 
WHERE products$.product_name='Dell AX420'
AND  orders$.order_type='buy' GROUP BY orders$.tot_units




