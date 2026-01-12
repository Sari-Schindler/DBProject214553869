CREATE OR REPLACE FUNCTION musiclesson.fn_CheckDiscount(p_sid INT)
RETURNS NUMERIC AS $$
DECLARE
    v_count INT;
BEGIN
    -- ספירת כמות הקורסים של התלמיד
    SELECT COUNT(*) INTO v_count FROM musiclesson.islearning WHERE sid = p_sid;
    
    -- החזרת אחוז הנחה
    IF v_count >= 3 THEN RETURN 0.20; -- 20% הנחה
    ELSIF v_count >= 1 THEN RETURN 0.10; -- 10% הנחה
    ELSE RETURN 0;
    END IF;
END;
$$ LANGUAGE plpgsql;