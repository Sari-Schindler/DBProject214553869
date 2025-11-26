###### Music Lesson System

**Author**
Sara Schindler

**Description**
This project is a relational database for managing a music lesson school. It includes tables for students, teachers, lessons, activities, equipment, and their relationships. The database allows tracking of which students participate in which lessons and activities, as well as which equipment is used.

The project also includes SQL scripts for creating tables, inserting data, and querying the database. It is intended as an educational project to practice database design, relational modeling, and SQL operations.

## Database Diagrams

### ERD
The ERD diagram was created using ERD PLUS and shows the relationships between the tables.
![ERD](img/ERD.png)

### DSD
The DSD diagram was created in PGADMIN after creating the tables.
![DSD](part1/img/DSD.png)

## Data Insertion
Data for all tables in the database were inserted using two methods:

### Method 1 - Python Script
All table data was inserted using a Python script. The screenshot below shows the code.
![Python Script](img/lesoonPython.png)

### Method 2 - Mockaroo
All table data was also inserted using Mockaroo. The screenshot below shows the process.
![Insert Mockaroo](img/mockaroo.png)


## SQL Files

- **createTables.sql** – Creates all the tables in the correct order.  
- **dropTables.sql** – Drops all the tables in the correct order.  
- **insertTables.sql** – Inserts the data into the tables.  
- **selectAll.sql** – Queries for verifying and displaying the table content.

---

## Additional Files
- **lesson.csv** – CSV file containing lesson data.
