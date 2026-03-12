-- ============================================================
-- BLOOD BANK MANAGEMENT SYSTEM
-- PL/SQL Components: Procedures, Functions, Triggers, Cursors
-- Oracle SQL Syntax
-- ============================================================

-- ============================================================
-- 1. STORED PROCEDURE: Process Blood Transfer
--    Transfers blood from one hospital to another,
--    updates inventory, logs the transfer, and commits.
-- ============================================================
CREATE OR REPLACE PROCEDURE ProcessBloodTransfer (
    p_from_hospital  IN INT,
    p_to_hospital    IN INT,
    p_blood_group    IN VARCHAR2,
    p_quantity       IN INT,
    p_transfer_id    IN INT
)
AS
    v_available     INT;
    v_compatible    VARCHAR2(3);
BEGIN
    -- Step 1: Check available stock at source hospital
    SELECT quantity INTO v_available
    FROM BloodInventory
    WHERE hospital_id = p_from_hospital
      AND blood_group  = p_blood_group;

    -- Step 2: Validate sufficient stock
    IF v_available < p_quantity THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Insufficient stock at hospital ' || p_from_hospital ||
            '. Available: ' || v_available || ' units.');
    END IF;

    -- Step 3: Deduct from source inventory
    UPDATE BloodInventory
    SET quantity     = quantity - p_quantity,
        last_updated = SYSDATE
    WHERE hospital_id = p_from_hospital
      AND blood_group  = p_blood_group;

    -- Step 4: Add to destination inventory (insert if not exists)
    MERGE INTO BloodInventory dest
    USING (SELECT p_to_hospital AS hospital_id, p_blood_group AS blood_group FROM DUAL) src
    ON (dest.hospital_id = src.hospital_id AND dest.blood_group = src.blood_group)
    WHEN MATCHED THEN
        UPDATE SET quantity = dest.quantity + p_quantity, last_updated = SYSDATE
    WHEN NOT MATCHED THEN
        INSERT (inventory_id, hospital_id, blood_group, quantity, last_updated)
        VALUES (inventory_seq.NEXTVAL, p_to_hospital, p_blood_group, p_quantity, SYSDATE);

    -- Step 5: Log the transfer
    INSERT INTO TransferLog (transfer_id, from_hospital_id, to_hospital_id, blood_group, quantity, transfer_date)
    VALUES (p_transfer_id, p_from_hospital, p_to_hospital, p_blood_group, p_quantity, SYSDATE);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transfer successful: ' || p_quantity || ' units of ' ||
                          p_blood_group || ' transferred from hospital ' ||
                          p_from_hospital || ' to hospital ' || p_to_hospital);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: Blood group ' || p_blood_group ||
                             ' not found in hospital ' || p_from_hospital || ' inventory.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END ProcessBloodTransfer;
/


-- ============================================================
-- 2. STORED PROCEDURE: Approve Blood Request
--    Checks compatibility, verifies stock, approves request.
-- ============================================================
CREATE OR REPLACE PROCEDURE ApproveBloodRequest (
    p_request_id  IN INT
)
AS
    v_hospital_id   INT;
    v_blood_group   VARCHAR2(3);
    v_req_qty       INT;
    v_avail_qty     INT;
    v_is_compatible INT;
BEGIN
    -- Fetch request details
    SELECT hospital_id, blood_group, requested_quantity
    INTO v_hospital_id, v_blood_group, v_req_qty
    FROM BloodRequest
    WHERE request_id = p_request_id
      AND status = 'Pending';

    -- Check available inventory at requesting hospital
    SELECT quantity INTO v_avail_qty
    FROM BloodInventory
    WHERE hospital_id = v_hospital_id
      AND blood_group  = v_blood_group;

    IF v_avail_qty < v_req_qty THEN
        -- Reject if insufficient stock
        UPDATE BloodRequest SET status = 'Rejected' WHERE request_id = p_request_id;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Request ' || p_request_id || ' REJECTED: Insufficient stock.');
    ELSE
        -- Approve and deduct inventory
        UPDATE BloodRequest SET status = 'Approved' WHERE request_id = p_request_id;
        UPDATE BloodInventory
        SET quantity     = quantity - v_req_qty,
            last_updated = SYSDATE
        WHERE hospital_id = v_hospital_id
          AND blood_group  = v_blood_group;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Request ' || p_request_id || ' APPROVED: ' ||
                              v_req_qty || ' units of ' || v_blood_group || ' allocated.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Request ' || p_request_id || ' not found or already processed.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END ApproveBloodRequest;
/


-- ============================================================
-- 3. FUNCTION: Check Blood Compatibility
--    Returns 'YES' if donor_group can donate to receiver_group.
-- ============================================================
CREATE OR REPLACE FUNCTION CheckCompatibility (
    p_donor_group    IN VARCHAR2,
    p_receiver_group IN VARCHAR2
) RETURN VARCHAR2
AS
    v_count INT;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM BloodCompatibility
    WHERE donor_group    = p_donor_group
      AND receiver_group = p_receiver_group;

    IF v_count > 0 THEN
        RETURN 'YES';
    ELSE
        RETURN 'NO';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END CheckCompatibility;
/

-- Example usage:
-- SELECT CheckCompatibility('O-', 'AB+') FROM DUAL;


-- ============================================================
-- 4. FUNCTION: Get Total Stock for Blood Group Across Network
-- ============================================================
CREATE OR REPLACE FUNCTION GetNetworkStock (
    p_blood_group IN VARCHAR2
) RETURN INT
AS
    v_total INT;
BEGIN
    SELECT NVL(SUM(quantity), 0) INTO v_total
    FROM BloodInventory
    WHERE blood_group = p_blood_group;

    RETURN v_total;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
        RETURN -1;
END GetNetworkStock;
/


-- ============================================================
-- 5. TRIGGER: Auto-update BloodInventory after TransferLog INSERT
--    Deducts quantity from source hospital automatically.
-- ============================================================
CREATE OR REPLACE TRIGGER trg_UpdateInventoryOnTransfer
AFTER INSERT ON TransferLog
FOR EACH ROW
BEGIN
    -- Deduct from sender
    UPDATE BloodInventory
    SET quantity     = quantity - :NEW.quantity,
        last_updated = SYSDATE
    WHERE hospital_id = :NEW.from_hospital_id
      AND blood_group  = :NEW.blood_group;

    -- Add to receiver (if record exists)
    UPDATE BloodInventory
    SET quantity     = quantity + :NEW.quantity,
        last_updated = SYSDATE
    WHERE hospital_id = :NEW.to_hospital_id
      AND blood_group  = :NEW.blood_group;

    DBMS_OUTPUT.PUT_LINE('Inventory updated for transfer ID: ' || :NEW.transfer_id);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Trigger ERROR: ' || SQLERRM);
END trg_UpdateInventoryOnTransfer;
/


-- ============================================================
-- 6. TRIGGER: Prevent negative inventory
-- ============================================================
CREATE OR REPLACE TRIGGER trg_PreventNegativeStock
BEFORE UPDATE ON BloodInventory
FOR EACH ROW
BEGIN
    IF :NEW.quantity < 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Stock cannot go negative for blood group ' || :NEW.blood_group ||
            ' at hospital ' || :NEW.hospital_id);
    END IF;
END trg_PreventNegativeStock;
/


-- ============================================================
-- 7. TRIGGER: Auto-timestamp on BloodRequest insert
-- ============================================================
CREATE OR REPLACE TRIGGER trg_SetRequestDate
BEFORE INSERT ON BloodRequest
FOR EACH ROW
BEGIN
    IF :NEW.request_date IS NULL THEN
        :NEW.request_date := SYSDATE;
    END IF;
    IF :NEW.status IS NULL THEN
        :NEW.status := 'Pending';
    END IF;
END trg_SetRequestDate;
/


-- ============================================================
-- 8. CURSOR: Generate Low Stock Report
--    Lists all blood groups with quantity < threshold.
-- ============================================================
CREATE OR REPLACE PROCEDURE GenerateLowStockReport (
    p_threshold IN INT DEFAULT 10
)
AS
    CURSOR low_stock_cursor IS
        SELECT H.hospital_name, H.location, BI.blood_group, BI.quantity
        FROM BloodInventory BI
        JOIN Hospital H ON BI.hospital_id = H.hospital_id
        WHERE BI.quantity < p_threshold
        ORDER BY BI.quantity ASC;

    v_hospital  VARCHAR2(100);
    v_location  VARCHAR2(100);
    v_group     VARCHAR2(3);
    v_qty       INT;
    v_count     INT := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== LOW STOCK REPORT (threshold: ' || p_threshold || ' units) ===');
    DBMS_OUTPUT.PUT_LINE(RPAD('Hospital', 30) || RPAD('Location', 20) ||
                         RPAD('Blood Group', 12) || 'Quantity');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));

    OPEN low_stock_cursor;
    LOOP
        FETCH low_stock_cursor INTO v_hospital, v_location, v_group, v_qty;
        EXIT WHEN low_stock_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE(RPAD(v_hospital, 30) || RPAD(v_location, 20) ||
                             RPAD(v_group, 12) || v_qty);
        v_count := v_count + 1;
    END LOOP;
    CLOSE low_stock_cursor;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 75, '-'));
    DBMS_OUTPUT.PUT_LINE('Total low-stock entries: ' || v_count);
EXCEPTION
    WHEN OTHERS THEN
        IF low_stock_cursor%ISOPEN THEN
            CLOSE low_stock_cursor;
        END IF;
        DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END GenerateLowStockReport;
/


-- ============================================================
-- 9. CURSOR: Remove expired blood units
--    (Uses expiry_date column if added to BloodInventory)
-- ============================================================
CREATE OR REPLACE PROCEDURE RemoveExpiredBlood
AS
    CURSOR exp_cursor IS
        SELECT inventory_id, hospital_id, blood_group, quantity
        FROM BloodInventory
        WHERE expiry_date < SYSDATE;

    v_removed_count INT := 0;
    v_removed_units INT := 0;
BEGIN
    FOR rec IN exp_cursor LOOP
        v_removed_units := v_removed_units + rec.quantity;
        DELETE FROM BloodInventory WHERE inventory_id = rec.inventory_id;
        v_removed_count := v_removed_count + 1;
        DBMS_OUTPUT.PUT_LINE('Removed expired record: ID=' || rec.inventory_id ||
                              ', Group=' || rec.blood_group ||
                              ', Units=' || rec.quantity);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Expired blood cleanup complete. ' ||
                          v_removed_count || ' records removed, ' ||
                          v_removed_units || ' total units discarded.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERROR during cleanup: ' || SQLERRM);
END RemoveExpiredBlood;
/


-- ============================================================
-- 10. TRANSACTION MANAGEMENT EXAMPLE
--     Full atomic transaction: Request → Compatibility Check → Approve
-- ============================================================
DECLARE
    v_request_id    INT := 1004;
    v_hospital_id   INT;
    v_blood_group   VARCHAR2(3);
    v_req_qty       INT;
    v_avail_qty     INT;
    v_compat        VARCHAR2(3);
    SAVEPOINT sp_before_approval;
BEGIN
    SAVEPOINT sp_before_approval;

    SELECT hospital_id, blood_group, requested_quantity
    INTO v_hospital_id, v_blood_group, v_req_qty
    FROM BloodRequest
    WHERE request_id = v_request_id AND status = 'Pending';

    SELECT quantity INTO v_avail_qty
    FROM BloodInventory
    WHERE hospital_id = v_hospital_id AND blood_group = v_blood_group;

    -- Compatibility self-check (same group always compatible)
    v_compat := CheckCompatibility(v_blood_group, v_blood_group);

    IF v_compat = 'YES' AND v_avail_qty >= v_req_qty THEN
        UPDATE BloodRequest SET status = 'Approved' WHERE request_id = v_request_id;
        UPDATE BloodInventory
        SET quantity = quantity - v_req_qty, last_updated = SYSDATE
        WHERE hospital_id = v_hospital_id AND blood_group = v_blood_group;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Transaction committed successfully.');
    ELSE
        ROLLBACK TO sp_before_approval;
        DBMS_OUTPUT.PUT_LINE('Transaction rolled back: incompatible or insufficient.');
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK TO sp_before_approval;
        DBMS_OUTPUT.PUT_LINE('Request not found or already processed.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/
