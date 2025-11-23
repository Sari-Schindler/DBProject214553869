
-- מורים
INSERT INTO teacher (tname, salary, email) VALUES
('Alice Cohen', 5000.00, 'alice.cohen@example.com'),
('David Levi', 4500.50, 'david.levi@example.com'),
('Rachel Mizrahi', 5200.75, 'rachel.mizrahi@example.com');

-- סטודנטים
INSERT INTO student (sname, address) VALUES
('Noam Ben-David', '1 Haatzmaut St, Tel Aviv'),
('Maya Shapiro', '22 Herzl St, Jerusalem'),
('Ori Levi', '15 Weizmann St, Haifa');

-- כיתות
INSERT INTO class (cname, maxstudents) VALUES
('Piano Beginners', 10),
('Guitar Intermediate', 8),
('Violin Advanced', 5);

-- ציוד
INSERT INTO equipment (type, color) VALUES
('Piano', 'Black'),
('Guitar', 'Brown'),
('Violin', 'Red');

-- פעילויות
INSERT INTO activity (place, activitydate, description) VALUES
('Concert Hall', '2025-12-01', 'Annual Winter Concert'),
('Music Studio', '2025-11-20', 'Recording Session'),
('Outdoor Park', '2025-12-10', 'Open Air Performance');

-- שיעורים
INSERT INTO lesson (lname, duration, lessontype, opendate, cid, tid) VALUES
('Piano Basics', 60, 'Individual', '2025-11-18', 1, 1),
('Guitar Chords', 45, 'Group', '2025-11-19', 2, 2),
('Violin Mastery', 90, 'Individual', '2025-11-20', 3, 3);

-- isLearning
INSERT INTO islearning (sid, lid) VALUES
(1, 1),
(2, 2),
(3, 3);

-- ParticipatesIn
INSERT INTO participatesin (sid, aid) VALUES
(1, 1),
(2, 2),
(3, 3);

-- IsHaving
INSERT INTO ishaving (cid, eid) VALUES
(1, 1),
(2, 2),
(3, 3);
