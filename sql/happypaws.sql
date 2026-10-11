-- ============================================================
-- HappyPaws Pet Care Centre
-- ECM 202 - Database Technology and Applications
-- Task 6: Database Creation | Task 7: Data Population | Task 8: SQL Queries
-- ============================================================

DROP DATABASE IF EXISTS happypaws;
CREATE DATABASE happypaws CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE happypaws;

-- ============================================================
-- TASK 6: DATABASE CREATION
-- ============================================================

-- ------------------------------------------------------------
-- 1. CUSTOMER
-- ------------------------------------------------------------
CREATE TABLE Customer (
    CustomerID    INT            NOT NULL AUTO_INCREMENT,
    FirstName     VARCHAR(50)    NOT NULL,
    LastName      VARCHAR(50)    NOT NULL,
    Phone         VARCHAR(20)    NOT NULL,
    Email         VARCHAR(100)   NOT NULL UNIQUE,
    AddressLine1  VARCHAR(100)   NOT NULL,
    AddressLine2  VARCHAR(100)   NULL,
    City          VARCHAR(50)    NOT NULL,
    Postcode      VARCHAR(10)    NOT NULL,
    DateJoined    DATE           NOT NULL,
    Notes         TEXT           NULL,
    CONSTRAINT PK_Customer PRIMARY KEY (CustomerID)
);

-- ------------------------------------------------------------
-- 2. PET
-- ------------------------------------------------------------
CREATE TABLE Pet (
    PetID          INT           NOT NULL AUTO_INCREMENT,
    CustomerID     INT           NOT NULL,
    Name           VARCHAR(50)   NOT NULL,
    Species        VARCHAR(30)   NOT NULL,
    Breed          VARCHAR(50)   NULL,
    Sex            ENUM('Male','Female','Unknown') NOT NULL DEFAULT 'Unknown',
    DateOfBirth    DATE          NULL,
    MicrochipNo    VARCHAR(20)   NULL UNIQUE,
    Allergies      TEXT          NULL,
    BehaviorNotes  TEXT          NULL,
    CONSTRAINT PK_Pet       PRIMARY KEY (PetID),
    CONSTRAINT FK_Pet_Cust  FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 3. STAFF
-- ------------------------------------------------------------
CREATE TABLE Staff (
    StaffID           INT           NOT NULL AUTO_INCREMENT,
    FirstName         VARCHAR(50)   NOT NULL,
    LastName          VARCHAR(50)   NOT NULL,
    Role              ENUM('Vet','Groomer','Assistant','Receptionist') NOT NULL,
    Phone             VARCHAR(20)   NOT NULL,
    Email             VARCHAR(100)  NOT NULL UNIQUE,
    EmploymentStatus  ENUM('Active','Inactive') NOT NULL DEFAULT 'Active',
    CONSTRAINT PK_Staff PRIMARY KEY (StaffID)
);

-- ------------------------------------------------------------
-- 4. SERVICE
-- ------------------------------------------------------------
CREATE TABLE Service (
    ServiceID               INT            NOT NULL AUTO_INCREMENT,
    ServiceName             VARCHAR(100)   NOT NULL,
    Category                ENUM('Grooming','Medical','Wellness','Other') NOT NULL,
    BasePrice               DECIMAL(10,2)  NOT NULL CHECK (BasePrice >= 0),
    DefaultDurationMinutes  INT            NOT NULL CHECK (DefaultDurationMinutes > 0),
    RequiresVet             TINYINT        NOT NULL DEFAULT 0,
    RequiresRoom            TINYINT        NOT NULL DEFAULT 0,
    CONSTRAINT PK_Service PRIMARY KEY (ServiceID)
);

-- ------------------------------------------------------------
-- 5. APPOINTMENT
-- ------------------------------------------------------------
CREATE TABLE Appointment (
    AppointmentID  INT           NOT NULL AUTO_INCREMENT,
    PetID          INT           NOT NULL,
    ServiceID      INT           NOT NULL,
    StaffID        INT           NOT NULL,
    StartDateTime  DATETIME      NOT NULL,
    EndDateTime    DATETIME      NOT NULL,
    Status         ENUM('Scheduled','Completed','Cancelled','Rescheduled','No-Show') NOT NULL DEFAULT 'Scheduled',
    Notes          TEXT          NULL,
    CONSTRAINT PK_Appointment       PRIMARY KEY (AppointmentID),
    CONSTRAINT FK_Appt_Pet          FOREIGN KEY (PetID)     REFERENCES Pet(PetID)         ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Appt_Service      FOREIGN KEY (ServiceID) REFERENCES Service(ServiceID)  ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_Appt_Staff        FOREIGN KEY (StaffID)   REFERENCES Staff(StaffID)      ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT CHK_Appt_Time        CHECK (EndDateTime > StartDateTime)
);

-- ------------------------------------------------------------
-- 6. GROOMING PREFERENCE
-- ------------------------------------------------------------
CREATE TABLE GroomingPreference (
    PreferenceID       INT           NOT NULL AUTO_INCREMENT,
    PetID              INT           NOT NULL,
    ShampooPreference  VARCHAR(100)  NULL,
    ClipLength         VARCHAR(50)   NULL,
    SensitiveSkin      TINYINT    NOT NULL DEFAULT 0,
    Notes              TEXT          NULL,
    LastUpdated        DATE          NULL,
    UpdatedBy          INT           NULL,
    CONSTRAINT PK_GroomPref          PRIMARY KEY (PreferenceID),
    CONSTRAINT FK_GroomPref_Pet      FOREIGN KEY (PetID)      REFERENCES Pet(PetID)     ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_GroomPref_Staff    FOREIGN KEY (UpdatedBy)  REFERENCES Staff(StaffID) ON UPDATE CASCADE ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 7. VACCINATION RECORD
-- ------------------------------------------------------------
CREATE TABLE VaccinationRecord (
    VaccinationID    INT            NOT NULL AUTO_INCREMENT,
    PetID            INT            NOT NULL,
    AppointmentID    INT            NOT NULL,
    VaccineName      VARCHAR(100)   NOT NULL,
    Manufacturer     VARCHAR(100)   NULL,
    BatchNo          VARCHAR(50)    NULL,
    BatchExpiryDate  DATE           NULL,
    Dose             VARCHAR(30)    NULL,
    Cost             DECIMAL(10,2)  NOT NULL CHECK (Cost >= 0),
    AdministeredBy   INT            NOT NULL,
    DateAdministered DATE           NOT NULL,
    NextDueDate      DATE           NOT NULL,
    AdverseReaction  TEXT           NULL,
    Notes            TEXT           NULL,
    CONSTRAINT PK_VaccinationRecord      PRIMARY KEY (VaccinationID),
    CONSTRAINT FK_VaccRec_Pet            FOREIGN KEY (PetID)          REFERENCES Pet(PetID)             ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_VaccRec_Appointment    FOREIGN KEY (AppointmentID)  REFERENCES Appointment(AppointmentID) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_VaccRec_Staff          FOREIGN KEY (AdministeredBy) REFERENCES Staff(StaffID)          ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT CHK_VaccRec_NextDue       CHECK (NextDueDate >= DateAdministered)
);

-- ------------------------------------------------------------
-- 8. ROOM
-- ------------------------------------------------------------
CREATE TABLE Room (
    RoomID            INT            NOT NULL AUTO_INCREMENT,
    RoomCode          VARCHAR(10)    NOT NULL UNIQUE,
    RoomType          ENUM('Standard','Deluxe') NOT NULL,
    Capacity          INT            NOT NULL DEFAULT 1 CHECK (Capacity > 0),
    NightlyRateDefault DECIMAL(10,2) NOT NULL CHECK (NightlyRateDefault >= 0),
    IsActive          TINYINT     NOT NULL DEFAULT 1,
    CONSTRAINT PK_Room PRIMARY KEY (RoomID)
);

-- ------------------------------------------------------------
-- 9. BOARDING BOOKING
-- ------------------------------------------------------------
CREATE TABLE BoardingBooking (
    BoardingID              INT            NOT NULL AUTO_INCREMENT,
    CustomerID              INT            NOT NULL,
    CheckInDateTime         DATETIME       NOT NULL,
    CheckOutDateTime        DATETIME       NOT NULL,
    DailyRate               DECIMAL(10,2)  NOT NULL CHECK (DailyRate >= 0),
    Status                  ENUM('Booked','Checked-In','Checked-Out','Cancelled') NOT NULL DEFAULT 'Booked',
    EmergencyContactName    VARCHAR(100)   NOT NULL,
    EmergencyContactPhone   VARCHAR(20)    NOT NULL,
    SpecialInstructions     TEXT           NULL,
    CONSTRAINT PK_BoardingBooking       PRIMARY KEY (BoardingID),
    CONSTRAINT FK_BoardingBooking_Cust  FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT CHK_Boarding_Time        CHECK (CheckOutDateTime > CheckInDateTime)
);

-- ------------------------------------------------------------
-- 10. BOARDING BOOKING PET (associative table)
-- ------------------------------------------------------------
CREATE TABLE BoardingBookingPet (
    BoardingPetID    INT   NOT NULL AUTO_INCREMENT,
    BoardingID       INT   NOT NULL,
    PetID            INT   NOT NULL,
    RoomID           INT   NOT NULL,
    FeedingSchedule  TEXT  NULL,
    MedicationNotes  TEXT  NULL,
    CONSTRAINT PK_BoardingBookingPet        PRIMARY KEY (BoardingPetID),
    CONSTRAINT FK_BBPet_BoardingBooking     FOREIGN KEY (BoardingID) REFERENCES BoardingBooking(BoardingID) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_BBPet_Pet                 FOREIGN KEY (PetID)      REFERENCES Pet(PetID)                  ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_BBPet_Room                FOREIGN KEY (RoomID)     REFERENCES Room(RoomID)                ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 11. SUPPLIER
-- ------------------------------------------------------------
CREATE TABLE Supplier (
    SupplierID    INT           NOT NULL AUTO_INCREMENT,
    SupplierName  VARCHAR(100)  NOT NULL,
    Phone         VARCHAR(20)   NULL,
    Email         VARCHAR(100)  NULL,
    CONSTRAINT PK_Supplier PRIMARY KEY (SupplierID)
);

-- ------------------------------------------------------------
-- 12. PRODUCT
-- ------------------------------------------------------------
CREATE TABLE Product (
    ProductID    INT            NOT NULL AUTO_INCREMENT,
    SKU          VARCHAR(50)    NOT NULL UNIQUE,
    ProductName  VARCHAR(100)   NOT NULL,
    Category     VARCHAR(50)    NOT NULL,
    UnitPrice    DECIMAL(10,2)  NOT NULL CHECK (UnitPrice >= 0),
    UnitInStock  INT            NOT NULL DEFAULT 0 CHECK (UnitInStock >= 0),
    ReorderLevel INT            NOT NULL DEFAULT 10 CHECK (ReorderLevel >= 0),
    ExpiryDate   DATE           NULL,
    SupplierID   INT            NULL,
    CONSTRAINT PK_Product           PRIMARY KEY (ProductID),
    CONSTRAINT FK_Product_Supplier  FOREIGN KEY (SupplierID) REFERENCES Supplier(SupplierID) ON UPDATE CASCADE ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 13. SALES ORDER
-- ------------------------------------------------------------
CREATE TABLE SalesOrder (
    SalesOrderID   INT            NOT NULL AUTO_INCREMENT,
    CustomerID     INT            NULL,
    OrderDateTime  DATETIME       NOT NULL,
    Channel        ENUM('In-Store','Online') NOT NULL DEFAULT 'In-Store',
    Status         ENUM('Open','Paid','Cancelled','Refunded') NOT NULL DEFAULT 'Open',
    TotalAmount    DECIMAL(10,2)  NOT NULL DEFAULT 0.00 CHECK (TotalAmount >= 0),
    CONSTRAINT PK_SalesOrder       PRIMARY KEY (SalesOrderID),
    CONSTRAINT FK_SalesOrder_Cust  FOREIGN KEY (CustomerID) REFERENCES Customer(CustomerID) ON UPDATE CASCADE ON DELETE SET NULL
);

-- ------------------------------------------------------------
-- 14. SALES ORDER ITEM
-- ------------------------------------------------------------
CREATE TABLE SalesOrderItem (
    SalesOrderItemID  INT            NOT NULL AUTO_INCREMENT,
    SalesOrderID      INT            NOT NULL,
    ProductID         INT            NOT NULL,
    Quantity          INT            NOT NULL CHECK (Quantity > 0),
    UnitPriceAtSale   DECIMAL(10,2)  NOT NULL CHECK (UnitPriceAtSale >= 0),
    LineTotal         DECIMAL(10,2)  NOT NULL CHECK (LineTotal >= 0),
    CONSTRAINT PK_SalesOrderItem        PRIMARY KEY (SalesOrderItemID),
    CONSTRAINT FK_SOItem_SalesOrder     FOREIGN KEY (SalesOrderID) REFERENCES SalesOrder(SalesOrderID) ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT FK_SOItem_Product        FOREIGN KEY (ProductID)    REFERENCES Product(ProductID)        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 15. INVENTORY MOVEMENT
-- ------------------------------------------------------------
CREATE TABLE InventoryMovement (
    MovementID        INT           NOT NULL AUTO_INCREMENT,
    ProductID         INT           NOT NULL,
    MovementType      ENUM('Purchase','Sale','Adjustment','ExpiryWriteOff') NOT NULL,
    QuantityChange    INT           NOT NULL,
    MovementDateTime  DATETIME      NOT NULL,
    Reference         VARCHAR(100)  NULL,
    CONSTRAINT PK_InventoryMovement       PRIMARY KEY (MovementID),
    CONSTRAINT FK_InvMove_Product         FOREIGN KEY (ProductID) REFERENCES Product(ProductID) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ------------------------------------------------------------
-- 16. PAYMENT
-- ------------------------------------------------------------
CREATE TABLE Payment (
    PaymentID        INT            NOT NULL AUTO_INCREMENT,
    PayerType        ENUM('SalesOrder','Appointment','Boarding') NOT NULL,
    PayerRefID       INT            NOT NULL,
    PaymentDateTime  DATETIME       NOT NULL,
    Amount           DECIMAL(10,2)  NOT NULL CHECK (Amount >= 0),
    Method           ENUM('Cash','Card','E-Wallet','Bank Transfer') NOT NULL,
    Status           ENUM('Success','Failed','Refunded') NOT NULL DEFAULT 'Success',
    CONSTRAINT PK_Payment PRIMARY KEY (PaymentID)
);


-- ============================================================
-- TASK 7: DATA POPULATION
-- ============================================================

-- ------------------------------------------------------------
-- Customers (10 rows)
-- ------------------------------------------------------------
INSERT INTO Customer (FirstName, LastName, Phone, Email, AddressLine1, AddressLine2, City, Postcode, DateJoined, Notes) VALUES
('Amirah',   'Binti Hassan',   '012-3456789', 'amirah.hassan@email.com',   'No. 12, Jalan Bahagia 3',  NULL,             'Petaling Jaya', '47810', '2023-01-15', NULL),
('Raj',      'Subramaniam',    '016-7891234', 'raj.subra@email.com',        'No. 5, Jalan Kenanga',     'Taman Maju',     'Shah Alam',     '40150', '2023-03-22', 'Prefers morning appointments'),
('Mei Ling', 'Tan',            '011-2345678', 'meiling.tan@email.com',      'Unit 3A, Jalan PJU 1/3',   NULL,             'Petaling Jaya', '47301', '2023-05-10', NULL),
('Farid',    'Bin Othman',     '019-8765432', 'farid.othman@email.com',     'No. 88, Lorong Damai 7',   NULL,             'Subang Jaya',   '47500', '2023-07-01', NULL),
('Priya',    'Nair',           '017-3334455', 'priya.nair@email.com',       'No. 22, Jalan SS2/10',     'SS2',            'Petaling Jaya', '47300', '2023-08-19', NULL),
('Kevin',    'Wong',           '012-9988776', 'kevin.wong@email.com',       'No. 45, Jalan Utama 1',    'Damansara',      'Petaling Jaya', '47400', '2023-09-05', 'VIP customer'),
('Nurul',    'Ain Binti Aziz', '014-5556677', 'nurul.ain@email.com',        'No. 3, Jalan Bunga Raya',  'Taman Bunga',    'Klang',         '41000', '2024-01-12', NULL),
('David',    'Lim',            '016-2223344', 'david.lim@email.com',        'B-12-3, Jalan Ampang',     'Residency Park', 'Kuala Lumpur',  '55000', '2024-02-28', NULL),
('Siti',     'Rahayu',         '018-7776655', 'siti.rahayu@email.com',      'No. 9, Jalan Putra 5',     NULL,             'Cyberjaya',     '63000', '2024-04-17', NULL),
('Jason',    'Ong',            '011-8889900', 'jason.ong@email.com',        'No. 18, Jalan Wangsa 3',   'Wangsa Maju',    'Kuala Lumpur',  '53300', '2024-06-01', NULL);

-- ------------------------------------------------------------
-- Pets (15 rows)
-- ------------------------------------------------------------
INSERT INTO Pet (CustomerID, Name, Species, Breed, Sex, DateOfBirth, MicrochipNo, Allergies, BehaviorNotes) VALUES
(1, 'Mochi',   'Dog',    'Shih Tzu',         'Female', '2020-04-10', 'MC001111', 'Chicken allergy', 'Shy with strangers'),
(1, 'Biscuit', 'Cat',    'Domestic Shorthair','Male',  '2021-08-22', 'MC001112', NULL,              'Playful'),
(2, 'Bruno',   'Dog',    'Labrador Retriever','Male',  '2019-06-15', 'MC002221', NULL,              'Very energetic'),
(3, 'Luna',    'Cat',    'Persian',           'Female','2022-01-05', 'MC003331', 'Fish allergy',    'Prefers gentle handling'),
(3, 'Kopi',    'Dog',    'Corgi',             'Male',  '2020-11-30', 'MC003332', NULL,              'Loves belly rubs'),
(4, 'Oreo',    'Dog',    'Beagle',            'Male',  '2021-03-18', 'MC004441', NULL,              'Calm and obedient'),
(5, 'Cleo',    'Cat',    'Siamese',           'Female','2020-07-25', 'MC005551', NULL,              'Vocal, likes attention'),
(6, 'Rex',     'Dog',    'German Shepherd',   'Male',  '2018-12-01', 'MC006661', NULL,              'Well-trained'),
(6, 'Noodle',  'Rabbit', 'Holland Lop',       'Female','2022-05-14', 'MC006662', NULL,              'Timid'),
(7, 'Pudding', 'Dog',    'Poodle',            'Female','2021-09-09', 'MC007771', 'Lavender shampoo','Sensitive skin'),
(8, 'Charlie', 'Dog',    'Golden Retriever',  'Male',  '2019-02-20', 'MC008881', NULL,              'Friendly'),
(8, 'Mimi',    'Cat',    'Ragdoll',           'Female','2023-03-11', 'MC008882', NULL,              'Calm'),
(9, 'Tofu',    'Cat',    'British Shorthair', 'Male',  '2022-10-01', 'MC009991', NULL,              'Curious'),
(10,'Dash',    'Dog',    'Dachshund',         'Male',  '2020-06-06', 'MC010001', NULL,              'Active'),
(10,'Pipi',    'Bird',   'Cockatiel',         'Unknown','2021-12-12', NULL,        NULL,             'Friendly, talks a little');

-- ------------------------------------------------------------
-- Staff (8 rows)
-- ------------------------------------------------------------
INSERT INTO Staff (FirstName, LastName, Role, Phone, Email, EmploymentStatus) VALUES
('Dr. Nisha',  'Pillai',         'Vet',          '012-1112222', 'nisha.pillai@happypaws.my',    'Active'),
('Dr. Ahmad',  'Zulkifli',       'Vet',          '013-2223333', 'ahmad.zul@happypaws.my',       'Active'),
('Suria',      'Binti Roslan',   'Groomer',      '014-3334444', 'suria.roslan@happypaws.my',    'Active'),
('Wei Han',    'Chong',          'Groomer',      '015-4445555', 'weihan.chong@happypaws.my',    'Active'),
('Fatin',      'Binti Saad',     'Receptionist', '016-5556666', 'fatin.saad@happypaws.my',      'Active'),
('Marcus',     'Tan',            'Assistant',    '017-6667777', 'marcus.tan@happypaws.my',      'Active'),
('Hana',       'Binti Yusoff',   'Groomer',      '018-7778888', 'hana.yusoff@happypaws.my',     'Active'),
('Dr. Kavita', 'Menon',          'Vet',          '019-8889999', 'kavita.menon@happypaws.my',    'Inactive');

-- ------------------------------------------------------------
-- Service (10 rows)
-- ------------------------------------------------------------
INSERT INTO Service (ServiceName, Category, BasePrice, DefaultDurationMinutes, RequiresVet, RequiresRoom) VALUES
('Full Groom',             'Grooming', 80.00,  90,  0, 0),
('Bath & Blow Dry',        'Grooming', 50.00,  60,  0, 0),
('Nail Trim',              'Grooming', 20.00,  15,  0, 0),
('Rabies Vaccination',     'Medical',  65.00,  30,  1, 0),
('DHPP Vaccination',       'Medical',  75.00,  30,  1, 0),
('Annual Wellness Check',  'Wellness', 90.00,  45,  1, 0),
('Pre-Vaccination Health Check', 'Wellness', 40.00, 30, 1, 0),
('Dental Scaling',         'Medical',  120.00, 60,  1, 0),
('Ear Cleaning',           'Grooming', 25.00,  20,  0, 0),
('Boarding Check-In Exam', 'Wellness', 30.00,  20,  1, 0);

-- ------------------------------------------------------------
-- Appointments (20 rows)
-- ------------------------------------------------------------
INSERT INTO Appointment (PetID, ServiceID, StaffID, StartDateTime, EndDateTime, Status, Notes) VALUES
-- Pre-vaccination health checks (mandatory before vaccination)
(1,  7, 1, '2024-02-01 09:00:00', '2024-02-01 09:30:00', 'Completed', 'Pre-vacc check for Mochi'),
(3,  7, 2, '2024-02-05 10:00:00', '2024-02-05 10:30:00', 'Completed', 'Pre-vacc check for Bruno'),
(6,  7, 1, '2024-03-10 09:00:00', '2024-03-10 09:30:00', 'Completed', 'Pre-vacc check for Oreo'),
-- Vaccination appointments
(1,  4, 1, '2024-02-01 09:30:00', '2024-02-01 10:00:00', 'Completed', 'Rabies vaccination'),
(3,  5, 2, '2024-02-05 10:30:00', '2024-02-05 11:00:00', 'Completed', 'DHPP vaccination'),
(6,  4, 1, '2024-03-10 09:30:00', '2024-03-10 10:00:00', 'Completed', 'Rabies vaccination'),
-- Wellness checks
(8,  6, 2, '2024-03-15 11:00:00', '2024-03-15 11:45:00', 'Completed', 'Annual wellness for Rex'),
(11, 6, 1, '2024-04-01 14:00:00', '2024-04-01 14:45:00', 'Completed', 'Annual wellness for Charlie'),
-- Grooming appointments
(1,  1, 3, '2024-03-20 10:00:00', '2024-03-20 11:30:00', 'Completed', 'Full groom with hypoallergenic shampoo'),
(5,  1, 4, '2024-03-22 09:00:00', '2024-03-22 10:30:00', 'Completed', 'Full groom'),
(10, 2, 7, '2024-04-05 11:00:00', '2024-04-05 12:00:00', 'Completed', 'Bath only, sensitive skin shampoo'),
(14, 3, 3, '2024-04-10 14:00:00', '2024-04-10 14:15:00', 'Completed', 'Nail trim'),
(4,  1, 4, '2024-04-18 10:00:00', '2024-04-18 11:30:00', 'Completed', 'Full groom for Luna'),
(7,  9, 3, '2024-05-02 09:30:00', '2024-05-02 09:50:00', 'Completed', 'Ear cleaning for Cleo'),
-- Future/upcoming appointments
(1,  1, 3, '2026-06-15 10:00:00', '2026-06-15 11:30:00', 'Scheduled', 'Upcoming full groom'),
(3,  6, 2, '2026-06-18 11:00:00', '2026-06-18 11:45:00', 'Scheduled', 'Annual wellness check'),
(11, 1, 4, '2026-06-20 09:00:00', '2026-06-20 10:30:00', 'Scheduled', 'Full groom for Charlie'),
(5,  7, 1, '2026-06-20 14:00:00', '2026-06-20 14:30:00', 'Scheduled', 'Pre-vacc health check for Kopi'),
-- Cancelled / rescheduled
(8,  1, 3, '2024-02-14 10:00:00', '2024-02-14 11:30:00', 'Cancelled',    'Owner cancelled - travel'),
(13, 6, 1, '2024-05-20 09:00:00', '2024-05-20 09:45:00', 'Rescheduled', 'Moved to next week');

-- ------------------------------------------------------------
-- Grooming Preferences (8 rows)
-- ------------------------------------------------------------
INSERT INTO GroomingPreference (PetID, ShampooPreference, ClipLength, SensitiveSkin, Notes, LastUpdated, UpdatedBy) VALUES
(1,  'Hypoallergenic oat shampoo', 'Short',  1, 'Allergic to chicken by-products in standard shampoo', '2024-03-20', 3),
(5,  'Lavender-free mild shampoo', 'Medium', 0, NULL,                                                    '2024-03-22', 4),
(10, 'Sensitive skin formula',     'Long',   1, 'Slight redness after strong shampoo',                  '2024-04-05', 7),
(14, 'Standard shampoo',           'Short',  0, NULL,                                                    '2024-04-10', 3),
(4,  'Gentle cat shampoo',         'Long',   0, 'Prefers quiet grooming environment',                    '2024-04-18', 4),
(7,  'Unscented shampoo',          'Short',  0, 'Easily stressed, keep sessions short',                  '2024-05-02', 3),
(11, 'Coconut oil shampoo',        'Long',   0, NULL,                                                    '2024-04-01', 4),
(8,  'Standard',                   'Short',  0, NULL,                                                    '2024-03-15', 7);

-- ------------------------------------------------------------
-- Vaccination Records (6 rows)
-- ------------------------------------------------------------
INSERT INTO VaccinationRecord (PetID, AppointmentID, VaccineName, Manufacturer, BatchNo, BatchExpiryDate, Dose, Cost, AdministeredBy, DateAdministered, NextDueDate, AdverseReaction, Notes) VALUES
(1,  4, 'Rabies Vaccine',   'Merial',    'BT2024-01', '2025-06-30', '1 mL', 65.00, 1, '2024-02-01', '2026-08-01', NULL,              'No adverse reactions'),
(3,  5, 'DHPP Combo',       'Nobivac',   'BT2024-02', '2025-09-30', '1 mL', 75.00, 2, '2024-02-05', '2026-09-05', NULL,              'Mild lethargy post-injection'),
(6,  6, 'Rabies Vaccine',   'Merial',    'BT2024-01', '2025-06-30', '1 mL', 65.00, 1, '2024-03-10', '2026-10-10', NULL,              NULL),
(8,  7, 'Annual Combo',     'Boehringer','BT2024-03', '2025-12-31', '1 mL', 90.00, 2, '2024-03-15', '2026-11-15', NULL,              'Wellness check included'),
(11, 8, 'DHPP Combo',       'Nobivac',   'BT2024-04', '2025-08-31', '1 mL', 75.00, 1, '2024-04-01', '2027-01-01', NULL,              NULL),
(5,  10, 'Bordetella',      'Zoetis',    'BT2024-05', '2025-07-31', '0.5 mL',55.00, 2,'2024-02-05', '2026-07-05', 'Minor swelling', 'Monitor for 30 min post-vaccination');

-- ------------------------------------------------------------
-- Rooms (8 rows)
-- ------------------------------------------------------------
INSERT INTO Room (RoomCode, RoomType, Capacity, NightlyRateDefault, IsActive) VALUES
('R01', 'Standard', 1, 45.00, 1),
('R02', 'Standard', 1, 45.00, 1),
('R03', 'Standard', 1, 45.00, 1),
('R04', 'Standard', 1, 45.00, 1),
('D01', 'Deluxe',   1, 80.00, 1),
('D02', 'Deluxe',   1, 80.00, 1),
('D03', 'Deluxe',   1, 80.00, 1),
('R05', 'Standard', 1, 45.00, 0);  -- Inactive room under maintenance

-- ------------------------------------------------------------
-- Boarding Bookings (6 rows)
-- ------------------------------------------------------------
INSERT INTO BoardingBooking (CustomerID, CheckInDateTime, CheckOutDateTime, DailyRate, Status, EmergencyContactName, EmergencyContactPhone, SpecialInstructions) VALUES
(1, '2024-04-10 14:00:00', '2024-04-15 12:00:00', 45.00, 'Checked-Out', 'Amirah Hassan',   '012-3456789', 'Feed twice daily; no chicken-based food'),
(2, '2024-04-12 13:00:00', '2024-04-14 12:00:00', 80.00, 'Checked-Out', 'Raj Subramaniam', '016-7891234', NULL),
(6, '2024-05-01 12:00:00', '2024-05-05 12:00:00', 80.00, 'Checked-Out', 'Kevin Wong',      '012-9988776', 'Rex needs daily exercise'),
(3, '2024-05-10 14:00:00', '2024-05-12 12:00:00', 45.00, 'Checked-Out', 'Mei Ling Tan',    '011-2345678', NULL),
(8, '2026-06-10 14:00:00', '2026-06-14 12:00:00', 80.00, 'Booked',      'David Lim',       '016-2223344', 'Charlie is allergic to peanuts'),
(4, '2026-06-08 13:00:00', '2026-06-10 12:00:00', 45.00, 'Checked-In',  'Farid Othman',    '019-8765432', NULL);

-- ------------------------------------------------------------
-- Boarding Booking Pet (8 rows)
-- ------------------------------------------------------------
INSERT INTO BoardingBookingPet (BoardingID, PetID, RoomID, FeedingSchedule, MedicationNotes) VALUES
(1, 1,  1, '8am: 50g dry food; 6pm: 50g dry food',       NULL),
(1, 2,  2, '8am: 40g cat kibble; 6pm: 40g cat kibble',   NULL),
(2, 3,  5, '7am: 100g wet food; 5pm: 100g wet food',     NULL),
(3, 8,  6, '7am: 150g kibble; 12pm: walk; 6pm: 150g',   'Joint supplement tablet with morning meal'),
(3, 9,  3, '9am: 30g pellets; 5pm: 30g pellets',         NULL),
(4, 5,  4, '8am: 60g corgi food; 6pm: 60g corgi food',   NULL),
(5, 11, 7, '7am: 120g golden food; 6pm: 120g + wet topper', NULL),
(6, 6,  1, '8am: 50g beagle mix; 6pm: 50g beagle mix',  NULL);

-- ------------------------------------------------------------
-- Suppliers (5 rows)
-- ------------------------------------------------------------
INSERT INTO Supplier (SupplierName, Phone, Email) VALUES
('PetNutrition Sdn Bhd',   '03-12345678', 'orders@petnutrition.com.my'),
('FurEver Supplies',        '03-87654321', 'sales@furever.com.my'),
('VetMed Malaysia',         '03-22334455', 'info@vetmed.com.my'),
('ToyBox Pet Co.',          '03-55667788', 'purchase@toybox.com.my'),
('GreenPaw Organics',       '03-99887766', 'hello@greenpaw.com.my');

-- ------------------------------------------------------------
-- Products (15 rows)
-- ------------------------------------------------------------
INSERT INTO Product (SKU, ProductName, Category, UnitPrice, UnitInStock, ReorderLevel, ExpiryDate, SupplierID) VALUES
('SKU-F001', 'Royal Canin Adult Dog Food 2kg',      'Pet Food',    55.00,  30, 10, '2025-12-31', 1),
('SKU-F002', 'Whiskas Cat Food Tuna 1.2kg',         'Pet Food',    28.00,  45, 15, '2025-10-31', 1),
('SKU-F003', 'Pedigree Puppy Dry Food 1.5kg',       'Pet Food',    32.00,  20, 10, '2025-11-30', 1),
('SKU-F004', 'Hill\'s Science Diet Senior Dog 2kg', 'Pet Food',    68.00,   8,  5, '2026-03-31', 1),
('SKU-T001', 'Rope Chew Toy',                       'Toy',          9.90,  50, 20, NULL,         4),
('SKU-T002', 'Catnip Mouse Toy',                    'Toy',          7.50,  40, 15, NULL,         4),
('SKU-T003', 'Squeaky Rubber Ball',                 'Toy',         12.00,  35, 15, NULL,         4),
('SKU-A001', 'Adjustable Dog Collar (S)',            'Accessory',   18.00,  25, 10, NULL,         2),
('SKU-A002', 'Cat Carrier Bag',                     'Accessory',   75.00,  10,  5, NULL,         2),
('SKU-A003', 'Stainless Steel Water Bowl',           'Accessory',   15.00,  30, 10, NULL,         2),
('SKU-V001', 'Heartgard Heartworm Tablet (6-pack)', 'Medication',  85.00,  12,  5, '2026-01-31', 3),
('SKU-V002', 'Frontline Flea Treatment (3-pack)',   'Medication',  65.00,  18,  8, '2026-02-28', 3),
('SKU-G001', 'Hypoallergenic Oat Shampoo 500ml',    'Grooming',    35.00,  20, 10, '2026-06-30', 5),
('SKU-G002', 'Sensitive Skin Conditioner 250ml',    'Grooming',    28.00,  15,  8, '2026-05-31', 5),
('SKU-F005', 'Organic Cat Treats 80g',              'Pet Food',    14.90,   5,  8, '2025-08-31', 5);

-- ------------------------------------------------------------
-- Sales Orders (8 rows)
-- ------------------------------------------------------------
INSERT INTO SalesOrder (CustomerID, OrderDateTime, Channel, Status, TotalAmount) VALUES
(1,   '2024-03-20 12:00:00', 'In-Store', 'Paid',      63.90),
(2,   '2024-03-22 15:30:00', 'In-Store', 'Paid',      55.00),
(5,   '2024-04-05 10:15:00', 'In-Store', 'Paid',      87.50),
(6,   '2024-04-10 09:45:00', 'In-Store', 'Paid',     150.00),
(3,   '2024-04-18 11:00:00', 'In-Store', 'Paid',      35.00),
(8,   '2024-05-01 14:20:00', 'Online',   'Paid',     123.00),
(NULL,'2024-05-10 16:00:00', 'In-Store', 'Paid',      27.40),   -- Walk-in customer
(10,  '2024-06-01 13:00:00', 'In-Store', 'Cancelled', 68.00);

-- ------------------------------------------------------------
-- Sales Order Items (15 rows)
-- ------------------------------------------------------------
INSERT INTO SalesOrderItem (SalesOrderID, ProductID, Quantity, UnitPriceAtSale, LineTotal) VALUES
(1, 13, 1, 35.00, 35.00),  -- Hypoallergenic Oat Shampoo
(1,  6, 2,  7.50, 15.00),  -- Catnip Mouse Toy x2
(1,  2, 1, 28.00, 28.00),  -- Whiskas Cat Food
(2,  1, 1, 55.00, 55.00),  -- Royal Canin Adult Dog Food
(3, 12, 1, 65.00, 65.00),  -- Frontline Flea Treatment
(3,  8, 1, 18.00, 18.00),  -- Adjustable Dog Collar
(3, 15, 1, 14.90, 14.90),  -- Organic Cat Treats
(4,  9, 1, 75.00, 75.00),  -- Cat Carrier Bag
(4,  1, 1, 55.00, 55.00),  -- Royal Canin Adult Dog Food
(5,  5, 2,  9.90, 19.80),  -- Rope Chew Toy x2
(5, 10, 1, 15.00, 15.00),  -- Stainless Steel Water Bowl
(6, 11, 1, 85.00, 85.00),  -- Heartgard Heartworm Tablet
(6,  2, 1, 28.00, 28.00),  -- Whiskas Cat Food
(6, 14, 1, 28.00, 28.00),  -- Sensitive Skin Conditioner
(7,  7, 1, 12.00, 12.00);  -- Squeaky Rubber Ball

-- ------------------------------------------------------------
-- Inventory Movements (12 rows)
-- ------------------------------------------------------------
INSERT INTO InventoryMovement (ProductID, MovementType, QuantityChange, MovementDateTime, Reference) VALUES
( 1, 'Purchase',       50, '2024-01-10 09:00:00', 'PO-2024-001'),
( 2, 'Purchase',       60, '2024-01-10 09:00:00', 'PO-2024-001'),
( 1, 'Sale',           -1, '2024-03-22 15:30:00', 'SO-2'),
( 2, 'Sale',           -1, '2024-03-20 12:00:00', 'SO-1'),
(12, 'Purchase',       30, '2024-02-01 10:00:00', 'PO-2024-002'),
(12, 'Sale',           -1, '2024-04-05 10:15:00', 'SO-3'),
(11, 'Purchase',       20, '2024-02-01 10:00:00', 'PO-2024-002'),
(11, 'Sale',           -1, '2024-05-01 14:20:00', 'SO-6'),
(15, 'ExpiryWriteOff', -5, '2024-07-01 08:00:00', 'WRITEOFF-2024-001'),
( 5, 'Purchase',       50, '2024-01-15 09:00:00', 'PO-2024-003'),
( 8, 'Purchase',       30, '2024-01-15 09:00:00', 'PO-2024-003'),
( 4, 'Adjustment',     -2, '2024-06-30 17:00:00', 'STOCKTAKE-JUN2024');

-- ------------------------------------------------------------
-- Payments (12 rows)
-- ------------------------------------------------------------
INSERT INTO Payment (PayerType, PayerRefID, PaymentDateTime, Amount, Method, Status) VALUES
('SalesOrder',  1, '2024-03-20 12:05:00',  63.90, 'E-Wallet',      'Success'),
('SalesOrder',  2, '2024-03-22 15:35:00',  55.00, 'Card',          'Success'),
('SalesOrder',  3, '2024-04-05 10:20:00',  87.50, 'Cash',          'Success'),
('SalesOrder',  4, '2024-04-10 09:50:00', 150.00, 'Card',          'Success'),
('SalesOrder',  5, '2024-04-18 11:05:00',  35.00, 'Cash',          'Success'),
('SalesOrder',  6, '2024-05-01 14:25:00', 123.00, 'Bank Transfer', 'Success'),
('SalesOrder',  7, '2024-05-10 16:05:00',  27.40, 'Cash',          'Success'),
('Appointment', 9, '2024-03-20 11:35:00',  80.00, 'Card',          'Success'),
('Appointment',10, '2024-03-22 10:35:00',  80.00, 'E-Wallet',      'Success'),
('Boarding',    1, '2024-04-15 12:10:00', 225.00, 'Card',          'Success'),  -- 5 nights x 45
('Boarding',    2, '2024-04-14 12:10:00', 160.00, 'E-Wallet',      'Success'),  -- 2 nights x 80
('Boarding',    3, '2024-05-05 12:10:00', 320.00, 'Card',          'Success');  -- 4 nights x 80


-- ============================================================
-- TASK 8: SQL QUERIES WITH TECHNICAL AND BUSINESS INTERPRETATION
-- ============================================================

-- ----------------------------------------------------------
-- Query 1: Basic Retrieval
-- List all active staff members with their roles
-- ----------------------------------------------------------
-- Technical: Simple SELECT with WHERE filter on a single table.
-- Business: HR and management can quickly view all currently active employees,
--           useful for scheduling and staff allocation decisions.
-- ----------------------------------------------------------
SELECT
    StaffID,
    CONCAT(FirstName, ' ', LastName) AS FullName,
    Role,
    Phone,
    Email
FROM Staff
WHERE EmploymentStatus = 'Active'
ORDER BY Role, LastName;

-- ----------------------------------------------------------
-- Query 2: Basic Retrieval
-- Display all pets and their owner contact information
-- ----------------------------------------------------------
-- Technical: INNER JOIN between Pet and Customer to combine
--            owner and pet data from two related tables.
-- Business: Receptionists can use this to quickly look up
--           a pet's owner contact details during check-in or emergencies.
-- ----------------------------------------------------------
SELECT
    p.PetID,
    p.Name              AS PetName,
    p.Species,
    p.Breed,
    CONCAT(c.FirstName, ' ', c.LastName) AS OwnerName,
    c.Phone             AS OwnerPhone,
    c.Email             AS OwnerEmail
FROM Pet p
INNER JOIN Customer c ON p.CustomerID = c.CustomerID
ORDER BY c.LastName, p.Name;

-- ----------------------------------------------------------
-- Query 3: Join Query
-- Full appointment schedule showing pet, owner, service and assigned staff
-- ----------------------------------------------------------
-- Technical: Multi-table JOIN across Appointment, Pet, Customer, Service, Staff.
--            Filters on upcoming/scheduled appointments only.
-- Business: Daily schedule view for reception and groomers/vets to see
--           who is coming in, what service is needed, and which staff is assigned.
-- ----------------------------------------------------------
SELECT
    a.AppointmentID,
    a.StartDateTime,
    a.EndDateTime,
    p.Name                              AS PetName,
    p.Species,
    CONCAT(c.FirstName, ' ', c.LastName) AS OwnerName,
    c.Phone                             AS OwnerPhone,
    s.ServiceName,
    s.Category,
    CONCAT(st.FirstName, ' ', st.LastName) AS AssignedStaff,
    st.Role,
    a.Status
FROM Appointment a
INNER JOIN Pet     p  ON a.PetID     = p.PetID
INNER JOIN Customer c ON p.CustomerID = c.CustomerID
INNER JOIN Service  s  ON a.ServiceID  = s.ServiceID
INNER JOIN Staff   st  ON a.StaffID    = st.StaffID
ORDER BY a.StartDateTime;

-- ----------------------------------------------------------
-- Query 4: Join Query
-- Vaccination history with upcoming reminder dates
-- ----------------------------------------------------------
-- Technical: JOINs VaccinationRecord with Pet, Customer, and Staff.
--            Shows all vaccination events and their NextDueDate.
-- Business: Vets and receptionists can use this to send proactive reminders
--           to owners whose pets have upcoming vaccinations due, improving
--           pet health compliance and generating repeat visits.
-- ----------------------------------------------------------
SELECT
    vr.VaccinationID,
    p.Name                               AS PetName,
    p.Species,
    CONCAT(c.FirstName, ' ', c.LastName) AS OwnerName,
    c.Phone,
    vr.VaccineName,
    vr.DateAdministered,
    vr.NextDueDate,
    DATEDIFF(vr.NextDueDate, CURDATE())  AS DaysUntilDue,
    CONCAT(st.FirstName, ' ', st.LastName) AS AdministeredByStaff
FROM VaccinationRecord vr
INNER JOIN Pet      p  ON vr.PetID          = p.PetID
INNER JOIN Customer c  ON p.CustomerID       = c.CustomerID
INNER JOIN Staff    st ON vr.AdministeredBy  = st.StaffID
ORDER BY vr.NextDueDate;

-- ----------------------------------------------------------
-- Query 5: Aggregate / Grouped Query
-- Monthly revenue summary from all payment sources
-- ----------------------------------------------------------
-- Technical: Aggregates Payment table by year-month and PayerType,
--            using SUM and COUNT with GROUP BY and ORDER BY.
-- Business: Management can track monthly revenue trends broken down
--           by service type (retail, appointments, boarding) to identify
--           peak periods and best-performing revenue streams.
-- ----------------------------------------------------------
SELECT
    DATE_FORMAT(PaymentDateTime, '%Y-%m')  AS Month,
    PayerType,
    COUNT(*)                               AS NumberOfTransactions,
    SUM(Amount)                            AS TotalRevenue
FROM Payment
WHERE Status = 'Success'
GROUP BY DATE_FORMAT(PaymentDateTime, '%Y-%m'), PayerType
ORDER BY Month, PayerType;

-- ----------------------------------------------------------
-- Query 6: Aggregate / Grouped Query
-- Top services by number of completed appointments
-- ----------------------------------------------------------
-- Technical: JOINs Appointment and Service, filters for Completed status,
--            groups by service, uses COUNT and ORDER BY DESC.
-- Business: Management can identify which services are most popular,
--           helping to plan staffing levels, promotions, and resource allocation.
-- ----------------------------------------------------------
SELECT
    s.ServiceName,
    s.Category,
    s.BasePrice,
    COUNT(a.AppointmentID)  AS TotalCompleted,
    SUM(s.BasePrice)        AS EstimatedRevenue
FROM Appointment a
INNER JOIN Service s ON a.ServiceID = s.ServiceID
WHERE a.Status = 'Completed'
GROUP BY s.ServiceID, s.ServiceName, s.Category, s.BasePrice
ORDER BY TotalCompleted DESC;

-- ----------------------------------------------------------
-- Query 7: Aggregate / Grouped Query
-- Products low in stock or near/below reorder level
-- ----------------------------------------------------------
-- Technical: Filters Product table where UnitInStock <= ReorderLevel,
--            joined with Supplier for contact information.
-- Business: Inventory supervisor can act immediately on this list to
--           reorder products before stockouts occur, preventing lost sales
--           and ensuring essential medications/food are always available.
-- ----------------------------------------------------------
SELECT
    p.ProductID,
    p.SKU,
    p.ProductName,
    p.Category,
    p.UnitInStock,
    p.ReorderLevel,
    (p.ReorderLevel - p.UnitInStock)  AS ShortfallQty,
    p.ExpiryDate,
    CASE
        WHEN p.ExpiryDate IS NOT NULL AND p.ExpiryDate <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
            THEN 'EXPIRING SOON'
        ELSE 'OK'
    END                               AS ExpiryAlert,
    COALESCE(s.SupplierName, 'N/A')   AS SupplierName,
    COALESCE(s.Phone, 'N/A')          AS SupplierPhone
FROM Product p
LEFT JOIN Supplier s ON p.SupplierID = s.SupplierID
WHERE p.UnitInStock <= p.ReorderLevel
ORDER BY p.UnitInStock ASC;

-- ----------------------------------------------------------
-- Query 8: Analytical / Advanced Query
-- Customer lifetime value: total spending per customer across all channels
-- ----------------------------------------------------------
-- Technical: Uses LEFT JOINs and UNION-style aggregation via subqueries.
--            Combines Sales, Appointment, and Boarding revenue per customer.
--            Uses COALESCE to handle NULLs (customers with no spend in a category).
-- Business: Management can identify high-value customers for loyalty rewards,
--           targeted promotions, or VIP treatment to improve retention.
-- ----------------------------------------------------------
SELECT
    c.CustomerID,
    CONCAT(c.FirstName, ' ', c.LastName)  AS CustomerName,
    c.Phone,
    c.Email,
    COALESCE(retail.RetailSpend,  0.00)   AS RetailSpend,
    COALESCE(board.BoardingSpend, 0.00)   AS BoardingSpend,
    COALESCE(appt.ApptSpend,      0.00)   AS AppointmentSpend,
    ROUND(
        COALESCE(retail.RetailSpend,  0.00) +
        COALESCE(board.BoardingSpend, 0.00) +
        COALESCE(appt.ApptSpend,      0.00), 2
    )                                     AS TotalLifetimeValue
FROM Customer c

-- Retail spend via SalesOrder
LEFT JOIN (
    SELECT so.CustomerID, SUM(py.Amount) AS RetailSpend
    FROM Payment py
    INNER JOIN SalesOrder so ON py.PayerRefID = so.SalesOrderID
    WHERE py.PayerType = 'SalesOrder' AND py.Status = 'Success'
    GROUP BY so.CustomerID
) AS retail ON c.CustomerID = retail.CustomerID

-- Boarding spend
LEFT JOIN (
    SELECT bb.CustomerID, SUM(py.Amount) AS BoardingSpend
    FROM Payment py
    INNER JOIN BoardingBooking bb ON py.PayerRefID = bb.BoardingID
    WHERE py.PayerType = 'Boarding' AND py.Status = 'Success'
    GROUP BY bb.CustomerID
) AS board ON c.CustomerID = board.CustomerID

-- Appointment spend (payment linked to appointment, appointment to pet, pet to customer)
LEFT JOIN (
    SELECT p2.CustomerID, SUM(py.Amount) AS ApptSpend
    FROM Payment py
    INNER JOIN Appointment a  ON py.PayerRefID = a.AppointmentID
    INNER JOIN Pet         p2 ON a.PetID = p2.PetID
    WHERE py.PayerType = 'Appointment' AND py.Status = 'Success'
    GROUP BY p2.CustomerID
) AS appt ON c.CustomerID = appt.CustomerID

ORDER BY TotalLifetimeValue DESC;

-- ----------------------------------------------------------
-- Query 9: Analytical / Advanced Query
-- Upcoming vaccinations due within the next 12 months
-- (reminder list for proactive customer outreach)
-- ----------------------------------------------------------
-- Technical: Filters VaccinationRecord by NextDueDate within a date range,
--            JOINs to get owner contact details, orders by soonest due.
-- Business: Reception can use this report to send reminder messages or
--           calls to owners, reducing missed vaccinations and driving
--           repeat appointment bookings.
-- ----------------------------------------------------------
SELECT
    vr.VaccinationID,
    p.Name                               AS PetName,
    p.Species,
    vr.VaccineName,
    vr.NextDueDate,
    DATEDIFF(vr.NextDueDate, CURDATE())  AS DaysUntilDue,
    CONCAT(c.FirstName, ' ', c.LastName) AS OwnerName,
    c.Phone,
    c.Email
FROM VaccinationRecord vr
INNER JOIN Pet      p ON vr.PetID       = p.PetID
INNER JOIN Customer c ON p.CustomerID   = c.CustomerID
WHERE vr.NextDueDate BETWEEN CURDATE() AND DATE_ADD(CURDATE(), INTERVAL 12 MONTH)
ORDER BY vr.NextDueDate ASC;

-- ----------------------------------------------------------
-- Query 10: Analytical / Advanced Query
-- Current boarding occupancy: rooms occupied vs available today
-- ----------------------------------------------------------
-- Technical: Uses LEFT JOIN from Room to BoardingBookingPet + BoardingBooking
--            filtering for currently active stays (Checked-In).
--            CASE expression derives occupancy status per room.
-- Business: Management and reception can instantly see room availability
--           to handle walk-in boarding requests or over-the-phone enquiries,
--           preventing overbooking and maximising occupancy revenue.
-- ----------------------------------------------------------
SELECT
    r.RoomID,
    r.RoomCode,
    r.RoomType,
    r.NightlyRateDefault,
    CASE
        WHEN bbp.RoomID IS NOT NULL THEN 'OCCUPIED'
        ELSE 'AVAILABLE'
    END                                  AS OccupancyStatus,
    p.Name                               AS CurrentPet,
    CONCAT(c.FirstName,' ',c.LastName)   AS OwnerName,
    bb.CheckInDateTime,
    bb.CheckOutDateTime
FROM Room r
LEFT JOIN BoardingBookingPet  bbp ON r.RoomID     = bbp.RoomID
LEFT JOIN BoardingBooking     bb  ON bbp.BoardingID = bb.BoardingID
                                  AND bb.Status    = 'Checked-In'
LEFT JOIN Pet                 p   ON bbp.PetID     = p.PetID
LEFT JOIN Customer            c   ON p.CustomerID  = c.CustomerID
WHERE r.IsActive = 1
ORDER BY r.RoomType, r.RoomCode;
