SET search_path TO MusicLesson;

-- Query 2: Average salary of teachers per lesson type
SELECT 
    l.LessonType,
    ROUND(AVG(t.Salary), 2) AS "Average Salary"
FROM Lesson l
JOIN Teacher t ON l.TId = t.TId
GROUP BY l.LessonType
ORDER BY "Average Salary" DESC;
