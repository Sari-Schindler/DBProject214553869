CREATE OR REPLACE FUNCTION musiclesson.fn_LimitStudents()
RETURNS TRIGGER AS $$
DECLARE
    v_max INT := 20; -- קיבולת ברירת מחדל למניעת שגיאות מבנה טבלה
    v_current INT;
BEGIN
    -- ספירת תלמידים רשומים לשיעור הספציפי
    SELECT COUNT(*) INTO v_current FROM musiclesson.islearning WHERE lid = NEW.lid;

    -- בדיקה מול הקיבולת
    IF v_current >= v_max THEN
        RAISE EXCEPTION 'החדר מלא! תפוסה מקסימלית: %', v_max;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- יצירת הטריגר על טבלת הרישום
DROP TRIGGER IF EXISTS trg_RoomLimit ON musiclesson.islearning;
CREATE TRIGGER trg_RoomLimit
BEFORE INSERT ON musiclesson.islearning
FOR EACH ROW EXECUTE FUNCTION musiclesson.fn_LimitStudents();