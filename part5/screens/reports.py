import tkinter as tk
from tkinter import ttk, messagebox
import styles
from database import connect_db

def open_reports_screen(root):
    win = tk.Toplevel(root)
    win.title("דוחות ושאילתות")
    win.geometry("700x500")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="דוחות מערכת (שלב ב')", font=styles.FONT_TITLE, bg=styles.BG_COLOR, fg=styles.PRIMARY_COLOR).pack(pady=20)

    tree = ttk.Treeview(win, show="headings")
    tree.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

    def run_query(q, cols):
        for item in tree.get_children(): tree.delete(item)
        conn = connect_db()
        if conn:
            cur = conn.cursor(); cur.execute(q)
            tree["columns"] = cols
            for c in cols: tree.heading(c, text=c)
            for row in cur.fetchall(): tree.insert("", tk.END, values=row)
            conn.close()

    btn_frame = tk.Frame(win, bg=styles.BG_COLOR)
    btn_frame.pack(pady=20)

    btn_month = tk.Button(btn_frame, text="פעילויות לפי חודש", command=lambda: run_query(
        "SELECT EXTRACT(MONTH FROM activitydate), COUNT(*) FROM musiclesson.activity GROUP BY 1", ("חודש", "כמות")), bg="white")
    btn_month.pack(side=tk.LEFT, padx=10)
    styles.apply_hover(btn_month, "white")
    
    btn_salary = tk.Button(btn_frame, text="ממוצע שכר מורים", command=lambda: run_query(
        "SELECT lessontype, ROUND(AVG(salary), 2) FROM musiclesson.lesson L JOIN musiclesson.teacher T ON L.tid=T.tid GROUP BY 1", ("סוג שיעור", "שכר ממוצע")), bg="white")
    btn_salary.pack(side=tk.LEFT, padx=10)
    styles.apply_hover(btn_salary, "white")