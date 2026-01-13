import tkinter as tk
import styles
from screens.students import open_students_screen
from screens.lessons import open_lessons_screen     # ייבוא חדש
from screens.registration import open_registration_screen
from screens.reports import open_reports_screen
from screens.about import open_about_screen         # ייבוא חדש

root = tk.Tk()
root.title("מערכת ניהול מוזיקה - שלב ה'")
root.geometry("500x650")
root.configure(bg=styles.BG_COLOR)

tk.Label(root, text="תפריט ניהול ראשי", font=("Arial", 22, "bold"), 
         bg=styles.BG_COLOR, fg=styles.PRIMARY_COLOR).pack(pady=40)

# רשימת כפתורים מסודרת (כל כפתור פותח מסך אחר)
tk.Button(root, text="1. ניהול תלמידים", font=("Arial", 12), width=30, height=2,
          bg="white", command=lambda: open_students_screen(root)).pack(pady=5)

tk.Button(root, text="2. ניהול שיעורים", font=("Arial", 12), width=30, height=2,
          bg="white", command=lambda: open_lessons_screen(root)).pack(pady=5)

tk.Button(root, text="3. רישום וביצוע לוגיקה", font=("Arial", 12), width=30, height=2,
          bg="white", command=lambda: open_registration_screen(root)).pack(pady=5)

tk.Button(root, text="4. דוחות ושאילתות", font=("Arial", 12), width=30, height=2,
          bg="white", command=lambda: open_reports_screen(root)).pack(pady=5)

tk.Button(root, text="5. אודות המערכת", font=("Arial", 12), width=30, height=2,
          bg="white", command=lambda: open_about_screen(root)).pack(pady=5)

# יציאה
tk.Button(root, text="יציאה", font=("Arial", 12), width=30, height=2,
          bg=styles.DANGER_COLOR, fg="white", command=root.quit).pack(pady=20)

root.mainloop()