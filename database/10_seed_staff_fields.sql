-- Version: 1.1.0
-- Demo seed for Staff fields and per-user/year allocations (post 09_migrate_staffcode)
--
-- =============================================================================
-- PARAMETERS
-- =============================================================================
-- Target Year for Allocations: 2025
-- Admin StaffCode (preserved): ADMIN001
--
-- =============================================================================
-- DESCRIPTION
-- =============================================================================
-- This script:
-- 1. Deletes existing user data (except ADMIN001)
-- 2. Copies staff data from tb_Staff to tb_Users with field mappings
-- 3. Clears and re-populates leave year allocations for 2025
--
-- =============================================================================
-- FIELD MAPPINGS (tb_Staff -> tb_Users)
-- =============================================================================
-- tb_Staff Field     -> tb_Users Field       | Description
-- -------------------------------------------------------------------------------
-- StaffCode          -> StaffCode            | Staff identifier (same)
-- EName              -> EName                | English name (same)
-- CName              -> CName                | Chinese name (same)
-- Email              -> Email                | Email address (same)
-- Mobile             -> Mobile               | Mobile phone (same)
-- EmployType         -> EmployType           | Employment type (same)
-- EmployDate         -> HireDate             | Hire date
-- SL                 -> SickLeavePaidDays    | Sick leave days
-- Title              -> Position             | Job title/position
-- Dept               -> DepartmentID         | Department code
-- Add1 + Add2 + Add3 -> Remark               | Combined address fields
-- -------------------------------------------------------------------------------

USE [HRLeaveSystemDB];
GO

PRINT 'Clearing existing user data and related records (except ADMIN001)...';

-- Delete related records first to avoid FK constraint issues
DELETE FROM dbo.tb_LeaveRequestDates WHERE RequestID IN (SELECT RequestID FROM dbo.tb_LeaveRequests WHERE RequesterStaffCode <> 'ADMIN001');
DELETE FROM dbo.tb_LeaveRequests WHERE RequesterStaffCode <> 'ADMIN001';
DELETE FROM dbo.tb_LeaveBalances WHERE StaffCode <> 'ADMIN001';
DELETE FROM dbo.tb_YearOpeningBalances WHERE StaffCode <> 'ADMIN001';
DELETE FROM dbo.tb_CompensatoryGrants WHERE StaffCode <> 'ADMIN001';
DELETE FROM dbo.tb_LeaveYearAllocations WHERE StaffCode <> 'ADMIN001';
DELETE FROM dbo.tb_BlackoutDates WHERE CreatedByStaffCode <> 'ADMIN001' OR CreatedByStaffCode IS NULL;

-- Now delete users except admin
DELETE FROM dbo.tb_Users WHERE StaffCode <> 'ADMIN001';

PRINT '✓ Existing data cleared.';
PRINT '';

PRINT 'Copying Staff data from tb_Staff to tb_Users...';

-- Check if tb_Staff exists
IF OBJECT_ID('dbo.tb_Staff','U') IS NOT NULL
BEGIN
    PRINT '📋 tb_Staff table found. Using MERGE to insert/update users...';
    
    -- Use MERGE to handle existing users with default password '000000'
    MERGE dbo.tb_Users AS T
    USING (
        SELECT 
            s.StaffCode,
            '000000' AS PasswordHash,  -- Default password before hash
            s.EName,
            s.CName,
            s.Email,
            s.Dept AS DepartmentID,
            s.Title AS Position,
            'Employee' AS Role,
            1 AS IsActive,
            s.EmployDate AS HireDate,  -- EmployDate -> HireDate
            COALESCE(s.SL, 4.5) AS SickLeavePaidDays,
            s.Mobile,
            s.EmployType,
            -- Combine Add1, Add2, Add3 with ' | ' separator
            LTRIM(RTRIM(
                CASE WHEN NULLIF(LTRIM(RTRIM(s.Add1)),'') IS NOT NULL THEN s.Add1 ELSE '' END +
                CASE WHEN NULLIF(LTRIM(RTRIM(s.Add2)),'') IS NOT NULL THEN 
                    CASE WHEN NULLIF(LTRIM(RTRIM(s.Add1)),'') IS NOT NULL THEN ' | ' ELSE '' END + s.Add2 
                ELSE '' END +
                CASE WHEN NULLIF(LTRIM(RTRIM(s.Add3)),'') IS NOT NULL THEN 
                    CASE WHEN NULLIF(LTRIM(RTRIM(s.Add1)),'') IS NOT NULL OR NULLIF(LTRIM(RTRIM(s.Add2)),'') IS NOT NULL THEN ' | ' ELSE '' END + s.Add3 
                ELSE '' END
            )) AS Remark,
            GETDATE() AS CreatedDate
        FROM dbo.tb_Staff s
        WHERE s.StaffCode <> 'ADMIN001'
          AND s.StaffCode IS NOT NULL
    ) AS S
    ON T.StaffCode = S.StaffCode
    WHEN MATCHED THEN
        UPDATE SET 
            T.EName = S.EName,
            T.CName = S.CName,
            T.Email = S.Email,
            T.DepartmentID = S.DepartmentID,
            T.Position = S.Position,
            T.HireDate = S.HireDate,
            T.SickLeavePaidDays = S.SickLeavePaidDays,
            T.Mobile = S.Mobile,
            T.EmployType = S.EmployType,
            T.Remark = S.Remark,
            T.LastModifiedDate = GETDATE()
    WHEN NOT MATCHED THEN
        INSERT (StaffCode, PasswordHash, EName, CName, Email, DepartmentID, Position, Role, IsActive, HireDate, SickLeavePaidDays, Mobile, EmployType, Remark, CreatedDate)
        VALUES (S.StaffCode, S.PasswordHash, S.EName, S.CName, S.Email, S.DepartmentID, S.Position, S.Role, S.IsActive, S.HireDate, S.SickLeavePaidDays, S.Mobile, S.EmployType, S.Remark, S.CreatedDate);
    
    PRINT '✓ Staff data copied/updated from tb_Staff.';
END
ELSE
BEGIN
    PRINT '⚠ tb_Staff table not found. Creating sample users manually...';
    
    -- Fallback: Create sample users if tb_Staff doesn't exist (default password: 000000)
    MERGE dbo.tb_Users AS T
    USING (
        SELECT * FROM (
            VALUES 
                ('L888', '000000', 'Lin Jianming',   N'林劍明',   '90000002', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E001', '000000', 'Xu Renchen',     N'徐人琛',   '90000003', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E002', '000000', 'Zeng Guangfa',   N'曾廣發',   '90000004', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E003', '000000', 'Zhu Zhuoyi',     N'朱卓倚',   '90000005', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E004', '000000', 'Deng Dejian',    N'鄧德建',   '90000006', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E005', '000000', 'Lee Jianhua',    N'李健華',   '90000007', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E006', '000000', 'Wang Zixuan',    N'王子軒',   '90000008', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E007', '000000', 'Lin Yongcheng',  N'林永誠',   '90000009', 'FULL(5.5)', 4.5, 'Demo user'),
                ('E008', '000000', 'Lin Bingwen',    N'林炳文',   '90000010', 'FULL(5.5)', 4.5, 'Demo user')
        ) AS V(StaffCode, PasswordHash, EName, CName, Mobile, EmployType, SickLeavePaidDays, Remark)
    ) AS S
    ON T.StaffCode = S.StaffCode
    WHEN NOT MATCHED THEN
        INSERT (StaffCode, PasswordHash, EName, CName, Mobile, EmployType, Role, IsActive, SickLeavePaidDays, Remark, CreatedDate)
        VALUES (S.StaffCode, S.PasswordHash, S.EName, S.CName, S.Mobile, S.EmployType, 'Employee', 1, S.SickLeavePaidDays, S.Remark, GETDATE());
    
    PRINT '✓ Sample users created/updated.';
END

PRINT '✓ Staff fields populated.';
PRINT '';

PRINT 'Clearing old allocations and upserting tb_LeaveYearAllocations for 2025...';

-- Delete old allocations for non-admin users
DELETE FROM dbo.tb_LeaveYearAllocations WHERE StaffCode <> 'ADMIN001';

-- Upsert allocations for all active users
MERGE dbo.tb_LeaveYearAllocations AS T
USING (
    SELECT 
        u.StaffCode, 
        [Year] = 2025,
        AnnualDays = CASE WHEN u.StaffCode='L888' THEN CAST(9.5 AS DECIMAL(5,1)) ELSE CAST(8.5 AS DECIMAL(5,1)) END,
           SickLeavePaidDays = CAST(4.5 AS DECIMAL(4,1))
    FROM dbo.tb_Users u
    WHERE u.StaffCode <> 'ADMIN001' AND u.IsActive = 1
) AS S
ON T.StaffCode = S.StaffCode AND T.[Year] = S.[Year]
WHEN MATCHED THEN 
    UPDATE SET T.AnnualDays = S.AnnualDays, T.SickLeavePaidDays = S.SickLeavePaidDays
WHEN NOT MATCHED THEN 
    INSERT (StaffCode,[Year],AnnualDays,SickLeavePaidDays) 
    VALUES (S.StaffCode,S.[Year],S.AnnualDays,S.SickLeavePaidDays);

PRINT '✓ LeaveYearAllocations upserted for all users.';
PRINT 'Demo Staff fields and allocations seeding completed.';
GO


