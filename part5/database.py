import psycopg2

def connect_db():
    try:
        return psycopg2.connect(
            user="postgres",
            password="Mss054333@", 
            host="127.0.0.1",
            port="5433",
            database="MusicLesson" 
        )
    except Exception as error:
        print(f"Database Connection Error: {error}")
        return None