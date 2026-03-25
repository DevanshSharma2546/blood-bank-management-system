-- BLOOD BANK MANAGEMENT SYSTEM
-- Advanced SQL Queries - Joins, Subqueries, Aggregates, Views

-- SECTION 1: JOIN QUERIES

-- Q1: List all hospitals with their blood inventory details
SELECT 
    H.hospital_id,
    H.hospital_name,
    H.location,
    B.blood_group,
    B.quantity,
    B.last_updated
FROM Hospital H
JOIN BloodInventory B ON H.hospital_id = B.hospital_id
ORDER BY H.hospital_name, B.blood_group;

-- Q2: List all pending blood requests with hospital name and location
SELECT 
    BR.request_id,
    H.hospital_name,
    H.location,
    BR.blood_group,
    BR.requested_quantity,
    BR.request_date,
    BR.status
FROM BloodRequest BR
JOIN Hospital H ON BR.hospital_id = H.hospital_id
WHERE BR.status = 'Pending'
ORDER BY BR.request_date;

-- Q3: Transfer log with sender and receiver hospital names
SELECT 
    TL.transfer_id,
    H1.hospital_name AS from_hospital,
    H2.hospital_name AS to_hospital,
    TL.blood_group,
    TL.quantity,
    TL.transfer_date
FROM TransferLog TL
JOIN Hospital H1 ON TL.from_hospital_id = H1.hospital_id
JOIN Hospital H2 ON TL.to_hospital_id   = H2.hospital_id
ORDER BY TL.transfer_date DESC;

-- Q4: Hospitals with low stock (< 10 units) for any blood group
SELECT 
    H.hospital_name,
    H.location,
    B.blood_group,
    B.quantity AS available_units
FROM BloodInventory B
JOIN Hospital H ON B.hospital_id = H.hospital_id
WHERE B.quantity < 10
ORDER BY B.quantity ASC;

-- Q5: Blood compatibility lookup - who can receive from O- donors?
SELECT 
    BC.donor_group,
    BC.receiver_group,
    H.hospital_name,
    BI.quantity
FROM BloodCompatibility BC
JOIN BloodInventory BI ON BC.donor_group = BI.blood_group
JOIN Hospital H ON BI.hospital_id = H.hospital_id
WHERE BC.donor_group = 'O-'
ORDER BY H.hospital_name;

-- SECTION 2: SUBQUERIES

-- Q6: Hospitals that have never made a blood request
SELECT hospital_id, hospital_name, location
FROM Hospital
WHERE hospital_id NOT IN (
    SELECT DISTINCT hospital_id FROM BloodRequest
);

-- Q7: Most demanded blood group (overall)
SELECT blood_group, total_requested
FROM (
    SELECT blood_group, SUM(requested_quantity) AS total_requested
    FROM BloodRequest
    GROUP BY blood_group
) AS demand_summary
WHERE total_requested = (
    SELECT MAX(total_req)
    FROM (
        SELECT SUM(requested_quantity) AS total_req
        FROM BloodRequest
        GROUP BY blood_group
    ) AS max_table
);

-- Q8: Hospitals whose O+ inventory is below the network average
SELECT H.hospital_name, BI.quantity AS op_stock
FROM BloodInventory BI
JOIN Hospital H ON BI.hospital_id = H.hospital_id
WHERE BI.blood_group = 'O+'
  AND BI.quantity < (
    SELECT AVG(quantity) FROM BloodInventory WHERE blood_group = 'O+'
  );

-- Q9: Requests that can be fulfilled from existing inventory (same hospital)
SELECT 
    BR.request_id,
    H.hospital_name,
    BR.blood_group,
    BR.requested_quantity,
    BI.quantity AS available
FROM BloodRequest BR
JOIN Hospital H ON BR.hospital_id = H.hospital_id
JOIN BloodInventory BI 
    ON BR.hospital_id = BI.hospital_id 
    AND BR.blood_group = BI.blood_group
WHERE BR.status = 'Pending'
  AND BI.quantity >= BR.requested_quantity;

-- SECTION 3: AGGREGATE FUNCTIONS + GROUP BY + HAVING

-- Q10: Total blood demand per blood group
SELECT 
    blood_group,
    COUNT(*)                    AS total_requests,
    SUM(requested_quantity)     AS total_units_demanded,
    AVG(requested_quantity)     AS avg_units_per_request,
    MAX(requested_quantity)     AS max_single_request
FROM BloodRequest
GROUP BY blood_group
ORDER BY total_units_demanded DESC;

-- Q11: Blood groups with total demand > 20 units
SELECT 
    blood_group,
    SUM(requested_quantity) AS total_units
FROM BloodRequest
GROUP BY blood_group
HAVING SUM(requested_quantity) > 20
ORDER BY total_units DESC;

-- Q12: Total blood transferred per hospital (as sender)
SELECT 
    H.hospital_name,
    TL.blood_group,
    SUM(TL.quantity) AS units_transferred
FROM TransferLog TL
JOIN Hospital H ON TL.from_hospital_id = H.hospital_id
GROUP BY H.hospital_name, TL.blood_group
ORDER BY units_transferred DESC;

-- Q13: Network-wide blood inventory summary
SELECT 
    blood_group,
    SUM(quantity)   AS total_units,
    AVG(quantity)   AS avg_per_hospital,
    MIN(quantity)   AS min_stock,
    MAX(quantity)   AS max_stock,
    COUNT(*)        AS hospitals_stocking
FROM BloodInventory
GROUP BY blood_group
ORDER BY total_units DESC;

-- Q14: Request approval rate by hospital
SELECT 
    H.hospital_name,
    COUNT(*)                                                AS total_requests,
    SUM(CASE WHEN BR.status = 'Approved' THEN 1 ELSE 0 END) AS approved,
    SUM(CASE WHEN BR.status = 'Rejected' THEN 1 ELSE 0 END) AS rejected,
    SUM(CASE WHEN BR.status = 'Pending'  THEN 1 ELSE 0 END) AS pending
FROM BloodRequest BR
JOIN Hospital H ON BR.hospital_id = H.hospital_id
GROUP BY H.hospital_name
ORDER BY total_requests DESC;

-- SECTION 4: VIEWS

-- View 1: Monthly blood usage
CREATE OR REPLACE VIEW MonthlyBloodUsage AS
SELECT 
    MONTH(request_date)         AS month_num,
    MONTHNAME(request_date)     AS month_name,
    YEAR(request_date)          AS year_num,
    blood_group,
    SUM(requested_quantity)     AS total_units_requested,
    COUNT(*)                    AS total_requests
FROM BloodRequest
WHERE status = 'Approved'
GROUP BY YEAR(request_date), MONTH(request_date), MONTHNAME(request_date), blood_group
ORDER BY year_num, month_num, blood_group;

-- View 2: Current blood availability across all hospitals
CREATE OR REPLACE VIEW NetworkInventoryView AS
SELECT 
    H.hospital_id,
    H.hospital_name,
    H.location,
    BI.blood_group,
    BI.quantity,
    BI.last_updated,
    CASE 
        WHEN BI.quantity = 0  THEN 'CRITICAL'
        WHEN BI.quantity < 10 THEN 'LOW'
        WHEN BI.quantity < 30 THEN 'MODERATE'
        ELSE 'ADEQUATE'
    END AS stock_status
FROM Hospital H
JOIN BloodInventory BI ON H.hospital_id = BI.hospital_id;

-- View 3: Pending requests summary
CREATE OR REPLACE VIEW PendingRequestsView AS
SELECT 
    BR.request_id,
    H.hospital_name,
    H.location,
    H.contact_number,
    BR.blood_group,
    BR.requested_quantity,
    BR.request_date,
    DATEDIFF(CURDATE(), BR.request_date) AS days_waiting
FROM BloodRequest BR
JOIN Hospital H ON BR.hospital_id = H.hospital_id
WHERE BR.status = 'Pending'
ORDER BY days_waiting DESC;

-- View 4: Transfer history with full hospital names
CREATE OR REPLACE VIEW TransferHistoryView AS
SELECT 
    TL.transfer_id,
    H1.hospital_name   AS from_hospital,
    H1.location        AS from_location,
    H2.hospital_name   AS to_hospital,
    H2.location        AS to_location,
    TL.blood_group,
    TL.quantity,
    TL.transfer_date
FROM TransferLog TL
JOIN Hospital H1 ON TL.from_hospital_id = H1.hospital_id
JOIN Hospital H2 ON TL.to_hospital_id   = H2.hospital_id;

-- SECTION 5: DML - UPDATE & DELETE EXAMPLES

-- Update: Approve a pending request
UPDATE BloodRequest
SET status = 'Approved'
WHERE request_id = 1003;

-- Update: Reduce inventory after transfer
UPDATE BloodInventory
SET quantity = quantity - 10,
    last_updated = CURDATE()
WHERE hospital_id = 1 AND blood_group = 'O-';

-- Delete: Remove a rejected request (cleanup)
DELETE FROM BloodRequest
WHERE status = 'Rejected'
  AND request_date < DATE_SUB(CURDATE(), INTERVAL 30 DAY);
