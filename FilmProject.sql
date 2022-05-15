-- Exploring IMDB Top 1000 Movies

SELECT*FROM FilmProject.dbo.imdb;

-- Exploring Director & Cast for IMDB Top 1000 Movies

SELECT*FROM FilmProject.dbo.crew;

------------------- CLEANING DATA IN IMDB TOP 1000 ------------------------------

-- What is our total row count?

SELECT COUNT(*) Total_Count
FROM FilmProject.dbo.imdb;

-- Looks like we have 1009 Row Counts. This doesn't look right since we are looking at Top 1000, IMDB Movies. We should have 1000 movies exactly!

-- Let's confirm whether the data set actually has 1000 unique records.

WITH Dedupe AS(
SELECT Distinct*
FROM FilmProject.dbo.imdb)
SELECT COUNT(*) As Total_unique_records
FROM Dedupe;

-- The data set does not have 1000 unique records. We need to remove the extra 9 duplicated data.

-- Let's find out which records have duplicate and how many times did they duplicate.

SELECT Poster_Link,Series_Title,Released_Year,Certificate,Runtime, Genre,IMDB_Rating,Overview,Meta_score,No_of_Votes,Gross,COUNT(*) AS Frequency
FROM FilmProject.dbo.imdb
GROUP BY
Poster_Link,Series_Title,Released_Year,Certificate,Runtime, Genre,IMDB_Rating,Overview,Meta_score,No_of_Votes,Gross
--ORDER BY Series_Title
HAVING COUNT(*) > 1;

-- Now we need to remove the duplicates

With Duplicated AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY Poster_Link,Series_Title,Released_Year,Certificate,Runtime, Genre,IMDB_Rating,Overview,Meta_score,No_of_Votes,Gross
	ORDER BY Series_Title) Row_Num				
FROM FilmProject.dbo.imdb)
DELETE
FROM Duplicated
WHERE Row_Num > 1

-- Confirming whether the 9 records have been deleted

SELECT COUNT(*) Total_Count
FROM FilmProject.dbo.imdb;

-- We only have 1000 records. Duplicate data deleted!

-- Are there any confusing/repetitive certifications?

SELECT Certificate, COUNT(*) AS Frequency
FROM FilmProject.dbo.imdb
GROUP BY Certificate;

-- Few of the Certifications are confusing because of how ranking system/film certification changed over years and because of how rating works in different film boards.
-- 16 should be PG-13
-- GP should be PG
-- U/A should be UA
-- Let's fix this

Select Certificate
, CASE When Certificate = '16' THEN 'PG-13'
	   When Certificate = 'GP' THEN 'PG'
	   WHEN Certificate = 'U/A' THEN 'UA'
	   ELSE Certificate
	   END
FROM FilmProject.dbo.imdb;


Update imdb
SET Certificate = CASE When Certificate = '16' THEN 'PG-13'
	   When Certificate = 'GP' THEN 'PG'
	   WHEN Certificate = 'U/A' THEN 'UA'
	   ELSE Certificate
	   END

-- Let's confirm whether the certificate terms have been cleaned

SELECT Certificate, COUNT(*) AS Frequency
FROM FilmProject.dbo.imdb
GROUP BY Certificate;

-- Confirmed. They have been cleaned.

-- Notice how many of the films have multiple genres grouped together. For example a film can have both Comedy and Drama.
-- It is difficult to work with data that are grouped together.
-- Let's breakdown the Genre into different columns.

-- Before proceeding, let's look at the maximum number of genres grouped together.

SELECT Genre
FROM FilmProject.dbo.imdb
GROUP BY Genre;

-- We can see that there are maximum three genres assigned to a film. This means we have to seperate them out into three columns.

SELECT
PARSENAME(REPLACE(Genre,',','.'),1) AS Genre_1,
PARSENAME(REPLACE(Genre,',','.'),2) AS Genre_2,
PARSENAME(REPLACE(Genre,',','.'),3) AS Genre_3
FROM FilmProject.dbo.imdb

ALTER TABLE Imdb
Add Genre_1 Nvarchar(255)

ALTER TABLE Imdb
Add Genre_2 Nvarchar(255)

ALTER TABLE Imdb
Add Genre_3 Nvarchar(255)

Update Imdb
SET Genre_1 = PARSENAME(REPLACE(Genre,',','.'),1)

Update Imdb
SET Genre_2 = PARSENAME(REPLACE(Genre,',','.'),2)

Update Imdb
SET Genre_3 = PARSENAME(REPLACE(Genre,',','.'),3)

ALTER TABLE Imdb
DROP COLUMN Genre

-- Above query we have broken downn Genre to different columns and deleted the redundant Genre column that grouped all the genres together.
--Let's confirm whether this worked

SELECT*
FROM FilmProject.dbo.imdb

-- It did!

-- Notice there are two ratings IMDB Rating and Metascore. IMDB is customer rating scored out of 10 whereas Metascore is aggregated critic rating scored out of 100.
-- Let's convert IMDB ratings to a scale of 100 so that later we can compare "apples to apples." 

SELECT imdb_rating, imdb_rating*10 As Customer_Rating
FROM FilmProject.dbo.imdb

ALTER TABLE FilmProject.dbo.imdb
Add Customer_Rating NUMERIC(10,0)

UPDATE FilmProject.dbo.imdb
SET Customer_Rating = imdb_rating*10


SELECT*
FROM FilmProject.dbo.imdb

--------------- DATA CLEANING COMPLETE FOR IMDB TOP 1000 MOVIES -------------------------------------------

------------------- CLEANING DATA IN CREW TABLE------------------------------

SELECT*
FROM FilmProject.dbo.Crew;

-- Let's confirm whether there are any duplicate data

SELECT Series_Title, Director, Star1, Star2, Star3, Star4, COUNT(*) As Frequency
FROM FilmProject.dbo.Crew
GROUP BY
Series_Title, Director, Star1, Star2, Star3, Star4
--ORDER BY Series_Title
HAVING COUNT(*) > 1;

-- No Duplicates confirmed!

-- Since the crew table has no uniqued ID (unlike the IMDB 1000 Movies table), let's confirm whether Series_Title is unique

SELECT Series_Title, COUNT(*) As Frequency
FROM FilmProject.dbo.Crew
GROUP BY Series_Title
HAVING COUNT(*) > 1

-- Looks like Drishyam has 2 records
-- Let's investigate furthermore

SELECT*
FROM FilmProject.dbo.Crew
WHERE Series_Title = 'Drishyam'

SELECT*
FROM FilmProject.dbo.imdb
WHERE Series_Title = 'Drishyam'

-- Series Title Drishyam was made twice by different crew and in different years.
-- We will need to use both Series Title and Release Year for joining tables

------------------- DATA EXPLORATION ------------------------------

-- Summary Statistics On Meta Score ---

--Mode calculation

With Meta AS (
SELECT Meta_Score, COUNT(Meta_Score) as Frequency
FROM FilmProject.dbo.imdb
GROUP BY Meta_score
)
SELECT Meta_Score
FROM Meta
Where Frequency = 32

-- Median Calculation

SELECT
PERCENTILE_CONT(0.5) WITHIN GROUP (order by Meta_Score) Over ()
FROM FilmProject.dbo.imdb

-- Now let's do Final Summary View calculation for Score

SELECT
ROUND(MIN(Meta_Score),2) As MIN_SCORE,
ROUND(MAX(Meta_score),2) As MAX_SCORE,
ROUND(AVG(Meta_score),2) As MEAN_SCORE,
76 As MODE_SCORE,
79 As MEDIAN_SCORE,
ROUND(STDEV(Meta_score),2) As Standard_Deviation
FROM FilmProject.dbo.imdb

-- Summary Statistics On IMDB Rating ---

--Mode calculation

With IMDB AS (
SELECT Customer_Rating, COUNT(Customer_Rating) as Frequency
FROM FilmProject.dbo.imdb
GROUP BY Customer_Rating
)
SELECT Customer_Rating
FROM IMDB
Where Frequency = 157

-- Median Calculation

SELECT
PERCENTILE_CONT(0.5) WITHIN GROUP (order by Customer_Rating) Over ()
FROM FilmProject.dbo.imdb

-- Now let's do Final Summary View calculation for Customer Score

SELECT
ROUND(MIN(Customer_Rating),2) As MIN_SCORE,
ROUND(MAX(Customer_Rating),2) As MAX_SCORE,
ROUND(AVG(Customer_Rating),2) As MEAN_SCORE,
77 As MODE_SCORE,
79 As MEDIAN_SCORE,
ROUND(STDEV(Customer_Rating),2) As Standard_Deviation
FROM FilmProject.dbo.imdb


-- Summary Statistics On Gross ---

-- Mode isn't as important for Gross. Median can be useful
SELECT
PERCENTILE_CONT(0.5) WITHIN GROUP (order by Gross) Over ()
FROM FilmProject.dbo.imdb

-- Now let's do Final Summary View calculation for Gross

SELECT
MIN(Gross)As MIN_GROSS,
MAX(Gross)As MAX_GROSS,
AVG(Gross) As MEAN_GROSS,
23530892 As MEDIAN_Gross,
STDEV(Gross) As Standard_Deviation_Gross
FROM FilmProject.dbo.imdb

-- Cumulative Distribution & Frequency Distribution Chart For Meta Score --

-- Cumulative Distribution

With Percentile_values AS (
SELECT Meta_Score,
NTILE(100) OVER (Order By Meta_Score) As Percentile
FROM FilmProject.dbo.imdb
WHERE Meta_Score IS NOT NULL)
Select
Percentile,
MIN (Meta_Score) As Floor_Value,
MAX(Meta_Score) As Ceiling_Value,
COUNT(*) As Percentile_Count
FROM Percentile_values
Group BY Percentile
Order By Percentile

-- Frequency Distribution Chart

With Bins AS (
SELECT
Floor(meta_score/20)*20 as bin_floor,
COUNT(*) As Frequency
FROM FilmProject.dbo.imdb
Group By Floor(meta_score/20)*20 
--Order By Floor(meta_score/20)*20 
)
SELECT bin_floor,
  CONCAT(bin_floor, ' to ', bin_floor +20) as Bin_ceiling,
  Frequency
  From Bins
  WHERE Frequency <> 157
  Group By bin_floor, Frequency
  Order By Bin_floor

  -- Frequency Distribution Chart for Customer Rating

  With Bins AS (
SELECT
Floor(Customer_rating/20)*20 as bin_floor,
COUNT(*) As Frequency
FROM FilmProject.dbo.imdb
Group By Floor(Customer_rating/20)*20 
--Order By Floor(meta_score/20)*20 
)
SELECT bin_floor,
  CONCAT(bin_floor, ' to ', bin_floor +20) as Bin_ceiling,
  Frequency
  From Bins
  WHERE Frequency <> 157
  Group By bin_floor, Frequency
  Order By Bin_floor

  -- Histogram For Gross Revenue --

 With Bins AS (
SELECT
Floor(Gross/10000000)*10000000 as bin_floor,
COUNT(*) As Frequency
FROM FilmProject.dbo.imdb
Group By Floor(Gross/10000000)*10000000
--Order By Floor(meta_score/20)*20 
)
SELECT bin_floor/10000 AS Floor,
  CONCAT(bin_floor/10000, ' to ', bin_floor/10000 +10000) as Bin_Ceiling,
  Frequency
  From Bins
  WHERE Frequency <> 169
  Group By bin_floor, Frequency
  Order By Bin_floor

-- Cumulative Distribution Chart For Gross Revenue --

With Percentile_values AS (
SELECT Series_Title, Gross,
NTILE(100) Over (Order By Gross) As Percentile
FROM FilmProject.dbo.imdb
Where Gross IS NOT NULL)
SELECT Percentile, Series_Title,
MIN (Gross) As Floor_Value,
MAX(Gross) As Ceiling_Value,
COUNT(*) As Percentile_Count
FROM Percentile_values
Group BY Percentile, Series_Title
Order By Percentile


---- Customer vs Critic Rating Analysis -----------

-- Average difference between Customer and Critic Rating ----

WITH RatingDiff AS (
SELECT Meta_score, customer_rating,(Meta_score - Customer_rating) As Avg_Difference
FROM FilmProject.dbo.imdb )
SELECT AVG(Meta_Score), AVG(customer_rating),AVG(Avg_Difference) As Average_Difference
FROM RatingDiff

-- On average, critics and customer's rating differs by +/- 1.35 score. This is almost negligible.

-- Since this dataset is built with Top IMDB 1000 movie list, it is fair to compare how customer's top 10 films rating compares with critic's top films ratings.
-- Finding top ten critic's choice and then comparing with customer's wouldn't make sense as this list is exahustive list of customer's choice ---

-- Top 10 Customer Choice vs Critic Rating

SELECT Top 10
Series_title, Released_year,Customer_rating, Meta_Score
FROM FilmProject.dbo.imdb
ORDER by 3 DESC

-- Bottom 10 Customer Choice vs Critic Rating

SELECT Top 10
Series_title, Released_year,Customer_rating, Meta_Score
FROM FilmProject.dbo.imdb
ORDER by 3 

-- Is there a relationship between Ratings & Certification?

-- Customer's preference of certification based off their top 100 films

With CustCert AS (
SELECT TOP 100
Certificate, Customer_Rating
FROM  FilmProject.dbo.imdb
Order by Customer_Rating
)
SELECT Certificate, COUNT(*) As Frequency
FROM CustCert
WHERE Certificate IS NOT NULL
GROUP BY Certificate
ORDER BY COUNT(*) DESC

-- Audience/Customer really likes approved and Rated R Films (not surprised).

-- Critic's preference of certification based off their top 100 films

With CritCert AS (
SELECT TOP 100
Certificate, Meta_Score
FROM  FilmProject.dbo.imdb
Order by Meta_Score
)
SELECT Certificate, COUNT(*) As Frequency
FROM CritCert
WHERE Certificate IS NOT NULL
GROUP BY Certificate
ORDER BY COUNT(*) DESC

-- Critic's perfer UA & U. Surprisingly Rated R films is not a big portion of their top choices. 

--Critic's Favorite Director vs Customer's Favorite Director

-- Customer Top 3 Directors Based off their Top 100 Movies ----

WITH Customer_Director As (
SELECT TOP 100 a.series_title,a.customer_rating,b.director as director,Gross
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
ORDER by 2 DESC
)
SELECT TOP 3
director, COUNT(*) As Frequency,ROUND(AVG(customer_rating), 2) As Average_Film_Rating, ROUND(AVG(Gross),0) As Average_Gross
FROM Customer_Director
GROUP by director
Order by COUNT(*) DESC

-- As an audience myself, I can confirm Christopher Nolan is one of the most talked about Directors!

-- Critic Top 3 Directors Based off their Top 100 Movies ----

WITH Critic_Director As (
SELECT TOP 100 a.series_title,a.meta_score,b.director as director, Gross
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 2 DESC
)
SELECT TOP 3
director, COUNT(*) As Frequency, ROUND(AVG(meta_score),2) As Average_Film_Rating, ROUND(AVG(Gross),0) As Average_Gross
FROM Critic_Director
GROUP by director
Order by COUNT(*) DESC

-- If you watch YouTube Videos on studying works of top directors, you will for sure come across Alfred Hitchcock

--Critic's Favorite Actor vs Customer's Favorite Actor

-- Customer Top 3 Actors Based off their Top 100 Movies ----

-- First we will need to Unpivot Star columns. The reason we have to do this is because Actors are seperated out into different columns

SELECT Series_Title, Released_Year, Director, Star, Actor
FROM FilmProject.dbo.crew b
UNPIVOT (
	ACTOR
	FOR
	Star IN(Star1,Star2,Star3)
) As UnPivotExample

-- Let's store this data in a temp table --

DROP Table if exists ModifiedCrew
Create Table ModifiedCrew
(
Series_title nvarchar(255),
Released_Year nvarchar(255),
Director nvarchar(255),
Star nvarchar(255),
Actor nvarchar(255)
)

Insert into ModifiedCrew
SELECT Series_Title, Released_Year, Director, Star, Actor
FROM FilmProject.dbo.crew b
UNPIVOT (
	ACTOR
	FOR
	Star IN(Star1,Star2,Star3)
) As UnPivotExample

SELECT*
FROM ModifiedCrew


-- Let's find Customers Top 3 Actors from their Top 100 movies ---

With TopActor AS (
SELECT TOP 100 a.series_title,a.customer_rating, b.actor as Actor_Name
FROM FilmProject.dbo.imdb a
INNER JOIN ModifiedCrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 2 DESC)
SELECT TOP 3 Actor_Name, COUNT(*) as Frequency, AVG(Customer_Rating) As Average_Rating
FROM TopActor
GROUP BY Actor_Name
Order by COUNT(*) DESC

-- Elijah Wood and Ian McKellen tied. This is because they both starred in the same Lord of the Rings series. Might be fair to say Elijah Wood and Ian McKellen are good combo (we will discover this later)
-- Robert De Niro made it too! Can't complain - he is the prince of crime thriller!

-- Let's find Critic's Top 3 Actors based of their Top 100 movies ---

With TopActor AS (
SELECT TOP 100 a.series_title,a.meta_score, a.gross, b.actor as Actor_Name
FROM FilmProject.dbo.imdb a
INNER JOIN ModifiedCrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 2 DESC)
SELECT TOP 3 Actor_Name, COUNT(*) as Frequency, AVG(Meta_Score) as Average_Rating
FROM TopActor
GROUP BY Actor_Name
Order by COUNT(*) DESC

-- Orson_Welles it is!

--Critic's Favorite Actor Director Combo vs Customer's Favorite Actor Director Combo

-- Customer's Favorite Actor Director Combo based of their Top 100 movies --

With Combo AS (
SELECT TOP 100 a.series_title,a.customer_rating,b.director As Director_Name, b.actor as Actor_Name
FROM FilmProject.dbo.imdb a
INNER JOIN ModifiedCrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 2 DESC)
SELECT TOP 3 Director_Name, Actor_Name, COUNT(*) As Frequency
FROM Combo
Group By Director_Name, Actor_Name
ORDER by COUNT(*) DESC

-- Peter Jackson directed both Elijah Wood and Ian McKellen in the Lord of the Rings series.
-- Francis Ford Coppila and Al Pacino worked together both in God Father 1 & 2.

-- Critic's Favorite Actor Director Combo based of their Top 100 Movies --

With Combo AS (
SELECT TOP 100 a.series_title,a.meta_score,b.director As Director_Name, b.actor as Actor_Name
FROM FilmProject.dbo.imdb a
INNER JOIN ModifiedCrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 2 DESC)
SELECT TOP 3 Director_Name, Actor_Name, COUNT(*) As Frequency
FROM Combo
Group By Director_Name, Actor_Name
ORDER by COUNT(*) DESC, Director_Name

-- Finally a foreign Director and Actor combo. Akira and Toshira are top Japanese director actor combo in my opinion as well

--Critic's Favorite Actor Combo vs Customer's Favorite Actor  Combo

-- For this exercise, we have to do the following three combinations
-- 1. Director X Star 1 X Star 2
-- 2. Director X Star 2 X Star 3
-- 3. Director X Star 1 X Star 3

-- Then we find the max counts from each combo and combine them in a table

-- Customer's Favorite Actor Combo based of their Top 100 movies --

With Combo1 AS (
SELECT Top 100 
a.customer_rating,b.Star1 as Actor1, b.Star2 as Actor2
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 1 DESC)
SELECT TOP 3 Actor1,Actor2, COUNT(*) As Frequency
FROM Combo1
GROUP BY Actor1,Actor2
HAVING COUNT(*) > 1
Order By COUNT(*) Desc


With Combo2 AS (
SELECT Top 100 
a.customer_rating,b.Star2 as Actor1, b.Star3 as Actor2
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 1 DESC)
SELECT TOP 3 Actor1,Actor2, COUNT(*) As Frequency
FROM Combo2
GROUP BY Actor1,Actor2
HAVING COUNT(*) > 1
Order By COUNT(*) Desc


With Combo3 AS (
SELECT Top 100 
a.customer_rating,b.Star1 as Actor1, b.Star3 as Actor2
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 1 DESC)
SELECT TOP 3 Actor1,Actor2, COUNT(*) As Frequency
FROM Combo3
GROUP BY Actor1,Actor2
HAVING COUNT(*) > 1
Order By COUNT(*) Desc


Drop Table IF EXISTs CustomerFavorite
CREATE TABLE CustomerFavorite
(Actor_1 varchar(255),
Actor_2 varchar(255),
Frequency numeric)

INSERT INTO CustomerFavorite
VALUES ('Elijah Wood','Ian McKellen','2'),('Joe Russo','Robert Downey Jr','2'),('Charles Chaplin','Paulette Goddard','2'),
('Harrison Ford','Carrie Fisher','2'),('Mark Hamill','Carrie Fisher','2')

SELECT* FROM
CustomerFavorite
ORDER BY 1,2

-- Critic's Favorite Actor Combo based of their Top 100 movies --

With Combo1 AS (
SELECT Top 100 
a.meta_score,b.Star1 as Actor1, b.Star2 as Actor2
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 1 DESC)
SELECT TOP 3 Actor1,Actor2, COUNT(*) As Frequency
FROM Combo1
GROUP BY Actor1,Actor2
HAVING COUNT(*) > 1
Order By COUNT(*) Desc


With Combo2 AS (
SELECT Top 100 
a.meta_score,b.Star2 as Actor1, b.Star3 as Actor2
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 1 DESC)
SELECT TOP 3 Actor1,Actor2, COUNT(*) As Frequency
FROM Combo2
GROUP BY Actor1,Actor2
HAVING COUNT(*) > 1
Order By COUNT(*) Desc


With Combo3 AS (
SELECT Top 100 
a.meta_score,b.Star1 as Actor1, b.Star3 as Actor2
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
Order by 1 DESC)
SELECT TOP 3 Actor1,Actor2, COUNT(*) As Frequency
FROM Combo3
GROUP BY Actor1,Actor2
HAVING COUNT(*) > 1
Order By COUNT(*) Desc


Drop Table IF EXISTs CriticFavorite
CREATE TABLE CriticFavorite
(Actor_1 varchar(255),
Actor_2 varchar(255),
Frequency numeric)

INSERT INTO CriticFavorite
VALUES ('Orson Welles','Joseph Cotten','2')

SELECT* FROM
CriticFavorite
ORDER BY 1,2


--- Genre Preference Between Critics & Customers -----

-- Genre 1 - Primary genre of the film, Genre 2 - seconday, Genre 3 - Tertiary

-- Customer Genre Combo Preference (Primary x Secondary X Tertiary) based of their Top 100 movies

With CustomerGenreCombo As (
SELECT Top 100
Genre_1, Genre_2, Genre_3, Customer_Rating
FROM FilmProject.dbo.imdb
Order By 4 DESC)
SELECT Genre_1, Genre_2, Genre_3, COUNT(*) As Frequency
FROM CustomerGenreCombo
Group by Genre_1, Genre_2, Genre_3
HAVING COUNT(*) > 3
Order by COUNT(*) DESC

-- Drama only genre is an audience favorite. That is surprising.

-- Critic Genre Combo Preference (Primary x Secondary X Tertiary)

With CriticGenreCombo As (
SELECT Top 100
Genre_1, Genre_2, Genre_3, Meta_score
FROM FilmProject.dbo.imdb
Order By 4 DESC)
SELECT Genre_1, Genre_2, Genre_3, COUNT(*) As Frequency
FROM CriticGenreCombo
Group by Genre_1, Genre_2, Genre_3
HAVING COUNT(*) > 3
Order by COUNT(*) DESC

-- Looks like even critics prefer drama only films!

--- Let's put on the hat of a film financier and try to understand where to put our bet on if we want to make a film ---

-- Revenue vs Ratings: Correlation between Revenue and Customer/Critic Ratings
-- The relationship will be easier to understand when we visualize this later

SELECT Series_Title, Gross, Customer_rating, Meta_Score
FROM FilmProject.dbo.imdb

-- When visualized, we can see there is no correlation between ratings and gross. In pre-screenings, customers/critics rating won't assess how the film will perform in the market.

-- Genre Vs Gross Relationship ---

-- Primary X Secondary X Tertiary Genre Vs Gross --

With GenreComboGross AS (
Select Genre_1,Genre_2, Genre_3,SUM(Gross) As Total_Gross, COUNT(*) As Frequency
FROM FilmProject.dbo.imdb
--Where Genre_2 is NOT NULL 
Group BY Genre_1, Genre_2, Genre_3
Having SUM(Gross) IS NOT NULL) 
SELECT Top 5 Genre_1, Genre_2, Genre_3, Total_Gross, Frequency, ROUND((Total_Gross/Frequency),0) As Average_Gross
FROM GenreComboGross
Where Frequency > 10
Group By Genre_1, Genre_2, Genre_3, Total_Gross, Frequency
Order By (Total_Gross/Frequency) DESC

-- If I had my own studio, I would definitely make a film with Sci-Fi, Adventure and Action

-- Director Vs Gross ---

-- First let's find Top 3 Directors with highest average Gross ---

SELECT TOP 3 b.director, SUM(a.gross) As Total_Gross, COUNT(*) As Frequency, (SUM(a.gross)/COUNT(*)) As Average_Gross
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
GROUP BY b.director
HAVING COUNT(*) > 3
Order by SUM(a.gross)/COUNT(*) DESC

-- FYI - Anthony Russo  made the Avengers series

-- Let's find top Directos and their genre combo --

With DirectorGenreGross AS (
SELECT b.director, a.genre_1, a.genre_2, a.genre_3, a.gross, SUM(a.gross) As Total_Gross, COUNT(*) As Frequency, (SUM(a.gross)/COUNT(*)) As Average_Gross,
Dense_rank() Over (Partition By director order by SUM(a.gross)/COUNT(*) DESC) as Rank
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.crew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
WHERE 
b.director = 'Anthony Russo' OR
b.director = 'James Cameron' OR
b.director = 'Peter Jackson'
GROUP BY b.director,a.genre_1, a.genre_2, a.genre_3,a.gross
)
SELECT director, genre_1, genre_2, genre_3, gross, Total_Gross, Frequency, Average_Gross, Rank
FROM DirectorGenreGross
WHERE Rank < 4
Order By 1

-- Actor vs Gross --

With ActorGross AS (
SELECT b.actor, a.gross
FROM FilmProject.dbo.imdb a
INNER JOIN Modifiedcrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
WHERE a.gross IS NOT NULL 
)
SELECT actor, SUM(gross) As Total_Gross, COUNT(*) As Frequency, ROUND(SUM(gross)/COUNT(*),0) As Average_Gross
FROM ActorGross
GROUP  BY actor
HAVING COUNT(*) > 5
Order by SUM(gross)/COUNT(*) DESC

-- All credit for Robert Downey Jr goes to Avengers series!

-- Actor X Genre X Gross Combo ---

With ActorGenreGross AS (
SELECT b.actor, a.genre_1, a.genre_2, a.genre_3, a.gross
FROM FilmProject.dbo.imdb a
INNER JOIN Modifiedcrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
WHERE a.gross IS NOT NULL 
),
ABC AS (
SELECT actor, genre_1, Genre_2, genre_3, SUM(gross) as Total_Gross, COUNT(*) as Frequency, ROUND(SUM(gross)/COUNT(*),0) as Average_Gross,
Dense_rank () Over (Partition by actor order by SUM(gross)/COUNT(*) DESC) as Rank
FROM ActorGenreGross
GROUP BY actor, genre_1, Genre_2, genre_3
Having COUNT(*) > 3
)
SELECT* 
FROM ABC
WHERE Rank < 4

-- Ultimate Director, Actor, Genre Combo -----


With UltimateCombo AS (
SELECT b.director, b.actor, a.genre_1, a.genre_2, a.genre_3, a.gross
FROM FilmProject.dbo.imdb a
INNER JOIN Modifiedcrew b
ON a.series_title = b.series_title
AND a.released_year = b.released_year
WHERE a.gross IS NOT NULL
)
SELECT Top 5 director, actor, genre_1, genre_2, genre_3, SUM(gross) as Total_Gross, COUNT(*) As Frequency, ROUND(SUM(Gross)/COUNT(*),0) As Average_Gross
FROM UltimateCombo
GROUP BY director, actor, genre_1, genre_2, genre_3
HAVING COUNT(*) > 2
ORDER BY SUM(Gross)/COUNT(*) DESC

-- Does Runtime impact gross --


WITH Runtimegross AS (
SELECT Runtime, Gross
FROM FilmProject.dbo.imdb
WHERE GROSS IS NOT NULL
)
SELECT Runtime, COUNT(*) As Frequency, ROUND(SUM(Gross)/COUNT(*),0) As Average_Gross
FROM Runtimegross
Group BY Runtime
HAVING COUNT(*) > 5

-- When visualized, we can see movies that are 2 hour 20 mins long, make the highest amount of money.


-- Does Certification impact gross --

SELECT Certificate, SUM(Gross) As Total_Gross
FROM FilmProject.dbo.imdb
Where Certificate IS NOT NULL
Group by Certificate
HAVING SUM(Gross) IS NOT NULL

-- UA films make the highest amount of money.


-- Fun easy exercise: which streaming platform should you go with: Netflix, Amazon Prime or Disney Plus ? ---

-- Criteria 1: Which Platform has most of Top 1000 imdb movies? ----

--Netflix --

Select*
FROM FilmProject.dbo.netflix

With NetflixImdb1000 AS (
SELECT a.customer_rating, b.title
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.netflix b
ON a.series_title = b.title
AND a.released_year = b.release_year)
SELECT COUNT(*) As Count_of_IMDB1000, ROUND(AVG(customer_rating),2) as Average_Rating
FROM NetflixImdb1000

-- Prime --

With NetflixImdb1000 AS (
SELECT a.customer_rating, b.title
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.prime b
ON a.series_title = b.title
AND a.released_year = b.release_year)
SELECT COUNT(*) As Count_of_IMDB1000, ROUND(AVG(customer_rating),2) as Average_Rating
FROM NetflixImdb1000

-- Disney Plus ---

With NetflixImdb1000 AS (
SELECT a.customer_rating, b.title
FROM FilmProject.dbo.imdb a
INNER JOIN FilmProject.dbo.disney b
ON a.series_title = b.title
AND a.released_year = b.release_year)
SELECT COUNT(*) As Count_of_IMDB1000, ROUND(AVG(customer_rating),2) as Average_Rating
FROM NetflixImdb1000

-- Netflix is the clear winner! 
