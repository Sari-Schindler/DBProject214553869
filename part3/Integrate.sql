SET search_path TO MusicLesson;

-------------------------------------------------------
-- 1. שינויי מבנה (Schema Updates)
-------------------------------------------------------

-- עדכון טבלת Teacher
ALTER TABLE Teacher ADD COLUMN specialization VARCHAR(100);

-- עדכון טבלת Student
ALTER TABLE Student ADD COLUMN enterdate DATE DEFAULT CURRENT_DATE;

-- יצירת טבלת Room (חדשה מהאגף השני)
CREATE TABLE Room (
    roomnum SERIAL PRIMARY KEY,
    capacity INTEGER CHECK (capacity >= 0),
    roomname VARCHAR(50) NOT NULL
);

-- עדכון טבלת Lesson
ALTER TABLE Lesson ADD COLUMN llevel VARCHAR(15);
ALTER TABLE Lesson ADD COLUMN lessonday INTEGER CHECK (lessonday BETWEEN 1 AND 6);
ALTER TABLE Lesson ADD COLUMN price NUMERIC(10,2) CHECK (price >= 0);
ALTER TABLE Lesson ADD COLUMN roomnum INT REFERENCES Room(roomnum) ON DELETE SET NULL;

-- יצירת טבלת Feedback
CREATE TABLE Feedback (
    fid SERIAL PRIMARY KEY,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    fdate DATE DEFAULT CURRENT_DATE,
    subject VARCHAR(50),
    SId INT REFERENCES Student(SId) ON DELETE CASCADE
);

-- עדכון טבלת Equipment וקישור לחדרים
ALTER TABLE Equipment ADD COLUMN roomnum INT REFERENCES Room(roomnum);
-- אופציונלי: ALTER TABLE Equipment DROP COLUMN groupid; (רק אם ה-ERD אומר שהציוד כבר לא קשור לקבוצה)

-------------------------------------------------------
-- 2. הזנת נתונים ראשונית (Data Seeding)
-- כדי שהמבטים (Views) לא יהיו ריקים בהרצה ראשונה
-------------------------------------------------------

-- הכנסת חדרים בסיסיים
INSERT INTO Room (capacity, roomname) VALUES 
(15, 'אולם פסנתר מרכזי'),
(10, 'חדר כלי נשיפה'),
(20, 'אולפן הקלטות');

-- עדכון מורים (התמחויות)
UPDATE Teacher SET specialization = 'פסנתר קלאסי' WHERE TId = (SELECT TId FROM Teacher LIMIT 1);
UPDATE Teacher SET specialization = 'גיטרה חשמלית' WHERE TId = (SELECT TId FROM Teacher OFFSET 1 LIMIT 1);

-- שיבוץ שיעורים קיימים לחדרים ומחירים
UPDATE Lesson SET 
    roomnum = (SELECT roomnum FROM Room LIMIT 1),
    price = 150.00,
    lessonday = 1
WHERE LId = (SELECT LId FROM Lesson LIMIT 1);

UPDATE Lesson SET 
    roomnum = (SELECT roomnum FROM Room OFFSET 1 LIMIT 1),
    price = 120.00,
    lessonday = 2
WHERE LId = (SELECT LId FROM Lesson OFFSET 1 LIMIT 1);