CREATE OR REPLACE PROCEDURE musiclesson.pr_SafeRegister(p_sid INT, p_lid INT)
AS $$
DECLARE
    -- הגדרת קורסור מפורש (Explicit Cursor) - מענה ישיר לדרישת המרצה
    cursor_student_courses CURSOR FOR 
        SELECT l.LName, l.LessonType 
        FROM musiclesson.islearning il
        JOIN musiclesson.lesson l ON il.lid = l.lid
        WHERE il.sid = p_sid;
        
    v_course_name TEXT;
    v_course_type TEXT;
    v_new_course_type TEXT;
    v_found_duplicate BOOLEAN := FALSE;
BEGIN
    -- שליפת סוג הקורס החדש
    SELECT LessonType INTO v_new_course_type FROM musiclesson.lesson WHERE lid = p_lid;

    RAISE NOTICE 'מתחיל סריקה מפורשת של קורסי התלמיד (SID: %)...', p_sid;

    -- פתיחת הקורסור ומעבר בלולאה (Loop)
    OPEN cursor_student_courses;
    LOOP
        FETCH cursor_student_courses INTO v_course_name, v_course_type;
        EXIT WHEN NOT FOUND;

        IF v_course_type = v_new_course_type THEN
            RAISE NOTICE 'התראה: התלמיד כבר לומד קורס מסוג % (שם הקורס: %)', v_course_type, v_course_name;
            v_found_duplicate := TRUE;
        END IF;
    END LOOP;
    CLOSE cursor_student_courses;

    IF v_found_duplicate THEN
        RAISE NOTICE 'הרישום מבוצע למרות קיום קורס דומה (מדיניות מוסד).';
    END IF;

    INSERT INTO musiclesson.islearning (sid, lid) VALUES (p_sid, p_lid);
    RAISE NOTICE 'הרישום לשיעור % הושלם בהצלחה.', p_lid;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'שגיאה: התלמיד כבר רשום ספציפית לשיעור מספר %', p_lid;
    WHEN OTHERS THEN
        RAISE NOTICE 'שגיאה לא צפויה: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;