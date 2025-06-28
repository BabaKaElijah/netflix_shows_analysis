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
