UPDATE Lesson l
SET openDate = DATE '2025-12-01'
WHERE LId IN (
    SELECT l2.LId
    FROM Lesson l2
    JOIN Class c ON l2.CId = c.CId
    JOIN isLearning il ON il.LId = l2.LId
    GROUP BY l2.LId, c.CId
    HAVING COUNT(il.SId) < 5
)
AND LessonType = 'Piano';
