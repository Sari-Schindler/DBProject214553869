SET search_path TO MusicLesson;

-- 1. עדכון טבלת Teacher (הוספת התמחות)
ALTER TABLE Teacher ADD COLUMN specialization VARCHAR(100);

-- 2. עדכון טבלת Student (הוספת תאריך הצטרפות ושינוי שם השדות להתאמה)
ALTER TABLE Student ADD COLUMN enterdate DATE DEFAULT CURRENT_DATE;

-- 3. יצירת טבלת Room (חדשה מהאגף השני)
CREATE TABLE Room (
    roomnum SERIAL PRIMARY KEY,
    capacity INTEGER CHECK (capacity >= 0),
    roomname VARCHAR(50) NOT NULL
);

-- 4. עדכון טבלת Lesson (הוספת מחיר, יום בשבוע וקישור לחדר)
ALTER TABLE Lesson ADD COLUMN llevel VARCHAR(15);
ALTER TABLE Lesson ADD COLUMN lessonday INTEGER CHECK (lessonday BETWEEN 1 AND 6);
ALTER TABLE Lesson ADD COLUMN price NUMERIC(10,2) CHECK (price >= 0);
ALTER TABLE Lesson ADD COLUMN roomnum INT REFERENCES Room(roomnum) ON DELETE SET NULL;

-- 5. יצירת טבלת Feedback (חדשה מהאגף השני)
CREATE TABLE Feedback (
    fid SERIAL PRIMARY KEY,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    fdate DATE DEFAULT CURRENT_DATE,
    subject VARCHAR(50),
    SId INT REFERENCES Student(SId) ON DELETE CASCADE
);

-- 6. העברת נתוני ציוד (Equipment) לקישור מול חדרים במקום כיתות (לפי ה-ERD המשולב)
ALTER TABLE Equipment ADD COLUMN roomnum INT REFERENCES Room(roomnum);