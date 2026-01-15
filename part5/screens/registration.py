import tkinter as tk
from tkinter import messagebox, ttk
import styles
from database import connect_db

def open_registration_screen(root):
    win = tk.Toplevel(root)
    win.title("רישום ולוגיקה עסקית")
    win.geometry("900x750")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="ניהול רישום", font=styles.FONT_TITLE, bg=styles.BG_COLOR).pack(pady=10)

    columns = ("SID", "שם תלמיד", "LID", "סוג שיעור")
    tree = ttk.Treeview(win, columns=columns, show="headings")
    for col in columns: 
        tree.heading(col, text=col)
        tree.column(col, width=150, anchor=tk.CENTER)
    tree.pack(pady=10, fill=tk.BOTH, expand=True, padx=20)

    def refresh_registrations():
        for item in tree.get_children(): tree.delete(item)
        conn = connect_db()
        if conn:
            cur = conn.cursor()
            cur.execute("""
                SELECT s.sid, s.sname, l.lid, l.lessontype 
                FROM musiclesson.student s 
                JOIN musiclesson.islearning il ON s.sid = il.sid 
                JOIN musiclesson.lesson l ON il.lid = l.lid
                ORDER BY s.sid DESC
            """)
            for row in cur.fetchall(): tree.insert("", tk.END, values=row)
            conn.close()

    card = tk.Frame(win, bg="white", padx=20, pady=20, relief=tk.RIDGE, borderwidth=1)
    card.pack(pady=20, padx=30, fill=tk.X)
    
    tk.Label(card, text="SID:", bg="white").grid(row=0, column=0)
    sid_ent = tk.Entry(card); sid_ent.grid(row=0, column=1, padx=10)
    tk.Label(card, text="LID:", bg="white").grid(row=0, column=2)
    lid_ent = tk.Entry(card); lid_ent.grid(row=0, column=3, padx=10)

    def register():
        sid, lid = sid_ent.get(), lid_ent.get()
        if not sid or not lid: return messagebox.showwarning("שגיאה", "מלא שדות")
        conn = connect_db()
        if not conn: return
        conn.notices = [] 
        cur = conn.cursor()
        try:
            cur.execute("CALL musiclesson.pr_SafeRegister(%s, %s)", (sid, lid))
            conn.commit()
            notices = [n.replace("NOTICE:", "").strip() for n in conn.notices]
            msg = "\n".join(notices) if notices else "הצלחה!"
            messagebox.showinfo("תוצאה", f"הרישום בוצע!\n{msg}")
            refresh_registrations()
        except Exception as e:
            messagebox.showerror("שגיאה", f"כשל: {str(e).split('\\n')[0]}")
        finally: conn.close()

    btn_reg = tk.Button(card, text="בצע רישום (Procedure)", command=register, 
                       bg=styles.SUCCESS_COLOR, fg="white", font=("Arial", 10, "bold"), padx=10)
    btn_reg.grid(row=0, column=4, padx=10)
    styles.apply_hover(btn_reg, styles.SUCCESS_COLOR)

    refresh_registrations()