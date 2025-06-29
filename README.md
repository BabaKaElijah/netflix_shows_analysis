# 📺 Netflix SQL Analysis Project

![App Screenshot](logo.png)

# Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

# Objectives
- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.
- Use views, triggers, functions and stored procedures for analyzing. 

# Schema
```sql
DROP TABLE IF EXISTS netflix;
CREATE TABLE netflix
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```
---

## 📊 Basic Queries

### 1. View All Data

```sql
SELECT * FROM netflix_titles;
```
### 2. Count the Number of Movies vs TV Shows
```sql
SELECT 
    type,
    COUNT(type) AS MoviesVSTv
FROM netflix_titles
GROUP BY type;
```
### 3. Most Common Rating for Movies and TV Shows
```sql
SELECT 
    rating,
    COUNT(rating) AS total_count
FROM netflix_titles
GROUP BY rating
ORDER BY total_count DESC;
```
### 4. List All Movies Released in 2020
```sql
SELECT 
    title, 
    release_year
FROM netflix_titles
WHERE release_year = 2020;
```
### 5. Top 5 Countries with the Most Content
```sql
SELECT TOP 5 
    country, 
    COUNT(*) AS total_titles
FROM netflix_titles
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_titles DESC;
```
### 6. Identify the Longest Movie 
```sql
SELECT TOP 10 
    title,
    duration,
    CAST(LEFT(LTRIM(RTRIM(duration)), CHARINDEX(' ', LTRIM(RTRIM(duration))) - 1) AS INT) AS numeric_duration
FROM netflix_titles
WHERE type = 'Movie' AND duration LIKE '%min'
ORDER BY numeric_duration DESC;
```
### 7. Content Added in the Last 5 Years
```sql
SELECT TOP 10
    title,
    TRY_CAST(date_added AS DATE)
FROM netflix_titles
WHERE TRY_CAST(date_added AS DATE) >= DATEADD(YEAR, -5, GETDATE())
ORDER BY TRY_CAST(date_added AS DATE) DESC;
```
### 8. Shows by Director 'Rajiv Chilaka'
```sql
SELECT 
    title,
    type,
    director
FROM netflix_titles
WHERE director = 'Rajiv Chilaka';
```
### 9. TV Shows with More Than 5 Seasons
```sql
SELECT 
    title,
    type, 
    duration
FROM netflix_titles
WHERE type = 'TV Show'
  AND duration LIKE '%Season%'
  AND CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT) > 5;
```
### 10. Count Content Items in Each Genre
```sql
SELECT 
    type,
    COUNT(type) AS total_count
FROM netflix_titles
GROUP BY type;
```
### 11. Top 5 Years with Highest % of Indian Content
```sql
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
```
# 🎯 Special Filters
### 12. List All Movies that Are Documentaries
```sql
SELECT 
    title,
    listed_in
FROM netflix_titles
WHERE listed_in LIKE '%Documentaries%';
```
### 13. Find Content Without a Director
```sql
SELECT 
    title,
    director
FROM netflix_titles
WHERE director IS NULL;
```
### 14. Count How Many Shows Salman Khan Appeared In
```sql
SELECT 
    COUNT(*) AS total_shows
FROM netflix_titles
WHERE cast LIKE '%Salman Khan%';
```
### 15. Top 10 Actors in Indian Movies
```sql
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
```
# 🚦 Categorization
### 16. Categorize Content Based on Keywords in Description
```sql
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
```
# 🔄 CTEs, Views, Triggers, and Functions
### 17. Top 5 Directors with the Most Content (CTE)
```sql
WITH DirectorCount AS (
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
```
### 18. Trigger: Prevent Duplicate Titles (Case-Insensitive)
```sql
CREATE TRIGGER trg_PreventDuplicateTitles
ON netflix_titles
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN netflix_titles nt ON LOWER(i.title) = LOWER(nt.title)
    )
    BEGIN
        RAISERROR ('Cannot insert duplicate title (case-insensitive match found).', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    INSERT INTO netflix_titles (
        show_id, type, title, director, cast, country,
        date_added, release_year, rating, duration, listed_in, description
    )
    SELECT
        show_id, type, title, director, cast, country,
        date_added, release_year, rating, duration, listed_in, description
    FROM inserted;
END;
```
### 19. Stored Procedure: Delete Only Movies (Rollback if TV Show)
```sql
CREATE PROCEDURE DeleteMoviesByShowID
    @show_id VARCHAR(20)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @content_type VARCHAR(20);

        SELECT @content_type = type
        FROM netflix_titles
        WHERE show_id = @show_id;

        IF @content_type IS NULL
        BEGIN
            RAISERROR('No content found with the given show_id.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        IF @content_type = 'TV Show'
        BEGIN
            RAISERROR('Deletion not allowed: Content is a TV Show.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

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
```
### 20. View: All Indian Movies
```sql
CREATE VIEW Indian_Movies_View 
AS
SELECT 
    title,
    director,
    release_year,
    description
FROM netflix_titles
WHERE type = 'Movie' AND country LIKE '%India%';

-- Test
SELECT * FROM Indian_Movies_View;
```
### 21. Scalar Function: Get Content Age
```sql
CREATE FUNCTION GetContentAge(@year INT)
RETURNS INT
AS
BEGIN
    DECLARE @age INT;
    SET @age = YEAR(GETDATE()) - @year;
    RETURN @age;
END;

-- Test
SELECT 
    title,
    release_year,
    dbo.GetContentAge(release_year) AS content_age
FROM netflix_titles;
```
### 22. Table-Valued Function: Get Content by Rating
```sql
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
```
## 👤 Author
Ellias Sithole

-- Test
SELECT * FROM dbo.GetContentByRating('TV-MA');
```
💡 Feel free to fork this project, use the SQL logic, or extend it with procedures for analytics, report generation, and more!
