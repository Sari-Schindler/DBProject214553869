-- SET SCHEMA
SET search_path TO MusicLesson;

-- 1️ CHECK - Teacher.Salary
ALTER TABLE Teacher
ADD CONSTRAINT check_salary_positive CHECK (Salary >= 0);


-- 2️ NOT NULL - Lesson.Duration
ALTER TABLE Lesson
ALTER COLUMN Duration SET NOT NULL;


-- 3️ DEFAULT - Class.MaxStudents
ALTER TABLE Class
ALTER COLUMN MaxStudents SET DEFAULT 20;


