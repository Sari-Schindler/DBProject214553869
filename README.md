****Music Lesson System 

**Author**
Sara Schindler

**Description**
This project is a relational database for managing a music lesson school. It includes tables for students, teachers, lessons, activities, equipment, and their relationships. The database allows tracking of which students participate in which lessons and activities, as well as which equipment is used.

The project also includes SQL scripts for creating tables, inserting data, and querying the database. It is intended as an educational project to practice database design, relational modeling, and SQL operations.

## Phase 1: Design and Build the Database

## Database Diagrams

### ERD
The ERD diagram was created using ERD PLUS and shows the relationships between the tables.
![ERD](part1/img/ERD.png)

### DSD
The DSD diagram was created in PGADMIN after creating the tables.
![DSD](part1/img/DSD.png)

## Data Insertion
Data for all tables in the database were inserted using two methods:

### Method 1 - Python Script
All table data was inserted using a Python script. The screenshot below shows the code.
![Python Script](part1/img/lesoonPython.png)

### Method 2 - Mockaroo
All table data was also inserted using Mockaroo. The screenshot below shows the process.
![Insert Mockaroo](part1/img/mockaroo.png)


## SQL Files

- **[createTables.sql](part1/createTables.sql)** – Creates all the tables in the correct order.  
- **[dropTables.sql](part1/[dropTables.sql)** – Drops all the tables in the correct order.  
- **[insertTables.sql](part1/[insertTables.sql)** – Inserts the data into the tables.  
- **[selectAll.sql](part1/selectAll.sql)** – Queries for verifying and displaying the table content.

---

## Additional Files
- **lesson.csv** – CSV file containing lesson data.
- **[backUp](part1/musicLsson.backup)** - backup file for part 1.

## Phase 2: Queries

### Select Queries:



### [שאילתה 1](part2/select_query/select1/select1.sql) — פעילויות לפי חודש ושנה

השאילתה סופרת את מספר הפעילויות שבוצעו בכל חודש ובשנה בטבלת Activity. היא מפרקת את התאריך (ActivityDate) לשנה ולחודש, מסכמת את כמות הפעילויות לפי כל חודש ושנה ומסדרת את התוצאה לפי סדר כרונולוגי (שנה → חודש).

![image](part2/select_query/select1/q1.png).
![image](part2/select_query/select1/r1.png).


### [שאילתה 2](part2/select_query/select2/select2.sql) — ממוצע משכורות מורים לפי סוג שיעור

השאילתה מחשבת את השכר הממוצע של המורים לכל סוג שיעור בטבלת Lesson. היא מצרפת את טבלת Lesson עם טבלת Teacher לפי מזהה המורה (TId), מחשבת את השכר הממוצע לכל סוג שיעור ומסדרת את התוצאה לפי השכר הממוצע מהגבוה לנמוך.

![image](part2/select_query/select2/q2.png).
![image](part2/select_query/select2/r2.png).

### [שאילתה 3](part2/select_query/select3/select3.sql) — ציוד לפי כיתות

השאילתה מציגה את הציוד שהוקצה לכל כיתה בטבלת Class. היא משתמשת בטבלת הקשר IsHaving כדי לקשר בין כיתות לציוד, ומצטרפת גם לטבלת Equipment כדי להביא את סוג הציוד (Type) ואת צבעו (Color). התוצאה כוללת את שם הכיתה, סוג הציוד וצבעו, ומסודרת לפי שם הכיתה (CName).
![image](part2/select_query/select3/q3.png).
![image](part2/select_query/select3/r3.png).


### [שאילתה 4](part2/select_query/select3/select3.sql) - שיעורים שנפתחו השנה

השאילתה מציגה את כל השיעורים שנפתחו במהלך השנה הנוכחית מתוך טבלת Lesson. היא בודקת את שנת הפתיחה (openDate) ומשווה אותה לשנה הנוכחית, ומחזירה את שם השיעור (LName), תאריך הפתיחה, וסוג השיעור (LessonType). התוצאות מוצגות לפי תאריך הפתיחה מהחדש לישן.

![image](part2/select_query/select4/q4.png).
![image](part2/select_query/select4/r4.png).

### Delete Queries:


### [שאילתה 1](part2/Delete_query/delete/delete1.sql) - מחיקת כל התלמידים שלא רשומים לשום שיעור

השאילתה מעדכנת את שכרם של המורים המלמדים שיעורי פסנתר (Piano) בטבלת Teacher. היא משתמשת בטבלת Lesson כדי לזהות אילו מורים מלמדים שיעורים מסוג זה, ומעלה את שכרם ב־30% (מכפילה את הערך בעזרת Salary * 1.3).

![image](part2/Delete_query/delete1/d1.png).

טבלת התלמידים לפני מחיקה:
![טבלה המציגה את כל התלמידים לפני מחיקה](part2/Delete_query/delete1/before1.png).
טבלת התלמידים אחרי מחיקה:
![טבלה המציגה את כל התלמידים אחרי מחיקה](part2/Delete_query/delete1/after.png).



### Update Queries:


### [שאילתה 1](part2/Update_query/update1/update1.sql) - הגדלת משכורת המורים שמלמדים שיעורי פסנתר

השאילתה מעדכנת את שכרם של המורים המלמדים שיעורי פסנתר (Piano) בטבלת Teacher. היא משתמשת בטבלת Lesson כדי לזהות אילו מורים מלמדים שיעורים מסוג זה, ומעלה את שכרם ב־30% (מכפילה את הערך בעזרת Salary * 1.3).

![image](part2/Update_query/update1/u1.png).

משכורת המורים לפני ההעלאה:
![טבלה המציגה את שכר המורים לפני ההעלאה](part2/Update_query/update1/before.png).
משכורת המורים אחרי ההעלאה:
![טבלה המציגה את שכר המורים אחרי ההעלאה](part2/Update_query/update1/after.png).


### [שאילתה 2](part2/Update_query/update2/update2.sql) -עדכון תאריך פתיחה לשיעורי פסנתר עם מעט תלמידים

השאילתה מעדכנת את תאריך הפתיחה (openDate) של שיעורים מסוג 'Piano' לתאריך 1 בדצמבר 2025.
העדכון מתבצע רק עבור שיעורים הנלמדים בכיתות שבהן יש פחות מ־5 תלמידים.
כדי לזהות את השיעורים הללו, השאילתה משתמשת בתת־שאילתה שמצטרפת לטבלאות Lesson, Class ו־isLearning, ומחשבת את מספר התלמידים בכל שיעור.

![image](part2/Update_query/update2/u2.png).

תאריכי פתיחת השיעורים לפני השינוי:
![טבלה המציגה את תאריכי השיעורים לפני השינוי](part2/Update_query/update2/before2.png).
תאריכי פתיחת השיעורים אחרי השינוי:
![טבלה המציגה את תאריכי השיעורים אחרי השינוי](part2/Update_query/update2/after2.png).

### Constraints:
- **[Constraints.sql](part2/Constraints/Constraints.sql)**




