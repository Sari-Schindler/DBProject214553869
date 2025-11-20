import random

# יצירת קובץ SQL
with open('ishaving_400.sql', 'w', encoding='utf-8') as f:
    f.write('-- קובץ SQL ל-IsHaving עם 400 שורות\n\n')
    
    for i in range(1, 401):
        cid = random.randint(1, 500)   # כיתה אקראית
        eid = random.randint(1, 400)   # ציוד אקראי
        f.write(f"INSERT INTO MusicLesson.IsHaving (CId, EId) VALUES ({cid}, {eid});\n")

print("קובץ ishaving_400.sql נוצר בהצלחה!")
