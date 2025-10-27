-- Version: 1.0.0
-- Demo seed script for entitlements-related data
-- Purpose: Populate HireDate, YearOpeningBalances, CompensatoryGrants, and LeaveTypeRules
-- Safe to re-run (idempotent upserts)

USE [HRLeaveSystemDB];
GO

PRINT 'Seeding demo entitlements data...';
PRINT '';

-- 1) HireDate (demo values)
PRINT 'Updating HireDate for demo users...';
UPDATE dbo.tb_Users SET HireDate='2021-01-01' WHERE StaffCode='ADMIN001' AND (HireDate IS NULL OR HireDate<>'2021-01-01');
UPDATE dbo.tb_Users SET HireDate='2022-11-01' WHERE StaffCode IN ('E001','L888') AND (HireDate IS NULL OR HireDate<>'2022-11-01');
UPDATE dbo.tb_Users SET HireDate='2023-03-01' WHERE StaffCode IN ('E002','E003','E004','E005','E006','E007','E008') AND (HireDate IS NULL OR HireDate<>'2023-03-01');
PRINT '✓ HireDate updated.';
PRINT '';

-- 2) Year Opening Balances (carry-forward for 2025)
PRINT 'Upserting YearOpeningBalances (2025)...';
MERGE dbo.tb_YearOpeningBalances AS T
USING (VALUES 
    ('E001', 2025, CAST(3.0 AS DECIMAL(5,1))),
    ('E002', 2025, CAST(1.0 AS DECIMAL(5,1)))
) AS S(StaffCode, [Year], AnnualCarryForward)
ON T.StaffCode = S.StaffCode AND T.[Year] = S.[Year]
WHEN MATCHED THEN UPDATE SET T.AnnualCarryForward = S.AnnualCarryForward
WHEN NOT MATCHED THEN INSERT (StaffCode, [Year], AnnualCarryForward) VALUES (S.StaffCode, S.[Year], S.AnnualCarryForward);
PRINT '✓ YearOpeningBalances upserted.';
PRINT '';

-- 3) Compensatory grants (2025)
PRINT 'Inserting compensatory grants (2025)...';
IF NOT EXISTS (SELECT 1 FROM dbo.tb_CompensatoryGrants WHERE StaffCode='E001' AND [Year]=2025 AND Days=4.0 AND Reason=N'Demo grant')
BEGIN
    INSERT INTO dbo.tb_CompensatoryGrants (StaffCode, [Year], Days, Reason, CreatedByStaffCode)
    VALUES ('E001', 2025, 4.0, N'Demo grant', 'ADMIN001');
END
PRINT '✓ Compensatory grants ensured.';
PRINT '';

-- 4) LeaveTypeRules for Annual Leave
PRINT 'Upserting LeaveTypeRules for Annual Leave...';
DECLARE @annualId INT = (SELECT TOP 1 LeaveTypeID FROM dbo.tb_LeaveTypes WHERE LeaveTypeName_EN = 'Annual Leave');
IF @annualId IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM dbo.tb_LeaveTypeRules WHERE LeaveTypeID=@annualId)
    BEGIN
        UPDATE dbo.tb_LeaveTypeRules
           SET BaseDays = 7.5,
               AnnualIncrement = 1.0,
               MaxDays = 16.5,
               ProRataFirstYear = 1,
               AllowDecimals = 0
         WHERE LeaveTypeID=@annualId;
    END
    ELSE
    BEGIN
        INSERT INTO dbo.tb_LeaveTypeRules (LeaveTypeID, BaseDays, AnnualIncrement, MaxDays, ProRataFirstYear, AllowDecimals)
        VALUES (@annualId, 7.5, 1.0, 16.5, 1, 0);
    END
END
PRINT '✓ LeaveTypeRules upserted.';
PRINT '';

PRINT 'Demo entitlements seeding completed.';
GO


