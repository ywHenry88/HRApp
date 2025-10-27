-- Version: 1.0.0
-- Computed views for entitlements and totals

USE [HRLeaveSystemDB];
GO

PRINT 'Creating computed views...';
PRINT '';

-- Helper: Current year (can be parameterized in procs)
-- Using GETDATE() context for views

-- v_AnnualEntitlement --------------------------------------------------------
IF OBJECT_ID('dbo.v_AnnualEntitlement', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_AnnualEntitlement];
GO

CREATE VIEW [dbo].[v_AnnualEntitlement]
AS
WITH Params AS (
    -- Pull annual leave parameters; if not present, default 7.5 base, +1 inc, max 16.5, prorata=1
    SELECT 
        COALESCE(ltr.BaseDays, CAST(7.5 AS DECIMAL(5,1))) AS BaseDays,
        COALESCE(ltr.AnnualIncrement, CAST(1.0 AS DECIMAL(4,1))) AS AnnualIncrement,
        COALESCE(ltr.MaxDays, CAST(16.5 AS DECIMAL(5,1))) AS MaxDays,
        COALESCE(ltr.ProRataFirstYear, 1) AS ProRataFirstYear
    FROM dbo.tb_LeaveTypes lt
    LEFT JOIN dbo.tb_LeaveTypeRules ltr ON ltr.LeaveTypeID = lt.LeaveTypeID
    WHERE lt.LeaveTypeName_EN = 'Annual Leave' -- match seeded name
), CY AS (
    SELECT YEAR(GETDATE()) AS [Year], CAST(DATEFROMPARTS(YEAR(GETDATE()),1,1) AS DATE) AS Jan1,
           CAST(DATEFROMPARTS(YEAR(GETDATE()),12,31) AS DATE) AS Dec31
)
SELECT 
    u.[StaffCode],
    cy.[Year],
    -- AnnualDays calculation
    CAST(
        CASE 
            WHEN u.HireDate IS NULL THEN p.BaseDays
            WHEN YEAR(u.HireDate) = cy.[Year] AND p.ProRataFirstYear = 1 THEN
                p.BaseDays * (CAST(DATEDIFF(DAY, CASE WHEN u.HireDate > cy.Jan1 THEN u.HireDate ELSE cy.Jan1 END, cy.Dec31) + 1 AS DECIMAL(9,4)) / 365.0)
            WHEN YEAR(u.HireDate) < cy.[Year] THEN
                CASE 
                    WHEN (p.BaseDays + (cy.[Year] - (YEAR(u.HireDate) + 1)) * p.AnnualIncrement) > p.MaxDays THEN p.MaxDays
                    ELSE p.BaseDays + (cy.[Year] - (YEAR(u.HireDate) + 1)) * p.AnnualIncrement
                END
            ELSE p.BaseDays
        END AS DECIMAL(6,2)
    ) AS [AnnualDays],
    COALESCE(yob.[AnnualCarryForward], 0) AS [CarryForward],
    COALESCE(
        (SELECT SUM(g.[Days]) FROM dbo.tb_CompensatoryGrants g WHERE g.[StaffCode] = u.[StaffCode] AND g.[Year] = cy.[Year])
    , 0) AS [Compensatory],
    CAST(0 AS DECIMAL(6,2)) AS [Reserved0],
    -- Total
    CAST(
        (
            CAST(
                CASE 
                    WHEN u.HireDate IS NULL THEN p.BaseDays
                    WHEN YEAR(u.HireDate) = cy.[Year] AND p.ProRataFirstYear = 1 THEN
                        p.BaseDays * (CAST(DATEDIFF(DAY, CASE WHEN u.HireDate > cy.Jan1 THEN u.HireDate ELSE cy.Jan1 END, cy.Dec31) + 1 AS DECIMAL(9,4)) / 365.0)
                    WHEN YEAR(u.HireDate) < cy.[Year] THEN
                        CASE 
                            WHEN (p.BaseDays + (cy.[Year] - (YEAR(u.HireDate) + 1)) * p.AnnualIncrement) > p.MaxDays THEN p.MaxDays
                            ELSE p.BaseDays + (cy.[Year] - (YEAR(u.HireDate) + 1)) * p.AnnualIncrement
                        END
                    ELSE p.BaseDays
                END AS DECIMAL(6,2)
            )
            + COALESCE(yob.[AnnualCarryForward], 0)
            + COALESCE((SELECT SUM(g.[Days]) FROM dbo.tb_CompensatoryGrants g WHERE g.[StaffCode] = u.[StaffCode] AND g.[Year] = cy.[Year]), 0)
        ) AS DECIMAL(6,2)
    ) AS [AnnualTotal]
FROM dbo.tb_Users u
CROSS JOIN CY cy
CROSS JOIN Params p
LEFT JOIN dbo.tb_YearOpeningBalances yob ON yob.[StaffCode] = u.[StaffCode] AND yob.[Year] = cy.[Year];
GO

PRINT '✓ View v_AnnualEntitlement created.';

-- v_SickBalance --------------------------------------------------------------
IF OBJECT_ID('dbo.v_SickBalance', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_SickBalance];
GO

CREATE VIEW [dbo].[v_SickBalance]
AS
WITH CY AS (
    SELECT YEAR(GETDATE()) AS [Year]
), SickUsed AS (
    -- Count approved sick days this year from LeaveRequestDates
    SELECT lr.[RequesterStaffCode] AS StaffCode, COUNT(1) AS SickApprovedDays
    FROM dbo.tb_LeaveRequests lr
    INNER JOIN dbo.tb_LeaveTypes lt ON lt.LeaveTypeID = lr.LeaveTypeID AND lt.LeaveTypeName_EN = 'Sick'
    INNER JOIN dbo.tb_LeaveRequestDates rd ON rd.RequestID = lr.RequestID AND rd.DateStatus = 'Approved'
    WHERE YEAR(rd.LeaveDate) = (SELECT [Year] FROM CY)
      AND lr.Status IN ('Approved','PartiallyApproved')
    GROUP BY lr.[RequesterStaffCode]
)
SELECT 
    u.[StaffCode],
    (SELECT [Year] FROM CY) AS [Year],
    u.[SickLeavePaidDays] AS [SickPaidEntitlement],
    COALESCE(su.[SickApprovedDays], 0) AS [SickPaidUsed],
    CAST(u.[SickLeavePaidDays] - COALESCE(su.[SickApprovedDays], 0) AS DECIMAL(6,2)) AS [SickPaidRemaining]
FROM dbo.tb_Users u
LEFT JOIN SickUsed su ON su.[StaffCode] = u.[StaffCode];
GO

PRINT '✓ View v_SickBalance created.';

-- v_LeaveTotals --------------------------------------------------------------
IF OBJECT_ID('dbo.v_LeaveTotals', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_LeaveTotals];
GO

CREATE VIEW [dbo].[v_LeaveTotals]
AS
WITH CY AS (
    SELECT YEAR(GETDATE()) AS [Year]
), AnnualUsed AS (
    -- Count approved Annual leave days this year
    SELECT lr.[RequesterStaffCode] AS StaffCode, COUNT(1) AS AnnualApprovedDays
    FROM dbo.tb_LeaveRequests lr
    INNER JOIN dbo.tb_LeaveTypes lt ON lt.LeaveTypeID = lr.LeaveTypeID AND lt.LeaveTypeName_EN = 'Annual Leave'
    INNER JOIN dbo.tb_LeaveRequestDates rd ON rd.RequestID = lr.RequestID AND rd.DateStatus = 'Approved'
    WHERE YEAR(rd.LeaveDate) = (SELECT [Year] FROM CY)
      AND lr.Status IN ('Approved','PartiallyApproved')
    GROUP BY lr.[RequesterStaffCode]
), Ent AS (
    SELECT * FROM dbo.v_AnnualEntitlement
)
SELECT 
    ent.[StaffCode],
    ent.[Year],
    ent.[AnnualTotal],
    COALESCE(au.[AnnualApprovedDays], 0) AS [AnnualUsed],
    CAST(ent.[AnnualTotal] - COALESCE(au.[AnnualApprovedDays], 0) AS DECIMAL(6,2)) AS [AnnualRemaining]
FROM Ent ent
LEFT JOIN AnnualUsed au ON au.[StaffCode] = ent.[StaffCode] AND (SELECT [Year] FROM CY) = ent.[Year];
GO

PRINT '✓ View v_LeaveTotals created.';
PRINT 'All computed views created.';
GO


