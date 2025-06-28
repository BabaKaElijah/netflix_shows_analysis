SELECT * FROM netflix_titles

--1. Count the number of Movies vs TV Shows

SELECT 
type,
COUNT(type) AS MoviesVSTv
FROM netflix_titles
GROUP BY type

--2. Find the most common rating for movies and TV shows

SELECT 
rating,
COUNT(rating) AS total_count
FROM netflix_titles
GROUP BY rating
ORDER BY total_count DESC

--3. List all movies released in a specific year (e.g., 2020)

SELECT 
title, 
release_year
FROM netflix_titles
WHERE release_year = 2020

--4. Find the top 5 countries with the most content on Netflix

SELECT TOP 5 
  country, 
  COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_titles DESC;

--5. Identify the longest movie

SELECT TOP 10 
    title,
    duration,
    CAST(LEFT(LTRIM(RTRIM(duration)), CHARINDEX(' ', LTRIM(RTRIM(duration))) - 1) AS INT) AS numeric_duration
FROM netflix_titles
WHERE type = 'Movie' AND duration LIKE '%min'
ORDER BY numeric_duration DESC;

--6. Find content added in the last 5 years

SELECT TOP 10
title,
TRY_CAST(date_added AS DATE)
FROM netflix_titles
WHERE TRY_CAST(date_added AS DATE) >= DATEADD(YEAR, -5, GETDATE())
ORDER BY TRY_CAST(date_added AS DATE) DESC;

--7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT 
title,
type,
director
FROM netflix_titles
WHERE director = 'Rajiv Chilaka'

--8. List all TV shows with more than 5 seasons

SELECT 
title,
type, 
duration
FROM netflix_titles
WHERE type = 'TV Show'
  AND duration LIKE '%Season%'
  AND CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT) > 5;

--9. Count the number of content items in each genre

SELECT 
type,
COUNT(type) AS total_count
FROM netflix_titles
GROUP BY type

--10. 10.Find each year and the average numbers of content release in India on netflix. 
--return top 5 year with highest avg content release!

SELECT TOP 5
    country,
    release_year,
    COUNT(show_id) AS total_release,
    FORMAT(
        CAST(COUNT(show_id) AS decimal(10,2)) / 
        CAST((SELECT COUNT(show_id) FROM netflix_titles WHERE country LIKE '%India%') AS decimal(10,2)) * 100,
        'N2'
    ) AS avg_release_percentage
FROM netflix_titles
WHERE country LIKE '%India%'
GROUP BY country, release_year
ORDER BY CAST(
        CAST(COUNT(show_id) AS decimal(10,2)) / 
        CAST((SELECT COUNT(show_id) FROM netflix_titles WHERE country LIKE '%India%') AS decimal(10,2)) * 100
    AS decimal(10,2)
) DESC;

--11. List all movies that are documentaries

SELECT 
title,
listed_in
FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%'

--12. Find all content without a director

SELECT 
title,
director
FROM netflix_titles
WHERE director IS NULL

--13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT 
COUNT(*) AS total_shows
FROM netflix_titles
WHERE cast LIKE '%Salman Khan%'

--14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

SELECT TOP 10 
    LTRIM(RTRIM(value)) AS actor,
    COUNT(*) AS movie_count
FROM netflix_titles
CROSS APPLY STRING_SPLIT(cast, ',')
WHERE type = 'Movie'
  AND country LIKE '%India%'
  AND cast IS NOT NULL
GROUP BY LTRIM(RTRIM(value))
ORDER BY movie_count DESC;

--Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
--the description field. Label content containing these keywords as 'Bad' and all other 
--content as 'Good'. Count how many items fall into each category.

SELECT 
    CASE 
        WHEN 
            PATINDEX('%[^a-zA-Z]kill[^a-zA-Z]%', ' ' + description + ' ') > 0
            OR
            PATINDEX('%[^a-zA-Z]violence[^a-zA-Z]%', ' ' + description + ' ') > 0
        THEN 'Bad'
        ELSE 'Good'
    END AS content_category,
    COUNT(*) AS item_count
FROM netflix_titles
WHERE description IS NOT NULL
GROUP BY 
    CASE 
        WHEN 
            PATINDEX('%[^a-zA-Z]kill[^a-zA-Z]%', ' ' + description + ' ') > 0
            OR
            PATINDEX('%[^a-zA-Z]violence[^a-zA-Z]%', ' ' + description + ' ') > 0
        THEN 'Bad'
        ELSE 'Good'
    END;

--16. Create a CTE to find the top 5 directors who have the most content 
--(movies + TV shows) on Netflix.

WITH DirectorCount AS(
SELECT 
director,
COUNT(*) AS total_shows
FROM netflix_titles
WHERE director IS NOT NULL
GROUP BY director
)
SELECT TOP 5
    director,
    total_shows
FROM DirectorCount
ORDER BY total_shows DESC;

--17. Write a trigger that prevents inserting any new content where title 
--already exists (case-insensitive).

CREATE TRIGGER trg_PreventDuplicateTitles
ON netflix_titles
INSTEAD OF INSERT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(
		SELECT 1 
		FROM inserted i
		JOIN netflix_titles nt
			ON LOWER(i.title) = LOWER(nt.title)
	)
	BEGIN
		RAISERROR ('Cannot insert duplicate title (case-insensitive match found).', 16, 1);
		ROLLBACK TRANSACTION;
		RETURN;
	END

	--if no duplicates found, allow insert
	INSERT INTO netflix_titles (
	    show_id, type, title, director, cast, country,
        date_added, release_year, rating, duration, listed_in, description
	)
	SELECT
        show_id, type, title, director, cast, country,
        date_added, release_year, rating, duration, listed_in, description
    FROM inserted;
END;

--17. Write a stored procedure or script to delete a title by show_id, but:
--Only if it's a Movie.
--Rollback if it's a TV Show.
--Use TRY...CATCH to handle errors.

CREATE PROCEDURE DeleteMoviesByShowID
	@show_id VARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

		--check the type of the content
		DECLARE @content_type VARCHAR(20);

		SELECT @content_type = type
		FROM netflix_titles
		WHERE show_id = @show_id;

		--if not found
		IF @content_type IS NULL
		BEGIN
			RAISERROR('No content found with the given show_id.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END		

		--if it's a TV show, rollback
		IF @content_type = 'TV Show'
		BEGIN
			RAISERROR('Deletion not allowed: Content is a TV Show.', 16, 1);
			ROLLBACK TRANSACTION;
			RETURN;
		END

		--if it;s a Movie, delete
		DELETE FROM netflix_titles
		WHERE show_id = @show_id;

		COMMIT TRANSACTION;
		PRINT 'Movie deleted successfully.';
	END TRY
	
	BEGIN CATCH
		ROLLBACK TRANSACTION;

		DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();

        RAISERROR(@ErrMsg, @ErrSeverity, 1);
	END CATCH
END;

--18. Create a view called Indian_Movies_View that includes:
--All movies from India.
--Shows title, director, release_year, and description.

CREATE VIEW Indian_Movies_View 
AS
SELECT 
	title,
	director,
	release_year,
	description
FROM netflix_titles
WHERE
	type = 'Movie'
	AND country LIKE '%India%'

SELECT * FROM Indian_Movies_View	

--19. Scalar Function
--Write a scalar function called GetContentAge(@year INT) 
--that returns how many years old the content is (compared to current year).

CREATE FUNCTION GetContentAge(@year INT)
RETURNS INT
AS
BEGIN
	DECLARE @age INT;

	--Calculate age by subtratcing release year from current year
	SET @age = YEAR(GETDATE()) - @year;

	RETURN @age;
END;

--TEST
SELECT 
    title,
    release_year,
    dbo.GetContentAge(release_year) AS content_age
FROM netflix_titles;

--20. Table-Valued Function
--Write a function GetContentByRating(@rating VARCHAR) 
--that returns all shows with that rating.

CREATE FUNCTION GetContentByRating (@rating VARCHAR(10))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        show_id,
        type,
        title,
        director,
        cast,
        country,
        date_added,
        release_year,
        rating,
        duration,
        listed_in,
        description
    FROM netflix_titles
    WHERE rating = @rating
);

--TEST
SELECT * FROM dbo.GetContentByRating('TV-MA');