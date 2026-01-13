import tkinter as tk
from tkinter import messagebox, ttk
import styles
from database import connect_db

def open_registration_screen(root):
    win = tk.Toplevel(root)
    win.title("רישום ולוגיקה")
    win.geometry("850x700")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="ניהול רישום (טבלה מקשרת + שלב ד')", font=styles.FONT_TITLE, bg=styles.BG_COLOR).pack(pady=10)

    # חלק א: טבלת רישומים קיימים (שליפה ומחיקה)
    columns = ("SID", "שם תלמיד", "LID", "סוג שיעור")
    tree = ttk.Treeview(win, columns=columns, show="headings")
    for col in columns: tree.heading(col, text=col)
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
            """)
            for row in cur.fetchall(): tree.insert("", tk.END, values=row)
            conn.close()

    def delete_registration():
        selected = tree.selection()
        if not selected: return messagebox.showwarning("שגיאה", "בחר רישום לביטול")
        vals = tree.item(selected)['values']
        if messagebox.askyesno("אישור", "לבטל את הרישום?"):
            conn = connect_db(); cur = conn.cursor()
            cur.execute("DELETE FROM musiclesson.islearning WHERE sid=%s AND lid=%s", (vals[0], vals[2]))
            conn.commit(); conn.close(); refresh_registrations()

    # חלק ב: טופס רישום ולוגיקה (שלב ד')
    card = tk.Frame(win, bg="white", padx=20, pady=20)
    card.pack(pady=10, padx=30, fill=tk.X)
    
    tk.Label(card, text="SID:", bg="white").grid(row=0, column=0)
    sid_ent = tk.Entry(card); sid_ent.grid(row=0, column=1, padx=5)
    tk.Label(card, text="LID:", bg="white").grid(row=0, column=2)
    lid_ent = tk.Entry(card); lid_ent.grid(row=0, column=3, padx=5)

    def register():
        conn = connect_db(); cur = conn.cursor()
        try:
            cur.execute("CALL musiclesson.pr_SafeRegister(%s, %s)", (sid_ent.get(), lid_ent.get()))
            conn.commit()
            msg = "\n".join(conn.notices) if conn.notices else "נרשם!"
            messagebox.showinfo("תוצאה", msg)
            refresh_registrations()
        except Exception as e: messagebox.showerror("שגיאה", str(e))
        finally: conn.close()

    tk.Button(card, text="בצע רישום (Procedure)", command=register, bg=styles.SUCCESS_COLOR, fg="white").grid(row=0, column=4, padx=5)
    tk.Button(win, text="מחק רישום נבחר", command=delete_registration, bg=styles.DANGER_COLOR, fg="white").pack(pady=5)

    refresh_registrations()