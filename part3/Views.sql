SET search_path TO MusicLesson;

-- הגדרת מבט 1
CREATE OR REPLACE VIEW LessonAssignments AS
SELECT 
    L.LName AS "שם השיעור", 
    T.TName AS "שם המורה", 
    R.roomname AS "שם החדר"
FROM Lesson L
LEFT JOIN Teacher T ON L.TId = T.TId
LEFT JOIN Room R ON L.roomnum = R.roomnum;

-- הגדרת מבט 2
CREATE OR REPLACE VIEW StudentSatisfactionReport AS
SELECT 
    S.SName AS "שם התלמיד",
    F.subject AS "נושא המשוב",
    F.rating AS "ציון",
    CASE 
        WHEN F.rating >= 4 THEN 'שביעות רצון גבוהה'
        WHEN F.rating = 3 THEN 'בינוני'
        ELSE 'דורש שיפור'
    END AS "סטטוס שביעות רצון",
    F.fdate AS "תאריך המשוב"
FROM Feedback F
JOIN Student S ON F.SId = S.SId;