-- ============================================================
-- BLOOD BANK MANAGEMENT SYSTEM
-- DDL - Schema Creation
-- Thapar Institute of Engineering and Technology, Patiala
-- ============================================================

-- Drop tables if they exist (in reverse FK order)
DROP TABLE IF EXISTS TransferLog;
DROP TABLE IF EXISTS BloodRequest;
DROP TABLE IF EXISTS BloodInventory;
DROP TABLE IF EXISTS BloodCompatibility;
DROP TABLE IF EXISTS Hospital;

-- ============================================================
-- TABLE 1: Hospital
-- ============================================================
CREATE TABLE Hospital (
    hospital_id     INT PRIMARY KEY,
    hospital_name   VARCHAR(100) NOT NULL,
    location        VARCHAR(100) NOT NULL,
    contact_number  VARCHAR(15)  NOT NULL,
    email           VARCHAR(100),
    CONSTRAINT chk_contact CHECK (LENGTH(contact_number) >= 10)
);

-- ============================================================
-- TABLE 2: BloodInventory
-- ============================================================
CREATE TABLE BloodInventory (
    inventory_id    INT PRIMARY KEY,
    hospital_id     INT NOT NULL,
    blood_group     VARCHAR(3) NOT NULL,
    quantity        INT NOT NULL DEFAULT 0,
    last_updated    DATE NOT NULL,
    CONSTRAINT fk_inv_hospital  FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id),
    CONSTRAINT chk_blood_group  CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_quantity     CHECK (quantity >= 0)
);

-- ============================================================
-- TABLE 3: BloodRequest
-- ============================================================
CREATE TABLE BloodRequest (
    request_id          INT PRIMARY KEY,
    hospital_id         INT NOT NULL,
    blood_group         VARCHAR(3) NOT NULL,
    requested_quantity  INT NOT NULL,
    request_date        DATE NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_req_hospital  FOREIGN KEY (hospital_id) REFERENCES Hospital(hospital_id),
    CONSTRAINT chk_req_blood    CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_req_qty      CHECK (requested_quantity > 0),
    CONSTRAINT chk_status       CHECK (status IN ('Pending','Approved','Rejected'))
);

-- ============================================================
-- TABLE 4: TransferLog
-- ============================================================
CREATE TABLE TransferLog (
    transfer_id         INT PRIMARY KEY,
    from_hospital_id    INT NOT NULL,
    to_hospital_id      INT NOT NULL,
    blood_group         VARCHAR(3) NOT NULL,
    quantity            INT NOT NULL,
    transfer_date       DATE NOT NULL,
    CONSTRAINT fk_from_hospital FOREIGN KEY (from_hospital_id) REFERENCES Hospital(hospital_id),
    CONSTRAINT fk_to_hospital   FOREIGN KEY (to_hospital_id)   REFERENCES Hospital(hospital_id),
    CONSTRAINT chk_trans_blood  CHECK (blood_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_trans_qty    CHECK (quantity > 0),
    CONSTRAINT chk_diff_hosp    CHECK (from_hospital_id <> to_hospital_id)
);

-- ============================================================
-- TABLE 5: BloodCompatibility
-- ============================================================
CREATE TABLE BloodCompatibility (
    donor_group     VARCHAR(3) NOT NULL,
    receiver_group  VARCHAR(3) NOT NULL,
    PRIMARY KEY (donor_group, receiver_group),
    CONSTRAINT chk_donor_grp    CHECK (donor_group    IN ('A+','A-','B+','B-','AB+','AB-','O+','O-')),
    CONSTRAINT chk_receiver_grp CHECK (receiver_group IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
);

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX idx_inv_hospital    ON BloodInventory(hospital_id);
CREATE INDEX idx_inv_bloodgroup  ON BloodInventory(blood_group);
CREATE INDEX idx_req_hospital    ON BloodRequest(hospital_id);
CREATE INDEX idx_req_bloodgroup  ON BloodRequest(blood_group);
CREATE INDEX idx_req_status      ON BloodRequest(status);
CREATE INDEX idx_trans_from      ON TransferLog(from_hospital_id);
CREATE INDEX idx_trans_to        ON TransferLog(to_hospital_id);
CREATE INDEX idx_trans_date      ON TransferLog(transfer_date);
