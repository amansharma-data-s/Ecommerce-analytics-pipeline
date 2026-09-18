/* ============================================================
   E Commerce Analysis
   ============================================================ */
   
   USE [E_commerce (brazill)]

   -- PREVIEW SECTION
Select top 10
*
from orders;

Select top 10
*
from order_payments;

Select top 10
*
from order_items;
select 
*
from [Product category renamed]
SELECT TOP 10 
*
FROM order_reviews;

SELECT TOP 10
*
FROM customers;

SELECT TOP 10
*
FROM sellers;

select top 10
*
from products

select top 10
*
from geolocation

select
*
from product_category_name_translation


 /* ============================================================
    data Quality
   ============================================================ */
select top 10
    count(*) as [NULL COUNT]
from products
where product_category_name is null and product_name_lenght is null


Select 
p.product_id,
o.price
from products as p
Left join order_items as o 
On o.product_id = p.product_id
where p.product_category_name is null


/*Confirmed these are real, sold products (not orphaned/unused
rows) by joining products -> order_items and checking price
data existed for them.*/



select 
count(Distinct p.product_id),
DATENAME(YEAR,o.order_purchase_timestamp) as [Years]
from products as p
Inner Join order_items as oi
on oi.product_id = p.product_id
Inner Join orders as o
on o.order_id = oi.order_id
where p.product_category_name is null 
group by DATENAME(YEAR,o.order_purchase_timestamp);


with [product first date] as(
select 
p.product_id,
min(o.order_purchase_timestamp) as [First sale date]
from products as p
Inner Join order_items as oi
on oi.product_id = p.product_id
Inner Join orders as o
on o.order_id = oi.order_id
where p.product_category_name is null 
group by p.product_id)
select 
count(product_id) as [null counts],
datename(MONTH,[First sale date]) as [month group]
from [product first date]
group by datename(MONTH,[First sale date])

/*Tested whether the nulls clustered around a specific time period (e.g. one bad data import) by finding each product's
first purchase date (MIN(order_purchase_timestamp) per product_id) and grouping by month/year.*/

/* Result: nulls are spread fairly evenly across all 12 months and multiple years (~30-70 per month) -> rules out a single
localized incident. Points instead to an ongoing gap in seller listing data entry.*/

/*No reliable column exists to infer the missing category (weight/height/dimensions don't correlate reliably with
category). Decided against guessing/imputing a category.*/
------------------------------------------------------------------------------------------------------------------------------

/*go
Create VIEW [Product category renamed] as 
select
product_id,
[product_photos_qty],
coalesce(product_category_name,'Category not found') as [remaned column] 
from products;
*/



/*Built a view ([Product category renamed]) that uses COALESCE to label these as "Category not found" instead of
dropping them or leaving them null - keeps them visible and analyzable rather than silently lost from category-based
reports.*/


Select  top 10
oi.order_id,
oi.freight_value,
oi.price,
op.payment_value
from order_items as oi
Left JOIN order_payments AS OP
ON oi.order_id = OP.order_id



with [total_price_sort] as (
select 
order_id,
sum(price) as [total price],
sum(freight_value)as [total freight]
from order_items
group by order_id),
[total_payment_sort]as(
select 
order_id,
SUM(payment_value) as [total payment]
from order_payments
group by order_id)
select
tps.order_id,
[total price],
[total freight],
tpys.[total payment],
o.order_status
from total_price_sort as [tps]
LEFT JOIN total_payment_sort as tpys
ON tps.order_id = tpys.order_id
left join orders as o 
On tps.order_id= o.order_id
--where [total payment] is null


/*Built a view ([Product category renamed]) that uses COALESCE to label these as "Category not found" instead of
dropping them or leaving them null - keeps them visible and analyzable rather than silently lost from category-based
reports.*/


select 
*
from order_payments
where order_id ='bfbd0f9bdef84302105ad712db648a6c'

select 
*
from orders
where order_id ='bfbd0f9bdef84302105ad712db648a6c'




 /* ============================================================
     Revenue & Order Partten
   ============================================================ */

/*Revenue metric = order_items.price only (not price + freight). freight_value is a shipping cost passed through to the
carrier, not earned income, so it's excluded from "revenue."

Order status filter: excluded 'unavailable' and 'canceled' (no money was retained). Verified the remaining 5 statuses
(delivered, processing, invoiced, shipped, approved) all have a non-null order_approved_at - confirmed payment had already
been approved for every one of them, not just assumed.*/

   select 
   order_approved_at
   from orders
   where order_status ='shipped' and order_approved_at is null
  --
   with [order item sort]as(
   select 
   order_id,
   Sum(price) as [Total revenue]
   from order_items
   group by order_id)
   select 
   o.order_status,
   count(oi.[Total revenue]) as [Sale Count]
   from [order item sort] as oi
   left join orders as o
   ON o.order_id = oi.order_id
   Group by order_status

   /*Total revenue and order/sale count per category, using [Product category renamed] view so the 610
   "Category not found" products stay visible instead of being dropped from the report.*/
   
 
   select 
   por.[remaned column] as [Catergory],
   Round(sum(oi.price),1) AS [Total Revenue],
   concat(Round(sum(oi.price)*100/sum(sum(Price)) over(),2),'%') as [Percent of Total Revenue]
   from order_items AS oi
   Left join  [Product category renamed] as por
   ON por.product_id = oi.product_id
   left join orders as o
   on o.order_id = oi.order_id
   where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
   Group by por.[remaned column] 
   order by sum(oi.price) DESC;


/*Same as above, plus % of total revenue per category, using SUM(SUM(price)) OVER () to get a grand total across all
categories without collapsing the per-category rows (avoids needing a separate subquery for the grand total)*/

/*time Over time Analysis*/
/*Seaonal Analysis*/
/*order count per year in specific months*/
Select
DATENAME(MONTH,o.order_purchase_timestamp) as [MONths],
count (*)
from orders as o
where year(o.order_purchase_timestamp) = 2016 --2017--2018
Group by DATENAME(MONTH,o.order_purchase_timestamp);


with [Month per Year]as(
select 
MONTH ([o].order_purchase_timestamp) as [Order Months] ,
year([o].order_purchase_timestamp) as [Order Year],
Round(sum(price),2) AS [total Revenue]
From order_items as [oi]
left join orders as [o]
on [o].order_id = [oi].order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled' 
and o.order_purchase_timestamp >='2017-01-01' and o.order_purchase_timestamp <'2018-07-01'
Group by MONTH([o].order_purchase_timestamp),year([o].order_purchase_timestamp))
select 
[Order Months],
AVG([total Revenue]) AS [Avrage Revenue]
from [Month per Year]
Group by [Order Months]
Order by [Avrage Revenue] desc


with [Month per Year]as(
select 
MONTH ([o].order_purchase_timestamp) as [Order Months] ,
year([o].order_purchase_timestamp) as [Order Year],
Round(sum(price),2) AS [total Revenue]
From order_items as [oi]
left join orders as [o]
on [o].order_id = [oi].order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled' and MONTH(o.order_purchase_timestamp)<= 8 and YEAR(o.order_purchase_timestamp) >2016
Group by MONTH([o].order_purchase_timestamp),year([o].order_purchase_timestamp))
select 
[Order Months],
AVG([total Revenue]) AS [Avrage Revenue]
from [Month per Year]
Group by [Order Months]
Order by [Avrage Revenue] desc

/*The Jan-Aug seasonal average above only includes months with genuine 2-year coverage (2017 + 2018). Sep-Dec were excluded
from that average because:

 - Sep/Oct 2018 have almost no orders (16 and 4 respectively, vs thousands in every neighboring month) - the dataset's
real coverage ends after August 2018, this isn't a real seasonal dip, just where the data was cut off.

- Nov/Dec only have 2017 data at all (2018 never reached these months), so an "average" for them would really just
be a single year's total mislabeled as a 2-year average - misleading if shown alongside genuinely averaged months.*/


select 
datename(MONTH,[o].order_purchase_timestamp) as [order Months],
YEAR([o].order_purchase_timestamp) as [Order year],
round(SUM(oi.price),2) as [Total revenue]
from order_items as [oi]
left join orders as [o]
on o.order_id = oi.order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled' and MONTH(o.order_purchase_timestamp)> 8
Group by datename(MONTH,[o].order_purchase_timestamp),YEAR([o].order_purchase_timestamp) 
order by [Total revenue] desc


/*This query shows raw totals per month AND year (not averaged) so the actual data coverage is visible and honest, rather than
blending incomplete years into a misleading single number.*/

/*order month check avalabiltiy per moanth*/
select 
YEAR(O.order_purchase_timestamp) AS [ORDER YEAR ],
COUNT(*) AS [ORDER COUNT]
from orders as o 
where month(O.order_purchase_timestamp) = 5
Group by YEAR(O.order_purchase_timestamp) ;


/*order value distribution - the shape of order sizes */

With [Total revenue sort] as (
select 
order_id,
sum(price) as [Total revenue] 
from order_items  
Group by order_id)
select 
    case
        when [Total revenue] < 50 then 'Under $50'
        when [Total revenue] >= 50  and [Total revenue] <100 then '$50-$100'
        when [Total revenue] >= 100  and [Total revenue] <200 then '$100-$200'
        when [Total revenue] >= 200  and [Total revenue] <500 then '$200-$500'
        else '$500+'
        end as [Total Revenue category],
    Round(SUM([Total revenue]),2) as [Total_revenue],
    Count(*) as [Order count]
from [Total revenue sort] as [tos]
left join orders as [o]
on tos.order_id = o.order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
Group by    
case
        when [Total revenue] < 50 then 'Under $50'
        when [Total revenue] >= 50  and [Total revenue] <100 then '$50-$100'
        when [Total revenue] >= 100  and [Total revenue] <200 then '$100-$200'
        when [Total revenue] >= 200  and [Total revenue] <500 then '$200-$500'
        else '$500+'
        end 
Order by [Total_revenue] DESC




 /*installment partten ,*/
 /*i considered this angle , but it didn't reveal anythinf non-obvios, so i skipped it */



/* ============================================================
	 Delivery Performance
   ============================================================ */
   /*over all delivery rate according to staus*/

   Select
   delivery_status,
   count(*) as [delivery count],
   Concat(count(*) * 100 /(select count(*) from orders),'%') as [Delivery rate %]
   from orders
   group by delivery_status
   order by [delivery count] DESC



/*Which state gets the worst delay */

select 
c.customer_state,
count(delivery_delay) as [Delivery count],
round(avg(delivery_delay),2) as [Avrage delivery delay]
from orders as o
left join customers as c 
on c.customer_id = o.customer_id
where delivery_delay > 0 and o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by c.customer_state

/*deliver count per state */

select 
c.customer_state,
round(avg(delivery_delay),2) as [Avrage delivery delay]
from orders as o 
left join customers as c
on c.customer_id = o.customer_id
where  delivery_delay > 0 and o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by c.customer_state
having count(*)>=20
order by [Avrage delivery delay] DESC

/*Which state gets the eary delivery*/
select 
c.customer_state,
count(delivery_delay) as [Delivery count],
round(avg(delivery_delay),2) as [Avrage early delivery]
from orders as o
left join customers as c 
on c.customer_id = o.customer_id
where delivery_delay <=0 and o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by c.customer_state
order by [Avrage early delivery] desc

/*deliver count per state */

select 
c.customer_state,
round(avg(delivery_delay),2) as [Avrage early delivery]
from orders as o 
left join customers as c
on c.customer_id = o.customer_id
where  delivery_delay < 0 and o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by c.customer_state
having count(*)>=20
order by [Avrage early delivery] DESC

/*
   Two separate queries instead of one blended average, because averaging delivery_delay directly (positive = late,
   negative = early) would let early and late deliveries cancel each other out, hiding real variability within a state.

   Query 1 (Late): filtered to delivery_delay > 0, average days
   late per state.


   Query 2 (Early): filtered to delivery_delay < 0, average days
   early per state.

   Both use HAVING COUNT(*) >= 20 to exclude states with too few orders to produce a reliable average - initial results without
 this filter showed states like AC (3 late orders) and AP (2 late orders) posting extreme averages driven by a handful
   of orders, not a real regional pattern.

   Result: SP (Sao Paulo) delivers earliest on average (~12 days ahead of estimate) - likely reflects proximity to major
   seller/warehouse hubs. SE (Sergipe) runs latest on average (~16 days behind estimate), among states with reliable sample
   sizes.*/



   select 
   o.order_id,
   count([or].review_score) as [review count]
   from orders as o
   left join order_reviews as [or]
   on o.order_id = [or].order_id
   group by o.order_id
   having count([or].review_score) > 1
   order by [review count] DESC;


   /*Distribution and customer reivew relationship */
with [Order_reviews_sort] as (
   select 
   order_id,
   round(AVG(cast(review_score as decimal)),1) as [reviwe score sort]
   from order_reviews
   group by order_id),
[Order Delay Sort] as (
select 
order_id,
CASE
When delivery_delay is null then 'Not Delivered'
WHEN delivery_delay <= 0 Then 'Early/On Time'
WHEN delivery_delay > 0 and delivery_delay <=5 Then '1-5 Days Late'
WHEN delivery_delay > 5 and delivery_delay <=15 Then '6-15 Days Late'
else '15+ Days Late'
end as [Delay Bucket]
from orders)
select
[ods].[Delay Bucket],
round(AVG(ors.[reviwe score sort]),2) as [Avrage Reviews],
count(ors.[reviwe score sort]) as [reviews count]
from [Order Delay Sort] as [ods]
left join Order_reviews_sort as[ors]
on[ods].order_id = [ors].order_id
Group by [Delay Bucket]
order by [Avrage Reviews]

/* ============================================================
     Customer Behavior
   ============================================================ */


   /* ============================================================
   CUSTOMER BEHAVIOR: One-Time vs Repeat Customers
   ============================================================
Used customer_unique_id, not customer_id, to identify real customers - customer_id is generated fresh per order in this
dataset, so every order automatically gets a unique customer_id even from the same person. Using it would make every customer
look like a one-time buyer by definition, regardless of reality.

Kept cancelled/unavailable orders in this count (unlike the revenue queries) - this measures customer engagement/intent to
return, not money earned, so a cancelled order still counts as evidence the customer chose to shop here again.

Verified customers has no duplicate customer_id rows before trusting the join (COUNT(DISTINCT customer_id) grouped by
customer_unique_id matched the joined query's counts exactly).

Hit the same integer-truncation bug as the review-score query: COUNT(*) is an integer, so count(*) * 100 / SUM(count(*)) OVER()
truncated to whole numbers until *100.0 forced decimal division.

Result: only 3.12% of customers (2,997) placed more than one order; 96.88% (93,099) were one-time buyers. Top repeat
customer placed 17 orders - worth flagging as a possible business/reseller account rather than a typical shopper.
   ============================================================ */

      /*Order count per unique customer*/
   select 
   customer_unique_id,
   COUNT(o.customer_id) as [order count]
   from   customers as c
   left join orders as o 
   on c.customer_id = o.customer_id
   group by c.customer_unique_id 
   order by [order count] desc

   select 
   customer_unique_id,
   count (distinct customer_id) as [id count]
   from customers
   group by customer_unique_id
   order by [id count] desc
   /*verification of data */

   /*Percentage of customer who repeat vs one-time */
   with [customer order count ]as(
      select 
        customer_unique_id,
        COUNT(o.customer_id) as [order count]
    from   customers as c
   left join orders as o 
   on c.customer_id = o.customer_id
   group by c.customer_unique_id )
   select 
    case 
        when [order count] <=1 Then 'One-time customer'
        else 'Repeat Customer'
        end as [Customer type],
      count(*)as[customer count],
      round( count(*)*100.0/SUM(Count(*)) over (),2) as [Percentage of cutomers]
   from [customer order count ] 
   Group by     case 
        when [order count] <=1 Then 'One-time customer'
        else 'Repeat Customer'
        end 
    Order by [Percentage of cutomers]


with [customer state count] as (
select 
customer_state,
count(customer_unique_id) as [cutomer per state]
from customers 
Group by customer_state),
[total_revenue] as (
select 
customer_state,
Round(SUM(price),2) as [Total revenu]
from order_items as oi
inner join orders as o
on oi.order_id = o.order_id 
inner join customers as c
on o.customer_id = c.customer_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by customer_state
) 
select 
csc.customer_state,
[cutomer per state],
[Total revenu]
from [customer state count] as csc
inner join[total_revenue] as tr
on csc.customer_state = tr.customer_state


/*customer lifetime value distribution*/
with [Per customer total revenue] as (
select 
    c.customer_unique_id as [customer],
    SUM(price) as [Total revenue]
from customers as c
inner join orders as o
on c.customer_id = o.customer_id
inner join order_items as oi 
on o.order_id = oi.order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by c.customer_unique_id)
select 
    case
      when [Total revenue] < 50 then 'Under $50'
        when [Total revenue] >= 50  and [Total revenue] <100 then '$50-$100'
        when [Total revenue] >= 100  and [Total revenue] <200 then '$100-$200'
        when [Total revenue] >= 200  and [Total revenue] <500 then '$200-$500'
       when [Total revenue] >= 500 and [Total revenue] <2000 then '$500-$2000'
       else '2000+'
    end as [Customer spending],
  COUNT(*) as [customer count],
  round(SUM([Total revenue]),2) as [Revenue genration]
from [Per customer total revenue]
group by    case
      when [Total revenue] < 50 then 'Under $50'
        when [Total revenue] >= 50  and [Total revenue] <100 then '$50-$100'
        when [Total revenue] >= 100  and [Total revenue] <200 then '$100-$200'
        when [Total revenue] >= 200  and [Total revenue] <500 then '$200-$500'
       when [Total revenue] >= 500 and [Total revenue] <2000 then '$500-$2000'
       else '2000+'
    end
order by [Revenue genration] DESC


/* ============================================================
   CUSTOMER BEHAVIOR: Customer Lifetime Value Distribution
============================================================
Same bucketing approach as the order-value distribution earlier, but aggregated per customer_unique_id instead of per
order - total revenue per real customer across all their orders, not per individual order.

Buckets reuse the same lower boundaries as the order-value version (Under $50 through $200-$500), since most customers
are one-time buyers (96.88% - see earlier finding) and their lifetime value is just their single order's value. Extended
the top end ($500-$2000, $2000+) to give the smaller repeat- customer tail somewhere meaningful to land, rather than lumping
everyone above $500 into one bucket.

Result: unlike the order-value distribution (where revenue was concentrated in a small number of high-value orders), customer
lifetime revenue is fairly evenly spread across the $100-$2000 range (~$3-3.6M per bucket) - no single spending tier dominates
the way high-value orders did at the order level.
============================================================ */




/* ============================================================
    Seller Performance
   ============================================================ */
   /*revenue by seller*/
/*most revnue genrated*/
select top 10
oi.seller_id,
round(SUM(oi.price),2) as [Total revenue],
count(*) as [Sale count]
from order_items as oi
left join orders as o 
on o.order_id = oi.order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
Group by oi.seller_id
order by [Total revenue] desc


/*least revenue genrated and are somewhat oprating*/
select 
oi.seller_id,
round(SUM(oi.price),2) as [Total revenue],
count(*) as [sold product]
from order_items as oi
left join orders as o 
on o.order_id = oi.order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
Group by oi.seller_id
having count(*) >= 15
order by [Total revenue] 

/*
Top revenue sellers query is straightforward - SUM(price) per seller_id, filtered by status.

Initial "lowest revenue" ranking was misleading: every seller in the bottom 10 had sold exactly 1 item (revenue as low as
$3.50) - not underperforming sellers, just sellers with a single, cheap, one-off sale. Added HAVING COUNT(*) >= 15 to
restrict the ranking to sellers with meaningful, ongoing activity, same principle as the state delivery-delay analysis
earlier (HAVING COUNT(*) >= 20) - small sample sizes product misleading extremes.

Result: among genuinely operating sellers, the lowest performers still moved 15-34 items each but only generated
$263-$404 total revenue - likely low-priced product categories or low per-item margins, worth a follow-up look at what these
   sellers actually sell.*/

/*lowest revenue sellers here are effectively minimal-activity sellers(1 sale each),not established sellers underperforming */

/*Seller dilevery consistancy performance*/
Select 
oi.seller_id,
round(stdev(o.delivery_delay),2) as [Delivery consistency],
round(avg(o.delivery_delay),2) as [AVG delay]
from order_items as oi
inner join orders as o
on o.order_id = oi.order_id
where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
group by oi.seller_id
having count(*) >= 10
order by [Delivery consistency] Desc;

select 
o.order_id,
o.delivery_delay
from order_items as oi
inner join orders as o 
on o.order_id = oi.order_id
where oi.seller_id ='cb41bfbcbda0aea354a834ab222f9a59'
order by o.delivery_delay desc;


with [overall stats]as (
select 
avg(delivery_delay)as [Overall avg],
STDEV(delivery_delay) as [Overall stdev]
from orders)
select 
oi.seller_id,
avg(o.delivery_delay)as [AVG delay],
STDEV(o.delivery_delay) as [Delivery consistency]
from order_items as oi
cross join [overall stats] as os
inner join orders as o
on o.order_id = oi.order_id 
where o.delivery_delay <= os.[Overall avg]+(3*os.[Overall stdev]) and o.delivery_delay >= os.[Overall avg]-(3*os.[Overall stdev])
group by oi.seller_id
having count(*) >= 10
order by [Delivery consistency] desc


/* ============================================================
Delivery Consistency by Seller

   Question: which sellers are unpredictable in delivery timing (not just late) - a separate, operationally useful question
   from the earlier delivery-vs-review analysis, which showed lateness specifically (not earliness) hurts reviews.

   Used STDEV(delivery_delay)  since it measures deviation from the mean regardless of sign, without needing to strip signs first.

   Applied a 3-standard-deviation outlier exclusion using the dataset's overall mean and stdev of delivery_delay (computed
   once in a CTE, joined in via CROSS JOIN) after finding the top "inconsistent" seller's STDEV (56.33) was driven almost
   entirely by a single 175-day-late order, not genuine chronic inconsistency. Excluding values beyond 3 stdev from the overall
   mean (both directions - extreme early outliers likely reflect data errors too, not real events) dropped the worst STDEV to
   ~18.88, a much more representative ranking.

   Kept HAVING COUNT(*) >= 10, consistent with the seller-revenue analysis - sellers with a median of 6-8 orders needed a lower
   threshold than the 20+ used for state-level analysis, or the majority of the seller base would be excluded. */

   with [Total_revenue] as (
   select 
   seller_id,
   sum(price) as [total revenue]
   from order_items as oi
   inner join orders as o
   on o.order_id = oi.order_id
   where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
   group by seller_id),
   [seller rank]as (select 
   s.seller_state,
   s.seller_id,
   DENSE_RANK() over (partition by seller_state order by tr.[total revenue] DESC )as [rank]
   from sellers as  s
   inner join [Total_revenue] as tr
   on tr.seller_id = s.seller_id)
   select
   seller_state,
   seller_id,
   [rank] as [top rank]
   from [seller rank]
   where  [rank]=1


/* ============================================================
    Payment
   ============================================================ */
   /*do orders paid via credit card skew higher value than boleto*/
  

  select 
  op.payment_type,
  COUNT(distinct op.order_id) as [Type used],
  ROund(Sum(op.payment_value),2) as [Total payment]
  from order_payments as op
  inner join orders as o
  on o.order_id = op.order_id
  where o.order_status <> 'unavailable' and o.order_status <> 'canceled'
  Group by op.payment_type

  order by [Type used] desc
  /*  Payment Type Distribution
   
   Result: credit card is the dominant payment method by a wide
   margin over boleto, voucher, and debit card, both in order
   count and total value.
   ============================================================ */

