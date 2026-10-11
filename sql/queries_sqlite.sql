-- SQLite ports of the Task 8 queries in happypaws.sql, used by
-- analysis/build_dashboard.py. Logic is unchanged unless a comment says so.
-- MySQL -> SQLite: CONCAT -> ||, DATE_FORMAT -> strftime,
-- DATEDIFF / DATE_ADD -> julianday / date(), CURDATE() -> :as_of.

-- name: q01_active_staff
SELECT StaffID, FirstName || ' ' || LastName AS FullName, Role
FROM Staff
WHERE EmploymentStatus = 'Active'
ORDER BY Role, LastName;

-- name: q02_pets_owners
SELECT p.PetID, p.Name AS PetName, p.Species, p.Breed,
       c.FirstName || ' ' || c.LastName AS OwnerName
FROM Pet p
INNER JOIN Customer c ON p.CustomerID = c.CustomerID
ORDER BY c.LastName, p.Name;

-- name: q03_appointments
SELECT a.AppointmentID, a.StartDateTime, p.Name AS PetName, p.Species,
       s.ServiceName, s.Category,
       st.FirstName || ' ' || st.LastName AS AssignedStaff, st.Role, a.Status
FROM Appointment a
INNER JOIN Pet      p  ON a.PetID      = p.PetID
INNER JOIN Customer c  ON p.CustomerID = c.CustomerID
INNER JOIN Service  s  ON a.ServiceID  = s.ServiceID
INNER JOIN Staff    st ON a.StaffID    = st.StaffID
ORDER BY a.StartDateTime;

-- name: q04_vaccinations
SELECT vr.VaccinationID, p.Name AS PetName, p.Species, vr.VaccineName,
       vr.DateAdministered, vr.NextDueDate,
       CAST(julianday(vr.NextDueDate) - julianday(:as_of) AS INTEGER) AS DaysUntilDue
FROM VaccinationRecord vr
INNER JOIN Pet      p  ON vr.PetID         = p.PetID
INNER JOIN Customer c  ON p.CustomerID     = c.CustomerID
INNER JOIN Staff    st ON vr.AdministeredBy = st.StaffID
ORDER BY vr.NextDueDate;

-- name: q05_monthly_revenue
SELECT strftime('%Y-%m', PaymentDateTime) AS Month, PayerType,
       COUNT(*) AS NumberOfTransactions, ROUND(SUM(Amount), 2) AS TotalRevenue
FROM Payment
WHERE Status = 'Success'
GROUP BY Month, PayerType
ORDER BY Month, PayerType;

-- name: q06_top_services
SELECT s.ServiceName, s.Category, s.BasePrice,
       COUNT(a.AppointmentID) AS TotalCompleted,
       ROUND(SUM(s.BasePrice), 2) AS EstimatedRevenue
FROM Appointment a
INNER JOIN Service s ON a.ServiceID = s.ServiceID
WHERE a.Status = 'Completed'
GROUP BY s.ServiceID, s.ServiceName, s.Category, s.BasePrice
ORDER BY TotalCompleted DESC, EstimatedRevenue DESC;

-- name: q07_low_stock
SELECT p.SKU, p.ProductName, p.Category, p.UnitInStock, p.ReorderLevel,
       (p.ReorderLevel - p.UnitInStock) AS ShortfallQty, p.ExpiryDate,
       CASE WHEN p.ExpiryDate IS NOT NULL AND p.ExpiryDate <= date(:as_of, '+90 days')
            THEN 'EXPIRING SOON' ELSE 'OK' END AS ExpiryAlert,
       COALESCE(s.SupplierName, 'N/A') AS SupplierName
FROM Product p
LEFT JOIN Supplier s ON p.SupplierID = s.SupplierID
WHERE p.UnitInStock <= p.ReorderLevel
ORDER BY p.UnitInStock ASC;

-- name: q08_customer_ltv
SELECT c.CustomerID, c.FirstName || ' ' || c.LastName AS CustomerName,
       COALESCE(retail.RetailSpend, 0)  AS RetailSpend,
       COALESCE(board.BoardingSpend, 0) AS BoardingSpend,
       COALESCE(appt.ApptSpend, 0)      AS AppointmentSpend,
       ROUND(COALESCE(retail.RetailSpend, 0) + COALESCE(board.BoardingSpend, 0)
             + COALESCE(appt.ApptSpend, 0), 2) AS TotalLifetimeValue
FROM Customer c
LEFT JOIN (
    SELECT so.CustomerID, SUM(py.Amount) AS RetailSpend
    FROM Payment py
    INNER JOIN SalesOrder so ON py.PayerRefID = so.SalesOrderID
    WHERE py.PayerType = 'SalesOrder' AND py.Status = 'Success'
    GROUP BY so.CustomerID
) AS retail ON c.CustomerID = retail.CustomerID
LEFT JOIN (
    SELECT bb.CustomerID, SUM(py.Amount) AS BoardingSpend
    FROM Payment py
    INNER JOIN BoardingBooking bb ON py.PayerRefID = bb.BoardingID
    WHERE py.PayerType = 'Boarding' AND py.Status = 'Success'
    GROUP BY bb.CustomerID
) AS board ON c.CustomerID = board.CustomerID
LEFT JOIN (
    SELECT p2.CustomerID, SUM(py.Amount) AS ApptSpend
    FROM Payment py
    INNER JOIN Appointment a  ON py.PayerRefID = a.AppointmentID
    INNER JOIN Pet         p2 ON a.PetID = p2.PetID
    WHERE py.PayerType = 'Appointment' AND py.Status = 'Success'
    GROUP BY p2.CustomerID
) AS appt ON c.CustomerID = appt.CustomerID
ORDER BY TotalLifetimeValue DESC;

-- name: q09_vaccinations_due
SELECT vr.VaccinationID, p.Name AS PetName, p.Species, vr.VaccineName, vr.NextDueDate,
       CAST(julianday(vr.NextDueDate) - julianday(:as_of) AS INTEGER) AS DaysUntilDue,
       c.FirstName || ' ' || c.LastName AS OwnerName
FROM VaccinationRecord vr
INNER JOIN Pet      p ON vr.PetID     = p.PetID
INNER JOIN Customer c ON p.CustomerID = c.CustomerID
WHERE vr.NextDueDate BETWEEN :as_of AND date(:as_of, '+12 months')
ORDER BY vr.NextDueDate ASC;

-- name: q10_occupancy_original
-- As submitted. The Checked-In filter sits on the BoardingBooking join, but the
-- CASE checks BoardingBookingPet, so any room that ever had a booking shows as
-- OCCUPIED with a past guest's name, and a room booked twice appears twice.
SELECT r.RoomCode, r.RoomType,
       CASE WHEN bbp.RoomID IS NOT NULL THEN 'OCCUPIED' ELSE 'AVAILABLE' END AS OccupancyStatus,
       p.Name AS CurrentPet
FROM Room r
LEFT JOIN BoardingBookingPet bbp ON r.RoomID       = bbp.RoomID
LEFT JOIN BoardingBooking    bb  ON bbp.BoardingID = bb.BoardingID
                                AND bb.Status      = 'Checked-In'
LEFT JOIN Pet                p   ON bbp.PetID      = p.PetID
LEFT JOIN Customer           c   ON p.CustomerID   = c.CustomerID
WHERE r.IsActive = 1
ORDER BY r.RoomType, r.RoomCode;

-- name: q10_occupancy
-- Fixed: join only stays that are checked in, so each room appears once and
-- past bookings no longer count as occupancy.
SELECT r.RoomCode, r.RoomType, r.NightlyRateDefault,
       CASE WHEN cur.RoomID IS NOT NULL THEN 'OCCUPIED' ELSE 'AVAILABLE' END AS OccupancyStatus,
       cur.PetName AS CurrentPet, cur.CheckOutDateTime
FROM Room r
LEFT JOIN (
    SELECT bbp.RoomID, p.Name AS PetName, bb.CheckOutDateTime
    FROM BoardingBookingPet bbp
    INNER JOIN BoardingBooking bb ON bbp.BoardingID = bb.BoardingID
    INNER JOIN Pet             p  ON bbp.PetID      = p.PetID
    WHERE bb.Status = 'Checked-In'
) AS cur ON r.RoomID = cur.RoomID
WHERE r.IsActive = 1
ORDER BY r.RoomType, r.RoomCode;

-- name: x_payment_coverage
-- Added for the dashboard: how many completed jobs have a successful payment.
SELECT 'Appointment' AS Stream,
       (SELECT COUNT(*) FROM Appointment WHERE Status = 'Completed') AS CompletedJobs,
       (SELECT COUNT(DISTINCT PayerRefID) FROM Payment
         WHERE PayerType = 'Appointment' AND Status = 'Success') AS PaidJobs
UNION ALL
SELECT 'Boarding',
       (SELECT COUNT(*) FROM BoardingBooking WHERE Status = 'Checked-Out'),
       (SELECT COUNT(DISTINCT PayerRefID) FROM Payment
         WHERE PayerType = 'Boarding' AND Status = 'Success')
UNION ALL
SELECT 'Retail',
       (SELECT COUNT(*) FROM SalesOrder WHERE Status = 'Paid'),
       (SELECT COUNT(DISTINCT PayerRefID) FROM Payment
         WHERE PayerType = 'SalesOrder' AND Status = 'Success');

-- name: x_payment_methods
-- Added for the dashboard: successful revenue by payment method.
SELECT Method, COUNT(*) AS Transactions, ROUND(SUM(Amount), 2) AS Revenue
FROM Payment
WHERE Status = 'Success'
GROUP BY Method
ORDER BY Revenue DESC;
