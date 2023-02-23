--Inspecting data
select *
from newtable_1 n2 

--Checking unique values
select distinct(status) from newtable_1 n2   --Good to plot
select distinct(productline) from newtable_1 n2 --Good to plot
select distinct(dealsize) from newtable_1 n2  --Good to plot
select distinct(year_id) from newtable_1 n2
select distinct(territory) from newtable_1 n2  --Good to plot
select distinct(country) from newtable_1 n2  --Good to plot

select distinct (month_id)
from newtable_1 n2   
where  year_id  = '2004'

--ANALYSIS--

--Group by productline
select productline,sum(sales) Revenue 
from newtable_1 n2  
group by 1
order by 2 desc

--Group by yearly sales
select year_id, sum(sales) Revenue
from newtable_1 n2   
group by 1
order by 2 desc 

--Group by dealsize
select dealsize,sum(sales) Revenue
from newtable_1 n2   
group by 1
order by 2 desc

---Which was the best performing month 
select month_id,sum(sales) Revenue
from newtable_1 n2   
where year_id  = '2004' --input year 
group by 1
order by 2 desc 

--Group quantity with year
select year_id,sum(quantityordered) Qty_ordered
from newtable_1 n2  
where year_id = '2003'
group by 1
order by 2 desc 

--What quantity was ordered in specific month and year
select month_id, sum(quantityordered) Monthy_qty_ordered
from newtable_1 n2
where year_id = '2004'
group by 1
order by 1

--November to be month with sales, what product has high sales
select 
	count(ordernumber),
	productline,
	month_id
from newtable_1 n2  
where year_id ='2004' and month_id = '11'
group by 2,3
order by 1 desc 

-- Which was the best month for sales in a specific year? How much was earned
select 
	month_id,
	sum(sales) Revenue,
	count(ordernumber) Frequency
from newtable_1 n2 
where year_id = '2004' --change the year
group by 1
order by 3 desc

-- Who is our best customer, to answer this we'll use RFM. Recency.Frequency.Monetary

drop table if exists #rfm;
with rfm as

(
-- Produces 92 records with the recent date(max order date) with the last order date. 
--The difference between the two gives a value of the number of days since the last order
select 
	customername,
	sum(sales) Monetaryvalue,
	avg(sales) AVGmonetaryvalue,
	count(ordernumber) Frequency,
	max(orderdate) last_order_date,
	(select max(orderdate) from newtable_1 n2) max_order_date,
	(select cast(max(orderdate) as date) from newtable_1 n2) - cast(max(orderdate) as date) Recency
from newtable_1 n2 
group by customername 
 
),
rfm_calc as 
(
	select r.*,
	-- Dividing the records into buckets
		ntile(4) over (order by Recency desc) rfm_recency,
		ntile(4) over (order by Frequency ) rfm_frequency,
		ntile(4) over (order by Monetaryvalue ) rfm_monetary
		
	from rfm r
)
select
	c.* ,concat(rfm_recency , rfm_frequency , rfm_monetary) as rfm_cell
into #rfm
from rfm_calc c

select customername, rfm_recency,rfm_frequency,rfm_monetary,
	case 
			when rfm_cell in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'Lost-customer' --lost customers
			when rfm_cell in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose,slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
			when rfm_cell in (311, 411, 331) then 'new customers'
			when rfm_cell in (222, 223, 233, 322) then 'potential churners'
			when rfm_cell in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
			when rfm_cell in (433, 434, 443, 444) then 'loyal'
	end rfm_segment
from #rfm
	
-- What products are often sold together?

select productcode, productline 
from newtable_1 n 
where  ordernumber in 
(	select ordernumber 
	from(
		select ordernumber, count(*) sold_together
		from newtable_1 n 
		where status = 'Shipped'
		group by ordernumber
		) twice
	where sold_together = 2 --change the number 
)
	