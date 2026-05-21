# FIFA 23 SQL Analysis

This SQL project analyzes FIFA 23 player data to understand market value patterns and identify practical transfer targets.

## Business Question

How can a club compare players by age, position, club, nationality, wage, and potential to find strong-value transfer options?

## Tools

- SQL Server
- SSMS
- FIFA 23 player dataset

## Analyst Skills Shown

- Data quality checks
- Reusable SQL view
- `CASE` statements for age-band segmentation
- Aggregations by position, club, and nationality
- CTEs for comparison analysis
- `RANK()` window function for position-level rankings
- Transfer shortlist filtering

## Key Analyses

- Market value and wage trends by age band
- Average player value by position
- Clubs with the highest total squad market value
- Countries with the deepest high-potential player pools
- Wage efficiency by club
- Top players within each position by market value
- Shortlists for young, affordable, high-potential players

## Files

- `fifa_23_player_market_analysis.sql`: main SQL analysis script
- Source table: `dbo.fifa_23_players`
- Analysis view: `dbo.vw_fifa_23_player_market`

## Summary

This project uses SQL to move from raw player data to business-focused insights that could support scouting and transfer decisions. The analysis balances simple reporting with associate-level SQL techniques such as CTEs, segmentation, and window functions.
