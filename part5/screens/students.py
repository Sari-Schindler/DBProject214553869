import tkinter as tk
from tkinter import messagebox, ttk
import styles
from database import connect_db

def open_students_screen(root):
    win = tk.Toplevel(root)
    win.title("ניהול תלמידים")
    win.geometry("800x650")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="ניהול תלמידים (CRUD מלא)", font=styles.FONT_TITLE, bg=styles.BG_COLOR, fg=styles.PRIMARY_COLOR).pack(pady=20)

    columns = ("ID", "Name", "Address")
    tree = ttk.Treeview(win, columns=columns, show="headings")
    for col in columns: tree.heading(col, text=col)
    tree.pack(pady=10, fill=tk.BOTH, expand=True, padx=20)

    def refresh_table():
        for item in tree.get_children(): tree.delete(item)
        conn = connect_db()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT sid, sname, address FROM musiclesson.student ORDER BY sid")
            for row in cur.fetchall(): tree.insert("", tk.END, values=row)
            conn.close()

    def add_student():
        name, addr = name_entry.get(), addr_entry.get()
        if name and addr:
            conn = connect_db()
            if conn:
                cur = conn.cursor(); cur.execute("INSERT INTO musiclesson.student (sname, address) VALUES (%s, %s)", (name, addr))
                conn.commit(); conn.close()
                refresh_table()
        else: messagebox.showwarning("שגיאה", "מלא את כל השדות")

    def delete_student():
        selected = tree.selection()
        if not selected: return messagebox.showwarning("שגיאה", "בחר תלמיד")
        sid = tree.item(selected)['values'][0]
        if messagebox.askyesno("אישור", f"למחוק את תלמיד {sid}?"):
            conn = connect_db(); cur = conn.cursor()
            cur.execute("DELETE FROM musiclesson.student WHERE sid = %s", (sid,))
            conn.commit(); conn.close(); refresh_table()

    def update_student():
        selected = tree.selection()
        if not selected: return messagebox.showwarning("שגיאה", "בחר תלמיד")
        sid = tree.item(selected)['values'][0]
        name, addr = name_entry.get(), addr_entry.get()
        conn = connect_db(); cur = conn.cursor()
        cur.execute("UPDATE musiclesson.student SET sname=%s, address=%s WHERE sid=%s", (name, addr, sid))
        conn.commit(); conn.close(); refresh_table()

    input_frame = tk.Frame(win, bg=styles.BG_COLOR)
    input_frame.pack(pady=10)
    tk.Label(input_frame, text="שם:", bg=styles.BG_COLOR).grid(row=0, column=0)
    name_entry = tk.Entry(input_frame); name_entry.grid(row=0, column=1, padx=5)
    tk.Label(input_frame, text="כתובת:", bg=styles.BG_COLOR).grid(row=0, column=2)
    addr_entry = tk.Entry(input_frame); addr_entry.grid(row=0, column=3, padx=5)

    btn_frame = tk.Frame(win, bg=styles.BG_COLOR)
    btn_frame.pack(pady=10)
    tk.Button(btn_frame, text="הוסף", command=add_student, bg=styles.SUCCESS_COLOR, fg="white", width=10).pack(side=tk.LEFT, padx=5)
    tk.Button(btn_frame, text="עדכן", command=update_student, bg=styles.ACCENT_COLOR, fg="white", width=10).pack(side=tk.LEFT, padx=5)
    tk.Button(btn_frame, text="מחק", command=delete_student, bg=styles.DANGER_COLOR, fg="white", width=10).pack(side=tk.LEFT, padx=5)
    
    refresh_table()