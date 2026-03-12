-- ============================================================
-- BLOOD BANK MANAGEMENT SYSTEM
-- DML - Sample Data Insertion
-- ============================================================

-- ============================================================
-- INSERT: BloodCompatibility (universal rules)
-- ============================================================
INSERT INTO BloodCompatibility VALUES ('O-',  'O-');
INSERT INTO BloodCompatibility VALUES ('O-',  'O+');
INSERT INTO BloodCompatibility VALUES ('O-',  'A-');
INSERT INTO BloodCompatibility VALUES ('O-',  'A+');
INSERT INTO BloodCompatibility VALUES ('O-',  'B-');
INSERT INTO BloodCompatibility VALUES ('O-',  'B+');
INSERT INTO BloodCompatibility VALUES ('O-',  'AB-');
INSERT INTO BloodCompatibility VALUES ('O-',  'AB+');
INSERT INTO BloodCompatibility VALUES ('O+',  'O+');
INSERT INTO BloodCompatibility VALUES ('O+',  'A+');
INSERT INTO BloodCompatibility VALUES ('O+',  'B+');
INSERT INTO BloodCompatibility VALUES ('O+',  'AB+');
INSERT INTO BloodCompatibility VALUES ('A-',  'A-');
INSERT INTO BloodCompatibility VALUES ('A-',  'A+');
INSERT INTO BloodCompatibility VALUES ('A-',  'AB-');
INSERT INTO BloodCompatibility VALUES ('A-',  'AB+');
INSERT INTO BloodCompatibility VALUES ('A+',  'A+');
INSERT INTO BloodCompatibility VALUES ('A+',  'AB+');
INSERT INTO BloodCompatibility VALUES ('B-',  'B-');
INSERT INTO BloodCompatibility VALUES ('B-',  'B+');
INSERT INTO BloodCompatibility VALUES ('B-',  'AB-');
INSERT INTO BloodCompatibility VALUES ('B-',  'AB+');
INSERT INTO BloodCompatibility VALUES ('B+',  'B+');
INSERT INTO BloodCompatibility VALUES ('B+',  'AB+');
INSERT INTO BloodCompatibility VALUES ('AB-', 'AB-');
INSERT INTO BloodCompatibility VALUES ('AB-', 'AB+');
INSERT INTO BloodCompatibility VALUES ('AB+', 'AB+');

-- ============================================================
-- INSERT: Hospitals
-- ============================================================
INSERT INTO Hospital VALUES (1, 'AIIMS Delhi',          'New Delhi',   '9810001111', 'aiims@delhi.gov.in');
INSERT INTO Hospital VALUES (2, 'PGI Chandigarh',       'Chandigarh',  '9810002222', 'pgi@chd.gov.in');
INSERT INTO Hospital VALUES (3, 'Fortis Mohali',        'Mohali',      '9810003333', 'fortis@mohali.com');
INSERT INTO Hospital VALUES (4, 'Apollo Ludhiana',      'Ludhiana',    '9810004444', 'apollo@ldh.com');
INSERT INTO Hospital VALUES (5, 'Max Superspecialty',   'Bathinda',    '9810005555', 'max@bathinda.com');

-- ============================================================
-- INSERT: BloodInventory
-- ============================================================
-- Hospital 1 - AIIMS Delhi
INSERT INTO BloodInventory VALUES (101, 1, 'A+',  45, CURDATE());
INSERT INTO BloodInventory VALUES (102, 1, 'A-',  10, CURDATE());
INSERT INTO BloodInventory VALUES (103, 1, 'B+',  60, CURDATE());
INSERT INTO BloodInventory VALUES (104, 1, 'B-',   5, CURDATE());
INSERT INTO BloodInventory VALUES (105, 1, 'O+',  80, CURDATE());
INSERT INTO BloodInventory VALUES (106, 1, 'O-',  20, CURDATE());
INSERT INTO BloodInventory VALUES (107, 1, 'AB+', 15, CURDATE());
INSERT INTO BloodInventory VALUES (108, 1, 'AB-',  8, CURDATE());

-- Hospital 2 - PGI Chandigarh
INSERT INTO BloodInventory VALUES (201, 2, 'A+',  30, CURDATE());
INSERT INTO BloodInventory VALUES (202, 2, 'A-',   7, CURDATE());
INSERT INTO BloodInventory VALUES (203, 2, 'B+',  40, CURDATE());
INSERT INTO BloodInventory VALUES (204, 2, 'B-',   3, CURDATE());
INSERT INTO BloodInventory VALUES (205, 2, 'O+',  55, CURDATE());
INSERT INTO BloodInventory VALUES (206, 2, 'O-',  12, CURDATE());
INSERT INTO BloodInventory VALUES (207, 2, 'AB+', 10, CURDATE());
INSERT INTO BloodInventory VALUES (208, 2, 'AB-',  4, CURDATE());

-- Hospital 3 - Fortis Mohali
INSERT INTO BloodInventory VALUES (301, 3, 'A+',  20, CURDATE());
INSERT INTO BloodInventory VALUES (302, 3, 'B+',  25, CURDATE());
INSERT INTO BloodInventory VALUES (303, 3, 'O+',  35, CURDATE());
INSERT INTO BloodInventory VALUES (304, 3, 'AB+',  6, CURDATE());

-- Hospital 4 - Apollo Ludhiana
INSERT INTO BloodInventory VALUES (401, 4, 'A+',  15, CURDATE());
INSERT INTO BloodInventory VALUES (402, 4, 'B+',  18, CURDATE());
INSERT INTO BloodInventory VALUES (403, 4, 'O+',  22, CURDATE());
INSERT INTO BloodInventory VALUES (404, 4, 'O-',   5, CURDATE());

-- Hospital 5 - Max Bathinda
INSERT INTO BloodInventory VALUES (501, 5, 'A+',  10, CURDATE());
INSERT INTO BloodInventory VALUES (502, 5, 'B+',  12, CURDATE());
INSERT INTO BloodInventory VALUES (503, 5, 'O+',  18, CURDATE());

-- ============================================================
-- INSERT: BloodRequests
-- ============================================================
INSERT INTO BloodRequest VALUES (1001, 3, 'O-',  10, DATE_SUB(CURDATE(), INTERVAL 5 DAY),  'Approved');
INSERT INTO BloodRequest VALUES (1002, 4, 'AB+',  5, DATE_SUB(CURDATE(), INTERVAL 4 DAY),  'Approved');
INSERT INTO BloodRequest VALUES (1003, 5, 'B-',   8, DATE_SUB(CURDATE(), INTERVAL 3 DAY),  'Pending');
INSERT INTO BloodRequest VALUES (1004, 2, 'A-',  12, DATE_SUB(CURDATE(), INTERVAL 2 DAY),  'Pending');
INSERT INTO BloodRequest VALUES (1005, 3, 'O+',  20, DATE_SUB(CURDATE(), INTERVAL 1 DAY),  'Approved');
INSERT INTO BloodRequest VALUES (1006, 5, 'AB-',  6, CURDATE(),                            'Pending');
INSERT INTO BloodRequest VALUES (1007, 4, 'O-',  15, CURDATE(),                            'Rejected');
INSERT INTO BloodRequest VALUES (1008, 2, 'B+',  30, CURDATE(),                            'Pending');

-- ============================================================
-- INSERT: TransferLog
-- ============================================================
INSERT INTO TransferLog VALUES (2001, 1, 3, 'O-',  10, DATE_SUB(CURDATE(), INTERVAL 5 DAY));
INSERT INTO TransferLog VALUES (2002, 1, 4, 'AB+',  5, DATE_SUB(CURDATE(), INTERVAL 4 DAY));
INSERT INTO TransferLog VALUES (2003, 2, 5, 'O+',  20, DATE_SUB(CURDATE(), INTERVAL 1 DAY));
INSERT INTO TransferLog VALUES (2004, 1, 2, 'A-',   8, DATE_SUB(CURDATE(), INTERVAL 7 DAY));
INSERT INTO TransferLog VALUES (2005, 2, 3, 'B+',  15, DATE_SUB(CURDATE(), INTERVAL 10 DAY));
