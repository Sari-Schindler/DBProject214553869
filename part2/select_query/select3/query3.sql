SET search_path TO MusicLesson;

-- Query 3: Equipment assigned to each class
SELECT 
    c.CName AS "Class Name",
    e.Type AS "Equipment Type",
    e.Color AS "Color"
FROM IsHaving ih
JOIN Class c ON ih.CId = c.CId
JOIN Equipment e ON ih.EId = e.EId
ORDER BY c.CName;
