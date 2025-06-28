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

