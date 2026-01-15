# styles.py

# צבעים קיימים
BG_COLOR = "#f0f2f5"
PRIMARY_COLOR = "#2c3e50"
SUCCESS_COLOR = "#27ae60"
ACCENT_COLOR = "#3498db"
DANGER_COLOR = "#e74c3c"
HOVER_COLOR = "#d1d1d1"  

FONT_TITLE = ("Arial", 18, "bold")
FONT_MAIN = ("Arial", 10)

def apply_hover(button, original_bg):
    """פונקציה שמוסיפה אפקט שינוי צבע לאפור בעת מעבר עכבר"""
    button.bind("<Enter>", lambda e: button.config(bg=HOVER_COLOR))
    button.bind("<Leave>", lambda e: button.config(bg=original_bg))