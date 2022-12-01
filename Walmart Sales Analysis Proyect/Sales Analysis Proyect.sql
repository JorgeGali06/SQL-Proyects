CREATE DATABASE ProyectoVentas;

USE ProyectoVentas;

SELECT * FROM [dbo].[sales_data_sample];



---ANALYSIS
----Grouping sales by Productline

select PRODUCTLINE, sum(sales) AS Revenue
from [dbo].[sales_data_sample]
group by PRODUCTLINE
order by Revenue desc;


select YEAR_ID, sum(sales) Revenue
from [dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc;

select  DEALSIZE,  sum(sales) Revenue
from [ProyectoVentas].[dbo].[sales_data_sample]
group by  DEALSIZE
order by 2 desc;



----What was the best month for sales in a specific year? 
select  MONTH_ID, sum(sales) AS Revenue, count(ORDERNUMBER) AS Frequency
from [ProyectoVentas].[dbo].[sales_data_sample]
where YEAR_ID = 2004 --change year to see the rest
group by  MONTH_ID
order by Revenue desc;


--What product do they sell in November and the number of orders.
select  MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Norders
from [dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11 --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc;




-- https://learn.microsoft.com/en-us/sql/t-sql/queries/with-common-table-expression-transact-sql?view=sql-server-ver16


DROP TABLE IF EXISTS #rfm;

with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) AS MonetaryValue,
		avg(sales) AS AvgMonetaryValue,
		count(ORDERNUMBER)  AS Frequency,
		max(ORDERDATE) AS last_order_date,
		(select max(ORDERDATE) from [dbo].[sales_data_sample]) AS max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) AS Recency
	from [ProyectoVentas].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),

rfm_calc as
(

	select rfm.*,
		NTILE(4) OVER (order by Recency desc) AS rfm_recency,
		NTILE(4) OVER (order by Frequency)  AS rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) AS rfm_monetary
	from rfm 
)

select 
	rfm_calc.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar) AS rfm_cell_to_string

-- Here the table #rfm creates.
into #rfm
from rfm_calc; 


--- Query #RFM
SELECT*FROM #rfm;



--- OPERATE #RFM

select CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_to_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_to_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_to_string in (311, 411, 331) then 'new customers'
		when rfm_cell_to_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_to_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_to_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm;






--What products are most often sold together? 
--select * from [dbo].[sales_data_sample] where ORDERNUMBER =  10411

-- STUFF: https://learn.microsoft.com/en-us/sql/t-sql/functions/stuff-transact-sql?view=sql-server-ver16

select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] AS p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM [ProyectoVentas].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')), 1, 1, '') AS ProductCodes

from [dbo].[sales_data_sample] AS s
order by 2 desc






