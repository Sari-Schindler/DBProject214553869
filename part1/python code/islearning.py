import random

# יצירת קובץ SQL
with open('islearning_400.sql', 'w', encoding='utf-8') as f:
    f.write('-- קובץ SQL ל-IsLearning עם 400 שורות ייחודיות\n\n')

    islearning_data = set()
    while len(islearning_data) < 400:
        sid = random.randint(412, 811)   # מזהה תלמיד אקראי
        lid = random.randint(101, 250)   # מזהה שיעור אקראי
        islearning_data.add((sid, lid))  # הוספה ל-set מונעת כפילויות

    for record in islearning_data:
        f.write(f"INSERT INTO MusicLesson.IsLearning (SId, LId) VALUES ({record[0]}, {record[1]});\n")

print("קובץ islearning_400.sql נוצר בהצלחה עם 400 שורות ייחודיות!")
