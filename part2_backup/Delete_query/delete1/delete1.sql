SET search_path TO MusicLesson;

-- מחיקה של תלמידים שלא לומדים בשום שיעור
DELETE FROM Student s
WHERE NOT EXISTS (
    SELECT 1
    FROM isLearning il
    WHERE il.SId = s.SId
);
