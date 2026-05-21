/*
    FIFA 23 Player Market & Transfer Value Analysis
    Associate Analyst SQL Portfolio Project

    Database: fifa_portfolio
    Source table: dbo.fifa_23_players

    Business question:
    How can a club use FIFA 23 player data to understand market value,
    compare player groups, and identify realistic transfer targets?

    Analyst skills shown:
    - Data quality checks
    - Reusable view creation
    - CASE-based segmentation
    - Aggregate analysis
    - CTEs
    - Window functions with RANK()
    - Practical shortlist logic
*/


/* ============================================================
   1. Data Quality Checks
   ============================================================ */

-- Confirm the total number of imported records.
SELECT
    COUNT(*) AS total_players
FROM dbo.fifa_23_players;


-- Check missing values in the columns used for analysis.
SELECT
    SUM(CASE WHEN [Known As] IS NULL OR [Known As] = '' THEN 1 ELSE 0 END) AS missing_known_as,
    SUM(CASE WHEN [Full Name] IS NULL OR [Full Name] = '' THEN 1 ELSE 0 END) AS missing_full_name,
    SUM(CASE WHEN [Overall] IS NULL THEN 1 ELSE 0 END) AS missing_overall,
    SUM(CASE WHEN [Potential] IS NULL THEN 1 ELSE 0 END) AS missing_potential,
    SUM(CASE WHEN [Value(in Euro)] IS NULL THEN 1 ELSE 0 END) AS missing_market_value,
    SUM(CASE WHEN [Wage(in Euro)] IS NULL THEN 1 ELSE 0 END) AS missing_wage,
    SUM(CASE WHEN [Best Position] IS NULL OR [Best Position] = '' THEN 1 ELSE 0 END) AS missing_best_position,
    SUM(CASE WHEN [Club Name] IS NULL OR [Club Name] = '' THEN 1 ELSE 0 END) AS missing_club
FROM dbo.fifa_23_players;


-- Review the range of key numeric fields.
SELECT
    MIN([Age]) AS min_age,
    MAX([Age]) AS max_age,
    MIN([Overall]) AS min_overall,
    MAX([Overall]) AS max_overall,
    MIN([Potential]) AS min_potential,
    MAX([Potential]) AS max_potential,
    MIN([Value(in Euro)]) AS min_market_value,
    MAX([Value(in Euro)]) AS max_market_value,
    MIN([Wage(in Euro)]) AS min_wage,
    MAX([Wage(in Euro)]) AS max_wage
FROM dbo.fifa_23_players;


GO

/* ============================================================
   2. Reusable Analysis View
   ============================================================ */

-- Create cleaner column names and a few simple derived fields.
CREATE OR ALTER VIEW dbo.vw_fifa_23_player_market AS
SELECT
    [Known As] AS known_as,
    [Full Name] AS full_name,
    [Overall] AS overall_rating,
    [Potential] AS potential_rating,
    ([Potential] - [Overall]) AS potential_growth,
    [Value(in Euro)] AS market_value_eur,
    [Wage(in Euro)] AS wage_eur,
    [Release Clause] AS release_clause_eur,
    [Best Position] AS best_position,
    [Positions Played] AS positions_played,
    [Nationality] AS nationality,
    [Age] AS age,
    CASE
        WHEN [Age] < 20 THEN 'Under 20'
        WHEN [Age] BETWEEN 20 AND 24 THEN '20-24'
        WHEN [Age] BETWEEN 25 AND 29 THEN '25-29'
        WHEN [Age] BETWEEN 30 AND 34 THEN '30-34'
        ELSE '35+'
    END AS age_band,
    [Height(in cm)] AS height_cm,
    [Weight(in kg)] AS weight_kg,
    [Club Name] AS club_name,
    [Club Position] AS club_position,
    [Contract Until] AS contract_until,
    [Preferred Foot] AS preferred_foot,
    [Weak Foot Rating] AS weak_foot_rating,
    [Skill Moves] AS skill_moves,
    [International Reputation] AS international_reputation,
    [Pace Total] AS pace_total,
    [Shooting Total] AS shooting_total,
    [Passing Total] AS passing_total,
    [Dribbling Total] AS dribbling_total,
    [Defending Total] AS defending_total,
    [Physicality Total] AS physicality_total
FROM dbo.fifa_23_players;


GO

/* ============================================================
   3. Market Overview
   ============================================================ */

-- Top players by market value.
SELECT TOP 20
    known_as,
    age,
    club_name,
    nationality,
    best_position,
    overall_rating,
    potential_rating,
    market_value_eur,
    wage_eur
FROM dbo.vw_fifa_23_player_market
WHERE market_value_eur > 0
ORDER BY market_value_eur DESC;


-- Average value and rating by age band.
-- Insight goal: show where market value peaks across player age groups.
SELECT
    age_band,
    COUNT(*) AS player_count,
    ROUND(AVG(CAST(age AS float)), 1) AS avg_age,
    ROUND(AVG(CAST(overall_rating AS float)), 1) AS avg_overall,
    ROUND(AVG(CAST(potential_rating AS float)), 1) AS avg_potential,
    ROUND(AVG(CAST(potential_growth AS float)), 1) AS avg_potential_growth,
    ROUND(AVG(CAST(market_value_eur AS float)), 0) AS avg_market_value_eur,
    ROUND(AVG(CAST(wage_eur AS float)), 0) AS avg_wage_eur
FROM dbo.vw_fifa_23_player_market
WHERE age IS NOT NULL
GROUP BY age_band
ORDER BY MIN(age);


-- Average value and wage by position.
-- Insight goal: identify expensive positions and compare them with average rating.
SELECT
    best_position,
    COUNT(*) AS player_count,
    ROUND(AVG(CAST(overall_rating AS float)), 1) AS avg_overall,
    ROUND(AVG(CAST(potential_rating AS float)), 1) AS avg_potential,
    ROUND(AVG(CAST(market_value_eur AS float)), 0) AS avg_market_value_eur,
    ROUND(AVG(CAST(wage_eur AS float)), 0) AS avg_wage_eur
FROM dbo.vw_fifa_23_player_market
WHERE best_position IS NOT NULL
GROUP BY best_position
HAVING COUNT(*) >= 100
ORDER BY avg_market_value_eur DESC;


/* ============================================================
   4. Club And Country Insights
   ============================================================ */

-- Clubs with the highest total squad market value.
SELECT TOP 20
    club_name,
    COUNT(*) AS player_count,
    SUM(market_value_eur) AS total_market_value_eur,
    SUM(wage_eur) AS total_weekly_wage_eur,
    ROUND(AVG(CAST(overall_rating AS float)), 1) AS avg_overall,
    ROUND(AVG(CAST(age AS float)), 1) AS avg_age
FROM dbo.vw_fifa_23_player_market
WHERE club_name IS NOT NULL
GROUP BY club_name
HAVING COUNT(*) >= 15
ORDER BY total_market_value_eur DESC;


-- Countries with the deepest high-potential player pool.
SELECT TOP 20
    nationality,
    COUNT(*) AS high_potential_players,
    ROUND(AVG(CAST(age AS float)), 1) AS avg_age,
    ROUND(AVG(CAST(overall_rating AS float)), 1) AS avg_overall,
    ROUND(AVG(CAST(potential_rating AS float)), 1) AS avg_potential,
    SUM(market_value_eur) AS total_market_value_eur
FROM dbo.vw_fifa_23_player_market
WHERE potential_rating >= 80
  AND nationality IS NOT NULL
GROUP BY nationality
ORDER BY high_potential_players DESC, avg_potential DESC;


-- Wage efficiency by club.
-- This compares squad rating against wage cost. Smaller values indicate lower wage cost per rating point.
SELECT TOP 20
    club_name,
    COUNT(*) AS player_count,
    ROUND(AVG(CAST(overall_rating AS float)), 1) AS avg_overall,
    SUM(wage_eur) AS total_weekly_wage_eur,
    CAST(SUM(wage_eur) AS decimal(18, 2)) / NULLIF(SUM(overall_rating), 0) AS wage_per_rating_point
FROM dbo.vw_fifa_23_player_market
WHERE club_name IS NOT NULL
  AND wage_eur > 0
GROUP BY club_name
HAVING COUNT(*) >= 15
ORDER BY wage_per_rating_point ASC;


/* ============================================================
   5. Associate-Level Advanced Analysis
   ============================================================ */

-- Rank players within each position by market value.
-- Technique: RANK() window function.
WITH position_value_rank AS (
    SELECT
        known_as,
        age,
        club_name,
        nationality,
        best_position,
        overall_rating,
        potential_rating,
        market_value_eur,
        RANK() OVER (
            PARTITION BY best_position
            ORDER BY market_value_eur DESC
        ) AS position_value_rank
    FROM dbo.vw_fifa_23_player_market
    WHERE best_position IS NOT NULL
      AND market_value_eur > 0
)
SELECT
    known_as,
    age,
    club_name,
    nationality,
    best_position,
    overall_rating,
    potential_rating,
    market_value_eur,
    position_value_rank
FROM position_value_rank
WHERE position_value_rank <= 5
ORDER BY best_position, position_value_rank;


-- Compare each player to the average market value for their position.
-- Technique: CTE with position averages.
WITH position_averages AS (
    SELECT
        best_position,
        AVG(CAST(market_value_eur AS float)) AS avg_position_value
    FROM dbo.vw_fifa_23_player_market
    WHERE best_position IS NOT NULL
      AND market_value_eur > 0
    GROUP BY best_position
),
player_value_comparison AS (
    SELECT
        p.known_as,
        p.age,
        p.club_name,
        p.best_position,
        p.overall_rating,
        p.potential_rating,
        p.market_value_eur,
        a.avg_position_value,
        p.market_value_eur - a.avg_position_value AS value_vs_position_avg
    FROM dbo.vw_fifa_23_player_market AS p
    INNER JOIN position_averages AS a
        ON p.best_position = a.best_position
    WHERE p.market_value_eur > 0
)
SELECT TOP 25
    known_as,
    age,
    club_name,
    best_position,
    overall_rating,
    potential_rating,
    market_value_eur,
    ROUND(avg_position_value, 0) AS avg_position_value,
    ROUND(value_vs_position_avg, 0) AS value_vs_position_avg
FROM player_value_comparison
WHERE overall_rating >= 75
ORDER BY value_vs_position_avg ASC;


/* ============================================================
   6. Transfer Shortlists
   ============================================================ */

-- Budget shortlist: young players with strong potential under 15M.
SELECT TOP 30
    known_as,
    age,
    club_name,
    nationality,
    best_position,
    overall_rating,
    potential_rating,
    potential_growth,
    market_value_eur,
    wage_eur
FROM dbo.vw_fifa_23_player_market
WHERE age <= 23
  AND potential_rating >= 80
  AND market_value_eur BETWEEN 1 AND 15000000
ORDER BY potential_growth DESC, potential_rating DESC, market_value_eur ASC;


-- Value shortlist: solid current players with a lower cost per overall rating point.
SELECT TOP 30
    known_as,
    age,
    club_name,
    nationality,
    best_position,
    overall_rating,
    potential_rating,
    market_value_eur,
    wage_eur,
    CAST(market_value_eur AS decimal(18, 2)) / NULLIF(overall_rating, 0) AS value_per_overall_point
FROM dbo.vw_fifa_23_player_market
WHERE overall_rating >= 75
  AND market_value_eur > 0
ORDER BY value_per_overall_point ASC, overall_rating DESC;


-- Wide player shortlist for a specific recruitment need.
-- Example business use: finding affordable wide players with pace and dribbling.
SELECT TOP 30
    known_as,
    age,
    club_name,
    nationality,
    best_position,
    overall_rating,
    potential_rating,
    pace_total,
    dribbling_total,
    market_value_eur,
    wage_eur
FROM dbo.vw_fifa_23_player_market
WHERE best_position IN ('LW', 'RW', 'LM', 'RM')
  AND age <= 26
  AND pace_total >= 80
  AND dribbling_total >= 78
  AND market_value_eur BETWEEN 1 AND 25000000
ORDER BY potential_rating DESC, overall_rating DESC, market_value_eur ASC;


/* ============================================================
   7. Final Takeaway Query
   ============================================================ */

-- Final balanced shortlist:
-- players who are young, have room to grow, are already usable, and are below 20M.
-- This is a strong query to screenshot for GitHub because it ties the analysis to a clear decision.
SELECT TOP 25
    known_as,
    age,
    club_name,
    nationality,
    best_position,
    overall_rating,
    potential_rating,
    potential_growth,
    market_value_eur,
    wage_eur,
    CAST(market_value_eur AS decimal(18, 2)) / NULLIF(potential_rating, 0) AS value_per_potential_point
FROM dbo.vw_fifa_23_player_market
WHERE age <= 23
  AND overall_rating >= 68
  AND potential_rating >= 80
  AND potential_growth >= 8
  AND market_value_eur BETWEEN 1 AND 20000000
ORDER BY value_per_potential_point ASC, potential_growth DESC, potential_rating DESC;
