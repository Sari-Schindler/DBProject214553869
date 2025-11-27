SET search_path TO MusicLesson;

UPDATE Teacher t
SET Salary = Salary * 1.3
FROM Lesson l
WHERE l.TId = t.TId
  AND l.LessonType = 'Piano';
