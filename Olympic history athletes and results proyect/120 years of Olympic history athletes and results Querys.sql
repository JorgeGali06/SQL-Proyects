/* QUERY Nº 1: SQL query to fetch the list of all sports which have been part of every olympics.*/

/*number of summer olympic games*/
with t1 as
	(select COUNT(DISTINCT games) as total_summer_games
	 from OLYMPICS_HISTORY
	WHERE season = 'Summer'),
/*Sports for each game year*/	
t2 as 
	(select DISTINCT sport, games
	 from OLYMPICS_HISTORY
	WHERE season = 'Summer' ORDER BY games),
/*Number of games (history) for each sport*/
t3 as
	(select sport, COUNT(games) as n_of_games
	 from t2
	 GROUP BY sport)
/* list of all sports which have been part of every olympics*/
SELECT * FROM t3
JOIN t1 on t1.total_summer_games = t3.n_of_games;
	


/* QUERY Nº 2: Top 5 athletes who have won the most gold medals.*/

/*Every athlete and the number of medals won*/

with t1 as
	(SELECT name, COUNT(medal) as total_medals
	FROM olympics_history 
	WHERE medal = 'Gold'
	GROUP BY name
	ORDER BY total_medals DESC),
	
/* We cant make a top 5 because there are many athletes that meet the requeriments*/
/* Using RANK to find the top 5*/
t2 as
   (SELECT *, DENSE_RANK() OVER (order by total_medals desc) as Rnk
	FROM t1)
	
SELECT *
FROM t2
WHERE Rnk <=5;





/*QUERY 3: Total gold, silver and bronze medals obteined by each country.*/

/*Join Between table olympics_history and table history_noc_regions  ON "noc"*/

/*Query 3 METHOD 1*/

SELECT onr.region as country,
SUM(CASE WHEN oh.medal = 'Gold' then 1 else 0 END) as Gold,
SUM(CASE WHEN oh.medal = 'Silver' then 1 else 0 END) as Silver,
SUM(CASE WHEN oh.medal = 'Bronze' then 1 else 0 END) as Bronze
FROM olympics_history oh
JOIN olympics_history_noc_regions onr ON oh.noc = onr.noc
WHERE medal <> 'NA'
GROUP BY onr.region
ORDER BY Gold DESC, Silver DESC, Bronze DESC;


/*Query 3 METHOD 2*/
with cte as (select noc, 
			 case when medal='Gold' then 1 else 0 end as gold,
			 case when medal='Silver' then 1 else 0 end as silver,
			 case when medal='Bronze' then 1 else 0 end as bronze
 from olympics_history where medal!='NA')
 select noc, sum(gold) as gold,sum(silver) as silver,sum(bronze) as bronze 
 from cte 
 group by noc 
 order by gold desc;
 
 
 
/*Query 3 METHOD 3*/
with medals as 
	(select nr.region as country,
		(case when medal = 'Gold' then 1 else 0 end) as Gold,
		(case when medal = 'Silver' then 1 else 0 end) as Silver,
		(case when medal = 'Bronze' then 1 else 0 end) as Bronze
		from olympics_history oh
	 	join olympics_history_noc_regions nr on nr.noc = oh.noc
	 	where medal <> 'NA')
select  country, sum(medals.Gold) as gold, sum(medals.Silver) as silver, sum(medals.Bronze) as bronze
from medals
group by country
order by gold desc, silver desc, bronze desc;








/* QUERY 4: Which country won the most gold, most silver and most bronze medals in each O. games? */

WITH t1 AS(
		SELECT DISTINCT ae.games, nr.region AS country,
		COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold,
		COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver,
		COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze
		FROM olympics_history ae
		JOIN olympics_history_noc_regions nr
		ON ae.noc = nr.noc
		WHERE medal <> 'NA'
		GROUP BY ae.games,nr.region
		)
SELECT DISTINCT games,
first_value(country) OVER(PARTITION BY games ORDER BY gold DESC)||' - '||first_value(gold) OVER(PARTITION BY games ORDER BY gold DESC)AS max_gold,
first_value(country) OVER(PARTITION BY games ORDER BY silver DESC)||' - '||first_value(silver) OVER(PARTITION BY games ORDER BY silver DESC)AS max_silver,
first_value(country) OVER(PARTITION BY games ORDER BY bronze DESC)||' - '||first_value(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)AS max_bronze
FROM t1
ORDER BY games;


/*QUERY 5. Which country won the most gold, most silver, most bronze medals and the most medals in each O. games?*/

WITH t1 AS(
		SELECT DISTINCT ae.games, nr.region AS country,
		COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold,
		COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver,
		COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze,
		COUNT(medal) AS medals
		FROM olympics_history AS ae
		JOIN olympics_history_noc_regions AS nr
		ON ae.noc = nr.noc
		WHERE medal <> 'NA'
		GROUP BY ae.games,nr.region
		ORDER BY ae.games
		)
		
SELECT DISTINCT games,
first_value(country) OVER(PARTITION BY games ORDER BY gold DESC)||' - '||first_value(gold) OVER(PARTITION BY games ORDER BY gold DESC)AS max_gold,
first_value(country) OVER(PARTITION BY games ORDER BY silver DESC)||' - '||first_value(silver) OVER(PARTITION BY games ORDER BY silver DESC)AS max_silver,
first_value(country) OVER(PARTITION BY games ORDER BY bronze DESC)||' - '||first_value(bronze) OVER(PARTITION BY games ORDER BY bronze DESC)AS max_bronze,
first_value(country) OVER(PARTITION BY games ORDER BY medals DESC)||' - '||first_value(medals) OVER(PARTITION BY games ORDER BY medals DESC)AS max_medals
FROM t1
ORDER BY games;


/*QUERY 6. Which countries have never won gold medal but have won silver/bronze medals?*/

WITH t1 AS(
		SELECT DISTINCT nr.region AS country,
		COUNT(CASE WHEN medal = 'Gold' THEN 1 END) AS gold,
		COUNT(CASE WHEN medal = 'Silver' THEN 1 END) AS silver,
		COUNT(CASE WHEN medal = 'Bronze' THEN 1 END) AS bronze
		FROM olympics_history AS ae
		JOIN olympics_history_noc_regions AS nr
		ON ae.noc = nr.noc
		WHERE medal <> 'NA'
		GROUP BY 1
		)
SELECT *
FROM t1
WHERE gold = 0
ORDER BY silver DESC, bronze DESC