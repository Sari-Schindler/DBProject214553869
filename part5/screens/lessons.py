import tkinter as tk
from tkinter import ttk, messagebox
import styles
from database import connect_db

def open_lessons_screen(root):
    win = tk.Toplevel(root)
    win.title("ניהול שיעורים")
    win.geometry("800x600")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="ניהול שיעורים", font=styles.FONT_TITLE, bg=styles.BG_COLOR).pack(pady=20)

    columns = ("ID", "סוג שיעור", "מחיר")
    tree = ttk.Treeview(win, columns=columns, show="headings")
    for col in columns: tree.heading(col, text=col)
    tree.pack(pady=10, fill=tk.BOTH, expand=True, padx=20)

    def refresh():
        for item in tree.get_children(): tree.delete(item)
        conn = connect_db()
        if conn:
            cur = conn.cursor(); cur.execute("SELECT lid, lessontype, price FROM musiclesson.lesson ORDER BY lid")
            for row in cur.fetchall(): tree.insert("", tk.END, values=row)
            conn.close()

    def update_price():
        selected = tree.selection()
        if not selected: return messagebox.showwarning("שגיאה", "בחר שיעור")
        lid = tree.item(selected)['values'][0]
        new_price = price_entry.get()
        conn = connect_db(); cur = conn.cursor()
        cur.execute("UPDATE musiclesson.lesson SET price = %s WHERE lid = %s", (new_price, lid))
        conn.commit(); conn.close(); refresh()

    input_frame = tk.Frame(win, bg=styles.BG_COLOR)
    input_frame.pack(pady=10)
    tk.Label(input_frame, text="מחיר חדש:", bg=styles.BG_COLOR).grid(row=0, column=0)
    price_entry = tk.Entry(input_frame); price_entry.grid(row=0, column=1, padx=5)
    tk.Button(input_frame, text="עדכן מחיר", command=update_price, bg=styles.ACCENT_COLOR, fg="white").grid(row=0, column=2)

    refresh()