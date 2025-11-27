-- ==========================================
-- SET SCHEMA
SET search_path TO MusicLesson;

-- ==========================================
BEGIN;

--  עדכון שכר המורים של Piano ב-30%
UPDATE Teacher t
SET Salary = Salary * 1.3
FROM Lesson l
WHERE l.TId = t.TId
  AND l.LessonType = 'Piano';

--  הצגת השכר לאחר העדכון 
SELECT * FROM Teacher;

--  COMMIT - לשמירת השינויים
 COMMIT;


SET search_path TO MusicLesson;

-- ==========================================
BEGIN;

--  עדכון שכר המורים של Piano ב-30%
UPDATE Teacher t
SET Salary = Salary * 1.3
FROM Lesson l
WHERE l.TId = t.TId
  AND l.LessonType = 'Piano';

--  הצגת השכר לאחר העדכון 
SELECT * FROM Teacher;

--  ROLLBACK - לביטול השינויים
ROLLBACK;