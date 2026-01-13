import tkinter as tk
import styles

def open_about_screen(root):
    win = tk.Toplevel(root)
    win.title("אודות המערכת")
    win.geometry("400x300")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="מערכת ניהול בית ספר למוזיקה", font=styles.FONT_TITLE, bg=styles.BG_COLOR, fg=styles.PRIMARY_COLOR).pack(pady=30)
    
    info = """
    גרסה: 1.0
    פותח על ידי: שרה שינדלר
    פרויקט גמר - שלב ה'
    שפת פיתוח: Python & Tkinter
    בסיס נתונים: PostgreSQL
    """
    tk.Label(win, text=info, font=styles.FONT_MAIN, bg=styles.BG_COLOR, justify="center").pack(pady=10)
    
    tk.Button(win, text="סגור", command=win.destroy, bg=styles.PRIMARY_COLOR, fg="white", width=10).pack(pady=10)