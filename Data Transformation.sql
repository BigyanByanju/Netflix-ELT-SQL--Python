--DATA CLEANING

--HANDLING FOREIGN CHARACTERS
--done via assigning proper data types

--REMOVE DUPLICATE DATAS

SELECT show_id, COUNT(*)
FROM netflix_raw
GROUP BY show_id
HAVING COUNT(*)>1;

--show_id has no duplicates. Making it the primary key

SELECT UPPER(title), COUNT(*)
FROM netflix_raw
GROUP BY UPPER(title)
HAVING COUNT(*)>1;


SELECT * from netflix_raw
WHERE UPPER(title) in (
	SELECT UPPER(title)
	FROM netflix_raw
	GROUP BY UPPER(title)
	HAVING COUNT(*)>1
)
order by title;


SELECT * from netflix_raw
WHERE (UPPER(title), type) in (
	SELECT UPPER(title), type
	FROM netflix_raw
	GROUP BY UPPER(title),type
	HAVING COUNT(*)>1
)
order by title;

WITH cte as (
	SELECT *, ROW_NUMBER() over (partition by UPPER(title), type ORDER BY show_id) as rn
	FROM netflix_raw
)
SELECT *
FROM CTE
WHERE rn=1;


--CREATING TABLE FOR LISTED IN, DIRECTOR, COUNTRY, CAST

--Creating separate table for director as each movie can have multiple director
SELECT show_id, TRIM(value) AS director
INTO netflix_directors
FROM netflix_raw,
LATERAL REGEXP_SPLIT_TO_TABLE(director, ',') AS value;

SELECT * FROM netflix_directors;

--Creating separate table for country
DROP TABLE IF EXISTS netflix_country;

SELECT show_id, TRIM(value) AS country
INTO netflix_country
FROM netflix_raw,
LATERAL REGEXP_SPLIT_TO_TABLE(country, ',') AS value;

SELECT show_id, TRIM(value) AS cast
INTO netflix_cast
FROM netflix_raw,
LATERAL REGEXP_SPLIT_TO_TABLE("cast", ',') AS value;

SELECT show_id, TRIM(value) AS genre
INTO netflix_genre
FROM netflix_raw,
LATERAL REGEXP_SPLIT_TO_TABLE(listed_in, ',') AS value;

select * from netflix_cast;

--Populating missing values in country, duration columns
--Assumed that a director must have directed shows of same country
INSERT INTO netflix_country
SELECT show_id, m.country
FROM netflix_raw nr
INNER JOIN(
	SELECT director, country
	FROM netflix_country nc
	INNER JOIN netflix_directors nd on nc.show_id=nd.show_id
	GROUP BY director, country
) m on nr.director=m.director
WHERE nr.country is null;

------------- For viewing purpose only
WITH cte as (
	SELECT *, ROW_NUMBER() over (partition by UPPER(title), type ORDER BY show_id) as rn
	FROM netflix_raw
)
SELECT show_id, type, title, cast(date_added as date) as date_added, release_year
,rating, CASE WHEN duration IS NULL THEN rating else duration END AS duration, description
FROM CTE
WHERE rn=1;
-------------

SELECT * FROM netflix_raw WHERE duration is null;


WITH cte as (
	SELECT *, ROW_NUMBER() over (partition by UPPER(title), type ORDER BY show_id) as rn
	FROM netflix_raw
)
SELECT show_id, type, title, cast(date_added as date) as date_added, release_year
,rating, CASE WHEN duration IS NULL THEN rating else duration END AS duration, description
INTO netflix
FROM CTE

