SET search_path TO MusicLesson;
-- Query 1: Number of activities per month and year
SELECT 
    EXTRACT(YEAR FROM ActivityDate) AS "Year",
    EXTRACT(MONTH FROM ActivityDate) AS "Month",
    COUNT(AId) AS "Number of Activities"
FROM Activity
GROUP BY EXTRACT(YEAR FROM ActivityDate), EXTRACT(MONTH FROM ActivityDate)
ORDER BY "Year", "Month";
