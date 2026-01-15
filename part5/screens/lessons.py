import tkinter as tk
from tkinter import ttk, messagebox
import styles
from database import connect_db

def open_lessons_screen(root):
    win = tk.Toplevel(root)
    win.title("ניהול שיעורים")
    win.geometry("800x700")
    win.configure(bg=styles.BG_COLOR)

    tk.Label(win, text="ניהול מערך שיעורים", font=styles.FONT_TITLE, bg=styles.BG_COLOR, fg=styles.PRIMARY_COLOR).pack(pady=20)

    columns = ("ID", "סוג שיעור", "מחיר")
    tree = ttk.Treeview(win, columns=columns, show="headings")
    for col in columns: 
        tree.heading(col, text=col)
        tree.column(col, anchor=tk.CENTER)
    tree.pack(pady=10, fill=tk.BOTH, expand=True, padx=20)

    def refresh():
        for item in tree.get_children(): tree.delete(item)
        conn = connect_db()
        if conn:
            cur = conn.cursor()
            cur.execute("SELECT lid, lessontype, price FROM musiclesson.lesson ORDER BY lid")
            for row in cur.fetchall(): tree.insert("", tk.END, values=row)
            cur.close()
            conn.close()

    def add_lesson():
        ltype, price = type_entry.get(), price_entry.get()
        if not ltype or not price: return messagebox.showwarning("שגיאה", "מלא את כל השדות")
        try:
            conn = connect_db(); cur = conn.cursor()
            cur.execute("INSERT INTO musiclesson.lesson (lessontype, price) VALUES (%s, %s)", (ltype, price))
            conn.commit(); cur.close(); conn.close(); refresh()
            type_entry.delete(0, tk.END); price_entry.delete(0, tk.END)
        except Exception as e: messagebox.showerror("שגיאה", f"כשל: {e}")

    def update_price():
        selected = tree.selection()
        if not selected: return messagebox.showwarning("שגיאה", "בחר שיעור")
        lid = tree.item(selected)['values'][0]
        new_price = price_entry.get()
        if not new_price: return messagebox.showwarning("שגיאה", "הזן מחיר")
        conn = connect_db(); cur = conn.cursor()
        cur.execute("UPDATE musiclesson.lesson SET price = %s WHERE lid = %s", (new_price, lid))
        conn.commit(); cur.close(); conn.close(); refresh()

    def delete_lesson():
        selected = tree.selection()
        if not selected: return messagebox.showwarning("שגיאה", "בחר שיעור")
        lid = tree.item(selected)['values'][0]
        if messagebox.askyesno("אישור", f"למחוק את שיעור {lid}?"):
            try:
                conn = connect_db(); cur = conn.cursor()
                cur.execute("DELETE FROM musiclesson.lesson WHERE lid = %s", (lid,))
                conn.commit(); cur.close(); conn.close(); refresh()
            except Exception as e: messagebox.showerror("שגיאה", "כשל במחיקה")

    input_frame = tk.LabelFrame(win, text="עריכה והוספה", bg=styles.BG_COLOR, padx=10, pady=10)
    input_frame.pack(pady=20, padx=20, fill=tk.X)
    tk.Label(input_frame, text="סוג:", bg=styles.BG_COLOR).grid(row=0, column=0)
    type_entry = tk.Entry(input_frame); type_entry.grid(row=0, column=1, padx=5)
    tk.Label(input_frame, text="מחיר:", bg=styles.BG_COLOR).grid(row=0, column=2)
    price_entry = tk.Entry(input_frame); price_entry.grid(row=0, column=3, padx=5)

    btn_frame = tk.Frame(win, bg=styles.BG_COLOR)
    btn_frame.pack(pady=10)

    btn_add = tk.Button(btn_frame, text="הוסף שיעור", command=add_lesson, bg=styles.SUCCESS_COLOR, fg="white", width=15)
    btn_add.pack(side=tk.LEFT, padx=5)
    styles.apply_hover(btn_add, styles.SUCCESS_COLOR)

    btn_upd = tk.Button(btn_frame, text="עדכן מחיר", command=update_price, bg=styles.ACCENT_COLOR, fg="white", width=15)
    btn_upd.pack(side=tk.LEFT, padx=5)
    styles.apply_hover(btn_upd, styles.ACCENT_COLOR)

    btn_del = tk.Button(btn_frame, text="מחק שיעור", command=delete_lesson, bg=styles.DANGER_COLOR, fg="white", width=15)
    btn_del.pack(side=tk.LEFT, padx=5)
    styles.apply_hover(btn_del, styles.DANGER_COLOR)

    refresh()