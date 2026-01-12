DO $$
DECLARE
    v_sid INT;
    v_lid INT;
BEGIN
    -- שליפת תלמיד ושיעור שקיימים באמת בטבלאות שלך
    SELECT sid INTO v_sid FROM musiclesson.student LIMIT 1;
    SELECT lid INTO v_lid FROM musiclesson.lesson LIMIT 1;

    RAISE NOTICE '--- בדיקת חלק 2: הנחות ורישום תלמידים ---';
    
    -- בדיקת פונקציית ההנחה על התלמיד שמצאנו
    RAISE NOTICE 'בדיקת הנחה עבור תלמיד מספר %: % %%', v_sid, (musiclesson.fn_CheckDiscount(v_sid) * 100);
    
    -- ניסיון רישום של התלמיד לשיעור
    RAISE NOTICE 'מנסה לרשום תלמיד % לשיעור %...', v_sid, v_lid;
    CALL musiclesson.pr_SafeRegister(v_sid, v_lid); 
    
    RAISE NOTICE '--- סיום בדיקה ---';
END $$;