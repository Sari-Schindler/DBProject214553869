import random

# פתיחת קובץ SQL חדש
with open('islearning_400.sql', 'w', encoding='utf-8') as f:
    f.write('-- קובץ SQL ל-isLearning עם 400 שורות\n\n')
    
    for i in range(1, 401):
        sid = i  # לכל תלמיד מזהה משלו
        lid = random.randint(1, 400)  # לכל תלמיד משויך שיעור אקראי
        f.write(f"INSERT INTO MusicLesson.isLearning (SId, LId) VALUES ({sid}, {lid});\n")

print("קובץ islearning_400.sql נוצר בהצלחה!")
