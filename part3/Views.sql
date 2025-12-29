SET search_path TO MusicLesson;

-- מחיקת המבטים הקיימים כדי לאפשר שינוי מבנה עמודות
DROP VIEW IF EXISTS LessonAssignments;
DROP VIEW IF EXISTS StudentSatisfactionReport;

-------------------------------------------------------
-- יצירה מחדש של מבט 1 (עם העמודה החדשה)
-------------------------------------------------------
CREATE VIEW LessonAssignments AS
SELECT 
    L.LName AS "שם השיעור", 
    L.llevel AS "רמת השיעור", 
    T.TName AS "שם המורה", 
    R.roomname AS "שם החדר"
FROM Lesson L
LEFT JOIN Teacher T ON L.TId = T.TId
LEFT JOIN Room R ON L.roomnum = R.roomnum;

-------------------------------------------------------
-- יצירה מחדש של מבט 2
-------------------------------------------------------
CREATE VIEW StudentSatisfactionReport AS
SELECT 
    S.SName AS "שם התלמיד",
    F.subject AS "נושא המשוב",
    F.rating AS "ציון",
    CASE 
        WHEN F.rating >= 4 THEN 'High Satisfaction'
        WHEN F.rating = 3 THEN 'Satisfactory'
        ELSE 'Needs Improvement'
    END AS "סטטוס שביעות רצון",
    F.fdate AS "תאריך המשוב"
FROM Feedback F
JOIN Student S ON F.SId = S.SId;