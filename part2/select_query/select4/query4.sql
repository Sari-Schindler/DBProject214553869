SET search_path TO MusicLesson;

-- Query 4: Lessons opened this year
SELECT 
    LName,
    openDate,
    LessonType
FROM Lesson
WHERE EXTRACT(YEAR FROM openDate) = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY openDate DESC;
