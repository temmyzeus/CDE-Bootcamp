
{{ config(materialized='table') }}

select
  "Team" as Team,
  "Winners" as NumCupsWon,
  "Runners-up" as NumRunnersUp,
  "Total finals" as TotalFinalsPlayed,
  CASE
    WHEN "Years won" = '—' THEN Null
    ELSE "Years won"
  END as YearsWon,
  CASE
    WHEN "Years runners-up" = '—' THEN Null
    ELSE "Years runners-up"
  END as YearsAsRunnersUp
from worldcup_stg
