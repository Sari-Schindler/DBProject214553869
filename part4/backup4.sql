--
-- PostgreSQL database dump
--

\restrict xgcdvL9h9doKO1XJyY5WFeJ84m7NtPXli7m32NOo2LZb92w4yauyPur5XyIXY1D

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-01-12 11:26:49

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 6 (class 2615 OID 16952)
-- Name: musiclesson; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA musiclesson;


--
-- TOC entry 244 (class 1255 OID 25446)
-- Name: fn_checkdiscount(integer); Type: FUNCTION; Schema: musiclesson; Owner: -
--

CREATE FUNCTION musiclesson.fn_checkdiscount(p_sid integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 245 (class 1255 OID 25442)
-- Name: fn_getteacherschedule(integer); Type: FUNCTION; Schema: musiclesson; Owner: -
--

CREATE FUNCTION musiclesson.fn_getteacherschedule(p_tid integer) RETURNS refcursor
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- הגדרת הסמן (Ref Cursor)
    my_cursor REFCURSOR := 'teacher_schedule_cursor';
BEGIN
    -- בדיקה אם המורה קיים בבסיס הנתונים
    IF NOT EXISTS (SELECT 1 FROM musiclesson.teacher WHERE tid = p_tid) THEN
        RAISE EXCEPTION 'מורה עם מזהה % לא נמצא במערכת.', p_tid;
    END IF;

    -- פתיחת הסמן עבור השאילתה המבוקשת
    OPEN my_cursor FOR 
        SELECT l.lname, l.price, r.roomname
        FROM musiclesson.lesson l
        LEFT JOIN musiclesson.room r ON l.roomnum = r.roomnum
        WHERE l.tid = p_tid;

    RETURN my_cursor;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'שגיאה בפונקציה: %', SQLERRM;
        RETURN NULL;
END;
$$;


--
-- TOC entry 259 (class 1255 OID 25447)
-- Name: fn_limitstudents(); Type: FUNCTION; Schema: musiclesson; Owner: -
--

CREATE FUNCTION musiclesson.fn_limitstudents() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;


--
-- TOC entry 247 (class 1255 OID 25444)
-- Name: fn_logpricechange(); Type: FUNCTION; Schema: musiclesson; Owner: -
--

CREATE FUNCTION musiclesson.fn_logpricechange() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO musiclesson.Price_Audit_Log (lid, old_price, new_price)
    VALUES (OLD.lid, OLD.price, NEW.price);
    RETURN NEW;
END;
$$;


--
-- TOC entry 260 (class 1255 OID 25449)
-- Name: pr_saferegister(integer, integer); Type: PROCEDURE; Schema: musiclesson; Owner: -
--

CREATE PROCEDURE musiclesson.pr_saferegister(IN p_sid integer, IN p_lid integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rec RECORD; -- שימוש ב-Record
BEGIN
    RAISE NOTICE 'בדיקת קורסים קיימים לתלמיד:';
    -- לולאת FOR שהיא למעשה Cursor מפורש
    FOR v_rec IN SELECT lid FROM musiclesson.islearning WHERE sid = p_sid LOOP
        RAISE NOTICE 'התלמיד כבר רשום לשיעור מספר %', v_rec.lid;
    END LOOP;

    INSERT INTO musiclesson.islearning (sid, lid) VALUES (p_sid, p_lid);
    RAISE NOTICE 'התלמיד נרשם בהצלחה!';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'שגיאה: %', SQLERRM;
END;
$$;


--
-- TOC entry 246 (class 1255 OID 25443)
-- Name: pr_updatelessonprices(numeric); Type: PROCEDURE; Schema: musiclesson; Owner: -
--

CREATE PROCEDURE musiclesson.pr_updatelessonprices(IN p_increase_rate numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_lesson RECORD;
    v_old_price NUMERIC;
    v_new_price NUMERIC;
BEGIN
    FOR v_lesson IN SELECT lid, lname, price FROM musiclesson.lesson WHERE llevel = 'Advanced' LOOP
        v_old_price := v_lesson.price;
        v_new_price := v_old_price * (1 + p_increase_rate);

        UPDATE musiclesson.lesson 
        SET price = v_new_price 
        WHERE lid = v_lesson.lid;

        RAISE NOTICE 'עודכן שיעור: %, מחיר ישן: %, מחיר חדש: %', 
                     v_lesson.lname, v_old_price, ROUND(v_new_price, 2);
    END LOOP;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 229 (class 1259 OID 16989)
-- Name: activity; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.activity (
    aid integer NOT NULL,
    place character varying(100),
    activitydate date,
    description text
);


--
-- TOC entry 228 (class 1259 OID 16988)
-- Name: activity_aid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.activity_aid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5159 (class 0 OID 0)
-- Dependencies: 228
-- Name: activity_aid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.activity_aid_seq OWNED BY musiclesson.activity.aid;


--
-- TOC entry 225 (class 1259 OID 16972)
-- Name: class; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.class (
    cid integer NOT NULL,
    cname character varying(100) NOT NULL,
    maxstudents integer DEFAULT 20
);


--
-- TOC entry 224 (class 1259 OID 16971)
-- Name: class_cid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.class_cid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5160 (class 0 OID 0)
-- Dependencies: 224
-- Name: class_cid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.class_cid_seq OWNED BY musiclesson.class.cid;


--
-- TOC entry 227 (class 1259 OID 16981)
-- Name: equipment; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.equipment (
    eid integer NOT NULL,
    type character varying(50),
    color character varying(50),
    roomnum integer
);


--
-- TOC entry 226 (class 1259 OID 16980)
-- Name: equipment_eid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.equipment_eid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5161 (class 0 OID 0)
-- Dependencies: 226
-- Name: equipment_eid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.equipment_eid_seq OWNED BY musiclesson.equipment.eid;


--
-- TOC entry 238 (class 1259 OID 25388)
-- Name: feedback; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.feedback (
    fid integer NOT NULL,
    rating integer,
    fdate date DEFAULT CURRENT_DATE,
    subject character varying(50),
    sid integer,
    CONSTRAINT feedback_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


--
-- TOC entry 237 (class 1259 OID 25387)
-- Name: feedback_fid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.feedback_fid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5162 (class 0 OID 0)
-- Dependencies: 237
-- Name: feedback_fid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.feedback_fid_seq OWNED BY musiclesson.feedback.fid;


--
-- TOC entry 234 (class 1259 OID 17049)
-- Name: ishaving; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.ishaving (
    cid integer NOT NULL,
    eid integer NOT NULL
);


--
-- TOC entry 232 (class 1259 OID 17015)
-- Name: islearning; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.islearning (
    sid integer NOT NULL,
    lid integer NOT NULL
);


--
-- TOC entry 231 (class 1259 OID 16997)
-- Name: lesson; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.lesson (
    lid integer NOT NULL,
    lname character varying(100) NOT NULL,
    duration integer NOT NULL,
    lessontype character varying(50),
    opendate date,
    cid integer,
    tid integer,
    llevel character varying(15),
    lessonday integer,
    price numeric(10,2),
    roomnum integer,
    CONSTRAINT lesson_lessonday_check CHECK (((lessonday >= 1) AND (lessonday <= 6))),
    CONSTRAINT lesson_price_check CHECK ((price >= (0)::numeric))
);


--
-- TOC entry 230 (class 1259 OID 16996)
-- Name: lesson_lid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.lesson_lid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5163 (class 0 OID 0)
-- Dependencies: 230
-- Name: lesson_lid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.lesson_lid_seq OWNED BY musiclesson.lesson.lid;


--
-- TOC entry 236 (class 1259 OID 25371)
-- Name: room; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.room (
    roomnum integer NOT NULL,
    capacity integer,
    roomname character varying(50) NOT NULL,
    CONSTRAINT room_capacity_check CHECK ((capacity >= 0))
);


--
-- TOC entry 221 (class 1259 OID 16954)
-- Name: teacher; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.teacher (
    tid integer NOT NULL,
    tname character varying(100) NOT NULL,
    salary numeric(10,2),
    email character varying(150),
    specialization character varying(100),
    CONSTRAINT check_salary_positive CHECK ((salary >= (0)::numeric))
);


--
-- TOC entry 240 (class 1259 OID 25421)
-- Name: lessonassignments; Type: VIEW; Schema: musiclesson; Owner: -
--

CREATE VIEW musiclesson.lessonassignments AS
 SELECT l.lname AS "שם השיעור",
    l.llevel AS "רמת השיעור",
    t.tname AS "שם המורה",
    r.roomname AS "שם החדר"
   FROM ((musiclesson.lesson l
     LEFT JOIN musiclesson.teacher t ON ((l.tid = t.tid)))
     LEFT JOIN musiclesson.room r ON ((l.roomnum = r.roomnum)));


--
-- TOC entry 233 (class 1259 OID 17032)
-- Name: participatesin; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.participatesin (
    sid integer NOT NULL,
    aid integer NOT NULL
);


--
-- TOC entry 243 (class 1259 OID 25431)
-- Name: price_audit_log; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.price_audit_log (
    log_id integer NOT NULL,
    lid integer,
    old_price numeric(10,2),
    new_price numeric(10,2),
    change_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    user_performing_change text DEFAULT CURRENT_USER
);


--
-- TOC entry 242 (class 1259 OID 25430)
-- Name: price_audit_log_log_id_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.price_audit_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5164 (class 0 OID 0)
-- Dependencies: 242
-- Name: price_audit_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.price_audit_log_log_id_seq OWNED BY musiclesson.price_audit_log.log_id;


--
-- TOC entry 235 (class 1259 OID 25370)
-- Name: room_roomnum_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.room_roomnum_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5165 (class 0 OID 0)
-- Dependencies: 235
-- Name: room_roomnum_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.room_roomnum_seq OWNED BY musiclesson.room.roomnum;


--
-- TOC entry 223 (class 1259 OID 16963)
-- Name: student; Type: TABLE; Schema: musiclesson; Owner: -
--

CREATE TABLE musiclesson.student (
    sid integer NOT NULL,
    sname character varying(100) NOT NULL,
    address character varying(200),
    enterdate date DEFAULT CURRENT_DATE
);


--
-- TOC entry 222 (class 1259 OID 16962)
-- Name: student_sid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.student_sid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5166 (class 0 OID 0)
-- Dependencies: 222
-- Name: student_sid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.student_sid_seq OWNED BY musiclesson.student.sid;


--
-- TOC entry 239 (class 1259 OID 25411)
-- Name: studentfeedbackdetails; Type: VIEW; Schema: musiclesson; Owner: -
--

CREATE VIEW musiclesson.studentfeedbackdetails AS
 SELECT s.sname AS "שם התלמיד",
    f.rating AS "דירוג",
    f.subject AS "נושא"
   FROM (musiclesson.feedback f
     JOIN musiclesson.student s ON ((f.sid = s.sid)));


--
-- TOC entry 241 (class 1259 OID 25426)
-- Name: studentsatisfactionreport; Type: VIEW; Schema: musiclesson; Owner: -
--

CREATE VIEW musiclesson.studentsatisfactionreport AS
 SELECT s.sname AS "שם התלמיד",
    f.subject AS "נושא המשוב",
    f.rating AS "ציון",
        CASE
            WHEN (f.rating >= 4) THEN 'High Satisfaction'::text
            WHEN (f.rating = 3) THEN 'Satisfactory'::text
            ELSE 'Needs Improvement'::text
        END AS "סטטוס שביעות רצון",
    f.fdate AS "תאריך המשוב"
   FROM (musiclesson.feedback f
     JOIN musiclesson.student s ON ((f.sid = s.sid)));


--
-- TOC entry 220 (class 1259 OID 16953)
-- Name: teacher_tid_seq; Type: SEQUENCE; Schema: musiclesson; Owner: -
--

CREATE SEQUENCE musiclesson.teacher_tid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 5167 (class 0 OID 0)
-- Dependencies: 220
-- Name: teacher_tid_seq; Type: SEQUENCE OWNED BY; Schema: musiclesson; Owner: -
--

ALTER SEQUENCE musiclesson.teacher_tid_seq OWNED BY musiclesson.teacher.tid;


--
-- TOC entry 4933 (class 2604 OID 16992)
-- Name: activity aid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.activity ALTER COLUMN aid SET DEFAULT nextval('musiclesson.activity_aid_seq'::regclass);


--
-- TOC entry 4930 (class 2604 OID 16975)
-- Name: class cid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.class ALTER COLUMN cid SET DEFAULT nextval('musiclesson.class_cid_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 16984)
-- Name: equipment eid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.equipment ALTER COLUMN eid SET DEFAULT nextval('musiclesson.equipment_eid_seq'::regclass);


--
-- TOC entry 4936 (class 2604 OID 25391)
-- Name: feedback fid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.feedback ALTER COLUMN fid SET DEFAULT nextval('musiclesson.feedback_fid_seq'::regclass);


--
-- TOC entry 4934 (class 2604 OID 17000)
-- Name: lesson lid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.lesson ALTER COLUMN lid SET DEFAULT nextval('musiclesson.lesson_lid_seq'::regclass);


--
-- TOC entry 4938 (class 2604 OID 25434)
-- Name: price_audit_log log_id; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.price_audit_log ALTER COLUMN log_id SET DEFAULT nextval('musiclesson.price_audit_log_log_id_seq'::regclass);


--
-- TOC entry 4935 (class 2604 OID 25374)
-- Name: room roomnum; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.room ALTER COLUMN roomnum SET DEFAULT nextval('musiclesson.room_roomnum_seq'::regclass);


--
-- TOC entry 4928 (class 2604 OID 16966)
-- Name: student sid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.student ALTER COLUMN sid SET DEFAULT nextval('musiclesson.student_sid_seq'::regclass);


--
-- TOC entry 4927 (class 2604 OID 16957)
-- Name: teacher tid; Type: DEFAULT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.teacher ALTER COLUMN tid SET DEFAULT nextval('musiclesson.teacher_tid_seq'::regclass);


--
-- TOC entry 5142 (class 0 OID 16989)
-- Dependencies: 229
-- Data for Name: activity; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.activity (aid, place, activitydate, description) FROM stdin;
46	Beausejour	2028-08-15	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
47	Gengma	2026-05-17	Cras non velit nec nisi vulputate nonummy.
48	Chak Two Hundred Forty-Nine TDA	2028-03-12	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
49	Nyíregyháza	2027-05-15	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
50	Darovskoy	2027-11-16	Nullam varius. Nulla facilisi.
51	Kujama	2028-06-06	Pellentesque viverra pede ac diam.
52	Madrid	2025-12-29	Duis mattis egestas metus. Aenean fermentum.
53	Knivsta	2028-05-20	Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla. Nunc purus.
54	Courtaboeuf	2027-06-06	Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla.
55	Santa Rosa de Lima	2026-02-23	Donec semper sapien a libero.
56	Tian’an	2026-01-11	Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem.
57	Banjar Baleagung	2026-08-19	Nulla ac enim.
58	Baochang	2026-08-03	Aenean lectus.
59	Gur’yevsk	2028-11-15	Proin leo odio, porttitor id, consequat in, consequat ut, nulla.
60	Gardutanjak	2026-02-16	Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est.
61	Voskopojë	2026-01-14	Morbi vel lectus in quam fringilla rhoncus.
62	Rafael Hernandez Ochoa	2027-11-25	Proin risus. Praesent lectus.
63	Gaza	2027-07-29	Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
64	Bochum	2026-12-12	Morbi a ipsum. Integer a nibh.
65	Patiya	2027-08-13	Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla.
66	Wulan	2028-10-10	In eleifend quam a odio.
67	Pocohuanca	2028-03-18	Pellentesque viverra pede ac diam.
68	Machico	2027-07-06	Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla.
69	Thị Trấn Mù Cang Chải	2026-05-06	Mauris sit amet eros.
70	Ribas do Rio Pardo	2026-04-03	Nulla facilisi.
71	Toroy	2027-09-11	Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla.
72	Purwa	2027-03-25	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
73	Lido	2027-05-27	Maecenas tincidunt lacus at velit. Vivamus vel nulla eget eros elementum pellentesque.
74	Muff	2027-12-02	Vestibulum rutrum rutrum neque.
75	Lendava	2027-01-02	In blandit ultrices enim.
76	Hecun	2028-11-12	Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.
77	Dengtang	2025-12-30	Praesent id massa id nisl venenatis lacinia.
78	Huayuan	2027-05-19	Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla.
79	Novyy Nekouz	2026-01-06	Nullam sit amet turpis elementum ligula vehicula consequat.
80	Marigot	2027-09-02	Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo.
81	Santiago De Compostela	2027-02-06	In congue. Etiam justo.
82	Ningxi	2027-03-20	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio. Curabitur convallis.
83	Oslo	2026-07-31	Nulla justo. Aliquam quis turpis eget elit sodales scelerisque.
84	Zhongguanyi	2027-10-09	Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl.
85	Banjar Sambangan	2028-05-28	Ut at dolor quis odio consequat varius.
86	Simpangpasir	2028-07-30	Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem.
87	Yag La	2027-11-07	Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti.
88	Kuanda	2027-06-27	Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.
89	Serednye	2028-09-03	Aenean fermentum.
90	Svetlogorsk	2027-03-06	Integer non velit.
91	Ylöjärvi	2026-02-15	Donec diam neque, vestibulum eget, vulputate ut, ultrices vel, augue. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi.
92	Sult	2026-12-09	Curabitur at ipsum ac tellus semper interdum. Mauris ullamcorper purus sit amet nulla.
93	Sindangrasa	2027-12-02	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc.
94	Neuquén	2026-09-16	Fusce consequat. Nulla nisl.
95	Binlod	2026-02-18	Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa.
96	Waru	2028-05-23	Nunc rhoncus dui vel sem.
97	Fengqiao	2028-08-30	Aenean fermentum.
98	Irbit	2028-02-14	Aliquam erat volutpat. In congue.
99	Santa Teresa	2026-06-10	Fusce consequat.
100	Alejal	2028-03-25	Nulla nisl.
101	Rudo	2027-08-24	In blandit ultrices enim.
102	Puolanka	2026-10-29	Proin leo odio, porttitor id, consequat in, consequat ut, nulla.
103	Dome	2026-02-27	Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci. Nullam molestie nibh in lectus.
104	Šid	2026-04-28	Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis.
105	Zhongba	2028-01-05	Nullam varius. Nulla facilisi.
106	Poniklá	2028-01-26	Duis mattis egestas metus.
107	Dembī Dolo	2028-01-30	Duis bibendum. Morbi non quam nec dui luctus rutrum.
108	Kikinda	2027-01-22	Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa. Donec dapibus.
109	Shanjiang	2028-05-21	Pellentesque ultrices mattis odio. Donec vitae nisi.
110	Banyubang	2027-04-07	Vestibulum sed magna at nunc commodo placerat.
111	Nariño	2026-06-15	In sagittis dui vel nisl. Duis ac nibh.
112	Šilheřovice	2026-03-31	Morbi quis tortor id nulla ultrices aliquet.
113	Pingdu	2028-07-08	Morbi non lectus.
114	Balingueo	2026-09-21	In est risus, auctor sed, tristique in, tempus sit amet, sem. Fusce consequat.
115	Chotcza	2027-11-10	Mauris lacinia sapien quis libero.
116	Rio Grande da Serra	2028-08-07	Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem.
117	Naschel	2027-12-05	Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla.
118	Guangli	2028-03-16	In hac habitasse platea dictumst. Etiam faucibus cursus urna.
119	La Eduvigis	2026-05-29	Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo.
120	Zhengcun	2027-03-08	Suspendisse potenti. Cras in purus eu magna vulputate luctus.
121	Tegalagung	2027-11-29	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem.
122	El Colorado	2026-04-27	In sagittis dui vel nisl. Duis ac nibh.
123	Mahébourg	2028-10-09	Phasellus sit amet erat. Nulla tempus.
124	Lobito	2028-05-16	Vestibulum sed magna at nunc commodo placerat.
125	Coruña, A	2028-02-17	Vivamus in felis eu sapien cursus vestibulum. Proin eu mi.
126	Pingsha	2026-03-10	Phasellus id sapien in sapien iaculis congue. Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.
127	Daliuhao	2027-03-25	Donec quis orci eget orci vehicula condimentum. Curabitur in libero ut massa volutpat convallis.
128	Jinnan	2028-03-23	Integer ac leo.
129	Pompéia	2026-10-24	Mauris sit amet eros. Suspendisse accumsan tortor quis turpis.
130	Garoua Boulaï	2027-12-19	Morbi a ipsum. Integer a nibh.
131	Uk	2028-07-05	Integer tincidunt ante vel ipsum. Praesent blandit lacinia erat.
132	Luboń	2026-03-14	Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante. Nulla justo.
133	Växjö	2026-08-10	Nulla tempus. Vivamus in felis eu sapien cursus vestibulum.
134	Xiadian	2026-05-16	Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.
135	Tanguá	2027-06-21	Praesent id massa id nisl venenatis lacinia. Aenean sit amet justo.
136	Feondari	2027-06-17	In eleifend quam a odio.
137	Yuanjue	2026-08-17	Praesent blandit lacinia erat. Vestibulum sed magna at nunc commodo placerat.
138	Mengxi	2028-07-04	In hac habitasse platea dictumst. Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem.
139	Blois	2026-12-06	Suspendisse accumsan tortor quis turpis.
140	Calebasses	2027-10-20	Etiam justo. Etiam pretium iaculis justo.
141	Gampaha	2026-11-25	In quis justo.
142	Yauca	2028-02-03	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem.
143	Šenov	2027-10-29	Pellentesque at nulla. Suspendisse potenti.
144	Timon	2028-10-26	Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum.
145	Bagratashen	2027-02-18	Sed ante. Vivamus tortor.
146	Sukogunungkrajan	2026-07-02	Nullam porttitor lacus at turpis.
147	Güines	2026-07-02	Phasellus sit amet erat. Nulla tempus.
148	Pelópion	2028-07-30	Fusce consequat.
149	Međa	2027-01-06	Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede.
150	Huangbu	2027-03-27	Vivamus tortor. Duis mattis egestas metus.
151	Nagasari	2028-07-18	In hac habitasse platea dictumst.
152	Irupi	2028-03-31	Nulla ut erat id mauris vulputate elementum.
153	Jiangtun	2027-04-09	Proin risus.
154	Setun’	2028-10-20	Sed vel enim sit amet nunc viverra dapibus.
155	Krosno Odrzańskie	2027-01-14	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam.
156	Cardal	2028-07-18	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc.
157	Dongtuan	2026-08-21	Vivamus in felis eu sapien cursus vestibulum. Proin eu mi.
158	Coutances	2026-01-05	Maecenas ut massa quis augue luctus tincidunt.
159	Castanheira	2026-09-07	Donec semper sapien a libero.
160	Matur	2026-07-20	Donec quis orci eget orci vehicula condimentum.
161	Caxambu	2026-09-17	Duis consequat dui nec nisi volutpat eleifend.
162	Pulangbato	2027-03-09	Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat.
163	Saint Helier	2028-05-08	Morbi vel lectus in quam fringilla rhoncus.
164	Borovo	2028-10-06	Fusce consequat. Nulla nisl.
165	Mae Hi	2027-08-01	Duis consequat dui nec nisi volutpat eleifend.
166	Leiling	2026-06-16	Aliquam non mauris. Morbi non lectus.
167	Umeå	2026-01-21	Suspendisse potenti. In eleifend quam a odio.
168	Ettal	2027-10-02	In congue. Etiam justo.
169	Porciúncula	2028-11-07	Pellentesque at nulla.
170	Pankrushikha	2027-01-27	In hac habitasse platea dictumst.
171	Ancol	2028-07-09	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est.
172	Trenton	2026-04-23	Nulla facilisi.
173	Bafoulabé	2028-11-07	Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum.
174	Kil	2028-02-01	Aliquam erat volutpat.
175	Glasgow	2028-06-25	Aenean auctor gravida sem.
176	Shanguang	2027-01-13	Phasellus id sapien in sapien iaculis congue.
177	Daoxian	2026-10-12	Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.
178	Paris 08	2026-01-17	Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.
179	Abū Mūsā	2027-07-03	Nulla mollis molestie lorem.
180	Conchal	2028-05-26	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue.
181	Xiatang	2026-02-05	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien.
182	Novokayakent	2027-05-16	Etiam pretium iaculis justo.
183	Jumpangdua	2026-01-12	Donec posuere metus vitae ipsum.
184	Cajolá	2028-09-21	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
185	Duyang	2027-08-31	Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla.
186	Lewotola	2027-12-05	Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla.
187	Gapluk	2026-02-02	Suspendisse accumsan tortor quis turpis. Sed ante.
188	Dake	2027-05-14	Morbi a ipsum.
189	Rio Grande da Serra	2027-08-10	Fusce posuere felis sed lacus.
190	Pátmos	2027-07-02	Praesent blandit. Nam nulla.
191	Lucapon	2027-10-17	Donec semper sapien a libero. Nam dui.
192	Carrasqueira	2026-12-03	Donec semper sapien a libero. Nam dui.
193	Gujrāt	2028-09-07	Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo.
194	Staraya Toropa	2027-04-16	Etiam faucibus cursus urna. Ut tellus.
195	Paris 03	2028-08-16	Curabitur in libero ut massa volutpat convallis.
196	Dongzhang	2027-05-02	Etiam faucibus cursus urna. Ut tellus.
197	Esperanza	2028-06-21	In hac habitasse platea dictumst.
198	Middelburg	2027-03-08	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam.
199	Verkhnyaya Tura	2027-05-11	Aenean lectus. Pellentesque eget nunc.
200	Popasna	2027-02-04	Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem.
201	Golcowa	2026-04-22	Proin risus.
202	Balas	2026-07-18	Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla.
203	Miass	2027-07-14	Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero.
204	Tuqiao	2027-11-27	Nam nulla.
205	Cinco Saltos	2028-02-13	Nulla justo. Aliquam quis turpis eget elit sodales scelerisque.
206	Kopychyntsi	2026-02-13	Sed accumsan felis.
207	Telêmaco Borba	2026-02-14	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc.
208	Arıqıran	2028-01-06	Maecenas pulvinar lobortis est. Phasellus sit amet erat.
209	Litibakul	2028-02-27	Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.
210	Languan	2027-02-01	Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem. Integer tincidunt ante vel ipsum.
211	Chrást	2026-08-01	Duis aliquam convallis nunc. Proin at turpis a pede posuere nonummy.
212	Davyd-Haradok	2027-02-22	Nam nulla.
213	Tân Phú	2028-11-03	Nam dui.
214	Quận Năm	2027-11-09	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem.
215	Cocabamba	2027-07-26	Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
216	Druzhba	2027-06-22	Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est.
217	Qigzhi	2026-04-21	Aliquam non mauris.
218	Znomenka	2028-08-26	Proin leo odio, porttitor id, consequat in, consequat ut, nulla.
219	Xianghu	2026-03-16	Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.
220	Fengyi	2027-01-24	Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue.
221	Oslo	2027-01-19	Sed sagittis.
222	Kulpin	2026-03-14	Cras in purus eu magna vulputate luctus. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
223	Shuishi	2027-08-10	Ut at dolor quis odio consequat varius. Integer ac leo.
224	Kunashak	2026-06-01	Etiam justo.
225	Pahing Pamulihan	2026-04-30	Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl. Aenean lectus.
226	Bystrytsya	2028-02-10	Suspendisse potenti.
227	Sharga	2028-01-16	Nulla suscipit ligula in lacus.
228	Hali	2027-04-07	Aliquam sit amet diam in magna bibendum imperdiet.
229	Pampanito	2027-04-26	Nam dui. Proin leo odio, porttitor id, consequat in, consequat ut, nulla.
230	Mosquera	2028-04-24	Mauris enim leo, rhoncus sed, vestibulum sit amet, cursus id, turpis. Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.
231	Zbiroh	2026-05-28	Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.
232	Vila Chã do Monte	2028-11-01	Nullam sit amet turpis elementum ligula vehicula consequat.
233	Bacnotan	2027-08-01	Nam nulla.
234	Junchuan	2027-04-27	Proin interdum mauris non ligula pellentesque ultrices.
235	Socorro	2027-10-11	Nunc nisl.
236	Yingtan	2026-06-05	Maecenas tincidunt lacus at velit.
237	Itami	2027-11-26	Duis bibendum. Morbi non quam nec dui luctus rutrum.
238	Żarnów	2028-10-28	Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.
239	Karema	2027-06-10	Aenean auctor gravida sem.
240	Lascano	2028-01-11	Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue.
241	Tonggu	2028-01-07	In hac habitasse platea dictumst. Etiam faucibus cursus urna.
242	El Asintal	2028-03-17	Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est.
243	Palanit	2025-12-22	Nulla justo.
244	Chengbei	2025-12-29	Morbi quis tortor id nulla ultrices aliquet.
245	Kurjan	2028-10-16	Duis bibendum, felis sed interdum venenatis, turpis enim blandit mi, in porttitor pede justo eu massa.
246	Kōchi-shi	2026-03-31	Vestibulum sed magna at nunc commodo placerat.
247	Évreux	2028-08-17	Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est.
248	Horlivka	2027-12-09	Etiam vel augue.
249	Miami	2027-10-24	Duis consequat dui nec nisi volutpat eleifend.
250	Beau Vallon	2027-08-13	Morbi a ipsum. Integer a nibh.
251	Ryazhsk	2026-05-13	Nulla suscipit ligula in lacus. Curabitur at ipsum ac tellus semper interdum.
252	Zhonglong	2026-06-14	Ut tellus.
253	Ābyek	2026-06-07	Aliquam augue quam, sollicitudin vitae, consectetuer eget, rutrum at, lorem.
254	Abū Ghaush	2027-10-21	Maecenas rhoncus aliquam lacus.
255	Popovice	2026-12-05	Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede.
256	Kaliasin	2026-06-07	Nam dui.
257	Oslo	2027-03-07	In hac habitasse platea dictumst.
258	União dos Palmares	2027-09-13	Ut tellus. Nulla ut erat id mauris vulputate elementum.
259	Luna	2026-11-26	Vestibulum sed magna at nunc commodo placerat. Praesent blandit.
260	Oakville	2026-11-27	Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci.
261	Ijero-Ekiti	2027-01-04	Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo. In blandit ultrices enim.
262	Oslo	2027-06-29	Curabitur gravida nisi at nibh. In hac habitasse platea dictumst.
263	Keli	2028-05-31	Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus.
264	Kanaya	2026-11-02	Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus.
265	Monte de Fralães	2028-02-25	Nunc rhoncus dui vel sem. Sed sagittis.
266	Belsk Duży	2027-02-23	Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.
267	Parigi	2028-10-13	Sed vel enim sit amet nunc viverra dapibus.
268	Xieji	2028-03-26	Fusce posuere felis sed lacus.
269	Beishan	2026-08-01	Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue.
270	Lubukalung	2028-06-25	Aenean fermentum. Donec ut mauris eget massa tempor convallis.
271	Kofelē	2028-01-17	Quisque porta volutpat erat.
272	Zelenogorsk	2026-05-11	Sed sagittis.
273	Jieheshi	2027-06-27	Duis at velit eu est congue elementum. In hac habitasse platea dictumst.
274	Gucheng	2027-07-21	Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.
275	Puhechang	2027-11-29	Quisque id justo sit amet sapien dignissim vestibulum.
276	Knivsta	2027-04-08	Ut tellus.
277	Tangjiapo	2026-03-19	Etiam vel augue. Vestibulum rutrum rutrum neque.
278	Stockholm	2027-09-19	Vivamus vel nulla eget eros elementum pellentesque.
279	Shiqiao	2027-02-20	Nulla justo.
280	Ivoti	2026-12-22	Ut at dolor quis odio consequat varius. Integer ac leo.
281	Lindavista	2027-12-11	Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl.
282	Telhado	2026-05-22	Nullam porttitor lacus at turpis.
283	Legaspi	2026-11-17	Mauris lacinia sapien quis libero.
284	San Diego	2026-12-16	Nulla ut erat id mauris vulputate elementum. Nullam varius.
285	Xingou	2028-06-05	Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus.
286	Sevlievo	2028-02-26	Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue. Aliquam erat volutpat.
287	Memaliaj	2026-06-29	In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem. Duis aliquam convallis nunc.
288	Osasco	2028-05-05	Nullam sit amet turpis elementum ligula vehicula consequat. Morbi a ipsum.
289	Apaga	2027-07-31	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
290	Isdalstø	2027-05-24	Proin leo odio, porttitor id, consequat in, consequat ut, nulla. Sed accumsan felis.
291	Jaciara	2028-05-11	Mauris lacinia sapien quis libero.
292	Longcheng	2027-03-22	Curabitur gravida nisi at nibh. In hac habitasse platea dictumst.
293	Kokar	2027-11-27	Pellentesque at nulla.
294	Sydney	2028-06-25	Suspendisse accumsan tortor quis turpis. Sed ante.
295	Telukpakedai	2028-07-27	Aenean fermentum.
296	Sidomulyo	2028-10-23	Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo. Pellentesque viverra pede ac diam.
297	Kabakovo	2026-12-28	Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est.
298	Capela	2027-09-19	Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero.
299	Biao	2026-07-07	Ut tellus. Nulla ut erat id mauris vulputate elementum.
300	Leye	2027-06-28	Suspendisse potenti. Nullam porttitor lacus at turpis.
301	Ochojno	2026-07-13	Vivamus metus arcu, adipiscing molestie, hendrerit at, vulputate vitae, nisl.
302	Ústí nad Labem	2026-03-04	Vivamus vestibulum sagittis sapien. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
303	Córdoba	2028-09-21	Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.
304	Panggulan	2027-03-30	Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla. Sed vel enim sit amet nunc viverra dapibus.
305	Tambong	2027-08-18	Vestibulum quam sapien, varius ut, blandit non, interdum in, ante.
306	Nesterov	2028-03-30	Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.
307	Turbaco	2027-12-12	Etiam justo. Etiam pretium iaculis justo.
308	Kongtian	2027-09-19	Nulla ut erat id mauris vulputate elementum.
309	Paris 12	2027-03-08	Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.
310	Nýřany	2026-02-03	Quisque porta volutpat erat. Quisque erat eros, viverra eget, congue eget, semper rutrum, nulla.
311	Tiandiba	2027-09-28	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est. Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros.
312	Xinxing	2027-08-27	Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula.
313	Katunayaka	2028-06-01	Nulla facilisi.
314	Białobrzegi	2026-07-20	Nunc purus. Phasellus in felis.
315	Binawara	2026-05-31	Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl.
316	Pápa	2026-07-15	Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique.
317	Shuangta	2027-08-16	Morbi non quam nec dui luctus rutrum. Nulla tellus.
318	Alingsås	2026-02-05	Nullam porttitor lacus at turpis. Donec posuere metus vitae ipsum.
319	Trondheim	2027-04-04	Mauris sit amet eros.
320	Corona	2026-03-12	Maecenas pulvinar lobortis est. Phasellus sit amet erat.
321	Sundsvall	2026-12-28	Sed ante. Vivamus tortor.
322	Kasimov	2028-04-16	Nulla mollis molestie lorem.
323	Novovolyns’k	2028-07-29	Duis consequat dui nec nisi volutpat eleifend.
324	Aikmel	2026-09-07	Nulla suscipit ligula in lacus.
325	Nevers	2028-06-17	Nunc rhoncus dui vel sem. Sed sagittis.
326	Asbest	2027-11-06	Aenean lectus. Pellentesque eget nunc.
327	Hukou	2026-10-21	Cras non velit nec nisi vulputate nonummy.
328	Cholpon-Ata	2026-10-14	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Mauris viverra diam vitae quam. Suspendisse potenti.
329	Kalangan	2028-03-24	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
330	Jargalant	2026-01-04	Duis at velit eu est congue elementum. In hac habitasse platea dictumst.
331	Litian	2026-02-05	Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula.
332	Chajarí	2027-09-30	Nulla mollis molestie lorem.
333	Sarapul	2027-12-08	Nulla ut erat id mauris vulputate elementum. Nullam varius.
334	Newark	2028-06-22	Suspendisse ornare consequat lectus.
335	Yucheng	2028-07-20	Morbi quis tortor id nulla ultrices aliquet.
336	Bhātpāra Abhaynagar	2027-08-05	Donec posuere metus vitae ipsum. Aliquam non mauris.
337	Weetombo	2026-10-06	Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.
338	Aurora	2027-04-16	Quisque id justo sit amet sapien dignissim vestibulum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Nulla dapibus dolor vel est.
339	Luchenza	2026-11-14	Mauris sit amet eros.
340	Kayu Agung	2027-10-20	Praesent lectus.
341	Strasbourg	2028-06-12	Aliquam non mauris.
342	Viangxai	2026-07-06	Vivamus vel nulla eget eros elementum pellentesque.
343	Namie	2026-09-18	Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.
344	Nan’an	2027-07-25	Integer a nibh. In quis justo.
345	Shangdian	2027-05-02	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam vel augue.
346	Sabinópolis	2026-12-17	Morbi non lectus.
347	Lisakovsk	2027-03-26	Aliquam quis turpis eget elit sodales scelerisque.
348	Krousón	2026-12-20	In quis justo. Maecenas rhoncus aliquam lacus.
349	Oropesa	2028-06-12	Morbi vestibulum, velit id pretium iaculis, diam erat fermentum justo, nec condimentum neque sapien placerat ante.
350	Velille	2026-12-12	Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti.
351	Puyuan	2028-11-12	Proin risus. Praesent lectus.
352	Ferreira	2028-10-03	Aliquam sit amet diam in magna bibendum imperdiet.
353	Praia da Tocha	2028-07-03	Curabitur in libero ut massa volutpat convallis. Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo.
354	Gemena	2028-09-10	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
355	Guradog	2026-02-15	Sed sagittis. Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci.
356	Pārūn	2026-07-21	Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede. Morbi porttitor lorem id ligula.
357	Sundsvall	2026-12-23	Proin eu mi.
358	Jojoima	2026-10-15	Pellentesque eget nunc. Donec quis orci eget orci vehicula condimentum.
359	Dawang	2028-01-24	Maecenas tincidunt lacus at velit.
360	Reims	2027-10-19	Pellentesque viverra pede ac diam. Cras pellentesque volutpat dui.
361	Trondheim	2026-11-11	Nulla mollis molestie lorem.
362	Charagua	2027-10-18	Suspendisse ornare consequat lectus. In est risus, auctor sed, tristique in, tempus sit amet, sem.
363	Adelaide Mail Centre	2026-12-14	Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci.
364	Malbork	2027-07-20	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
365	Sandefjord	2026-10-03	Mauris ullamcorper purus sit amet nulla. Quisque arcu libero, rutrum ac, lobortis vel, dapibus at, diam.
366	Banjar Ponggang	2026-07-25	In congue.
367	‘Afak	2026-12-22	Vivamus tortor.
368	Panay	2026-11-03	Donec dapibus.
369	La Mohammedia	2026-12-17	Morbi porttitor lorem id ligula. Suspendisse ornare consequat lectus.
370	Semënovskoye	2027-07-25	Cras non velit nec nisi vulputate nonummy. Maecenas tincidunt lacus at velit.
371	Maxu	2027-03-26	Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Donec pharetra, magna vestibulum aliquet ultrices, erat tortor sollicitudin mi, sit amet lobortis sapien sapien non mi. Integer ac neque.
372	Luleå	2027-10-28	Sed sagittis.
373	La Dicha	2026-11-16	Morbi ut odio. Cras mi pede, malesuada in, imperdiet et, commodo vulputate, justo.
374	São Sepé	2026-08-05	Duis ac nibh. Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus.
375	Puyan	2026-06-24	Cras non velit nec nisi vulputate nonummy.
376	Uwelini	2028-06-28	Aliquam erat volutpat. In congue.
377	Portela	2027-04-13	Phasellus id sapien in sapien iaculis congue.
378	Balkh	2025-12-18	Praesent blandit lacinia erat.
379	Januária	2026-01-24	Vivamus vestibulum sagittis sapien.
380	Ayamaru	2026-03-12	Fusce consequat.
381	Gornji Petrovci	2027-09-18	Nulla neque libero, convallis eget, eleifend luctus, ultricies eu, nibh.
382	Blois	2026-09-08	Maecenas rhoncus aliquam lacus. Morbi quis tortor id nulla ultrices aliquet.
383	Urazovo	2028-04-29	In hac habitasse platea dictumst.
384	Lembanah	2026-09-21	Duis at velit eu est congue elementum. In hac habitasse platea dictumst.
385	Paris La Défense	2027-09-07	Fusce lacus purus, aliquet at, feugiat non, pretium quis, lectus. Suspendisse potenti.
386	Ban Huai Thalaeng	2028-02-23	Morbi odio odio, elementum eu, interdum eu, tincidunt in, leo. Maecenas pulvinar lobortis est.
387	Samangawah	2026-02-12	Aenean fermentum.
388	Perth	2027-05-17	Praesent blandit lacinia erat.
389	Imbituva	2027-07-26	Maecenas rhoncus aliquam lacus.
390	Meilin	2027-01-12	Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo.
391	Rancaseneng	2028-09-13	In hac habitasse platea dictumst.
392	Poá	2028-11-04	Donec ut dolor. Morbi vel lectus in quam fringilla rhoncus.
393	Weixin	2027-12-02	Praesent blandit.
394	Halmstad	2026-10-01	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus vestibulum sagittis sapien.
395	Wiang Chiang Rung	2026-01-13	Cras pellentesque volutpat dui. Maecenas tristique, est et tempus semper, est quam pharetra magna, ac consequat metus sapien ut nunc.
396	Alicia	2027-01-18	Nulla justo. Aliquam quis turpis eget elit sodales scelerisque.
397	Penja	2026-11-17	Lorem ipsum dolor sit amet, consectetuer adipiscing elit.
398	Dongdai	2027-12-16	Vestibulum quam sapien, varius ut, blandit non, interdum in, ante. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; Duis faucibus accumsan odio.
399	Rakvere	2026-01-24	Vestibulum quam sapien, varius ut, blandit non, interdum in, ante.
400	Karangampel	2028-04-25	Sed vel enim sit amet nunc viverra dapibus. Nulla suscipit ligula in lacus.
401	Besuki Dua	2028-11-03	Pellentesque at nulla.
402	Xianhe	2027-01-18	Vestibulum ac est lacinia nisi venenatis tristique. Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue.
403	Maicao	2028-08-13	Curabitur gravida nisi at nibh.
404	Riđica	2027-03-09	Nulla nisl. Nunc nisl.
405	Yashiro	2028-09-26	Lorem ipsum dolor sit amet, consectetuer adipiscing elit. Proin interdum mauris non ligula pellentesque ultrices.
406	Xiangdian	2026-05-05	Morbi sem mauris, laoreet ut, rhoncus aliquet, pulvinar sed, nisl.
407	Ningshan Chengguanzhen	2028-08-26	Aenean lectus.
408	Izumi	2026-10-05	Nam nulla. Integer pede justo, lacinia eget, tincidunt eget, tempus vel, pede.
409	Al Khawkhah	2027-10-26	Duis bibendum.
410	Des Moines	2027-01-04	In hac habitasse platea dictumst.
411	Jiucaizhuang	2027-04-14	Nunc rhoncus dui vel sem.
412	Shibi	2027-05-11	Praesent id massa id nisl venenatis lacinia.
413	Spas-Zaulok	2026-10-12	Integer ac neque. Duis bibendum.
414	Xinjian	2026-02-06	Donec odio justo, sollicitudin ut, suscipit a, feugiat et, eros. Vestibulum ac est lacinia nisi venenatis tristique.
415	Creighton	2026-09-14	Nulla ac enim. In tempor, turpis nec euismod scelerisque, quam turpis adipiscing lorem, vitae mattis nibh ligula nec sem.
416	Volary	2028-03-03	Vivamus in felis eu sapien cursus vestibulum. Proin eu mi.
417	Dallas	2028-10-03	Mauris lacinia sapien quis libero.
418	Novhorod-Sivers’kyy	2028-06-09	Fusce congue, diam id ornare imperdiet, sapien urna pretium nisl, ut volutpat sapien arcu sed augue.
419	Caujul	2028-03-03	Nam congue, risus semper porta volutpat, quam pede lobortis ligula, sit amet eleifend pede libero quis orci.
420	Arras	2027-03-03	Donec vitae nisi. Nam ultrices, libero non mattis pulvinar, nulla pede ullamcorper augue, a suscipit nulla elit ac nulla.
421	Bharatpur	2028-07-30	Integer aliquet, massa id lobortis convallis, tortor risus dapibus augue, vel accumsan tellus nisi eu orci. Mauris lacinia sapien quis libero.
422	Hubynykha	2028-11-07	Aliquam erat volutpat.
423	Oldřišov	2028-06-27	In congue.
424	Vawkavysk	2026-02-05	Suspendisse accumsan tortor quis turpis.
425	Victoria Falls	2028-06-11	Mauris lacinia sapien quis libero.
426	Tabia	2026-11-11	Donec ut dolor.
427	Halimpu	2028-09-28	Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
428	Al Ḩammāmāt	2027-01-22	Nullam porttitor lacus at turpis.
429	Taluksangay	2026-12-08	Suspendisse potenti.
430	Tsukuba	2028-04-10	Integer a nibh. In quis justo.
431	Naukšēni	2026-06-29	Mauris lacinia sapien quis libero. Nullam sit amet turpis elementum ligula vehicula consequat.
432	Imsida	2027-10-22	Duis consequat dui nec nisi volutpat eleifend. Donec ut dolor.
433	Donghui	2026-11-30	Phasellus sit amet erat.
434	El Bolsón	2028-10-25	Nulla nisl. Nunc nisl.
435	Ailigandí	2028-11-10	Morbi ut odio.
436	Aleshtar	2027-10-16	Aenean lectus. Pellentesque eget nunc.
437	Malbork	2026-12-03	Morbi non quam nec dui luctus rutrum.
438	Al Jamālīyah	2028-10-07	Fusce consequat.
439	Chowki Jamali	2027-01-15	Pellentesque viverra pede ac diam.
440	Chile Chico	2027-04-18	Morbi quis tortor id nulla ultrices aliquet. Maecenas leo odio, condimentum id, luctus nec, molestie sed, justo.
441	Llazicë	2026-07-16	Pellentesque ultrices mattis odio.
442	Lamalewar	2027-05-16	Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.
443	Shah Alam	2026-01-10	Aliquam sit amet diam in magna bibendum imperdiet. Nullam orci pede, venenatis non, sodales sed, tincidunt eu, felis.
444	Krasnokamensk	2027-12-25	Integer ac neque. Duis bibendum.
445	Kantyshevo	2028-09-14	Nulla tellus. In sagittis dui vel nisl.
446	Concert Hall	2025-12-01	Annual Winter Concert
447	Music Studio	2025-11-20	Recording Session
448	Outdoor Park	2025-12-10	Open Air Performance
1	Test	2025-01-01	Sample activity
449	Music Hall	2025-12-01	Piano Concert
450	Auditorium	2025-12-10	Violin Practice
451	Music Hall	2025-12-01	Piano Concert
452	Auditorium	2025-12-10	Violin Practice
453	Music Hall	2025-12-01	Piano Concert
454	Music Hall	2025-12-01	Piano Concert
455	Music Hall	2025-12-01	Piano Concert
456	Music Hall	2025-12-01	Piano Concert
457	Music Hall	2025-12-01	Piano Concert
\.


--
-- TOC entry 5138 (class 0 OID 16972)
-- Dependencies: 225
-- Data for Name: class; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.class (cid, cname, maxstudents) FROM stdin;
1	dmaton0	4
2	mhuetson1	7
3	cduplantier2	4
4	jrandell3	6
5	chaggarty4	5
6	bclixby5	3
7	soculligan6	6
8	smawman7	8
9	cdarlaston8	4
10	jcowthart9	6
11	abeechinga	5
12	hdemicob	4
13	dlevec	5
14	aimlawd	9
15	lkilgrewe	7
16	cgianneschif	4
17	lcalveyg	5
18	araesideh	9
19	wcasarilii	8
20	cmerrgenj	8
21	fnichollk	7
22	diliffel	5
23	srasherm	5
24	slidgettn	5
25	tbeeno	8
26	hhamberstonep	6
27	gsperingq	3
28	idawdaryr	7
29	wmcbratneys	7
30	ajakest	4
31	aworsteru	7
32	lpeircev	10
33	nmeneghiw	8
34	lsedgemanx	5
35	bscotchmorey	9
36	apirazziz	9
37	shubbard10	4
38	draden11	5
39	kdrysdale12	10
40	landrysiak13	5
41	acreed14	10
42	aschaffel15	4
43	rludron16	7
44	apignon17	4
45	cbedward18	5
46	nmeatcher19	9
47	bstonehouse1a	4
48	dcolquitt1b	4
49	bgoschalk1c	4
50	wphillins1d	7
51	meliff1e	4
52	gbeauman1f	6
53	agoeff1g	4
54	gcassel1h	6
55	swyatt1i	8
56	rbohje1j	7
57	hcorre1k	10
58	arimington1l	4
59	bbubeer1m	6
60	aphilbrick1n	8
61	rcalltone1o	8
62	ctetford1p	6
63	hdevaney1q	3
64	alamden1r	4
65	mkier1s	4
66	coakman1t	10
67	fseamark1u	4
68	mbaack1v	6
69	eboarer1w	10
70	cfiddian1x	9
71	wsculley1y	8
72	mhawlgarth1z	6
73	hmorena20	3
74	bneward21	3
75	kcoy22	4
76	ishiel23	4
77	asimmonett24	4
78	ppittway25	7
79	vfaltin26	3
80	mpuig27	6
81	mgyver28	7
82	oholstein29	5
83	bbilbrooke2a	9
84	mpersehouse2b	8
85	mgenever2c	9
86	lchellam2d	10
87	bstranks2e	8
88	vhedley2f	8
89	ftipperton2g	6
90	jrhodef2h	4
91	dstroton2i	7
92	dmeeron2j	6
93	jzupa2k	5
94	rmeins2l	6
95	jreiner2m	4
96	mwillshaw2n	3
97	jgirodin2o	5
98	apocklington2p	9
99	rmerrington2q	5
100	wlamy2r	10
101	ppovele2s	9
102	trickard2t	9
103	gassur2u	5
104	jkeeler2v	7
105	ijuzek2w	7
106	dmeaddowcroft2x	3
107	bdorgon2y	6
108	triep2z	9
109	lbalmadier30	7
110	rlyston31	6
111	mgallymore32	6
112	fdumbelton33	9
113	rcarpmile34	9
114	bleagas35	7
115	rbodker36	5
116	rclerke37	3
117	hnielson38	5
118	kstreight39	6
119	ghorribine3a	5
120	lbollans3b	6
121	ccanto3c	10
122	kmacquarrie3d	8
123	bstearne3e	9
124	tmccafferky3f	10
125	awitul3g	9
126	jshory3h	3
127	bromanelli3i	6
128	dgeorgeau3j	6
129	uramberg3k	7
130	hgrzegorek3l	8
131	gdoornbos3m	8
132	rcreus3n	10
133	ebrunke3o	6
134	nmckeney3p	5
135	rblenkharn3q	6
136	jscay3r	7
137	mshory3s	5
138	fstormouth3t	4
139	fpaule3u	7
140	cdallinder3v	4
141	pbalsillie3w	10
142	rmickleburgh3x	7
143	gmacgiollapheadair3y	7
144	rlahrs3z	7
145	dshirtliff40	4
146	ddumper41	7
147	mspeaks42	8
148	mdumbelton43	5
149	kpizer44	10
150	fgudyer45	3
151	psutch46	3
152	lcarncross47	7
153	ddawe48	5
154	bwince49	6
155	rmcdavitt4a	7
156	wferroni4b	3
157	ekyston4c	4
158	csunnex4d	5
159	yhodgen4e	5
160	sikringill4f	5
161	lpreshous4g	4
162	rzavattari4h	9
163	mdregan4i	4
164	tshrimptone4j	9
165	lketteridge4k	5
166	lfison4l	8
167	ibims4m	5
168	ekubacki4n	10
169	olushey4o	6
170	gbeert4p	5
171	rskaid4q	9
172	dhurworth4r	10
173	hredmore4s	4
174	bvanderweedenburg4t	4
175	uottery4u	9
176	cshippard4v	10
177	nharrinson4w	9
178	cmaleham4x	8
179	mwyness4y	10
180	dradbourn4z	5
181	yandreotti50	10
182	drivers51	7
183	ddallaway52	8
184	ghealks53	6
185	abitterton54	6
186	bdimnage55	9
187	bhalls56	4
188	kneeson57	4
189	aloos58	9
190	kjerosch59	10
191	ncawdell5a	6
192	kmattiassi5b	6
193	ljoberne5c	3
194	rcheson5d	9
195	ndodd5e	5
196	efiddeman5f	5
197	bmuldoon5g	9
198	lgernier5h	9
199	esivior5i	4
200	mblasli5j	6
201	bbryers5k	7
202	pscyone5l	10
203	arunnicles5m	4
204	dcadalleder5n	5
205	tpaolazzi5o	5
206	nbendig5p	8
207	emoehler5q	8
208	twhitebread5r	4
209	mcreighton5s	4
210	lpurse5t	8
211	cdicte5u	10
212	kwaterstone5v	5
213	gstiant5w	5
214	roda5x	8
215	tmishow5y	4
216	mtidey5z	5
217	omalsher60	9
218	esmead61	7
219	sverbrugge62	6
220	omccarle63	7
221	mmattia64	6
222	geastbury65	8
223	xvonhagt66	9
224	twoodson67	10
225	clawtie68	6
226	rolver69	4
227	mturbat6a	4
228	bdifrancecshi6b	3
229	cbarnby6c	6
230	abaggs6d	5
231	lbromfield6e	6
232	hkilby6f	8
233	dmatticci6g	6
234	dhynes6h	4
235	cdullingham6i	7
236	lkuhn6j	7
237	kramstead6k	6
238	gboeter6l	5
239	nboolsen6m	5
240	gkeneford6n	6
241	kpigeon6o	4
242	lscougal6p	9
243	cgobat6q	6
244	ascammell6r	9
245	rfursland6s	7
246	tsallenger6t	6
247	kruffler6u	8
248	mschrieves6v	4
249	vdommersen6w	5
250	adursley6x	5
251	gfessions6y	8
252	cseedull6z	8
253	coliver70	7
254	gabadam71	7
255	josbourn72	5
256	jinns73	9
257	vfetteplace74	5
258	bveare75	7
259	tchace76	10
260	dlovel77	7
261	agonthier78	7
262	schritchley79	9
263	ebier7a	7
264	blackemann7b	5
265	syakubowicz7c	7
266	rhearfield7d	6
267	sfranceschelli7e	7
268	aperis7f	8
269	mgadesby7g	4
270	dstoeckle7h	3
271	kgandey7i	10
272	ldaw7j	9
273	csolland7k	4
274	otasch7l	7
275	dmacguigan7m	9
276	ebeecheno7n	7
277	btumelty7o	6
278	claybourn7p	4
279	bculbert7q	4
280	dbruff7r	3
281	kcollelton7s	10
282	lbrolechan7t	9
283	asayburn7u	5
284	lklamman7v	9
285	vcannings7w	5
286	awillerton7x	6
287	lharvatt7y	5
288	rjeste7z	9
289	dormston80	6
290	yickovicz81	9
291	gdreschler82	5
292	mmcginlay83	3
293	cortes84	5
294	smagenny85	8
295	flangton86	5
296	gginnell87	8
297	svarcoe88	9
298	jcoslett89	4
299	cguntrip8a	9
300	cmatterface8b	6
301	mrenison8c	4
302	cwallett8d	9
303	kroft8e	5
304	cwatsham8f	4
305	lfirmager8g	6
306	hskyme8h	8
307	rcampelli8i	5
308	ymathwen8j	6
309	nfilipson8k	8
310	rbeckhurst8l	8
311	ofullager8m	8
312	cgatehouse8n	3
313	cjacobovitch8o	10
314	bgiacomasso8p	8
315	mflicker8q	6
316	arayworth8r	4
317	agehring8s	10
318	smckmurrie8t	5
319	srutledge8u	4
320	bvizard8v	9
321	pbrazelton8w	10
322	rruddin8x	6
323	acabane8y	10
324	lrollingson8z	8
325	cspradbrow90	4
326	wscholz91	9
327	kmetcalfe92	4
328	gconey93	6
329	bstovin94	9
330	fgladtbach95	7
331	gnormanville96	6
332	lbaynham97	9
333	sflade98	3
334	jrangell99	8
335	hbentsen9a	10
336	kwhale9b	10
337	sbreens9c	3
338	cshanley9d	4
339	dpercival9e	6
340	bduffield9f	9
341	cpipes9g	7
342	rgrigorey9h	9
343	kmottley9i	6
344	nandrysek9j	8
345	aphilips9k	5
346	mgoodband9l	4
347	kprene9m	4
348	zpavel9n	5
349	gdoughartie9o	8
350	bfarragher9p	9
351	astreeting9q	5
352	aklimochkin9r	7
353	lbaal9s	10
354	bbreston9t	8
355	apapworth9u	5
356	dfalkingham9v	9
357	lmcaulay9w	8
358	vbercevelo9x	6
359	kmeriot9y	6
360	itippler9z	8
361	fgrigorinia0	4
362	rkirscha1	8
363	kocarrolla2	4
364	twifflera3	8
365	camsdena4	4
366	rmalshingera5	6
367	ddobeya6	7
368	estillwella7	8
369	lcovendona8	3
370	cmaciaszeka9	7
371	gpietaschaa	8
372	kocosgraab	4
373	dolinac	8
374	adennertad	9
375	eantoshinae	9
376	lmartillaf	6
377	bguerreroag	6
378	emcinteeah	9
379	chuffyai	9
380	lcrudgingtonaj	4
381	edinseak	5
382	pcudal	7
383	ffehneram	8
384	glipscomban	6
385	ebourdonao	10
386	epeirazziap	4
387	gfellneeaq	5
388	sverdiear	5
389	rringeras	3
390	schalonerat	4
391	mbrydoneau	5
392	gbastonav	9
393	lmatsellaw	7
394	cdurganax	4
395	jwhitwhamay	9
396	tdeacockaz	8
397	jhelstromb0	5
398	opatonb1	6
399	mrowberryb2	7
400	aperchb3	6
401	1	5
402	6	16
403	7	28
404	10	7
405	11	33
406	15	26
407	17	19
408	7	3
409	5	15
410	14	25
411	14	5
412	18	17
413	7	25
414	15	25
415	6	46
416	7	41
417	2	44
418	9	25
419	20	43
420	3	7
421	4	17
422	5	25
423	18	25
424	1	24
425	17	48
426	20	22
427	3	16
428	20	35
429	1	2
430	16	38
431	11	41
432	20	10
433	19	16
434	12	2
435	1	45
436	2	45
437	3	27
438	9	40
439	2	7
440	14	2
441	7	37
442	19	47
443	10	45
444	12	46
445	14	6
446	20	18
447	20	48
448	19	49
449	5	11
450	4	41
451	6	30
452	6	50
453	4	15
454	15	28
455	13	1
456	5	23
457	17	25
458	16	17
459	1	28
460	13	16
461	2	19
462	13	34
463	10	17
464	17	20
465	4	14
466	6	15
467	10	11
468	20	21
469	10	37
470	6	19
471	9	46
472	11	32
473	9	40
474	15	17
475	19	46
476	13	46
477	7	6
478	19	37
479	15	35
480	3	28
481	5	3
482	6	34
483	12	47
484	17	13
485	5	47
486	5	44
487	12	42
488	8	46
489	2	31
490	17	48
491	18	25
492	17	31
493	11	36
494	19	32
495	16	10
496	12	34
497	11	6
498	8	28
499	20	17
500	19	24
501	19	20
502	19	8
503	6	28
504	13	7
505	6	8
506	1	41
507	11	4
508	1	28
509	17	16
510	4	34
511	1	7
512	18	3
513	19	2
514	11	5
515	5	4
516	10	3
517	10	44
518	14	17
519	5	7
520	11	43
521	8	10
522	9	16
523	6	21
524	7	41
525	1	31
526	1	34
527	13	50
528	2	10
529	15	22
530	5	9
531	10	34
532	10	9
533	10	50
534	7	18
535	13	22
536	2	41
537	2	22
538	18	41
539	10	1
540	15	40
541	14	16
542	3	50
543	14	6
544	5	47
545	4	21
546	20	3
547	9	39
548	19	34
549	1	19
550	19	8
551	4	4
552	9	41
553	19	29
554	18	16
555	12	8
556	10	28
557	5	3
558	7	20
559	10	41
560	11	39
561	10	31
562	18	19
563	19	4
564	9	29
565	17	3
566	13	9
567	17	22
568	4	49
569	6	13
570	9	23
571	11	48
572	18	32
573	6	23
574	18	21
575	13	36
576	6	3
577	18	4
578	1	6
579	7	47
580	7	6
581	12	30
582	19	10
583	16	28
584	18	2
585	19	28
586	17	1
587	7	43
588	11	21
589	12	29
590	10	28
591	6	46
592	14	46
593	19	16
594	7	21
595	4	45
596	7	36
597	11	10
598	19	24
599	19	34
600	9	20
601	20	24
602	11	10
603	6	47
604	5	39
605	1	38
606	17	38
607	19	27
608	19	38
609	5	40
610	4	14
611	13	23
612	12	32
613	3	20
614	1	8
615	3	36
616	16	29
617	2	36
618	7	48
619	19	33
620	16	5
621	2	5
622	11	6
623	16	25
624	20	13
625	15	42
626	7	13
627	7	41
628	16	32
629	2	37
630	8	38
631	12	37
632	2	16
633	15	22
634	12	27
635	13	17
636	7	26
637	6	18
638	20	47
639	12	14
640	19	33
641	9	6
642	3	16
643	8	49
644	14	36
645	14	30
646	6	36
647	13	49
648	14	3
649	2	3
650	4	16
651	10	3
652	19	33
653	16	7
654	10	9
655	5	49
656	2	2
657	12	31
658	7	30
659	17	36
660	19	4
661	7	17
662	9	7
663	5	26
664	1	19
665	18	11
666	20	34
667	4	47
668	3	31
669	5	29
670	3	20
671	1	13
672	11	12
673	7	14
674	2	30
675	17	29
676	8	1
677	7	50
678	14	41
679	3	23
680	12	18
681	18	14
682	17	11
683	14	15
684	9	20
685	3	19
686	3	49
687	2	29
688	6	1
689	7	36
690	9	14
691	8	35
692	8	40
693	12	34
694	11	49
695	13	44
696	17	42
697	14	19
698	17	28
699	13	38
700	2	29
701	3	21
702	13	30
703	5	1
704	5	11
705	14	38
706	19	42
707	4	22
708	19	4
709	13	32
710	5	37
711	3	49
712	8	18
713	3	29
714	5	45
715	1	41
716	5	9
717	17	21
718	17	48
719	19	33
720	5	6
721	15	12
722	2	34
723	1	17
724	18	46
725	5	19
726	17	18
727	1	31
728	16	49
729	8	27
730	1	3
731	6	24
732	6	32
733	5	38
734	3	14
735	17	11
736	17	33
737	11	46
738	8	49
739	7	39
740	8	21
741	9	28
742	15	33
743	8	31
744	18	34
745	8	48
746	4	2
747	12	48
748	6	3
749	11	40
750	12	20
751	4	9
752	5	23
753	11	16
754	8	42
755	9	44
756	15	6
757	13	2
758	5	41
759	11	17
760	2	27
761	6	46
762	12	20
763	10	42
764	8	41
765	11	12
766	14	20
767	13	32
768	8	14
769	13	36
770	13	49
771	5	39
772	19	9
773	18	47
774	15	11
775	10	14
776	17	43
777	3	43
778	15	10
779	8	17
780	15	35
781	11	4
782	12	20
783	12	36
784	8	34
785	13	15
786	12	50
787	16	48
788	20	9
789	11	28
790	6	50
791	11	14
792	19	6
793	7	9
794	8	23
795	3	34
796	20	23
797	9	32
798	12	30
799	20	33
800	19	7
801	Piano Beginners	10
802	Guitar Intermediate	8
803	Violin Advanced	5
807	Class A	20
808	Bad Class	-5
809	Bad Class	-5
\.


--
-- TOC entry 5140 (class 0 OID 16981)
-- Dependencies: 227
-- Data for Name: equipment; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.equipment (eid, type, color, roomnum) FROM stdin;
1	Piano	Teal	\N
2	Guitar	Maroon	\N
3	Violin	Puce	\N
4	Microphone	Crimson	\N
5	Guitar	Puce	\N
6	Microphone	Blue	\N
7	Microphone	Purple	\N
8	Drum	Crimson	\N
9	Guitar	Turquoise	\N
10	Piano	Khaki	\N
11	Piano	Purple	\N
12	Microphone	Purple	\N
13	Piano	Maroon	\N
14	Piano	Orange	\N
15	Drum	Fuscia	\N
16	Violin	Fuscia	\N
17	Piano	Fuscia	\N
18	Piano	Mauv	\N
19	Drum	Puce	\N
20	Violin	Teal	\N
21	Violin	Puce	\N
22	Piano	Khaki	\N
23	Violin	Goldenrod	\N
24	Violin	Red	\N
25	Piano	Pink	\N
26	Microphone	Orange	\N
27	Piano	Red	\N
28	Drum	Puce	\N
29	Piano	Violet	\N
30	Violin	Puce	\N
31	Piano	Fuscia	\N
32	Guitar	Goldenrod	\N
33	Guitar	Aquamarine	\N
34	Drum	Teal	\N
35	Guitar	Aquamarine	\N
36	Drum	Mauv	\N
37	Guitar	Red	\N
38	Violin	Indigo	\N
39	Violin	Mauv	\N
40	Violin	Maroon	\N
41	Microphone	Blue	\N
42	Drum	Crimson	\N
43	Microphone	Purple	\N
44	Piano	Mauv	\N
45	Violin	Indigo	\N
46	Drum	Fuscia	\N
47	Drum	Blue	\N
48	Drum	Goldenrod	\N
49	Guitar	Khaki	\N
50	Microphone	Blue	\N
51	Piano	Khaki	\N
52	Microphone	Red	\N
53	Piano	Turquoise	\N
54	Microphone	Aquamarine	\N
55	Violin	Green	\N
56	Guitar	Indigo	\N
57	Piano	Violet	\N
58	Guitar	Puce	\N
59	Violin	Yellow	\N
60	Violin	Green	\N
61	Violin	Teal	\N
62	Violin	Goldenrod	\N
63	Guitar	Yellow	\N
64	Microphone	Turquoise	\N
65	Violin	Pink	\N
66	Drum	Puce	\N
67	Violin	Mauv	\N
68	Drum	Mauv	\N
69	Guitar	Blue	\N
70	Drum	Red	\N
71	Drum	Blue	\N
72	Guitar	Purple	\N
73	Microphone	Crimson	\N
74	Drum	Pink	\N
75	Microphone	Turquoise	\N
76	Guitar	Blue	\N
77	Drum	Purple	\N
78	Guitar	Red	\N
79	Piano	Khaki	\N
80	Violin	Puce	\N
81	Drum	Yellow	\N
82	Violin	Fuscia	\N
83	Drum	Goldenrod	\N
84	Guitar	Pink	\N
85	Drum	Orange	\N
86	Guitar	Red	\N
87	Guitar	Purple	\N
88	Piano	Goldenrod	\N
89	Piano	Violet	\N
90	Drum	Mauv	\N
91	Guitar	Crimson	\N
92	Piano	Green	\N
93	Microphone	Orange	\N
94	Violin	Crimson	\N
95	Violin	Orange	\N
96	Piano	Indigo	\N
97	Guitar	Violet	\N
98	Piano	Green	\N
99	Microphone	Mauv	\N
100	Guitar	Teal	\N
101	Microphone	Purple	\N
102	Guitar	Red	\N
103	Microphone	Indigo	\N
104	Guitar	Violet	\N
105	Violin	Purple	\N
106	Drum	Crimson	\N
107	Piano	Pink	\N
108	Guitar	Puce	\N
109	Drum	Red	\N
110	Violin	Indigo	\N
111	Drum	Pink	\N
112	Violin	Green	\N
113	Microphone	Indigo	\N
114	Piano	Goldenrod	\N
115	Guitar	Yellow	\N
116	Guitar	Teal	\N
117	Microphone	Violet	\N
118	Microphone	Fuscia	\N
119	Piano	Teal	\N
120	Violin	Turquoise	\N
121	Guitar	Puce	\N
122	Guitar	Aquamarine	\N
123	Microphone	Indigo	\N
124	Violin	Teal	\N
125	Piano	Crimson	\N
126	Drum	Blue	\N
127	Microphone	Purple	\N
128	Guitar	Purple	\N
129	Piano	Red	\N
130	Violin	Green	\N
131	Piano	Orange	\N
132	Violin	Red	\N
133	Violin	Red	\N
134	Guitar	Teal	\N
135	Piano	Purple	\N
136	Drum	Pink	\N
137	Guitar	Blue	\N
138	Violin	Orange	\N
139	Guitar	Blue	\N
140	Piano	Blue	\N
141	Piano	Aquamarine	\N
142	Microphone	Puce	\N
143	Piano	Pink	\N
144	Microphone	Crimson	\N
145	Microphone	Crimson	\N
146	Guitar	Purple	\N
147	Guitar	Aquamarine	\N
148	Violin	Orange	\N
149	Piano	Pink	\N
150	Guitar	Red	\N
151	Microphone	Red	\N
152	Violin	Goldenrod	\N
153	Drum	Pink	\N
154	Violin	Indigo	\N
155	Drum	Khaki	\N
156	Piano	Red	\N
157	Piano	Turquoise	\N
158	Guitar	Orange	\N
159	Piano	Orange	\N
160	Piano	Mauv	\N
161	Piano	Khaki	\N
162	Microphone	Violet	\N
163	Violin	Orange	\N
164	Violin	Goldenrod	\N
165	Piano	Khaki	\N
166	Microphone	Teal	\N
167	Violin	Aquamarine	\N
168	Microphone	Goldenrod	\N
169	Guitar	Blue	\N
170	Microphone	Purple	\N
171	Microphone	Purple	\N
172	Violin	Blue	\N
173	Microphone	Violet	\N
174	Drum	Fuscia	\N
175	Microphone	Goldenrod	\N
176	Drum	Khaki	\N
177	Guitar	Teal	\N
178	Violin	Violet	\N
179	Microphone	Purple	\N
180	Microphone	Orange	\N
181	Guitar	Turquoise	\N
182	Violin	Fuscia	\N
183	Piano	Teal	\N
184	Piano	Khaki	\N
185	Microphone	Purple	\N
186	Microphone	Aquamarine	\N
187	Piano	Violet	\N
188	Microphone	Pink	\N
189	Piano	Red	\N
190	Violin	Yellow	\N
191	Violin	Teal	\N
192	Drum	Khaki	\N
193	Piano	Turquoise	\N
194	Violin	Indigo	\N
195	Piano	Red	\N
196	Guitar	Red	\N
197	Drum	Puce	\N
198	Microphone	Turquoise	\N
199	Microphone	Orange	\N
200	Microphone	Indigo	\N
201	Microphone	Purple	\N
202	Guitar	Green	\N
203	Violin	Purple	\N
204	Piano	Purple	\N
205	Violin	Crimson	\N
206	Piano	Aquamarine	\N
207	Microphone	Green	\N
208	Drum	Turquoise	\N
209	Guitar	Mauv	\N
210	Drum	Violet	\N
211	Microphone	Orange	\N
212	Guitar	Fuscia	\N
213	Microphone	Aquamarine	\N
214	Violin	Yellow	\N
215	Guitar	Blue	\N
216	Guitar	Yellow	\N
217	Drum	Red	\N
218	Guitar	Green	\N
219	Piano	Indigo	\N
220	Microphone	Purple	\N
221	Drum	Khaki	\N
222	Piano	Khaki	\N
223	Guitar	Yellow	\N
224	Piano	Crimson	\N
225	Drum	Blue	\N
226	Microphone	Yellow	\N
227	Violin	Green	\N
228	Guitar	Khaki	\N
229	Microphone	Blue	\N
230	Piano	Yellow	\N
231	Drum	Red	\N
232	Guitar	Teal	\N
233	Microphone	Orange	\N
234	Piano	Goldenrod	\N
235	Violin	Indigo	\N
236	Microphone	Green	\N
237	Microphone	Mauv	\N
238	Piano	Indigo	\N
239	Violin	Green	\N
240	Microphone	Mauv	\N
241	Violin	Pink	\N
242	Drum	Maroon	\N
243	Guitar	Aquamarine	\N
244	Drum	Khaki	\N
245	Drum	Pink	\N
246	Guitar	Purple	\N
247	Microphone	Mauv	\N
248	Microphone	Maroon	\N
249	Drum	Red	\N
250	Piano	Yellow	\N
251	Violin	Indigo	\N
252	Microphone	Aquamarine	\N
253	Guitar	Goldenrod	\N
254	Microphone	Orange	\N
255	Violin	Green	\N
256	Guitar	Turquoise	\N
257	Piano	Yellow	\N
258	Violin	Pink	\N
259	Drum	Khaki	\N
260	Violin	Violet	\N
261	Drum	Aquamarine	\N
262	Violin	Indigo	\N
263	Microphone	Maroon	\N
264	Guitar	Puce	\N
265	Microphone	Green	\N
266	Violin	Green	\N
267	Drum	Indigo	\N
268	Violin	Pink	\N
269	Violin	Mauv	\N
270	Violin	Yellow	\N
271	Drum	Khaki	\N
272	Piano	Goldenrod	\N
273	Piano	Violet	\N
274	Piano	Red	\N
275	Violin	Teal	\N
276	Piano	Fuscia	\N
277	Drum	Blue	\N
278	Microphone	Pink	\N
279	Microphone	Khaki	\N
280	Piano	Purple	\N
281	Drum	Orange	\N
282	Drum	Turquoise	\N
283	Drum	Purple	\N
284	Violin	Teal	\N
285	Piano	Khaki	\N
286	Drum	Indigo	\N
287	Violin	Red	\N
288	Drum	Turquoise	\N
289	Guitar	Yellow	\N
290	Microphone	Pink	\N
291	Violin	Pink	\N
292	Guitar	Mauv	\N
293	Violin	Purple	\N
294	Piano	Khaki	\N
295	Drum	Puce	\N
296	Guitar	Yellow	\N
297	Violin	Green	\N
298	Guitar	Violet	\N
299	Microphone	Puce	\N
300	Violin	Indigo	\N
301	Violin	Red	\N
302	Microphone	Orange	\N
303	Violin	Indigo	\N
304	Piano	Maroon	\N
305	Piano	Orange	\N
306	Drum	Crimson	\N
307	Microphone	Maroon	\N
308	Drum	Crimson	\N
309	Violin	Teal	\N
310	Microphone	Orange	\N
311	Violin	Teal	\N
312	Piano	Teal	\N
313	Guitar	Mauv	\N
314	Drum	Indigo	\N
315	Drum	Yellow	\N
316	Guitar	Maroon	\N
317	Guitar	Maroon	\N
318	Microphone	Teal	\N
319	Guitar	Maroon	\N
320	Piano	Yellow	\N
321	Drum	Crimson	\N
322	Guitar	Yellow	\N
323	Piano	Blue	\N
324	Piano	Khaki	\N
325	Guitar	Puce	\N
326	Microphone	Purple	\N
327	Violin	Aquamarine	\N
328	Guitar	Orange	\N
329	Drum	Maroon	\N
330	Piano	Goldenrod	\N
331	Violin	Indigo	\N
332	Violin	Yellow	\N
333	Guitar	Crimson	\N
334	Guitar	Puce	\N
335	Guitar	Teal	\N
336	Violin	Orange	\N
337	Piano	Blue	\N
338	Violin	Indigo	\N
339	Violin	Khaki	\N
340	Drum	Aquamarine	\N
341	Drum	Orange	\N
342	Violin	Puce	\N
343	Drum	Indigo	\N
344	Violin	Violet	\N
345	Microphone	Indigo	\N
346	Drum	Orange	\N
347	Guitar	Khaki	\N
348	Microphone	Orange	\N
349	Guitar	Orange	\N
350	Piano	Goldenrod	\N
351	Drum	Maroon	\N
352	Piano	Khaki	\N
353	Violin	Mauv	\N
354	Piano	Khaki	\N
355	Guitar	Blue	\N
356	Drum	Red	\N
357	Guitar	Purple	\N
358	Piano	Green	\N
359	Guitar	Teal	\N
360	Drum	Khaki	\N
361	Drum	Fuscia	\N
362	Piano	Mauv	\N
363	Drum	Teal	\N
364	Piano	Goldenrod	\N
365	Microphone	Aquamarine	\N
366	Microphone	Orange	\N
367	Piano	Mauv	\N
368	Microphone	Pink	\N
369	Violin	Pink	\N
370	Guitar	Crimson	\N
371	Piano	Red	\N
372	Microphone	Fuscia	\N
373	Piano	Puce	\N
374	Microphone	Crimson	\N
375	Guitar	Indigo	\N
376	Microphone	Indigo	\N
377	Violin	Aquamarine	\N
378	Guitar	Fuscia	\N
379	Guitar	Yellow	\N
380	Microphone	Indigo	\N
381	Drum	Puce	\N
382	Piano	Teal	\N
383	Microphone	Teal	\N
384	Piano	Purple	\N
385	Microphone	Violet	\N
386	Microphone	Red	\N
387	Guitar	Khaki	\N
388	Piano	Violet	\N
389	Drum	Aquamarine	\N
390	Microphone	Teal	\N
391	Violin	Yellow	\N
392	Guitar	Crimson	\N
393	Drum	Purple	\N
394	Violin	Aquamarine	\N
395	Violin	Aquamarine	\N
396	Microphone	Aquamarine	\N
397	Violin	Maroon	\N
398	Guitar	Aquamarine	\N
399	Microphone	Aquamarine	\N
400	Violin	Crimson	\N
401	Piano	Black	\N
402	Guitar	Brown	\N
403	Violin	Red	\N
404	b	Maroon	\N
405	b	Orange	\N
406	a	Red	\N
\.


--
-- TOC entry 5151 (class 0 OID 25388)
-- Dependencies: 238
-- Data for Name: feedback; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.feedback (fid, rating, fdate, subject, sid) FROM stdin;
48	1	2025-12-27	יחס אישי	715
49	5	2025-12-26	יחס אישי	673
50	5	2025-12-25	זמינות שיעורים	631
51	3	2025-12-24	מקצועיות מורים	755
52	1	2025-12-23	זמינות שיעורים	559
53	4	2025-12-22	מחיר חוג	621
54	5	2025-12-21	מחיר חוג	571
55	1	2025-12-20	יחס אישי	697
56	2	2025-12-19	תחזוקת פסנתרים	477
57	3	2025-12-18	זמינות שיעורים	623
58	2	2025-12-17	מחיר חוג	753
59	4	2025-12-16	יחס אישי	590
60	5	2025-12-15	זמינות שיעורים	756
61	4	2025-12-14	זמינות שיעורים	574
62	3	2025-12-13	יחס אישי	426
63	1	2025-12-12	מקצועיות מורים	786
64	3	2025-12-11	מחיר חוג	807
65	2	2025-12-10	יחס אישי	600
66	4	2025-12-09	יחס אישי	618
67	5	2025-12-08	ניקיון חדרים	463
68	3	2025-12-07	מחיר חוג	768
69	4	2025-12-06	ניקיון חדרים	646
70	2	2025-12-05	ניקיון חדרים	797
71	4	2025-12-04	זמינות שיעורים	552
72	4	2025-12-03	מחיר חוג	731
73	4	2025-12-02	יחס אישי	564
74	5	2025-12-01	מקצועיות מורים	810
75	2	2025-11-30	מחיר חוג	504
76	4	2025-11-29	מקצועיות מורים	450
77	1	2025-11-28	זמינות שיעורים	481
78	3	2025-11-27	תחזוקת פסנתרים	508
79	1	2025-11-26	מקצועיות מורים	677
80	2	2025-11-25	תחזוקת פסנתרים	772
81	2	2025-11-24	מקצועיות מורים	632
82	5	2025-11-23	יחס אישי	505
83	5	2025-11-22	מחיר חוג	427
84	4	2025-11-21	מקצועיות מורים	711
85	2	2025-11-20	מקצועיות מורים	672
86	4	2025-11-19	יחס אישי	739
87	1	2025-11-18	ניקיון חדרים	487
\.


--
-- TOC entry 5147 (class 0 OID 17049)
-- Dependencies: 234
-- Data for Name: ishaving; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.ishaving (cid, eid) FROM stdin;
61	112
159	366
110	231
337	249
371	34
384	259
347	36
143	93
419	354
405	21
25	51
44	223
406	2
239	124
274	297
110	160
79	265
3	195
483	132
7	220
27	301
212	84
323	156
4	176
243	322
391	242
193	346
440	335
59	242
188	371
342	182
469	234
346	339
442	161
339	263
218	30
18	380
25	257
275	343
80	23
259	147
478	257
30	257
88	297
205	271
324	253
474	236
492	210
31	209
500	133
297	160
199	101
104	3
61	135
481	371
276	212
264	358
348	390
277	233
186	174
383	91
337	126
313	263
431	340
241	21
76	139
249	252
344	247
493	255
134	232
469	352
382	393
25	111
348	330
191	100
421	233
155	88
361	204
382	310
363	159
79	115
185	58
267	150
322	196
429	293
284	336
190	255
246	152
218	154
368	78
170	326
439	231
168	105
261	14
21	302
212	395
350	314
229	349
34	380
124	192
133	312
172	49
496	367
395	323
381	284
469	264
441	24
95	337
364	246
255	163
162	157
296	331
31	219
372	59
76	93
188	5
5	123
76	66
406	207
137	162
224	125
17	399
4	192
471	170
201	337
186	168
287	210
131	356
58	95
232	309
111	306
40	323
158	36
144	219
363	201
84	372
179	71
144	39
65	327
283	140
44	166
228	251
88	51
355	392
461	72
433	213
5	122
80	346
477	113
143	388
101	116
100	61
481	157
47	210
291	184
253	345
243	97
405	222
73	65
152	287
343	318
152	263
9	134
34	1
181	200
203	230
46	230
188	334
240	365
287	364
298	333
38	372
328	276
227	216
327	2
234	146
319	189
406	121
304	157
119	67
342	239
106	289
194	358
193	128
211	347
115	330
142	311
41	218
493	115
49	77
158	247
500	271
11	174
260	93
427	300
116	372
37	239
161	322
279	261
315	273
225	36
445	6
197	71
275	325
44	370
122	193
302	190
398	357
223	230
444	86
24	117
250	171
466	345
279	252
496	356
167	172
71	168
76	386
279	285
47	169
36	172
344	395
424	34
24	222
224	10
65	323
402	145
116	299
251	346
23	153
159	115
69	324
88	213
384	28
163	27
387	213
123	136
87	95
263	277
431	114
421	378
416	235
5	391
378	186
63	158
344	64
156	364
233	323
417	276
87	153
13	322
293	285
139	351
351	188
326	391
335	103
444	347
493	271
214	84
111	197
173	112
137	325
109	388
13	177
218	2
277	364
213	387
482	69
110	283
214	68
437	354
201	73
328	385
163	383
70	270
393	332
280	274
381	360
278	364
228	331
393	313
412	386
110	97
345	112
128	153
222	385
364	385
440	119
241	345
231	305
247	341
128	211
376	324
241	75
380	234
247	124
276	213
60	365
184	155
117	40
49	393
39	399
391	245
300	89
68	272
182	119
36	210
53	39
10	139
291	336
50	109
144	376
134	60
31	10
122	261
123	117
459	379
262	40
337	42
464	105
219	56
168	154
287	32
408	80
157	156
392	33
307	96
153	178
397	86
166	210
363	324
134	104
57	245
392	268
1	12
19	180
91	149
475	7
477	130
154	123
107	17
292	5
350	349
125	72
301	28
47	27
154	226
11	46
371	191
324	205
407	342
379	351
340	45
367	158
191	58
416	203
66	393
88	394
151	114
428	110
295	52
473	230
108	249
471	154
130	335
22	328
459	182
399	76
490	190
61	47
341	79
116	210
180	293
345	391
80	238
266	206
322	358
316	375
447	95
302	377
115	367
131	323
439	57
458	123
118	100
56	127
300	144
251	65
36	208
41	238
324	377
126	176
229	370
288	158
446	178
128	14
92	48
13	34
143	49
353	3
\.


--
-- TOC entry 5145 (class 0 OID 17015)
-- Dependencies: 232
-- Data for Name: islearning; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.islearning (sid, lid) FROM stdin;
627	247
761	210
513	243
597	224
453	121
443	184
682	191
705	202
455	158
778	146
783	121
601	230
747	195
806	119
438	199
645	183
678	180
471	250
462	192
718	127
584	136
479	101
681	245
586	236
606	160
498	132
741	128
571	220
771	156
477	185
539	106
730	231
419	180
556	204
631	127
518	168
682	190
750	154
686	160
747	176
739	190
531	161
426	206
657	120
606	182
623	216
728	180
422	110
443	151
744	142
467	117
612	117
799	172
598	191
717	237
507	189
520	208
529	195
713	132
542	241
553	152
616	190
490	203
736	115
711	189
567	190
413	132
622	242
570	204
523	110
583	161
618	128
697	183
629	146
576	140
629	240
633	112
766	147
767	210
467	107
416	132
508	117
762	140
564	143
457	169
732	108
792	168
772	199
478	237
587	153
721	238
475	204
695	109
507	147
516	214
583	124
737	191
646	171
497	228
538	229
655	158
457	164
604	174
627	194
504	114
552	163
427	150
557	107
806	201
587	233
440	223
713	220
495	159
591	132
497	214
564	115
551	194
510	153
807	101
498	169
625	228
697	244
746	118
546	120
477	249
755	221
768	169
508	102
673	160
635	152
426	158
528	187
520	183
659	109
761	138
675	233
806	155
731	250
462	116
545	132
508	232
511	228
429	186
682	204
750	119
756	190
516	190
590	139
463	193
518	227
729	163
443	242
674	245
573	171
687	202
671	105
674	101
740	186
572	230
685	116
662	114
678	247
442	245
494	246
480	119
682	226
749	136
717	202
632	225
602	221
495	247
436	179
513	161
753	133
519	222
715	106
468	113
736	156
659	229
505	180
517	154
694	195
686	191
668	161
743	182
672	140
678	192
577	149
755	174
684	132
533	210
684	150
703	239
557	203
604	153
579	218
750	207
460	127
743	168
811	186
585	158
508	185
782	168
556	189
626	186
702	154
772	249
775	156
677	115
472	222
620	218
459	121
438	107
631	233
551	231
676	164
687	164
501	132
775	106
460	140
449	201
684	104
534	165
785	192
473	176
646	104
486	124
602	192
763	118
799	202
716	195
629	145
724	144
532	230
659	200
706	141
605	238
580	163
786	231
661	236
425	136
626	126
726	222
428	150
603	240
541	167
629	158
449	200
693	170
733	117
730	237
617	180
660	249
798	201
734	207
486	105
726	114
810	184
483	216
569	139
492	157
531	234
805	217
678	185
806	191
765	153
675	116
487	163
656	130
786	230
802	193
619	211
709	123
789	241
449	154
730	182
698	248
804	131
550	224
541	166
807	145
808	119
788	150
516	118
417	234
648	237
580	130
530	120
735	162
578	169
495	171
561	125
744	219
531	121
600	211
660	122
510	165
492	147
778	226
795	166
461	150
607	115
762	245
586	159
755	215
448	225
487	153
724	227
737	175
463	210
797	235
575	131
522	134
496	234
523	111
694	249
534	108
587	123
456	179
565	193
589	169
660	220
699	211
746	143
621	121
630	188
630	197
654	145
499	131
671	234
443	236
591	134
741	167
450	131
413	240
763	191
574	175
671	126
786	183
413	105
797	216
811	132
530	208
552	137
550	204
806	139
687	209
436	209
728	219
565	192
765	128
721	198
769	211
736	195
568	239
705	226
652	229
569	185
432	207
612	174
550	190
491	113
532	163
515	241
620	123
586	139
559	122
464	159
598	131
526	210
719	110
769	224
811	113
772	140
604	147
750	201
699	137
695	185
461	107
522	123
677	244
810	108
540	247
658	221
521	243
481	188
777	205
453	135
779	147
601	217
663	210
515	204
507	200
447	195
806	106
488	214
555	115
806	133
458	182
595	169
413	8
\.


--
-- TOC entry 5144 (class 0 OID 16997)
-- Dependencies: 231
-- Data for Name: lesson; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.lesson (lid, lname, duration, lessontype, opendate, cid, tid, llevel, lessonday, price, roomnum) FROM stdin;
8	Lesson5	41	Guitar	2026-07-25	389	152	\N	\N	\N	\N
10	Lesson7	58	Violin	2026-01-23	354	89	\N	\N	\N	\N
11	Lesson8	58	Guitar	2026-09-27	138	236	\N	\N	\N	\N
13	Lesson10	63	Piano	2026-06-24	347	196	\N	\N	\N	\N
14	Lesson11	38	Piano	2026-12-02	152	304	\N	\N	\N	\N
15	Lesson12	58	Violin	2026-05-08	416	399	\N	\N	\N	\N
16	Lesson13	79	Piano	2026-11-23	455	371	\N	\N	\N	\N
17	Lesson14	74	Drums	2026-07-03	26	198	\N	\N	\N	\N
18	Lesson15	106	Singing	2026-09-14	367	183	\N	\N	\N	\N
19	Lesson16	63	Singing	2026-02-04	240	266	\N	\N	\N	\N
20	Lesson17	117	Guitar	2026-05-03	189	271	\N	\N	\N	\N
409	Guitar 101	60	Guitar	\N	\N	\N	\N	\N	\N	\N
22	Lesson19	88	Violin	2026-04-05	341	95	\N	\N	\N	\N
2	Guitar Chords	45	Group	2025-11-19	2	2	Beginner	1	150.00	6
24	Lesson21	92	Singing	2026-08-19	175	347	\N	\N	\N	\N
25	Lesson22	38	Singing	2026-08-09	203	43	\N	\N	\N	\N
26	Lesson23	115	Piano	2026-10-11	480	312	\N	\N	\N	\N
27	Lesson24	35	Violin	2026-01-19	270	90	\N	\N	\N	\N
28	Lesson25	43	Drums	2026-08-03	200	383	\N	\N	\N	\N
29	Lesson26	67	Piano	2026-12-01	320	222	\N	\N	\N	\N
30	Lesson27	68	Drums	2026-05-20	482	98	\N	\N	\N	\N
3	Violin Mastery	90	Individual	2025-11-20	3	3	\N	1	150.00	6
32	Lesson29	57	Violin	2026-11-26	73	9	\N	\N	\N	\N
33	Lesson30	36	Drums	2026-01-27	238	7	\N	\N	\N	\N
34	Lesson31	70	Violin	2026-04-11	117	130	\N	\N	\N	\N
35	Lesson32	33	Singing	2026-01-14	56	158	\N	\N	\N	\N
6	Lesson3	119	Violin	2025-12-12	223	132	\N	2	120.00	7
37	Lesson34	52	Singing	2026-12-02	447	289	\N	\N	\N	\N
38	Lesson35	43	Singing	2026-10-18	116	39	\N	\N	\N	\N
40	Lesson37	67	Piano	2026-06-06	175	355	\N	\N	\N	\N
41	Lesson38	59	Violin	2026-11-10	338	148	\N	\N	\N	\N
43	Lesson40	50	Singing	2025-11-30	306	263	\N	\N	\N	\N
44	Lesson41	105	Drums	2025-12-25	424	84	\N	\N	\N	\N
45	Lesson42	30	Violin	2026-02-19	55	225	\N	\N	\N	\N
414	Vocal Technique	60	\N	\N	\N	\N	Intermediate	2	180.00	9
47	Lesson44	93	Drums	2026-05-28	251	65	\N	\N	\N	\N
48	Lesson45	50	Singing	2026-10-06	333	8	\N	\N	\N	\N
49	Lesson46	76	Drums	2026-01-24	349	311	\N	\N	\N	\N
50	Lesson47	50	Drums	2026-12-11	494	186	\N	\N	\N	\N
51	Lesson48	76	Drums	2026-03-24	119	238	\N	\N	\N	\N
52	Lesson49	87	Singing	2026-11-21	300	276	\N	\N	\N	\N
53	Lesson50	50	Drums	2026-03-15	418	376	\N	\N	\N	\N
54	Lesson51	81	Guitar	2025-12-18	305	123	\N	\N	\N	\N
55	Lesson52	87	Singing	2026-09-02	50	244	\N	\N	\N	\N
56	Lesson53	43	Drums	2026-09-11	64	336	\N	\N	\N	\N
415	Beginner Drums	30	\N	\N	\N	\N	Beginner	4	150.00	\N
58	Lesson55	39	Guitar	2026-10-15	314	260	\N	\N	\N	\N
59	Lesson56	86	Guitar	2026-08-30	405	130	\N	\N	\N	\N
60	Lesson57	75	Guitar	2026-09-28	358	194	\N	\N	\N	\N
61	Lesson58	88	Guitar	2026-03-30	133	184	\N	\N	\N	\N
62	Lesson59	79	Singing	2026-10-23	393	320	\N	\N	\N	\N
63	Lesson60	41	Guitar	2026-11-20	141	186	\N	\N	\N	\N
64	Lesson61	62	Violin	2025-12-19	292	61	\N	\N	\N	\N
65	Lesson62	59	Violin	2026-10-25	201	289	\N	\N	\N	\N
66	Lesson63	97	Violin	2026-11-12	40	330	\N	\N	\N	\N
68	Lesson65	119	Guitar	2026-03-24	220	47	\N	\N	\N	\N
69	Lesson66	30	Drums	2026-10-06	470	346	\N	\N	\N	\N
70	Lesson67	83	Guitar	2026-07-08	93	48	\N	\N	\N	\N
71	Lesson68	51	Guitar	2026-07-14	262	367	\N	\N	\N	\N
72	Lesson69	86	Violin	2026-12-03	101	150	\N	\N	\N	\N
73	Lesson70	102	Piano	2026-10-11	190	246	\N	\N	\N	\N
74	Lesson71	84	Singing	2026-01-08	335	76	\N	\N	\N	\N
75	Lesson72	41	Guitar	2026-03-27	470	61	\N	\N	\N	\N
76	Lesson73	66	Drums	2026-01-10	278	62	\N	\N	\N	\N
77	Lesson74	38	Piano	2026-06-09	441	145	\N	\N	\N	\N
78	Lesson75	33	Drums	2026-06-27	306	149	\N	\N	\N	\N
79	Lesson76	112	Violin	2026-12-24	151	60	\N	\N	\N	\N
80	Lesson77	108	Singing	2026-11-23	462	25	\N	\N	\N	\N
81	Lesson78	45	Guitar	2026-07-18	42	102	\N	\N	\N	\N
82	Lesson79	79	Singing	2026-02-01	271	361	\N	\N	\N	\N
83	Lesson80	85	Violin	2026-07-23	108	154	\N	\N	\N	\N
84	Lesson81	68	Drums	2026-11-06	272	344	\N	\N	\N	\N
85	Lesson82	54	Guitar	2025-12-23	83	229	\N	\N	\N	\N
86	Lesson83	118	Violin	2026-02-22	215	377	\N	\N	\N	\N
87	Lesson84	95	Guitar	2026-03-17	232	126	\N	\N	\N	\N
88	Lesson85	117	Violin	2026-05-17	158	332	\N	\N	\N	\N
90	Lesson87	120	Drums	2026-01-01	414	281	\N	\N	\N	\N
93	Lesson90	114	Guitar	2026-08-24	374	113	\N	\N	\N	\N
94	Lesson91	75	Singing	2025-12-14	463	190	\N	\N	\N	\N
95	Lesson92	83	Singing	2026-01-02	265	46	\N	\N	\N	\N
96	Lesson93	71	Violin	2026-02-02	183	94	\N	\N	\N	\N
97	Lesson94	40	Drums	2025-11-30	418	294	\N	\N	\N	\N
98	Lesson95	86	Violin	2026-07-18	273	220	\N	\N	\N	\N
99	Lesson96	102	Drums	2026-09-05	422	273	\N	\N	\N	\N
100	Lesson97	37	Violin	2026-11-19	361	246	\N	\N	\N	\N
101	Lesson98	81	Drums	2026-04-23	123	12	\N	\N	\N	\N
102	Lesson99	102	Singing	2026-09-23	388	78	\N	\N	\N	\N
104	Lesson101	120	Drums	2026-03-30	356	55	\N	\N	\N	\N
105	Lesson102	31	Piano	2026-05-27	273	398	\N	\N	\N	\N
106	Lesson103	50	Drums	2026-03-04	306	213	\N	\N	\N	\N
107	Lesson104	49	Violin	2026-07-16	380	56	\N	\N	\N	\N
108	Lesson105	51	Guitar	2026-02-18	92	42	\N	\N	\N	\N
109	Lesson106	82	Violin	2026-10-23	179	313	\N	\N	\N	\N
110	Lesson107	106	Drums	2025-12-08	399	9	\N	\N	\N	\N
111	Lesson108	96	Guitar	2026-01-31	4	181	\N	\N	\N	\N
112	Lesson109	77	Drums	2026-11-17	358	80	\N	\N	\N	\N
113	Lesson110	96	Piano	2026-12-17	228	250	\N	\N	\N	\N
114	Lesson111	112	Singing	2026-09-26	466	152	\N	\N	\N	\N
116	Lesson113	108	Guitar	2025-11-29	451	140	\N	\N	\N	\N
4	Lesson1	99	Guitar	2026-06-18	267	297	\N	\N	500.00	\N
118	Lesson115	111	Singing	2026-03-01	284	271	\N	\N	\N	\N
119	Lesson116	76	Violin	2026-04-28	424	327	\N	\N	\N	\N
7	Lesson4	60	Drums	2026-05-15	24	387	\N	\N	999.00	\N
5	Lesson2	72	Piano	2025-12-01	397	217	\N	\N	\N	\N
413	Heavy Metal Soloing	45	\N	\N	\N	\N	Advanced	3	229.21	\N
120	Lesson117	104	Singing	2026-10-22	395	162	\N	\N	\N	\N
121	Lesson118	104	Violin	2026-05-19	350	375	\N	\N	\N	\N
122	Lesson119	91	Guitar	2026-08-26	180	196	\N	\N	\N	\N
123	Lesson120	58	Guitar	2025-12-02	455	173	\N	\N	\N	\N
124	Lesson121	72	Guitar	2026-09-19	309	198	\N	\N	\N	\N
125	Lesson122	99	Guitar	2026-11-07	139	249	\N	\N	\N	\N
126	Lesson123	63	Guitar	2026-10-28	450	71	\N	\N	\N	\N
128	Lesson125	54	Violin	2026-04-25	181	33	\N	\N	\N	\N
129	Lesson126	31	Guitar	2026-01-02	206	120	\N	\N	\N	\N
130	Lesson127	73	Violin	2026-07-11	444	203	\N	\N	\N	\N
131	Lesson128	42	Drums	2025-12-22	125	135	\N	\N	\N	\N
132	Lesson129	91	Guitar	2026-11-28	276	14	\N	\N	\N	\N
134	Lesson131	94	Singing	2026-04-24	440	77	\N	\N	\N	\N
135	Lesson132	115	Singing	2025-11-21	430	224	\N	\N	\N	\N
137	Lesson134	94	Drums	2026-07-21	291	298	\N	\N	\N	\N
138	Lesson135	103	Violin	2025-11-27	312	292	\N	\N	\N	\N
139	Lesson136	89	Drums	2026-12-05	134	135	\N	\N	\N	\N
140	Lesson137	105	Piano	2026-10-08	71	377	\N	\N	\N	\N
141	Lesson138	75	Guitar	2026-06-19	15	195	\N	\N	\N	\N
142	Lesson139	55	Drums	2026-01-15	129	33	\N	\N	\N	\N
143	Lesson140	52	Singing	2026-11-30	307	28	\N	\N	\N	\N
144	Lesson141	58	Singing	2026-12-25	77	44	\N	\N	\N	\N
145	Lesson142	98	Singing	2026-09-15	475	318	\N	\N	\N	\N
146	Lesson143	31	Singing	2026-10-14	424	160	\N	\N	\N	\N
148	Lesson145	77	Drums	2025-12-12	87	27	\N	\N	\N	\N
149	Lesson146	107	Singing	2026-12-25	457	164	\N	\N	\N	\N
150	Lesson147	119	Drums	2026-07-01	419	28	\N	\N	\N	\N
151	Lesson148	114	Drums	2025-11-21	71	383	\N	\N	\N	\N
152	Lesson149	77	Violin	2026-05-28	158	148	\N	\N	\N	\N
153	Lesson150	114	Drums	2026-04-25	208	261	\N	\N	\N	\N
154	Lesson151	108	Drums	2026-06-03	277	175	\N	\N	\N	\N
155	Lesson152	52	Guitar	2026-11-13	430	123	\N	\N	\N	\N
156	Lesson153	68	Violin	2026-07-22	164	233	\N	\N	\N	\N
157	Lesson154	57	Guitar	2026-11-29	31	400	\N	\N	\N	\N
158	Lesson155	103	Drums	2026-05-23	481	204	\N	\N	\N	\N
159	Lesson156	97	Singing	2026-05-29	312	218	\N	\N	\N	\N
160	Lesson157	53	Violin	2026-10-31	267	99	\N	\N	\N	\N
162	Lesson159	45	Drums	2026-06-26	8	154	\N	\N	\N	\N
163	Lesson160	94	Violin	2026-12-13	91	6	\N	\N	\N	\N
164	Lesson161	80	Piano	2026-12-21	406	166	\N	\N	\N	\N
165	Lesson162	48	Piano	2026-09-09	323	365	\N	\N	\N	\N
166	Lesson163	90	Drums	2026-11-19	55	192	\N	\N	\N	\N
168	Lesson165	53	Violin	2025-12-16	187	193	\N	\N	\N	\N
169	Lesson166	73	Singing	2026-09-24	357	73	\N	\N	\N	\N
170	Lesson167	80	Singing	2025-12-25	39	380	\N	\N	\N	\N
171	Lesson168	52	Drums	2026-10-04	225	61	\N	\N	\N	\N
172	Lesson169	106	Guitar	2026-10-11	468	64	\N	\N	\N	\N
173	Lesson170	84	Guitar	2026-10-13	71	144	\N	\N	\N	\N
175	Lesson172	34	Guitar	2026-02-04	275	18	\N	\N	\N	\N
176	Lesson173	111	Drums	2026-12-26	57	294	\N	\N	\N	\N
177	Lesson174	72	Drums	2025-12-06	483	376	\N	\N	\N	\N
179	Lesson176	65	Singing	2026-09-20	449	38	\N	\N	\N	\N
180	Lesson177	97	Drums	2026-08-24	98	180	\N	\N	\N	\N
181	Lesson178	85	Drums	2026-03-10	176	283	\N	\N	\N	\N
182	Lesson179	79	Singing	2026-07-13	424	247	\N	\N	\N	\N
183	Lesson180	95	Guitar	2025-11-27	270	160	\N	\N	\N	\N
184	Lesson181	73	Singing	2026-10-24	263	128	\N	\N	\N	\N
185	Lesson182	63	Violin	2026-07-11	265	363	\N	\N	\N	\N
188	Lesson185	86	Piano	2026-05-09	382	51	\N	\N	\N	\N
189	Lesson186	80	Drums	2026-02-06	88	64	\N	\N	\N	\N
190	Lesson187	68	Drums	2026-07-07	250	72	\N	\N	\N	\N
191	Lesson188	67	Singing	2026-01-28	209	257	\N	\N	\N	\N
192	Lesson189	109	Guitar	2026-11-30	254	28	\N	\N	\N	\N
193	Lesson190	89	Violin	2026-08-30	427	240	\N	\N	\N	\N
194	Lesson191	47	Violin	2025-12-02	381	317	\N	\N	\N	\N
195	Lesson192	84	Guitar	2026-04-08	123	297	\N	\N	\N	\N
196	Lesson193	110	Piano	2026-05-17	35	252	\N	\N	\N	\N
197	Lesson194	67	Guitar	2026-01-11	56	152	\N	\N	\N	\N
199	Lesson196	85	Drums	2026-07-16	97	151	\N	\N	\N	\N
200	Lesson197	44	Drums	2026-05-24	12	140	\N	\N	\N	\N
202	Lesson199	77	Violin	2026-04-12	386	73	\N	\N	\N	\N
203	Lesson200	108	Drums	2026-04-21	361	347	\N	\N	\N	\N
204	Lesson201	111	Singing	2026-09-04	122	357	\N	\N	\N	\N
205	Lesson202	48	Guitar	2026-03-21	283	215	\N	\N	\N	\N
206	Lesson203	105	Piano	2026-05-01	423	164	\N	\N	\N	\N
207	Lesson204	35	Singing	2025-11-18	417	102	\N	\N	\N	\N
208	Lesson205	38	Violin	2026-05-02	406	291	\N	\N	\N	\N
209	Lesson206	101	Guitar	2026-05-15	33	34	\N	\N	\N	\N
210	Lesson207	44	Violin	2026-06-28	215	196	\N	\N	\N	\N
212	Lesson209	83	Singing	2026-12-04	178	334	\N	\N	\N	\N
213	Lesson210	117	Singing	2026-08-16	132	382	\N	\N	\N	\N
215	Lesson212	104	Singing	2026-01-27	198	385	\N	\N	\N	\N
216	Lesson213	101	Guitar	2026-06-25	140	156	\N	\N	\N	\N
217	Lesson214	69	Singing	2026-05-22	485	153	\N	\N	\N	\N
218	Lesson215	106	Guitar	2026-01-09	92	270	\N	\N	\N	\N
219	Lesson216	114	Violin	2026-11-16	472	275	\N	\N	\N	\N
220	Lesson217	95	Singing	2026-03-05	141	316	\N	\N	\N	\N
221	Lesson218	42	Violin	2025-12-09	429	343	\N	\N	\N	\N
223	Lesson220	114	Guitar	2026-05-12	51	26	\N	\N	\N	\N
224	Lesson221	95	Singing	2026-02-05	41	353	\N	\N	\N	\N
225	Lesson222	110	Singing	2026-03-20	177	326	\N	\N	\N	\N
227	Lesson224	114	Drums	2026-07-12	254	308	\N	\N	\N	\N
228	Lesson225	37	Drums	2026-02-24	362	105	\N	\N	\N	\N
229	Lesson226	112	Singing	2026-10-10	205	112	\N	\N	\N	\N
230	Lesson227	80	Singing	2026-03-01	479	220	\N	\N	\N	\N
231	Lesson228	62	Violin	2026-10-02	277	5	\N	\N	\N	\N
232	Lesson229	57	Singing	2026-12-29	489	154	\N	\N	\N	\N
233	Lesson230	44	Singing	2026-12-07	87	248	\N	\N	\N	\N
235	Lesson232	51	Singing	2025-12-04	162	188	\N	\N	\N	\N
236	Lesson233	104	Drums	2026-02-11	315	114	\N	\N	\N	\N
237	Lesson234	108	Drums	2026-02-15	357	43	\N	\N	\N	\N
238	Lesson235	60	Piano	2026-05-31	318	178	\N	\N	\N	\N
240	Lesson237	41	Violin	2026-11-08	99	78	\N	\N	\N	\N
241	Lesson238	85	Drums	2026-03-08	15	52	\N	\N	\N	\N
243	Lesson240	32	Drums	2026-12-03	475	71	\N	\N	\N	\N
244	Lesson241	56	Singing	2026-07-14	130	63	\N	\N	\N	\N
245	Lesson242	35	Guitar	2026-06-27	64	291	\N	\N	\N	\N
247	Lesson244	45	Violin	2026-07-27	308	232	\N	\N	\N	\N
248	Lesson245	109	Singing	2026-07-07	360	65	\N	\N	\N	\N
249	Lesson246	60	Guitar	2026-07-21	490	135	\N	\N	\N	\N
251	Lesson248	90	Violin	2025-12-21	358	370	\N	\N	\N	\N
252	Lesson249	106	Violin	2026-01-03	76	381	\N	\N	\N	\N
253	Lesson250	79	Guitar	2026-02-28	216	353	\N	\N	\N	\N
254	Lesson251	119	Drums	2026-01-15	101	205	\N	\N	\N	\N
255	Lesson252	88	Drums	2026-12-19	347	366	\N	\N	\N	\N
256	Lesson253	36	Violin	2026-09-25	355	104	\N	\N	\N	\N
257	Lesson254	57	Violin	2026-03-21	491	116	\N	\N	\N	\N
258	Lesson255	107	Violin	2026-01-25	295	62	\N	\N	\N	\N
259	Lesson256	60	Singing	2026-04-02	356	294	\N	\N	\N	\N
260	Lesson257	75	Violin	2026-03-21	162	284	\N	\N	\N	\N
261	Lesson258	70	Piano	2026-10-21	101	32	\N	\N	\N	\N
262	Lesson259	80	Singing	2026-05-27	282	188	\N	\N	\N	\N
263	Lesson260	74	Singing	2026-08-01	91	167	\N	\N	\N	\N
264	Lesson261	112	Guitar	2026-07-02	476	315	\N	\N	\N	\N
265	Lesson262	94	Singing	2026-12-26	334	234	\N	\N	\N	\N
266	Lesson263	75	Piano	2026-02-09	413	18	\N	\N	\N	\N
267	Lesson264	80	Drums	2026-12-21	190	29	\N	\N	\N	\N
268	Lesson265	53	Singing	2026-05-06	350	151	\N	\N	\N	\N
269	Lesson266	86	Singing	2026-05-25	326	151	\N	\N	\N	\N
270	Lesson267	108	Singing	2026-06-26	34	223	\N	\N	\N	\N
271	Lesson268	87	Violin	2026-03-09	170	378	\N	\N	\N	\N
272	Lesson269	101	Violin	2025-12-28	118	331	\N	\N	\N	\N
274	Lesson271	95	Singing	2026-05-20	467	26	\N	\N	\N	\N
275	Lesson272	60	Singing	2026-02-16	476	259	\N	\N	\N	\N
276	Lesson273	89	Drums	2026-05-11	166	153	\N	\N	\N	\N
277	Lesson274	117	Violin	2026-10-14	266	77	\N	\N	\N	\N
278	Lesson275	103	Singing	2026-08-25	209	211	\N	\N	\N	\N
280	Lesson277	110	Drums	2026-06-05	446	330	\N	\N	\N	\N
281	Lesson278	84	Violin	2026-01-21	150	177	\N	\N	\N	\N
283	Lesson280	45	Singing	2026-09-22	109	359	\N	\N	\N	\N
284	Lesson281	115	Violin	2026-07-24	427	46	\N	\N	\N	\N
285	Lesson282	38	Violin	2026-07-04	426	181	\N	\N	\N	\N
286	Lesson283	61	Singing	2026-01-26	448	34	\N	\N	\N	\N
287	Lesson284	65	Violin	2026-03-22	306	248	\N	\N	\N	\N
288	Lesson285	118	Guitar	2026-05-04	236	212	\N	\N	\N	\N
289	Lesson286	64	Guitar	2026-05-03	200	247	\N	\N	\N	\N
291	Lesson288	83	Drums	2025-11-29	57	247	\N	\N	\N	\N
292	Lesson289	106	Violin	2026-09-02	258	338	\N	\N	\N	\N
293	Lesson290	64	Drums	2025-12-31	144	187	\N	\N	\N	\N
294	Lesson291	63	Guitar	2026-02-01	396	112	\N	\N	\N	\N
295	Lesson292	49	Guitar	2026-08-16	21	62	\N	\N	\N	\N
296	Lesson293	107	Violin	2026-09-21	322	320	\N	\N	\N	\N
297	Lesson294	62	Drums	2026-03-09	404	126	\N	\N	\N	\N
298	Lesson295	62	Violin	2025-12-17	58	357	\N	\N	\N	\N
300	Lesson297	47	Drums	2026-04-23	408	249	\N	\N	\N	\N
301	Lesson298	51	Guitar	2026-11-30	284	330	\N	\N	\N	\N
302	Lesson299	52	Drums	2026-05-07	102	393	\N	\N	\N	\N
303	Lesson300	117	Drums	2026-08-27	110	49	\N	\N	\N	\N
304	Lesson301	96	Drums	2026-11-20	258	215	\N	\N	\N	\N
306	Lesson303	66	Violin	2026-09-04	347	207	\N	\N	\N	\N
307	Lesson304	107	Drums	2026-06-06	396	232	\N	\N	\N	\N
308	Lesson305	33	Violin	2026-09-10	178	207	\N	\N	\N	\N
310	Lesson307	31	Drums	2026-04-05	391	161	\N	\N	\N	\N
311	Lesson308	97	Piano	2026-05-17	217	157	\N	\N	\N	\N
312	Lesson309	117	Singing	2025-12-31	259	208	\N	\N	\N	\N
313	Lesson310	57	Singing	2026-06-09	488	167	\N	\N	\N	\N
314	Lesson311	101	Singing	2026-10-11	150	271	\N	\N	\N	\N
315	Lesson312	46	Guitar	2026-03-13	451	25	\N	\N	\N	\N
317	Lesson314	46	Piano	2026-02-22	207	320	\N	\N	\N	\N
318	Lesson315	69	Piano	2026-07-23	336	309	\N	\N	\N	\N
320	Lesson317	41	Violin	2026-05-20	85	148	\N	\N	\N	\N
321	Lesson318	66	Drums	2026-01-23	271	171	\N	\N	\N	\N
322	Lesson319	53	Drums	2026-12-25	251	71	\N	\N	\N	\N
323	Lesson320	51	Guitar	2026-02-23	336	334	\N	\N	\N	\N
324	Lesson321	31	Singing	2026-10-15	135	81	\N	\N	\N	\N
325	Lesson322	89	Guitar	2026-12-06	351	364	\N	\N	\N	\N
326	Lesson323	38	Guitar	2026-07-18	293	234	\N	\N	\N	\N
327	Lesson324	72	Drums	2026-04-26	85	69	\N	\N	\N	\N
328	Lesson325	62	Drums	2026-10-04	409	389	\N	\N	\N	\N
329	Lesson326	74	Drums	2025-12-10	334	304	\N	\N	\N	\N
330	Lesson327	117	Violin	2026-08-12	421	360	\N	\N	\N	\N
331	Lesson328	91	Drums	2026-09-30	405	133	\N	\N	\N	\N
332	Lesson329	77	Piano	2026-11-14	193	138	\N	\N	\N	\N
333	Lesson330	82	Piano	2026-05-27	485	18	\N	\N	\N	\N
334	Lesson331	111	Singing	2026-05-07	415	287	\N	\N	\N	\N
335	Lesson332	32	Singing	2026-02-26	71	171	\N	\N	\N	\N
336	Lesson333	110	Singing	2026-03-05	166	381	\N	\N	\N	\N
337	Lesson334	43	Singing	2026-09-30	241	308	\N	\N	\N	\N
338	Lesson335	113	Guitar	2025-12-05	231	31	\N	\N	\N	\N
340	Lesson337	86	Guitar	2026-07-10	254	273	\N	\N	\N	\N
341	Lesson338	82	Singing	2026-12-01	493	198	\N	\N	\N	\N
343	Lesson340	34	Guitar	2026-07-11	234	242	\N	\N	\N	\N
344	Lesson341	38	Piano	2026-10-18	30	214	\N	\N	\N	\N
345	Lesson342	41	Violin	2026-07-24	252	386	\N	\N	\N	\N
346	Lesson343	94	Violin	2026-07-03	335	260	\N	\N	\N	\N
347	Lesson344	65	Singing	2026-09-27	126	62	\N	\N	\N	\N
348	Lesson345	46	Violin	2026-03-30	121	262	\N	\N	\N	\N
349	Lesson346	108	Drums	2025-12-05	138	153	\N	\N	\N	\N
350	Lesson347	55	Drums	2026-03-03	390	207	\N	\N	\N	\N
351	Lesson348	96	Violin	2026-09-27	88	381	\N	\N	\N	\N
352	Lesson349	35	Violin	2026-07-03	452	136	\N	\N	\N	\N
353	Lesson350	84	Singing	2026-11-10	325	134	\N	\N	\N	\N
354	Lesson351	100	Violin	2026-11-19	147	242	\N	\N	\N	\N
355	Lesson352	30	Singing	2025-12-11	11	141	\N	\N	\N	\N
356	Lesson353	108	Singing	2026-09-12	143	74	\N	\N	\N	\N
357	Lesson354	35	Guitar	2026-08-20	28	202	\N	\N	\N	\N
358	Lesson355	32	Singing	2026-01-21	61	399	\N	\N	\N	\N
359	Lesson356	101	Violin	2026-11-03	237	113	\N	\N	\N	\N
360	Lesson357	95	Drums	2026-12-11	157	221	\N	\N	\N	\N
361	Lesson358	96	Piano	2026-06-27	217	384	\N	\N	\N	\N
362	Lesson359	77	Drums	2026-07-06	67	92	\N	\N	\N	\N
363	Lesson360	108	Violin	2026-11-07	347	216	\N	\N	\N	\N
364	Lesson361	106	Violin	2026-06-03	352	222	\N	\N	\N	\N
365	Lesson362	94	Singing	2026-06-04	312	139	\N	\N	\N	\N
366	Lesson363	71	Singing	2026-02-20	123	262	\N	\N	\N	\N
367	Lesson364	51	Guitar	2026-08-22	230	288	\N	\N	\N	\N
369	Lesson366	33	Guitar	2025-12-17	36	258	\N	\N	\N	\N
370	Lesson367	42	Violin	2026-04-09	151	28	\N	\N	\N	\N
371	Lesson368	58	Guitar	2026-01-03	253	189	\N	\N	\N	\N
372	Lesson369	113	Singing	2026-01-01	46	373	\N	\N	\N	\N
373	Lesson370	80	Violin	2026-10-23	394	150	\N	\N	\N	\N
374	Lesson371	118	Singing	2026-11-25	451	268	\N	\N	\N	\N
375	Lesson372	116	Guitar	2026-03-27	470	317	\N	\N	\N	\N
376	Lesson373	98	Drums	2026-08-29	467	56	\N	\N	\N	\N
377	Lesson374	100	Singing	2025-12-24	135	328	\N	\N	\N	\N
378	Lesson375	115	Piano	2026-10-17	135	65	\N	\N	\N	\N
379	Lesson376	115	Drums	2026-01-25	468	402	\N	\N	\N	\N
380	Lesson377	75	Guitar	2026-04-05	247	329	\N	\N	\N	\N
381	Lesson378	66	Guitar	2026-07-22	459	42	\N	\N	\N	\N
382	Lesson379	64	Piano	2026-11-27	33	359	\N	\N	\N	\N
383	Lesson380	117	Violin	2026-07-01	500	372	\N	\N	\N	\N
384	Lesson381	36	Singing	2026-11-15	173	275	\N	\N	\N	\N
386	Lesson383	62	Singing	2026-10-24	392	319	\N	\N	\N	\N
387	Lesson384	111	Singing	2026-09-02	230	177	\N	\N	\N	\N
388	Lesson385	93	Guitar	2026-02-06	349	212	\N	\N	\N	\N
389	Lesson386	98	Violin	2026-11-03	4	127	\N	\N	\N	\N
390	Lesson387	107	Violin	2026-08-15	243	190	\N	\N	\N	\N
392	Lesson389	68	Drums	2026-02-25	55	23	\N	\N	\N	\N
393	Lesson390	41	Drums	2026-06-11	181	326	\N	\N	\N	\N
395	Lesson392	52	Guitar	2026-05-01	395	129	\N	\N	\N	\N
396	Lesson393	50	Singing	2026-06-15	185	191	\N	\N	\N	\N
397	Lesson394	72	Singing	2025-12-03	324	147	\N	\N	\N	\N
399	Lesson396	56	Guitar	2026-09-24	207	105	\N	\N	\N	\N
400	Lesson397	43	Violin	2026-03-16	467	342	\N	\N	\N	\N
401	Lesson398	96	Piano	2026-05-05	61	178	\N	\N	\N	\N
402	Lesson399	112	Guitar	2026-05-01	89	304	\N	\N	\N	\N
403	Lesson400	66	Violin	2026-01-01	214	282	\N	\N	\N	\N
404	Test Lesson No Teacher	60	Piano	2025-11-20	\N	\N	\N	\N	\N	\N
405	Guitar for Beginners	45	Guitar	2025-11-20	\N	\N	\N	\N	\N	\N
1	Piano Basics	60	Individual	2025-11-18	1	401	\N	\N	\N	\N
440	Expert Session Sherwood Lilloe	60	\N	\N	\N	4	Advanced	4	241.82	10
437	Expert Session Sherwood Lilloe	60	\N	\N	\N	4	Advanced	3	280.78	7
438	Expert Session Sherwood Lilloe	60	\N	\N	\N	4	Advanced	3	238.38	8
439	Expert Session Sherwood Lilloe	60	\N	\N	\N	4	Advanced	5	303.71	9
441	Piano Masterclass	60	\N	\N	\N	1	Advanced	\N	286.52	6
443	Advanced Jazz	90	\N	\N	\N	1	Advanced	\N	401.12	6
9	Lesson6	96	Piano	2025-12-01	409	287	\N	\N	\N	\N
12	Lesson9	54	Piano	2025-12-01	106	172	\N	\N	\N	\N
21	Lesson18	71	Piano	2025-12-01	244	277	\N	\N	\N	\N
23	Lesson20	118	Piano	2025-12-01	327	18	\N	\N	\N	\N
31	Lesson28	119	Piano	2025-12-01	368	146	\N	\N	\N	\N
36	Lesson33	43	Piano	2025-12-01	186	320	\N	\N	\N	\N
39	Lesson36	44	Piano	2025-12-01	193	38	\N	\N	\N	\N
42	Lesson39	120	Piano	2025-12-01	61	94	\N	\N	\N	\N
46	Lesson43	33	Piano	2025-12-01	443	390	\N	\N	\N	\N
57	Lesson54	79	Piano	2025-12-01	197	69	\N	\N	\N	\N
67	Lesson64	111	Piano	2025-12-01	321	133	\N	\N	\N	\N
89	Lesson86	113	Piano	2025-12-01	306	152	\N	\N	\N	\N
91	Lesson88	44	Piano	2025-12-01	103	294	\N	\N	\N	\N
92	Lesson89	95	Piano	2025-12-01	187	298	\N	\N	\N	\N
103	Lesson100	104	Piano	2025-12-01	317	219	\N	\N	\N	\N
115	Lesson112	115	Piano	2025-12-01	281	209	\N	\N	\N	\N
117	Lesson114	97	Piano	2025-12-01	363	263	\N	\N	\N	\N
127	Lesson124	62	Piano	2025-12-01	492	9	\N	\N	\N	\N
133	Lesson130	114	Piano	2025-12-01	89	197	\N	\N	\N	\N
136	Lesson133	103	Piano	2025-12-01	494	179	\N	\N	\N	\N
147	Lesson144	102	Piano	2025-12-01	469	231	\N	\N	\N	\N
161	Lesson158	103	Piano	2025-12-01	302	327	\N	\N	\N	\N
167	Lesson164	118	Piano	2025-12-01	38	173	\N	\N	\N	\N
174	Lesson171	117	Piano	2025-12-01	201	180	\N	\N	\N	\N
178	Lesson175	100	Piano	2025-12-01	314	396	\N	\N	\N	\N
186	Lesson183	84	Piano	2025-12-01	107	310	\N	\N	\N	\N
187	Lesson184	88	Piano	2025-12-01	126	167	\N	\N	\N	\N
198	Lesson195	68	Piano	2025-12-01	18	317	\N	\N	\N	\N
201	Lesson198	82	Piano	2025-12-01	368	323	\N	\N	\N	\N
211	Lesson208	75	Piano	2025-12-01	14	115	\N	\N	\N	\N
214	Lesson211	104	Piano	2025-12-01	184	13	\N	\N	\N	\N
222	Lesson219	103	Piano	2025-12-01	72	300	\N	\N	\N	\N
226	Lesson223	109	Piano	2025-12-01	312	257	\N	\N	\N	\N
234	Lesson231	53	Piano	2025-12-01	151	319	\N	\N	\N	\N
239	Lesson236	68	Piano	2025-12-01	269	389	\N	\N	\N	\N
242	Lesson239	114	Piano	2025-12-01	366	21	\N	\N	\N	\N
246	Lesson243	113	Piano	2025-12-01	444	103	\N	\N	\N	\N
250	Lesson247	89	Piano	2025-12-01	345	371	\N	\N	\N	\N
273	Lesson270	89	Piano	2025-12-01	232	302	\N	\N	\N	\N
279	Lesson276	58	Piano	2025-12-01	442	101	\N	\N	\N	\N
282	Lesson279	44	Piano	2025-12-01	398	214	\N	\N	\N	\N
290	Lesson287	110	Piano	2025-12-01	194	205	\N	\N	\N	\N
299	Lesson296	65	Piano	2025-12-01	167	164	\N	\N	\N	\N
305	Lesson302	60	Piano	2025-12-01	374	125	\N	\N	\N	\N
309	Lesson306	112	Piano	2025-12-01	442	18	\N	\N	\N	\N
316	Lesson313	63	Piano	2025-12-01	208	76	\N	\N	\N	\N
319	Lesson316	92	Piano	2025-12-01	338	355	\N	\N	\N	\N
339	Lesson336	66	Piano	2025-12-01	293	40	\N	\N	\N	\N
342	Lesson339	33	Piano	2025-12-01	15	41	\N	\N	\N	\N
368	Lesson365	76	Piano	2025-12-01	75	318	\N	\N	\N	\N
385	Lesson382	30	Piano	2025-12-01	234	78	\N	\N	\N	\N
391	Lesson388	46	Piano	2025-12-01	470	234	\N	\N	\N	\N
394	Lesson391	74	Piano	2025-12-01	312	350	\N	\N	\N	\N
398	Lesson395	54	Piano	2025-12-01	246	156	\N	\N	\N	\N
442	Guitar Basics	45	\N	\N	\N	1	Beginner	\N	120.00	6
412	Advanced Piano Masterclass	60	\N	\N	\N	\N	Advanced	1	286.52	8
416	Masterclass Mohandis Giberd	60	\N	\N	\N	2	Advanced	2	285.37	6
417	Masterclass Mohandis Giberd	60	\N	\N	\N	2	Advanced	5	291.10	7
418	Masterclass Mohandis Giberd	60	\N	\N	\N	2	Advanced	4	281.93	8
419	Masterclass Mohandis Giberd	60	\N	\N	\N	2	Advanced	1	236.10	9
420	Masterclass Mohandis Giberd	60	\N	\N	\N	2	Advanced	2	264.74	10
421	Expert Session Mohandis Giberd	60	\N	\N	\N	2	Advanced	5	237.23	6
422	Expert Session Mohandis Giberd	60	\N	\N	\N	2	Advanced	4	247.55	7
423	Expert Session Mohandis Giberd	60	\N	\N	\N	2	Advanced	2	288.80	8
424	Expert Session Mohandis Giberd	60	\N	\N	\N	2	Advanced	1	333.50	9
425	Expert Session Mohandis Giberd	60	\N	\N	\N	2	Advanced	1	330.07	10
426	Advanced Workshop Mohandis Giberd	60	\N	\N	\N	2	Advanced	2	334.65	6
427	Advanced Workshop Mohandis Giberd	60	\N	\N	\N	2	Advanced	1	283.08	7
428	Advanced Workshop Mohandis Giberd	60	\N	\N	\N	2	Advanced	2	294.53	8
429	Advanced Workshop Mohandis Giberd	60	\N	\N	\N	2	Advanced	5	269.32	9
430	Advanced Workshop Mohandis Giberd	60	\N	\N	\N	2	Advanced	6	319.75	10
431	Masterclass Sherwood Lilloe	60	\N	\N	\N	4	Advanced	6	280.78	6
432	Masterclass Sherwood Lilloe	60	\N	\N	\N	4	Advanced	6	249.85	7
433	Masterclass Sherwood Lilloe	60	\N	\N	\N	4	Advanced	1	296.83	8
434	Masterclass Sherwood Lilloe	60	\N	\N	\N	4	Advanced	5	333.50	9
435	Masterclass Sherwood Lilloe	60	\N	\N	\N	4	Advanced	3	280.78	10
436	Expert Session Sherwood Lilloe	60	\N	\N	\N	4	Advanced	2	275.05	6
\.


--
-- TOC entry 5146 (class 0 OID 17032)
-- Dependencies: 233
-- Data for Name: participatesin; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.participatesin (sid, aid) FROM stdin;
726	271
625	48
744	395
473	435
652	196
648	296
728	325
553	55
541	355
674	61
807	334
553	347
483	359
492	435
740	429
645	295
627	107
601	216
456	126
788	298
671	298
419	95
646	223
475	103
473	322
676	251
724	398
553	180
633	298
491	214
438	68
449	324
462	443
729	378
753	326
799	442
737	229
578	330
782	245
585	253
579	322
695	124
729	373
684	231
804	296
676	376
458	409
539	343
556	441
811	303
449	314
429	103
684	64
655	433
702	127
804	165
545	417
718	107
507	143
486	205
772	181
646	203
523	361
579	271
630	362
490	449
426	294
545	156
520	346
719	137
456	312
756	223
464	51
681	67
785	133
762	238
612	52
515	110
555	430
658	302
763	68
677	181
551	432
556	120
766	240
804	370
632	105
531	68
450	232
659	253
519	111
532	139
761	129
618	355
464	306
604	438
806	420
530	98
798	416
508	326
487	410
449	127
746	252
498	177
656	62
737	297
617	399
633	325
659	234
429	455
631	428
711	271
721	83
736	300
475	125
494	138
598	115
681	415
735	206
517	383
432	186
540	393
604	405
746	80
508	208
619	295
731	64
625	64
756	395
619	407
728	323
576	55
573	138
478	404
661	269
505	278
726	255
763	164
736	299
413	298
625	297
697	75
492	69
681	243
427	88
577	112
497	278
631	98
621	75
447	286
477	439
737	277
802	105
508	301
546	422
443	275
473	288
459	408
483	109
598	306
538	166
480	332
456	105
473	292
574	353
600	262
648	400
768	66
744	117
570	90
779	358
744	400
510	319
578	206
462	278
726	226
685	328
619	355
495	167
462	417
521	314
633	384
491	62
477	136
719	414
728	410
695	233
553	140
732	389
715	165
747	145
530	376
515	387
732	119
501	372
553	400
456	220
521	295
426	417
447	247
488	257
654	289
736	349
442	244
678	273
663	1
789	235
618	106
746	273
775	309
413	222
573	439
730	50
807	242
478	197
427	124
798	409
579	105
721	445
777	71
763	334
677	240
755	177
786	164
605	256
416	91
652	206
635	135
686	198
449	371
578	386
786	424
635	121
743	72
762	332
792	333
568	314
513	387
762	197
\.


--
-- TOC entry 5153 (class 0 OID 25431)
-- Dependencies: 243
-- Data for Name: price_audit_log; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.price_audit_log (log_id, lid, old_price, new_price, change_date, user_performing_change) FROM stdin;
1	7	\N	999.00	2025-12-30 13:17:51.824125	postgres
2	413	254.68	229.21	2025-12-30 13:19:02.073516	postgres
3	440	268.69	241.82	2025-12-30 13:19:02.073516	postgres
4	437	311.98	280.78	2025-12-30 13:19:02.073516	postgres
5	438	264.87	238.38	2025-12-30 13:19:02.073516	postgres
6	439	337.45	303.71	2025-12-30 13:19:02.073516	postgres
7	441	318.35	286.52	2025-12-30 13:19:02.073516	postgres
8	443	445.69	401.12	2025-12-30 13:19:02.073516	postgres
9	412	318.35	286.52	2025-12-30 13:19:02.073516	postgres
10	416	317.08	285.37	2025-12-30 13:19:02.073516	postgres
11	417	323.44	291.10	2025-12-30 13:19:02.073516	postgres
12	418	313.26	281.93	2025-12-30 13:19:02.073516	postgres
13	419	262.33	236.10	2025-12-30 13:19:02.073516	postgres
14	420	294.15	264.74	2025-12-30 13:19:02.073516	postgres
15	421	263.59	237.23	2025-12-30 13:19:02.073516	postgres
16	422	275.06	247.55	2025-12-30 13:19:02.073516	postgres
17	423	320.89	288.80	2025-12-30 13:19:02.073516	postgres
18	424	370.56	333.50	2025-12-30 13:19:02.073516	postgres
19	425	366.74	330.07	2025-12-30 13:19:02.073516	postgres
20	426	371.83	334.65	2025-12-30 13:19:02.073516	postgres
21	427	314.53	283.08	2025-12-30 13:19:02.073516	postgres
22	428	327.26	294.53	2025-12-30 13:19:02.073516	postgres
23	429	299.24	269.32	2025-12-30 13:19:02.073516	postgres
24	430	355.28	319.75	2025-12-30 13:19:02.073516	postgres
25	431	311.98	280.78	2025-12-30 13:19:02.073516	postgres
26	432	277.61	249.85	2025-12-30 13:19:02.073516	postgres
27	433	329.81	296.83	2025-12-30 13:19:02.073516	postgres
28	434	370.56	333.50	2025-12-30 13:19:02.073516	postgres
29	435	311.98	280.78	2025-12-30 13:19:02.073516	postgres
30	436	305.61	275.05	2025-12-30 13:19:02.073516	postgres
\.


--
-- TOC entry 5149 (class 0 OID 25371)
-- Dependencies: 236
-- Data for Name: room; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.room (roomnum, capacity, roomname) FROM stdin;
6	20	אולם פסנתר
7	15	חדר גיטרות
8	15	אולם פסנתר מרכזי
9	10	חדר כלי נשיפה
10	20	אולפן הקלטות
\.


--
-- TOC entry 5136 (class 0 OID 16963)
-- Dependencies: 223
-- Data for Name: student; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.student (sid, sname, address, enterdate) FROM stdin;
413	Cooper Videler	2 Lakewood Gardens Court	2025-12-28
416	Clemens Tondeur	313 Kropf Crossing	2025-12-28
417	Isahella O'Dogherty	71491 Northwestern Lane	2025-12-28
815	ישראל ישראלי	רחוב הרצל 1, ירושלים	2023-01-01
419	Wittie Ham	076 Loomis Road	2025-12-28
816	חנה כהן	רחוב השקד 10, תל אביב	2023-05-15
422	Filberto Mylechreest	39 Golden Leaf Pass	2025-12-28
425	Drucie Ruberry	5 Marquette Court	2025-12-28
426	Ferd Kynaston	6 Surrey Court	2025-12-28
427	Maritsa Yedy	45316 Fairfield Trail	2025-12-28
428	Ailey Najara	025 Algoma Road	2025-12-28
429	Ephrayim Shortin	7173 Florence Parkway	2025-12-28
432	Dionysus Corran	84 Straubel Drive	2025-12-28
436	Berry Pogosian	65 Scott Point	2025-12-28
438	Sherri Libero	3958 Lotheville Drive	2025-12-28
440	Carver Liffe	5031 Calypso Place	2025-12-28
442	Angelico Farrance	09375 Eliot Street	2025-12-28
443	Arlene Marrison	146 Green Parkway	2025-12-28
447	Bernette Gerasch	14 Cordelia Place	2025-12-28
448	Shay Zannutti	796 Bunting Junction	2025-12-28
449	Gothart Knevit	76 Cordelia Terrace	2025-12-28
450	Kimberlee Gibbings	2 Sherman Plaza	2025-12-28
453	Lane Petters	9 Carpenter Hill	2025-12-28
455	Skip Dorking	1 Kropf Center	2025-12-28
456	Rakel Lincke	99174 Twin Pines Center	2025-12-28
457	Kara Curee	803 Butternut Street	2025-12-28
458	Oberon Court	92179 Burning Wood Drive	2025-12-28
459	Batholomew Sybry	3264 Mitchell Parkway	2025-12-28
460	Mildred Couve	8036 Ridge Oak Alley	2025-12-28
461	Carlos Dibson	1 Dawn Terrace	2025-12-28
462	Corella Le Friec	08003 Briar Crest Point	2025-12-28
463	Reeba Bordis	06773 Magdeline Road	2025-12-28
464	Karine Cape	82194 Pond Center	2025-12-28
467	Joice Crossan	59225 Merrick Street	2025-12-28
468	Clem Joubert	06672 Harper Point	2025-12-28
471	Ettore Ocklin	7853 Nelson Parkway	2025-12-28
472	Perle Lattimer	085 Huxley Court	2025-12-28
473	Kassandra Heisman	18880 Roth Point	2025-12-28
475	Isidore Hansell	95192 Jana Junction	2025-12-28
477	Odella Spelman	7313 Bultman Parkway	2025-12-28
478	Thorny Bowering	92587 Comanche Terrace	2025-12-28
479	Viva Meneyer	42 Texas Park	2025-12-28
480	Bryana Martini	915 Scott Trail	2025-12-28
481	Rosita Dickings	474 Gina Way	2025-12-28
483	Harv Lamp	07 Elmside Road	2025-12-28
486	Wyndham Tremouille	30466 Grayhawk Junction	2025-12-28
487	Gerri Brummell	17 Transport Pass	2025-12-28
488	Layney Holley	6235 Commercial Drive	2025-12-28
490	York Chiplin	50 Buhler Way	2025-12-28
491	Harcourt Hamber	78 Summer Ridge Parkway	2025-12-28
492	Wade Arnot	422 Mcbride Pass	2025-12-28
494	Kristal Orange	7 Kropf Alley	2025-12-28
495	Tabitha Penvarden	90 Sommers Alley	2025-12-28
496	Pierre Hayller	96 Coolidge Crossing	2025-12-28
497	Lissie Davidge	6935 Troy Plaza	2025-12-28
498	Karlie Vickery	98 Rowland Trail	2025-12-28
499	Nikaniki Kinforth	1519 Ruskin Alley	2025-12-28
501	Etienne Spaice	31 Tomscot Plaza	2025-12-28
504	Vinnie Masic	5 Welch Circle	2025-12-28
505	Ciro Florence	3 Chinook Way	2025-12-28
507	Dore Mileham	378 Russell Court	2025-12-28
508	Giulietta Simpkin	20 Eagle Crest Drive	2025-12-28
510	Torin Birwhistle	3022 Meadow Ridge Park	2025-12-28
511	Berri Mattke	52930 Vahlen Way	2025-12-28
513	Lionel Guilbert	8690 Grasskamp Park	2025-12-28
515	Kristoffer Kefford	7050 Cody Court	2025-12-28
516	Lorrayne Deaconson	06 Maywood Terrace	2025-12-28
517	Allx Costanza	525 Anderson Street	2025-12-28
518	Rad Paddefield	6 Independence Drive	2025-12-28
519	Trumann Pocke	76441 Maple Hill	2025-12-28
520	Warden Jeaffreson	80382 Westport Center	2025-12-28
521	Dun Armitage	0 Moose Circle	2025-12-28
522	Halsey Noriega	05992 Arapahoe Plaza	2025-12-28
523	Bartlett Gonthard	548 American Plaza	2025-12-28
526	Tirrell Gerhartz	16 Waubesa Terrace	2025-12-28
528	Nancy Blades	242 Glacier Hill Court	2025-12-28
529	Hamish Golds	8532 Victoria Road	2025-12-28
530	Costanza Brunt	13 Milwaukee Plaza	2025-12-28
531	Heywood Ragsdall	07103 Alpine Point	2025-12-28
532	Romain Dovydenas	47316 Grayhawk Drive	2025-12-28
533	Rubina Cordes	8 Birchwood Court	2025-12-28
534	Shoshana McCrow	7783 Comanche Parkway	2025-12-28
538	Carmelia Husbands	4 Ridge Oak Place	2025-12-28
539	Breanne Calladine	5665 6th Alley	2025-12-28
540	Gun Stookes	3 Morning Road	2025-12-28
541	Lowrance Lutsch	933 Bayside Way	2025-12-28
542	Lolly Huckleby	47 Iowa Pass	2025-12-28
545	Ashia Inchboard	53 Arapahoe Trail	2025-12-28
546	Josepha Fauning	0 Kropf Lane	2025-12-28
550	Jaime Barbary	9220 Lotheville Road	2025-12-28
551	Killy Huggon	2825 Maryland Drive	2025-12-28
552	Darrick Clarridge	726 Valley Edge Avenue	2025-12-28
553	Rockie Muir	9850 New Castle Junction	2025-12-28
555	Kerwinn Don	340 Transport Street	2025-12-28
556	Jeremie Olivari	9 Esch Place	2025-12-28
557	Modesty Denson	9 Mcbride Point	2025-12-28
559	Judas Glamart	4487 Clarendon Street	2025-12-28
561	Eberhard Pyer	20 7th Trail	2025-12-28
564	Cassaundra Langabeer	1398 Gina Way	2025-12-28
565	Prisca Geerdts	247 Sheridan Alley	2025-12-28
567	Bernie Reggler	5610 Waxwing Road	2025-12-28
568	Alison Winwood	433 Clyde Gallagher Street	2025-12-28
569	August Bricket	072 Sunnyside Parkway	2025-12-28
570	Cordey Shrimplin	8 Sutherland Pass	2025-12-28
571	Florenza Ardron	6 Jenna Hill	2025-12-28
572	Stepha Arlt	94948 Waywood Drive	2025-12-28
573	Becca Round	9370 Texas Avenue	2025-12-28
574	Amalita Sellman	9490 Hansons Way	2025-12-28
575	Kim Yesichev	30 Derek Junction	2025-12-28
576	Frannie Doveston	3 Pond Pass	2025-12-28
577	Laurent Van Brug	574 Warner Trail	2025-12-28
578	Tab Backhurst	707 Iowa Drive	2025-12-28
579	Adriane Palethorpe	452 Melby Crossing	2025-12-28
580	Humfrey Maddin	18 6th Circle	2025-12-28
583	Tirrell Hove	73 Scofield Circle	2025-12-28
584	Moina Flewitt	581 Waxwing Terrace	2025-12-28
585	Calhoun Fantonetti	77295 Boyd Court	2025-12-28
586	Decca Popping	38 Hovde Center	2025-12-28
587	Andrea Nuemann	2593 Aberg Parkway	2025-12-28
589	Heall Feige	55 Acker Road	2025-12-28
590	Marsha Gethin	9793 Sycamore Lane	2025-12-28
591	Falito Kemm	9 Elka Parkway	2025-12-28
595	Shelly Dufour	718 Ronald Regan Court	2025-12-28
597	Karlene Winterflood	2765 1st Trail	2025-12-28
598	Roi Kerss	5673 Glendale Terrace	2025-12-28
600	Simone Roscher	9 Cody Avenue	2025-12-28
601	Stanfield Prestie	83 Delaware Parkway	2025-12-28
602	Merle Felgat	260 Havey Center	2025-12-28
603	Jeremie Rainy	750 Kropf Point	2025-12-28
604	Lettie Knyvett	6 Bluejay Junction	2025-12-28
605	Laurette Phillpotts	39781 Lawn Court	2025-12-28
606	Aguistin Degoy	69848 Calypso Center	2025-12-28
607	Hanson Gecks	67 Meadow Valley Lane	2025-12-28
612	Gussi Lethby	885 Dawn Place	2025-12-28
616	Phil Tattersall	1 Becker Court	2025-12-28
617	Garnet Meffin	55 Brown Crossing	2025-12-28
618	Karney Murdoch	41 Buena Vista Court	2025-12-28
619	Rose Nowill	9046 Golf Circle	2025-12-28
620	Jsandye Da Costa	6551 Harbort Street	2025-12-28
621	Benoite Stroulger	1760 Crownhardt Parkway	2025-12-28
622	Ilsa Ardley	9 Iowa Crossing	2025-12-28
623	Willi Muccino	18552 Barby Point	2025-12-28
625	Auguste Kleinzweig	67254 Stoughton Crossing	2025-12-28
626	Tann Cleatherow	1 Holy Cross Terrace	2025-12-28
627	Tab Connow	95 Goodland Drive	2025-12-28
629	Lesley Gusney	59257 Kings Trail	2025-12-28
630	Udall Overstreet	2 Fremont Terrace	2025-12-28
631	Anthe Chestney	2 Basil Terrace	2025-12-28
632	Eugenius Lecount	49650 Utah Terrace	2025-12-28
633	Gwynne Arthy	7404 Mitchell Way	2025-12-28
635	Penelope Routham	7759 Bashford Way	2025-12-28
645	Bliss Oxley	61744 Bashford Circle	2025-12-28
646	Jere Glancy	3 Vidon Center	2025-12-28
648	Adolpho Harniman	584 Sullivan Plaza	2025-12-28
652	Arlinda Leaver	294 Westend Street	2025-12-28
654	Jennee Veldens	8559 Charing Cross Center	2025-12-28
655	Izzy Robic	00768 Shasta Terrace	2025-12-28
656	Griffie Weller	2770 Milwaukee Place	2025-12-28
657	Tad Crinson	601 Vidon Plaza	2025-12-28
658	Octavia Moughtin	2 Debra Hill	2025-12-28
659	Oralle Dowda	19616 Northridge Road	2025-12-28
660	Filippa Silverstone	83338 Carberry Plaza	2025-12-28
661	Darell Rewcastle	44 Mesta Crossing	2025-12-28
662	Lukas McInally	5 Mallory Avenue	2025-12-28
663	Cleo Bordone	47358 Ludington Way	2025-12-28
668	Mitchell Busen	8115 Brown Road	2025-12-28
671	Ephraim Kohrt	613 Hagan Trail	2025-12-28
672	Benedicta Fenna	2578 Oriole Plaza	2025-12-28
673	Garland Antrag	6 Scoville Pass	2025-12-28
674	Rina Deacock	892 Hollow Ridge Road	2025-12-28
675	Chastity Milliken	61367 Fulton Place	2025-12-28
676	Siward Hurrell	2 Carpenter Trail	2025-12-28
677	Horace Banasevich	52003 Sherman Place	2025-12-28
678	Murray Shorto	636 Bartillon Drive	2025-12-28
681	Ethelin Amyes	68564 Gateway Junction	2025-12-28
682	Tamera Jiles	865 Eastwood Drive	2025-12-28
684	Elvina Cowell	434 New Castle Trail	2025-12-28
685	Koenraad Newe	2968 Garrison Avenue	2025-12-28
686	Vonni Crowdson	77 Forster Junction	2025-12-28
687	Silvain Farrant	40 Rusk Drive	2025-12-28
693	Norah Lainton	61312 Miller Drive	2025-12-28
694	Patrizius Vogeler	0 Hoard Pass	2025-12-28
695	Gaynor Aleksankov	1007 Russell Alley	2025-12-28
697	Nehemiah Killich	8 Glendale Court	2025-12-28
698	Zedekiah Batie	067 Ryan Road	2025-12-28
699	Abey Gumn	605 Roth Lane	2025-12-28
702	Lilyan Worcs	04209 Morrow Place	2025-12-28
703	Iggy Inskipp	9 Marquette Crossing	2025-12-28
705	Zena Workman	48707 Hollow Ridge Parkway	2025-12-28
706	Ferguson Klewi	2 Twin Pines Court	2025-12-28
709	Fredrika Worcs	4 Spenser Place	2025-12-28
711	Bengt Tolson	63542 Sommers Park	2025-12-28
713	Hermy Headington	97 Independence Crossing	2025-12-28
715	Georgianna Gianetti	147 Ruskin Terrace	2025-12-28
716	Maurise Castillon	76214 Goodland Alley	2025-12-28
717	Nelia Casham	05908 Hoepker Parkway	2025-12-28
718	Say Borrow	4 Veith Way	2025-12-28
719	Abra Giorgietto	063 Karstens Plaza	2025-12-28
721	Tull Gissing	731 Dennis Court	2025-12-28
724	Lisabeth Callaghan	8090 Saint Paul Park	2025-12-28
726	Adams Tethcote	45485 Derek Drive	2025-12-28
728	Pegeen Gianni	41 Monument Avenue	2025-12-28
729	Jsandye Simmens	71 Graedel Avenue	2025-12-28
730	Hamish Fenner	9 Steensland Point	2025-12-28
731	Claiborn Conigsby	09120 Portage Circle	2025-12-28
732	Adriano Gabbitus	502 Tennyson Way	2025-12-28
733	Annalise Buckthorp	88382 Ramsey Court	2025-12-28
734	Spike Simeonov	76 Anhalt Lane	2025-12-28
735	Colman Figures	552 Arapahoe Crossing	2025-12-28
736	Torr Marton	63 Columbus Alley	2025-12-28
737	Cleopatra Treanor	8999 Cardinal Circle	2025-12-28
739	Harriot Haugen	6200 Moulton Drive	2025-12-28
740	Sheena Jolliman	22 Monument Center	2025-12-28
741	Liza Branchett	3486 Pierstorff Lane	2025-12-28
743	Holly Duesberry	69 Morning Junction	2025-12-28
744	Dorita Sanchis	42769 Atwood Avenue	2025-12-28
746	Dane Gulc	38 Swallow Avenue	2025-12-28
747	Opal Rainville	8 Mitchell Plaza	2025-12-28
749	Jacquelynn Zywicki	64000 La Follette Drive	2025-12-28
750	Silvester Mariolle	6 Bartillon Hill	2025-12-28
753	Yelena Diver	7934 Sachtjen Terrace	2025-12-28
755	Lynnett Maggorini	14451 Arkansas Hill	2025-12-28
756	Sharity Cridland	0622 Carey Street	2025-12-28
761	Jeni Sidey	7287 Shopko Junction	2025-12-28
762	Alfy Incogna	2746 Mallard Street	2025-12-28
763	Jasmin Bickerdike	172 Graceland Pass	2025-12-28
765	Aile Mangam	13926 Merchant Point	2025-12-28
766	Normy Edmunds	78 Fuller Lane	2025-12-28
767	Claudia Helleckas	9 Bunting Point	2025-12-28
768	Gaile Bartrap	5 Goodland Center	2025-12-28
769	Raleigh Frisby	173 Merchant Pass	2025-12-28
771	Paddie Fairbrother	75 Lake View Hill	2025-12-28
772	Morly Rivard	43 Union Lane	2025-12-28
775	Calla Prene	87 Anniversary Street	2025-12-28
777	Lettie Kasper	899 Mayfield Crossing	2025-12-28
778	Meade Leynagh	0283 Hayes Lane	2025-12-28
779	Bayard Barends	863 Barby Terrace	2025-12-28
782	Gigi Spenceley	91060 Killdeer Hill	2025-12-28
783	Jennifer Sawday	54387 Farwell Circle	2025-12-28
785	Billye Blunkett	7672 Nancy Avenue	2025-12-28
786	Ailene Teal	717 Hazelcrest Alley	2025-12-28
788	Nicky Erskine	88 Talmadge Way	2025-12-28
789	Randee Bruckental	7 Rusk Plaza	2025-12-28
792	Robbyn Vel	843 Sutteridge Alley	2025-12-28
795	Mattie Crumpton	544 Manufacturers Plaza	2025-12-28
797	Jenn Hilliam	2 Hagan Plaza	2025-12-28
798	Tabbitha Earles	09828 Crowley Place	2025-12-28
799	Genni Frunks	69 Namekagon Avenue	2025-12-28
802	Gael Ratlee	81977 Service Junction	2025-12-28
804	Gianni Murty	657 Mandrake Pass	2025-12-28
805	Fielding Guesford	5 Crest Line Avenue	2025-12-28
806	Wolfie Danilowicz	1318 Holy Cross Way	2025-12-28
807	Winston McRuvie	248 Bartillon Avenue	2025-12-28
808	Berk Pattemore	42 Jackson Hill	2025-12-28
810	Gaspard Rosindill	659 Doe Crossing Pass	2025-12-28
811	Lyndsay Verden	34212 Sachtjen Circle	2025-12-28
\.


--
-- TOC entry 5134 (class 0 OID 16954)
-- Dependencies: 221
-- Data for Name: teacher; Type: TABLE DATA; Schema: musiclesson; Owner: -
--

COPY musiclesson.teacher (tid, tname, salary, email, specialization) FROM stdin;
2	Mohandis Giberd	12088.32	mgiberd1@digg.com	\N
4	Sherwood Lilloe	4139.45	slilloe3@last.fm	\N
5	Jamey Cicetti	8885.69	jcicetti4@eepurl.com	\N
6	Quinn MacGebenay	13774.41	qmacgebenay5@last.fm	\N
7	Rochell Godbehere	7847.44	rgodbehere6@mozilla.com	\N
8	Anthea Kochel	10194.03	akochel7@posterous.com	\N
10	Allegra Kalinowsky	6849.25	akalinowsky9@mysql.com	\N
11	Rowland Wink	3223.69	rwinka@blinklist.com	\N
12	Cassie Monckman	10063.22	cmonckmanb@uiuc.edu	\N
14	Millard Hukin	11989.21	mhukind@nyu.edu	\N
15	Catie Chilley	8050.23	cchilleye@hhs.gov	\N
16	Gottfried Denford	5635.12	gdenfordf@japanpost.jp	\N
17	Waiter Kelston	10912.98	wkelstong@wordpress.org	\N
19	Jennine Yoodall	10027.37	jyoodalli@yandex.ru	\N
20	Hugues Calf	14187.51	hcalfj@tmall.com	\N
22	Roselle Kimbell	12415.77	rkimbelll@cocolog-nifty.com	\N
23	Gregg Siggee	11316.86	gsiggeem@gizmodo.com	\N
24	Luke Fritschmann	4415.49	lfritschmannn@spotify.com	\N
25	Fallon Whetnall	8722.12	fwhetnallo@fda.gov	\N
26	Giordano Basindale	13922.61	gbasindalep@blinklist.com	\N
27	Jeromy Penny	6876.82	jpennyq@prnewswire.com	\N
28	Dudley Muddle	4907.82	dmuddler@ucsd.edu	\N
29	Margeaux Dullaghan	11384.08	mdullaghans@ebay.com	\N
30	Barty Brisson	7397.77	bbrissont@marriott.com	\N
31	Timmi Lissemore	9425.94	tlissemoreu@prnewswire.com	\N
33	Aaron Jesteco	14958.89	ajestecow@businesswire.com	\N
34	Daren Ambrogi	4054.04	dambrogix@wikia.com	\N
35	Ayn Readshall	9734.37	areadshally@hc360.com	\N
36	Mahalia Muckersie	8043.12	mmuckersiez@topsy.com	\N
37	Ervin Finnis	7712.55	efinnis10@qq.com	\N
39	Cosme Souster	11446.91	csouster12@arstechnica.com	\N
42	Ladonna Shillabeare	8522.66	lshillabeare15@livejournal.com	\N
43	Klarrisa Ellam	8825.24	kellam16@independent.co.uk	\N
44	Zorina Harwood	6480.84	zharwood17@jiathis.com	\N
45	Mariele Dixson	11034.40	mdixson18@meetup.com	\N
46	Elihu Dugdale	12808.47	edugdale19@cnn.com	\N
47	Federico Brew	10191.11	fbrew1a@home.pl	\N
48	Dotty Blaiklock	4389.66	dblaiklock1b@google.com.br	\N
49	Jolynn Crilley	3395.53	jcrilley1c@nsw.gov.au	\N
50	Harmonia Castellino	4414.58	hcastellino1d@youtu.be	\N
411	יוסי לוי	5000.00	yossi@music.com	פסנתר קלאסי
52	Silva Scartifield	4722.03	sscartifield1f@edublogs.org	\N
53	Winfield Ligerton	8031.60	wligerton1g@icq.com	\N
54	Eddi Camplejohn	13324.73	ecamplejohn1h@sohu.com	\N
55	Nettie Kruschov	14643.23	nkruschov1i@constantcontact.com	\N
56	Davide Grogor	10337.09	dgrogor1j@macromedia.com	\N
57	Gusty Rutledge	13733.56	grutledge1k@usnews.com	\N
58	Jenn Widdowfield	13461.75	jwiddowfield1l@nature.com	\N
59	Demeter Valiant	8914.26	dvaliant1m@prweb.com	\N
60	Gare Gymblett	11959.72	ggymblett1n@godaddy.com	\N
61	Kissie Capoun	3648.44	kcapoun1o@studiopress.com	\N
62	Trixi MacTrustey	7773.15	tmactrustey1p@eventbrite.com	\N
63	Bob Dugue	4086.17	bdugue1q@myspace.com	\N
64	Mira Verny	4725.75	mverny1r@barnesandnoble.com	\N
412	שרה רפאלי	5500.00	sara@music.com	גיטרה אקוסטית
66	Francene Bocock	5607.49	fbocock1t@aboutads.info	\N
67	Anett England	7291.98	aengland1u@seesaa.net	\N
68	Truman Cayle	9632.16	tcayle1v@sogou.com	\N
1	Wallace Hynson	7115.92	whynson0@amazonaws.com	פסנתר קלאסי
70	Michel Booeln	14517.50	mbooeln1x@t.co	\N
71	Tedda Midgley	3510.35	tmidgley1y@hugedomains.com	\N
72	Nikkie Havesides	9434.61	nhavesides1z@ehow.com	\N
73	Odo Lobbe	7324.13	olobbe20@hexun.com	\N
74	Eldon Bonsey	7606.60	ebonsey21@geocities.jp	\N
75	Domenic Scoyles	8153.65	dscoyles22@shareasale.com	\N
3	Cale Adnett	3512.45	cadnett2@army.mil	גיטרה חשמלית
77	Rosalind Bestall	10763.53	rbestall24@vimeo.com	\N
79	Rickert Overshott	4485.81	rovershott26@themeforest.net	\N
80	Pandora Tock	4731.88	ptock27@walmart.com	\N
81	Maisie Bidewell	12209.26	mbidewell28@people.com.cn	\N
82	Alric Kighly	14389.02	akighly29@youtube.com	\N
83	Rakel Killby	8454.24	rkillby2a@phoca.cz	\N
84	Maribelle Thirwell	12755.11	mthirwell2b@1688.com	\N
85	Vilma Doyle	14650.29	vdoyle2c@twitter.com	\N
86	Lyda Deare	5755.85	ldeare2d@answers.com	\N
87	Jamil Marval	8817.63	jmarval2e@nasa.gov	\N
88	Roi Stollwerck	14661.30	rstollwerck2f@apache.org	\N
89	Tansy Goodfield	3190.08	tgoodfield2g@cornell.edu	\N
90	Jerrilee Strahan	10289.54	jstrahan2h@elpais.com	\N
91	Stefania Slayny	8414.05	sslayny2i@earthlink.net	\N
92	Horst MacCarlich	3026.30	hmaccarlich2j@microsoft.com	\N
93	Karlens Astbury	9478.52	kastbury2k@hc360.com	\N
95	Linnie Kock	14113.23	lkock2m@apple.com	\N
96	Moe MacNamara	8371.59	mmacnamara2n@yellowbook.com	\N
97	Aldon Ayris	14678.83	aayris2o@nps.gov	\N
98	Lola Chapleo	10989.68	lchapleo2p@auda.org.au	\N
99	Erminia Corradi	10549.17	ecorradi2q@behance.net	\N
100	Kirsten Lamboll	13561.72	klamboll2r@cyberchimps.com	\N
407	Valid Teacher	1000.00	\N	\N
102	Alphonse Sorby	8057.88	asorby2t@booking.com	\N
104	Emelita Kornilyev	7141.21	ekornilyev2v@cloudflare.com	\N
105	Christoffer Addyman	12238.53	caddyman2w@ebay.com	\N
106	Thorn Finessy	11933.64	tfinessy2x@ebay.com	\N
107	Loretta Brownlea	13995.79	lbrownlea2y@jigsy.com	\N
108	Arleta Waldocke	12239.91	awaldocke2z@columbia.edu	\N
109	Chrissie Catenot	9707.24	ccatenot30@ebay.co.uk	\N
110	Horace Hinksen	6573.26	hhinksen31@hhs.gov	\N
111	Griffin Rodge	12489.49	grodge32@pagesperso-orange.fr	\N
112	Basilio McGavin	12528.01	bmcgavin33@jimdo.com	\N
113	Merrill Vaughten	4449.98	mvaughten34@wikimedia.org	\N
114	Frazer McInnes	8781.68	fmcinnes35@salon.com	\N
116	Barbara McGarahan	3084.58	bmcgarahan37@walmart.com	\N
117	Vicki Lovering	5787.53	vlovering38@nsw.gov.au	\N
118	Muhammad Caddens	10342.68	mcaddens39@deliciousdays.com	\N
119	Nana Linton	4400.37	nlinton3a@xinhuanet.com	\N
120	Erl Jerwood	11001.50	ejerwood3b@netscape.com	\N
121	Kara-lynn Stephens	4600.00	kstephens3c@studiopress.com	\N
122	Meggy Walcot	4264.40	mwalcot3d@marketwatch.com	\N
123	Aldis Stivani	8603.68	astivani3e@so-net.ne.jp	\N
124	Beatriz Airds	4245.01	bairds3f@etsy.com	\N
126	May Sarre	12925.42	msarre3h@wufoo.com	\N
127	Emile Bayle	8860.69	ebayle3i@networksolutions.com	\N
128	Noella Ferrand	12774.12	nferrand3j@epa.gov	\N
129	Rupert Jordeson	9692.51	rjordeson3k@fotki.com	\N
130	Graig Ivison	11688.05	givison3l@wsj.com	\N
131	Tanney Grinyov	3281.98	tgrinyov3m@godaddy.com	\N
132	Ulick Hardwick	4210.69	uhardwick3n@exblog.jp	\N
134	Davidson Maplesden	12140.65	dmaplesden3p@linkedin.com	\N
135	Hanny Lougheed	3978.14	hlougheed3q@tamu.edu	\N
136	Demetris Cloake	5337.06	dcloake3r@zdnet.com	\N
137	Sadye Krishtopaittis	5594.91	skrishtopaittis3s@kickstarter.com	\N
139	Taite Hambrick	4792.83	thambrick3u@com.com	\N
140	Walker Brisse	13896.46	wbrisse3v@rambler.ru	\N
141	Rufe Murfin	3954.42	rmurfin3w@tripod.com	\N
142	Gerri MacAloren	10949.45	gmacaloren3x@ow.ly	\N
143	Dru Marrow	14594.11	dmarrow3y@dell.com	\N
144	Sybil Yaldren	9960.73	syaldren3z@a8.net	\N
147	Ciro Erskine	11962.16	cerskine42@creativecommons.org	\N
148	Corrinne Juan	6034.63	cjuan43@fotki.com	\N
149	Celestine Gave	3179.33	cgave44@elpais.com	\N
150	Dodi Tilt	12595.82	dtilt45@vkontakte.ru	\N
151	Ogden Server	14887.46	oserver46@cdc.gov	\N
153	Elsie Delepine	4958.35	edelepine48@wikispaces.com	\N
154	Margaretta Martin	6705.07	mmartin49@bloomberg.com	\N
155	Phedra Cheake	12583.51	pcheake4a@japanpost.jp	\N
158	Catharina Stainfield	13478.80	cstainfield4d@google.nl	\N
159	Lena Pawsey	6185.05	lpawsey4e@amazonaws.com	\N
160	Illa Mendes	6221.85	imendes4f@narod.ru	\N
161	Jori Theze	9205.85	jtheze4g@bloomberg.com	\N
162	Casandra Coughlan	3554.00	ccoughlan4h@mit.edu	\N
163	Geri Bruckental	5656.40	gbruckental4i@about.com	\N
165	Jeannine Jakubczyk	3246.66	jjakubczyk4k@bandcamp.com	\N
168	Tonnie Musslewhite	3507.87	tmusslewhite4n@ow.ly	\N
169	Doralia Kibbee	6588.10	dkibbee4o@ucoz.com	\N
170	Marnie Docksey	8225.07	mdocksey4p@wikipedia.org	\N
171	Henka Clouter	14714.04	hclouter4q@photobucket.com	\N
174	Britni Swann	3669.45	bswann4t@state.gov	\N
175	Tripp Cadell	10356.14	tcadell4u@nsw.gov.au	\N
176	Monte Nice	13112.39	mnice4v@list-manage.com	\N
177	Bennie Eve	4256.02	beve4w@hugedomains.com	\N
181	Burgess Clooney	10911.86	bclooney50@msu.edu	\N
182	Trace Tallman	7438.00	ttallman51@cdc.gov	\N
183	Desmond Arnoll	14794.57	darnoll52@ezinearticles.com	\N
184	Hollis Tschirasche	4928.09	htschirasche53@fastcompany.com	\N
185	Hunter Hurdis	11163.93	hhurdis54@who.int	\N
186	Fulton Gloucester	10086.45	fgloucester55@cmu.edu	\N
187	Muffin Thorns	12281.44	mthorns56@blogger.com	\N
188	Ignazio Prettyjohn	3116.55	iprettyjohn57@amazonaws.com	\N
189	Phaidra Adshede	13501.14	padshede58@webnode.com	\N
190	Lonnard Sackur	8454.99	lsackur59@blog.com	\N
191	Brice Blockley	5803.68	bblockley5a@spiegel.de	\N
192	Marv Enstone	13411.64	menstone5b@bbb.org	\N
193	Jesselyn Marchant	12394.75	jmarchant5c@odnoklassniki.ru	\N
194	Buck Dowley	4525.95	bdowley5d@dedecms.com	\N
195	Byrom Gell	12536.50	bgell5e@chronoengine.com	\N
198	Jerrie Packman	5350.59	jpackman5h@mapquest.com	\N
199	Hendrick Capon	4175.06	hcapon5i@miitbeian.gov.cn	\N
200	Dyanne Shergold	14267.00	dshergold5j@cbc.ca	\N
201	Bobine Stonall	3075.50	bstonall5k@comsenz.com	\N
202	Lemar Gounot	13717.73	lgounot5l@networkadvertising.org	\N
203	Emmit Tolley	3655.95	etolley5m@barnesandnoble.com	\N
204	Melli Sanford	10411.45	msanford5n@nps.gov	\N
206	Mela Sammonds	13452.18	msammonds5p@blogspot.com	\N
207	Karlotta Salt	14402.13	ksalt5q@vistaprint.com	\N
208	Gregory Pleasance	5687.59	gpleasance5r@sphinn.com	\N
210	Jacki Issitt	10201.22	jissitt5t@tumblr.com	\N
211	Javier Collingworth	10415.40	jcollingworth5u@nasa.gov	\N
212	Fredelia Leport	3045.01	fleport5v@youtube.com	\N
213	Benoite Duffan	3961.61	bduffan5w@cocolog-nifty.com	\N
215	Konstanze Steuhlmeyer	7454.69	ksteuhlmeyer5y@noaa.gov	\N
216	Nelson Roff	5154.96	nroff5z@digg.com	\N
218	Alvina Chang	6730.59	achang61@dropbox.com	\N
220	Heath Symson	8321.89	hsymson63@cnn.com	\N
221	Casey Dukesbury	5647.32	cdukesbury64@dagondesign.com	\N
223	Oralla Inkin	3559.31	oinkin66@independent.co.uk	\N
224	Boris Lorne	8914.92	blorne67@github.io	\N
225	Rudy Melvin	9098.81	rmelvin68@cnbc.com	\N
226	Barbabas Kahan	7981.92	bkahan69@globo.com	\N
227	Towny Arpur	13851.92	tarpur6a@simplemachines.org	\N
228	Liliane Menaul	9927.67	lmenaul6b@mlb.com	\N
229	Emmaline Thaim	11582.89	ethaim6c@spiegel.de	\N
230	Ronnie Daouse	14700.27	rdaouse6d@behance.net	\N
232	Faye Stearnes	8026.06	fstearnes6f@comsenz.com	\N
233	Joby Joiris	8100.08	jjoiris6g@baidu.com	\N
235	Ashlee Negus	13244.60	anegus6i@cafepress.com	\N
236	Katherine Hanaby	7315.51	khanaby6j@ox.ac.uk	\N
237	Nels Flindall	14562.97	nflindall6k@forbes.com	\N
238	Hewe Burtwistle	4735.12	hburtwistle6l@oakley.com	\N
239	Heddie McGlaughn	14395.48	hmcglaughn6m@netscape.com	\N
240	Agosto Keeling	10468.92	akeeling6n@nsw.gov.au	\N
241	Teirtza Cheal	9452.12	tcheal6o@ucoz.com	\N
242	Angelico Aldcorne	3669.90	aaldcorne6p@fda.gov	\N
243	Lanie Gehrtz	7509.27	lgehrtz6q@livejournal.com	\N
244	Elspeth Troak	6165.25	etroak6r@addthis.com	\N
245	Joe Stickells	14405.57	jstickells6s@hp.com	\N
247	Doe Budden	6732.78	dbudden6u@spotify.com	\N
248	Sig Stean	6017.56	sstean6v@dion.ne.jp	\N
249	Daisy Janczewski	4766.30	djanczewski6w@businessweek.com	\N
251	Eliot Barthot	12190.23	ebarthot6y@4shared.com	\N
253	Hort Benn	8690.63	hbenn70@delicious.com	\N
254	Jammie Piercey	6136.00	jpiercey71@ft.com	\N
255	Ernesta Oleshunin	6880.82	eoleshunin72@arizona.edu	\N
256	Natalya Rumbellow	5250.78	nrumbellow73@google.es	\N
258	Lori Shimon	12631.01	lshimon75@cbc.ca	\N
259	Agneta Wagenen	14259.99	awagenen76@nymag.com	\N
260	Adolpho Boakes	13544.81	aboakes77@google.it	\N
261	Sunny Christoforou	5886.77	schristoforou78@hibu.com	\N
262	Fredrika Dyson	3979.37	fdyson79@nasa.gov	\N
264	Camila Carver	8805.17	ccarver7b@who.int	\N
265	Broddie Carrell	11685.45	bcarrell7c@spiegel.de	\N
266	Eilis Stores	3834.56	estores7d@cmu.edu	\N
267	Friederike Perkinson	10482.61	fperkinson7e@columbia.edu	\N
268	Eldredge Gianasi	6638.71	egianasi7f@indiatimes.com	\N
269	Jeanne Sonier	6230.24	jsonier7g@blogger.com	\N
270	Genovera Sporner	14458.69	gsporner7h@weibo.com	\N
271	Dianemarie Wilfinger	8141.75	dwilfinger7i@artisteer.com	\N
272	Jacques Foxhall	14555.16	jfoxhall7j@amazon.de	\N
273	Gusty Stobie	7303.91	gstobie7k@bizjournals.com	\N
274	Johnny Steers	3987.93	jsteers7l@mysql.com	\N
275	Joe Boaler	10067.49	jboaler7m@tripod.com	\N
276	Albert Prewett	12669.35	aprewett7n@accuweather.com	\N
278	Taite Beeswing	5672.12	tbeeswing7p@hexun.com	\N
279	Benn Balfour	7115.89	bbalfour7q@washingtonpost.com	\N
280	Malissa Djurkovic	3443.52	mdjurkovic7r@skyrock.com	\N
281	Delia Denniston	11148.70	ddenniston7s@ucla.edu	\N
282	Andriette Mityakov	9833.85	amityakov7t@angelfire.com	\N
283	Cynthy Renachowski	12477.80	crenachowski7u@stumbleupon.com	\N
284	Osgood Tight	5445.09	otight7v@clickbank.net	\N
285	Dominic Kolis	4047.76	dkolis7w@goodreads.com	\N
286	Ethan Briddle	6073.59	ebriddle7x@sourceforge.net	\N
288	Odette Jayme	14305.15	ojayme7z@baidu.com	\N
289	Jarrett Peoples	4901.56	jpeoples80@bbb.org	\N
290	Ashley Ainge	12826.88	aainge81@unc.edu	\N
291	Marigold Gowdridge	7650.69	mgowdridge82@prweb.com	\N
292	Brucie Gabel	10867.37	bgabel83@squidoo.com	\N
293	Pincus MacCague	5973.26	pmaccague84@youku.com	\N
295	Alexio McIvor	14344.42	amcivor86@nature.com	\N
296	Fernandina Bakewell	3585.29	fbakewell87@cargocollective.com	\N
297	Gustav Clink	12568.43	gclink88@abc.net.au	\N
299	Adelind Elloy	13967.23	aelloy8a@google.nl	\N
301	Benedicta Pipet	12936.58	bpipet8c@cornell.edu	\N
303	Moises Lott	9208.65	mlott8e@ustream.tv	\N
305	Sharon Preble	7048.71	spreble8g@cnbc.com	\N
306	Suzy Jecks	5099.58	sjecks8h@last.fm	\N
307	Zorah Ellif	8195.05	zellif8i@wired.com	\N
308	Betti Fader	11631.11	bfader8j@canalblog.com	\N
311	Moe Castelluzzi	3867.98	mcastelluzzi8m@state.tx.us	\N
313	Shandra Bamforth	14737.59	sbamforth8o@livejournal.com	\N
314	Tucky Ever	12288.01	tever8p@qq.com	\N
315	Brynna Loynton	12856.71	bloynton8q@behance.net	\N
316	Cherey Purvis	6474.96	cpurvis8r@purevolume.com	\N
321	Antonie Tollow	11843.80	atollow8w@printfriendly.com	\N
322	Jesse Wadforth	11382.41	jwadforth8x@vk.com	\N
324	Chelsea Bardell	5129.08	cbardell8z@symantec.com	\N
325	Gamaliel Bowhay	11893.94	gbowhay90@tiny.cc	\N
326	Arabela Guppey	6640.58	aguppey91@mozilla.com	\N
328	Klemens Benford	6135.10	kbenford93@howstuffworks.com	\N
329	Benito Laboune	12375.76	blaboune94@imgur.com	\N
330	Olag Gianotti	4682.33	ogianotti95@feedburner.com	\N
331	Amos Baudts	12788.46	abaudts96@cnet.com	\N
332	Adoree Lazar	11301.04	alazar97@elpais.com	\N
333	Maurice Treble	6997.48	mtreble98@abc.net.au	\N
334	Constantine Drewett	7690.56	cdrewett99@facebook.com	\N
335	Mariam Loache	10890.76	mloache9a@xinhuanet.com	\N
336	Glynnis Tawse	5765.22	gtawse9b@google.nl	\N
337	Teodorico Bowhey	11581.53	tbowhey9c@dedecms.com	\N
338	Mariquilla Kindell	13394.17	mkindell9d@ehow.com	\N
339	Brittani MacAloren	12801.14	bmacaloren9e@theglobeandmail.com	\N
340	Merola Roseveare	8303.12	mroseveare9f@example.com	\N
341	Nathanael Marchelli	6589.30	nmarchelli9g@whitehouse.gov	\N
342	Annamarie Upjohn	5219.91	aupjohn9h@unblog.fr	\N
343	Merla Castelain	5216.41	mcastelain9i@mysql.com	\N
344	Dominick Tick	8684.22	dtick9j@rediff.com	\N
345	Gerrie McArtan	13008.14	gmcartan9k@163.com	\N
346	Eran Tizard	6849.55	etizard9l@google.de	\N
347	Harley Hitchens	6624.01	hhitchens9m@loc.gov	\N
348	Karylin Aston	14776.68	kaston9n@mashable.com	\N
349	Jessamyn Redwin	14914.08	jredwin9o@yellowpages.com	\N
351	Zebulon Haggath	5060.33	zhaggath9q@csmonitor.com	\N
352	Esta Moreton	9346.95	emoreton9r@plala.or.jp	\N
353	Jemie Knoble	12245.47	jknoble9s@purevolume.com	\N
354	Dollie Gossage	8145.99	dgossage9t@shop-pro.jp	\N
356	Emlen Vynarde	11648.31	evynarde9v@usda.gov	\N
357	Jacquelin Shawe	7347.83	jshawe9w@examiner.com	\N
358	Annora Tadman	7760.60	atadman9x@hp.com	\N
360	Demetris Worthy	13252.40	dworthy9z@constantcontact.com	\N
361	Lia Ledgeway	11570.87	lledgewaya0@java.com	\N
362	Angelle Arons	4186.44	aaronsa1@google.ca	\N
363	Neville Bownd	13933.02	nbownda2@berkeley.edu	\N
364	Anatole Ivatts	14037.96	aivattsa3@t.co	\N
366	Sam McCully	9097.45	smccullya5@wunderground.com	\N
367	Ulrikaumeko Brettor	12115.26	ubrettora6@360.cn	\N
368	Merla O'Cannon	3182.70	mocannona7@163.com	\N
369	Borg Brigdale	5522.79	bbrigdalea8@purevolume.com	\N
370	Liana Christauffour	7081.45	lchristauffoura9@alexa.com	\N
372	Jessika Camamill	6125.07	jcamamillab@arizona.edu	\N
373	Albert Tupie	6301.26	atupieac@gov.uk	\N
374	Roy Hallam	5431.31	rhallamad@joomla.org	\N
375	Ryley Joreau	6653.67	rjoreauae@whitehouse.gov	\N
376	Ilene Martugin	9209.34	imartuginaf@amazon.co.jp	\N
378	Puff Stairmond	11125.92	pstairmondah@alexa.com	\N
379	Corry McInility	6398.72	cmcinilityai@pbs.org	\N
380	Page Bruckental	10472.49	pbruckentalaj@mashable.com	\N
381	Brandon Molyneaux	11028.09	bmolyneauxak@theglobeandmail.com	\N
382	Ailee Godball	5449.58	agodballal@auda.org.au	\N
383	Ruthie Holgan	14405.79	rholganam@ebay.com	\N
385	Lila Jeandeau	14601.49	ljeandeauao@mlb.com	\N
386	Naomi Valadez	13415.37	nvaladezap@usa.gov	\N
387	Pippo Gummie	9629.45	pgummieaq@irs.gov	\N
388	Eda Tackell	12545.33	etackellar@bizjournals.com	\N
391	Ferrel Follen	4765.17	ffollenau@geocities.com	\N
392	Cedric Logesdale	5094.76	clogesdaleav@elpais.com	\N
393	Angelita Canero	13852.43	acaneroaw@columbia.edu	\N
394	Skipton Fordy	5763.91	sfordyax@ftc.gov	\N
395	Evelyn Youde	14293.44	eyoudeay@usgs.gov	\N
397	Cindelyn Swatheridge	3090.61	cswatheridgeb0@sciencedaily.com	\N
399	Flossie Sutcliff	10830.28	fsutcliffb2@deviantart.com	\N
400	Kass Giacomoni	5019.89	kgiacomonib3@mlb.com	\N
401	Alice Cohen	5000.00	alice.cohen@example.com	\N
402	David Levi	4500.50	david.levi@example.com	\N
403	Rachel Mizrahi	5200.75	rachel.mizrahi@example.com	\N
9	Aretha Fletcher	7639.40	afletcher8@craigslist.org	\N
13	Tera De Ferrari	16399.51	tdec@hugedomains.com	\N
18	Darbee Scroxton	7672.94	dscroxtonh@oaic.gov.au	\N
21	Sara-ann Tollady	8548.98	stolladyk@bbc.co.uk	\N
32	Dewey Campagne	13100.30	dcampagnev@salon.com	\N
38	Charmian Jacobbe	7020.05	cjacobbe11@facebook.com	\N
40	Ruthe Tolliday	5601.74	rtolliday13@ifeng.com	\N
41	Tomi Spadari	16605.91	tspadari14@blogger.com	\N
51	Lillis Carmont	14062.80	lcarmont1e@macromedia.com	\N
65	Dolley Goldine	12761.53	dgoldine1s@ow.ly	\N
69	Cindee Maskrey	8613.66	cmaskrey1w@youku.com	\N
76	Golda Sanchis	15312.60	gsanchis23@skype.com	\N
78	Loralee Orritt	17678.40	lorritt25@privacy.gov.au	\N
94	Luz Dashwood	7361.65	ldashwood2l@nasa.gov	\N
101	Veronique Gwilt	9307.12	vgwilt2s@privacy.gov.au	\N
103	Mercy Rogerson	14983.79	mrogerson2u@delicious.com	\N
115	Perle Akast	4389.19	pakast36@google.pl	\N
125	Costanza Forgan	8361.37	cforgan3g@123-reg.co.uk	\N
133	Arri Rubin	11904.75	arubin3o@blogger.com	\N
138	Saundra Andrzejewski	16510.87	sandrzejewski3t@nih.gov	\N
145	Ayn Doolan	15852.01	adoolan40@virginia.edu	\N
146	Vale Pottle	7917.04	vpottle41@cbc.ca	\N
152	Abbe Dwelly	7861.30	adwelly47@hibu.com	\N
156	Debi Killeen	12583.29	dkilleen4b@weebly.com	\N
157	Fawnia Riggott	7371.91	friggott4c@harvard.edu	\N
164	Terrance Skirvane	15003.76	tskirvane4j@samsung.com	\N
166	Gabbie Saggs	6944.54	gsaggs4l@tripod.com	\N
167	Wash Devey	14560.42	wdevey4m@ustream.tv	\N
172	Lindie Dalloway	6808.07	ldalloway4r@chron.com	\N
173	Cynthie Gavaghan	6918.61	cgavaghan4s@goo.ne.jp	\N
178	Feodora Hartless	12538.90	fhartless4x@reverbnation.com	\N
179	Rosaleen Di Domenico	15912.56	rdi4y@ovh.net	\N
180	Lissie Siddeley	7733.79	lsiddeley4z@miitbeian.gov.cn	\N
196	Addia Domengue	7361.93	adomengue5f@salon.com	\N
197	Karie Dressell	10522.56	kdressell5g@redcross.org	\N
205	Maighdiln Ianitti	6027.63	mianitti5o@dion.ne.jp	\N
209	Mickie Elliker	15231.52	melliker5s@zimbio.com	\N
214	Alina Chasney	7287.18	achasney5x@github.com	\N
217	Michaela Enterle	15021.38	menterle60@stanford.edu	\N
219	Kylen Lisciandro	17128.97	klisciandro62@blogs.com	\N
222	Ema Oris	5862.52	eoris65@altervista.org	\N
231	Chanda Reeson	15994.91	creeson6e@canalblog.com	\N
234	Jules Fitchen	11548.73	jfitchen6h@paypal.com	\N
246	Gale Lanchbery	15960.78	glanchbery6t@illinois.edu	\N
250	Ange Cansdale	16133.69	acansdale6x@indiatimes.com	\N
252	Jon Lowis	9296.27	jlowis6z@cyberchimps.com	\N
257	Giffy McKeachie	4569.86	gmckeachie74@oaic.gov.au	\N
263	West Jurkowski	9410.51	wjurkowski7a@earthlink.net	\N
277	Tris Gabel	14322.92	tgabel7o@unicef.org	\N
287	Locke Latimer	14206.30	llatimer7y@1688.com	\N
294	Malinda D'Ambrogi	13965.87	mdambrogi85@msu.edu	\N
298	Cynthy Tirone	5374.27	ctirone89@cnet.com	\N
300	Heidi Wisdish	16304.11	hwisdish8b@narod.ru	\N
302	Rabbi Yare	16287.57	ryare8d@opensource.org	\N
304	Mayer Begin	15275.94	mbegin8f@globo.com	\N
309	Chantal Treneman	7005.49	ctreneman8k@businessinsider.com	\N
310	Adi Newlin	9045.99	anewlin8l@feedburner.com	\N
312	Elaine Innocenti	5842.63	einnocenti8n@sfgate.com	\N
317	Danyelle Cheng	11605.84	dcheng8s@google.ca	\N
318	Hallie Morrad	9806.45	hmorrad8t@wikipedia.org	\N
319	Corbin Fleeming	19415.60	cfleeming8u@psu.edu	\N
320	Nicolis Bank	12113.44	nbank8v@ucla.edu	\N
323	Brandtr Mc Harg	12357.62	bmc8y@sakura.ne.jp	\N
327	Agatha Sly	15437.99	asly92@google.com	\N
350	Gabriel Borris	12043.85	gborris9p@webs.com	\N
355	Charles Chewter	10820.98	cchewter9u@oaic.gov.au	\N
359	Dalton Belf	16433.96	dbelf9y@forbes.com	\N
365	Zaccaria Akitt	15770.59	zakitta4@wikia.com	\N
371	Samuel Klaaasen	12847.95	sklaaasenaa@census.gov	\N
377	Felix Antonetti	7530.90	fantonettiag@miitbeian.gov.cn	\N
384	Giovanni Melan	19128.07	gmelanan@statcounter.com	\N
389	Jane Trudgian	5157.71	jtrudgianas@people.com.cn	\N
390	Windham Somerbell	17212.35	wsomerbellat@wix.com	\N
396	Janey Brome	14069.25	jbromeaz@admin.ch	\N
398	Jordana Chard	9348.66	jchardb1@people.com.cn	\N
\.


--
-- TOC entry 5168 (class 0 OID 0)
-- Dependencies: 228
-- Name: activity_aid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.activity_aid_seq', 460, true);


--
-- TOC entry 5169 (class 0 OID 0)
-- Dependencies: 224
-- Name: class_cid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.class_cid_seq', 809, true);


--
-- TOC entry 5170 (class 0 OID 0)
-- Dependencies: 226
-- Name: equipment_eid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.equipment_eid_seq', 409, true);


--
-- TOC entry 5171 (class 0 OID 0)
-- Dependencies: 237
-- Name: feedback_fid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.feedback_fid_seq', 87, true);


--
-- TOC entry 5172 (class 0 OID 0)
-- Dependencies: 230
-- Name: lesson_lid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.lesson_lid_seq', 443, true);


--
-- TOC entry 5173 (class 0 OID 0)
-- Dependencies: 242
-- Name: price_audit_log_log_id_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.price_audit_log_log_id_seq', 30, true);


--
-- TOC entry 5174 (class 0 OID 0)
-- Dependencies: 235
-- Name: room_roomnum_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.room_roomnum_seq', 13, true);


--
-- TOC entry 5175 (class 0 OID 0)
-- Dependencies: 222
-- Name: student_sid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.student_sid_seq', 816, true);


--
-- TOC entry 5176 (class 0 OID 0)
-- Dependencies: 220
-- Name: teacher_tid_seq; Type: SEQUENCE SET; Schema: musiclesson; Owner: -
--

SELECT pg_catalog.setval('musiclesson.teacher_tid_seq', 416, true);


--
-- TOC entry 4955 (class 2606 OID 16995)
-- Name: activity activity_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.activity
    ADD CONSTRAINT activity_pkey PRIMARY KEY (aid);


--
-- TOC entry 4951 (class 2606 OID 16979)
-- Name: class class_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.class
    ADD CONSTRAINT class_pkey PRIMARY KEY (cid);


--
-- TOC entry 4953 (class 2606 OID 16987)
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (eid);


--
-- TOC entry 4967 (class 2606 OID 25396)
-- Name: feedback feedback_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.feedback
    ADD CONSTRAINT feedback_pkey PRIMARY KEY (fid);


--
-- TOC entry 4963 (class 2606 OID 17055)
-- Name: ishaving ishaving_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.ishaving
    ADD CONSTRAINT ishaving_pkey PRIMARY KEY (cid, eid);


--
-- TOC entry 4959 (class 2606 OID 17021)
-- Name: islearning islearning_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.islearning
    ADD CONSTRAINT islearning_pkey PRIMARY KEY (sid, lid);


--
-- TOC entry 4957 (class 2606 OID 17004)
-- Name: lesson lesson_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.lesson
    ADD CONSTRAINT lesson_pkey PRIMARY KEY (lid);


--
-- TOC entry 4961 (class 2606 OID 17038)
-- Name: participatesin participatesin_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.participatesin
    ADD CONSTRAINT participatesin_pkey PRIMARY KEY (sid, aid);


--
-- TOC entry 4969 (class 2606 OID 25441)
-- Name: price_audit_log price_audit_log_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.price_audit_log
    ADD CONSTRAINT price_audit_log_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4965 (class 2606 OID 25379)
-- Name: room room_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.room
    ADD CONSTRAINT room_pkey PRIMARY KEY (roomnum);


--
-- TOC entry 4949 (class 2606 OID 16970)
-- Name: student student_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (sid);


--
-- TOC entry 4947 (class 2606 OID 16961)
-- Name: teacher teacher_pkey; Type: CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.teacher
    ADD CONSTRAINT teacher_pkey PRIMARY KEY (tid);


--
-- TOC entry 4981 (class 2620 OID 25445)
-- Name: lesson trg_priceupdate; Type: TRIGGER; Schema: musiclesson; Owner: -
--

CREATE TRIGGER trg_priceupdate AFTER UPDATE ON musiclesson.lesson FOR EACH ROW EXECUTE FUNCTION musiclesson.fn_logpricechange();


--
-- TOC entry 4982 (class 2620 OID 33622)
-- Name: islearning trg_roomlimit; Type: TRIGGER; Schema: musiclesson; Owner: -
--

CREATE TRIGGER trg_roomlimit BEFORE INSERT ON musiclesson.islearning FOR EACH ROW EXECUTE FUNCTION musiclesson.fn_limitstudents();


--
-- TOC entry 4970 (class 2606 OID 25402)
-- Name: equipment equipment_roomnum_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.equipment
    ADD CONSTRAINT equipment_roomnum_fkey FOREIGN KEY (roomnum) REFERENCES musiclesson.room(roomnum);


--
-- TOC entry 4980 (class 2606 OID 25397)
-- Name: feedback feedback_sid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.feedback
    ADD CONSTRAINT feedback_sid_fkey FOREIGN KEY (sid) REFERENCES musiclesson.student(sid) ON DELETE CASCADE;


--
-- TOC entry 4978 (class 2606 OID 17056)
-- Name: ishaving ishaving_cid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.ishaving
    ADD CONSTRAINT ishaving_cid_fkey FOREIGN KEY (cid) REFERENCES musiclesson.class(cid) ON DELETE CASCADE;


--
-- TOC entry 4979 (class 2606 OID 17061)
-- Name: ishaving ishaving_eid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.ishaving
    ADD CONSTRAINT ishaving_eid_fkey FOREIGN KEY (eid) REFERENCES musiclesson.equipment(eid) ON DELETE CASCADE;


--
-- TOC entry 4974 (class 2606 OID 17027)
-- Name: islearning islearning_lid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.islearning
    ADD CONSTRAINT islearning_lid_fkey FOREIGN KEY (lid) REFERENCES musiclesson.lesson(lid) ON DELETE CASCADE;


--
-- TOC entry 4975 (class 2606 OID 17022)
-- Name: islearning islearning_sid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.islearning
    ADD CONSTRAINT islearning_sid_fkey FOREIGN KEY (sid) REFERENCES musiclesson.student(sid) ON DELETE CASCADE;


--
-- TOC entry 4971 (class 2606 OID 17005)
-- Name: lesson lesson_cid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.lesson
    ADD CONSTRAINT lesson_cid_fkey FOREIGN KEY (cid) REFERENCES musiclesson.class(cid) ON DELETE SET NULL;


--
-- TOC entry 4972 (class 2606 OID 25382)
-- Name: lesson lesson_roomnum_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.lesson
    ADD CONSTRAINT lesson_roomnum_fkey FOREIGN KEY (roomnum) REFERENCES musiclesson.room(roomnum) ON DELETE SET NULL;


--
-- TOC entry 4973 (class 2606 OID 17010)
-- Name: lesson lesson_tid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.lesson
    ADD CONSTRAINT lesson_tid_fkey FOREIGN KEY (tid) REFERENCES musiclesson.teacher(tid) ON DELETE SET NULL;


--
-- TOC entry 4976 (class 2606 OID 17044)
-- Name: participatesin participatesin_aid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.participatesin
    ADD CONSTRAINT participatesin_aid_fkey FOREIGN KEY (aid) REFERENCES musiclesson.activity(aid) ON DELETE CASCADE;


--
-- TOC entry 4977 (class 2606 OID 17039)
-- Name: participatesin participatesin_sid_fkey; Type: FK CONSTRAINT; Schema: musiclesson; Owner: -
--

ALTER TABLE ONLY musiclesson.participatesin
    ADD CONSTRAINT participatesin_sid_fkey FOREIGN KEY (sid) REFERENCES musiclesson.student(sid) ON DELETE CASCADE;


-- Completed on 2026-01-12 11:26:50

--
-- PostgreSQL database dump complete
--

\unrestrict xgcdvL9h9doKO1XJyY5WFeJ84m7NtPXli7m32NOo2LZb92w4yauyPur5XyIXY1D

