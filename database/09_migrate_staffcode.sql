-- Version: 1.0.0
-- Migration: Switch identity to StaffCode, update related tables, add user fields,
--            and create per-user/year allocations table.
-- Safe to re-run (idempotent guards). Execute after scripts 01-08.

USE [HRLeaveSystemDB];
GO

PRINT 'Starting StaffCode migration...';
PRINT '';

-- Pre-drop foreign keys that reference tb_Users.UserID to allow PK change
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_YOB_User')
    ALTER TABLE dbo.tb_YearOpeningBalances DROP CONSTRAINT FK_tb_YOB_User;
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_CompGrants_User')
    ALTER TABLE dbo.tb_CompensatoryGrants DROP CONSTRAINT FK_tb_CompGrants_User;
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_CompGrants_CreatedBy')
    ALTER TABLE dbo.tb_CompensatoryGrants DROP CONSTRAINT FK_tb_CompGrants_CreatedBy;

/* =============================================
   1) tb_Users: add StaffCode and new fields
   ============================================= */
IF COL_LENGTH('dbo.tb_Users','StaffCode') IS NULL
BEGIN
    ALTER TABLE dbo.tb_Users ADD StaffCode NVARCHAR(20) NULL; -- backfill then set NOT NULL
    PRINT '✓ Added tb_Users.StaffCode (NULL for now)';
END

IF COL_LENGTH('dbo.tb_Users','EName') IS NULL ALTER TABLE dbo.tb_Users ADD EName NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.tb_Users','CName') IS NULL ALTER TABLE dbo.tb_Users ADD CName NVARCHAR(100) NULL;
IF COL_LENGTH('dbo.tb_Users','Mobile') IS NULL ALTER TABLE dbo.tb_Users ADD Mobile NVARCHAR(50) NULL;
IF COL_LENGTH('dbo.tb_Users','Remark') IS NULL ALTER TABLE dbo.tb_Users ADD Remark NVARCHAR(200) NULL;
IF COL_LENGTH('dbo.tb_Users','EmployType') IS NULL ALTER TABLE dbo.tb_Users ADD EmployType NVARCHAR(50) NULL;

GO

-- Prefer StaffCode from tb_Staff when available, else fallback to EmployeeCode/Username
IF OBJECT_ID('dbo.tb_Staff','U') IS NOT NULL 
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Staff') AND name='StaffCode')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='EmployeeCode')
   AND COL_LENGTH('dbo.tb_Users','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE u SET StaffCode = s.StaffCode FROM dbo.tb_Users u INNER JOIN dbo.tb_Staff s ON s.StaffCode = u.EmployeeCode WHERE u.StaffCode IS NULL');
END
-- Fallbacks
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='EmployeeCode')
   AND COL_LENGTH('dbo.tb_Users','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE u SET StaffCode = COALESCE(StaffCode, NULLIF(u.EmployeeCode,'''')) FROM dbo.tb_Users u WHERE u.StaffCode IS NULL');
END
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='Username')
   AND COL_LENGTH('dbo.tb_Users','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE dbo.tb_Users SET StaffCode = COALESCE(StaffCode, Username) WHERE StaffCode IS NULL');
END

-- Backfill EName/CName/Mobile/EmployType from tb_Staff when available
IF OBJECT_ID('dbo.tb_Staff','U') IS NOT NULL
BEGIN
    UPDATE u
    SET u.EName = COALESCE(u.EName, s.EName),
        u.CName = COALESCE(u.CName, s.CName),
        u.Mobile = COALESCE(u.Mobile, s.Mobile),
        u.EmployType = COALESCE(u.EmployType, s.EmployType)
    FROM dbo.tb_Users u
    INNER JOIN dbo.tb_Staff s ON s.StaffCode = u.StaffCode;
END

/* =============================================
   2) Drop FKs referencing tb_Users.UserID
   ============================================= */
-- Departments manager FK
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_Departments_Manager')
    ALTER TABLE dbo.tb_Departments DROP CONSTRAINT FK_tb_Departments_Manager;
-- LeaveBalances
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_LeaveBalances_User')
    ALTER TABLE dbo.tb_LeaveBalances DROP CONSTRAINT FK_tb_LeaveBalances_User;
-- LeaveRequests
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_LeaveRequests_User')
    ALTER TABLE dbo.tb_LeaveRequests DROP CONSTRAINT FK_tb_LeaveRequests_User;
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_LeaveRequests_ReviewedBy')
    ALTER TABLE dbo.tb_LeaveRequests DROP CONSTRAINT FK_tb_LeaveRequests_ReviewedBy;
-- BlackoutDates
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_BlackoutDates_CreatedBy')
    ALTER TABLE dbo.tb_BlackoutDates DROP CONSTRAINT FK_tb_BlackoutDates_CreatedBy;
IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_BlackoutDates_ModifiedBy')
    ALTER TABLE dbo.tb_BlackoutDates DROP CONSTRAINT FK_tb_BlackoutDates_ModifiedBy;

-- Before PK switch: ensure no NULL/blank StaffCode and resolve duplicates
-- Only execute if Username column exists (old schema)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='Username')
   AND COL_LENGTH('dbo.tb_Users','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE dbo.tb_Users SET StaffCode = Username WHERE (StaffCode IS NULL OR LTRIM(RTRIM(StaffCode)) = '''')');
END

-- Resolve duplicates only if UserID exists
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_Users','StaffCode') IS NOT NULL
BEGIN
    EXEC('
    WITH Dups AS (
      SELECT StaffCode, UserID, ROW_NUMBER() OVER (PARTITION BY StaffCode ORDER BY UserID) AS rn
      FROM dbo.tb_Users
    )
    UPDATE u
    SET StaffCode = LEFT(CONCAT(u.StaffCode, ''_'', u.UserID), 40)
    FROM dbo.tb_Users u
    JOIN Dups d ON d.UserID = u.UserID
    WHERE d.rn > 1
    ');
    
    -- FINAL SANITATION: fill any remaining NULL/empty StaffCode with generated code
    EXEC('
    UPDATE dbo.tb_Users
    SET StaffCode = LEFT(CONCAT(''SC'', RIGHT(''000000'', 6 - LEN(CAST(UserID AS NVARCHAR(10)))) + CAST(UserID AS NVARCHAR(10))), 40)
    WHERE StaffCode IS NULL OR LTRIM(RTRIM(StaffCode)) = ''''
    ');
END

-- Switch tb_Users primary key to StaffCode (after dropping dependent FKs)
DECLARE @pkName NVARCHAR(200) = (SELECT name FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('dbo.tb_Users') AND type='PK');
IF @pkName IS NOT NULL AND COL_LENGTH('dbo.tb_Users','UserID') IS NOT NULL
BEGIN
    DECLARE @dropSql NVARCHAR(500) = N'ALTER TABLE dbo.tb_Users DROP CONSTRAINT ' + QUOTENAME(@pkName) + N';';
    EXEC(@dropSql);
END
-- Drop unique index to allow altering nullability if exists
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='UK_tb_Users_StaffCode' AND object_id=OBJECT_ID('dbo.tb_Users'))
    DROP INDEX UK_tb_Users_StaffCode ON dbo.tb_Users;
-- Force NOT NULL on StaffCode (ensure consistent length NVARCHAR(40))
IF COL_LENGTH('dbo.tb_Users','StaffCode') IS NOT NULL
    ALTER TABLE dbo.tb_Users ALTER COLUMN StaffCode NVARCHAR(40) NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('dbo.tb_Users') AND type='PK')
BEGIN
    ALTER TABLE dbo.tb_Users ADD CONSTRAINT PK_tb_Users_StaffCode PRIMARY KEY CLUSTERED(StaffCode);
    PRINT '✓ Primary key set to StaffCode';
END

/* =============================================
   3) Add StaffCode columns and backfill in related tables
   ============================================= */
-- LeaveBalances: StaffCode
IF COL_LENGTH('dbo.tb_LeaveBalances','StaffCode') IS NULL
    ALTER TABLE dbo.tb_LeaveBalances ADD StaffCode NVARCHAR(40) NULL;
GO
-- Backfill only if UserID columns exist in both tables
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_LeaveBalances') AND name='UserID')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_LeaveBalances','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE lb SET StaffCode = u.StaffCode FROM dbo.tb_LeaveBalances lb JOIN dbo.tb_Users u ON lb.UserID = u.UserID WHERE lb.StaffCode IS NULL');
END
-- Set NOT NULL after backfill
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.tb_LeaveBalances') AND name='StaffCode' AND is_nullable=1)
    ALTER TABLE dbo.tb_LeaveBalances ALTER COLUMN StaffCode NVARCHAR(40) NOT NULL;
-- Replace unique index to use StaffCode instead of UserID
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='UK_tb_LeaveBalances_UserLeaveYear' AND object_id=OBJECT_ID('dbo.tb_LeaveBalances'))
    DROP INDEX UK_tb_LeaveBalances_UserLeaveYear ON dbo.tb_LeaveBalances;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='UK_tb_LeaveBalances_StaffLeaveYear' AND object_id=OBJECT_ID('dbo.tb_LeaveBalances'))
    CREATE UNIQUE NONCLUSTERED INDEX UK_tb_LeaveBalances_StaffLeaveYear ON dbo.tb_LeaveBalances(StaffCode, LeaveTypeID, [Year]);

-- LeaveRequests: RequesterStaffCode, ReviewedByStaffCode
IF COL_LENGTH('dbo.tb_LeaveRequests','RequesterStaffCode') IS NULL
    ALTER TABLE dbo.tb_LeaveRequests ADD RequesterStaffCode NVARCHAR(40) NULL;
IF COL_LENGTH('dbo.tb_LeaveRequests','ReviewedByStaffCode') IS NULL
    ALTER TABLE dbo.tb_LeaveRequests ADD ReviewedByStaffCode NVARCHAR(40) NULL;
GO
-- Backfill only if UserID columns exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_LeaveRequests') AND name='UserID')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_LeaveRequests','RequesterStaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE lr SET RequesterStaffCode = u.StaffCode FROM dbo.tb_LeaveRequests lr JOIN dbo.tb_Users u ON lr.UserID = u.UserID WHERE lr.RequesterStaffCode IS NULL');
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_LeaveRequests') AND name='ReviewedBy')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_LeaveRequests','ReviewedByStaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE lr SET ReviewedByStaffCode = u.StaffCode FROM dbo.tb_LeaveRequests lr JOIN dbo.tb_Users u ON lr.ReviewedBy = u.UserID WHERE lr.ReviewedBy IS NOT NULL AND lr.ReviewedByStaffCode IS NULL');
END
-- Set NOT NULL for requester
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.tb_LeaveRequests') AND name='RequesterStaffCode' AND is_nullable=1)
    ALTER TABLE dbo.tb_LeaveRequests ALTER COLUMN RequesterStaffCode NVARCHAR(40) NOT NULL;

-- BlackoutDates: CreatedByStaffCode, LastModifiedByStaffCode
IF COL_LENGTH('dbo.tb_BlackoutDates','CreatedByStaffCode') IS NULL
    ALTER TABLE dbo.tb_BlackoutDates ADD CreatedByStaffCode NVARCHAR(40) NULL;
IF COL_LENGTH('dbo.tb_BlackoutDates','LastModifiedByStaffCode') IS NULL
    ALTER TABLE dbo.tb_BlackoutDates ADD LastModifiedByStaffCode NVARCHAR(40) NULL;
GO
-- Backfill only if old UserID columns exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_BlackoutDates') AND name='CreatedBy')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_BlackoutDates','CreatedByStaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE b SET CreatedByStaffCode = u.StaffCode FROM dbo.tb_BlackoutDates b JOIN dbo.tb_Users u ON b.CreatedBy = u.UserID WHERE b.CreatedByStaffCode IS NULL');
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_BlackoutDates') AND name='LastModifiedBy')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_BlackoutDates','LastModifiedByStaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE b SET LastModifiedByStaffCode = u.StaffCode FROM dbo.tb_BlackoutDates b JOIN dbo.tb_Users u ON b.LastModifiedBy = u.UserID WHERE b.LastModifiedBy IS NOT NULL AND b.LastModifiedByStaffCode IS NULL');
END

-- AuditLog: StaffCode
IF COL_LENGTH('dbo.tb_AuditLog','StaffCode') IS NULL
    ALTER TABLE dbo.tb_AuditLog ADD StaffCode NVARCHAR(40) NULL;
GO
-- Backfill only if UserID columns exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_AuditLog') AND name='UserID')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_AuditLog','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE a SET StaffCode = u.StaffCode FROM dbo.tb_AuditLog a LEFT JOIN dbo.tb_Users u ON a.UserID = u.UserID WHERE a.StaffCode IS NULL AND a.UserID IS NOT NULL');
END

/* =============================================
   4) YearOpeningBalances and CompensatoryGrants to StaffCode
   ============================================= */
-- YearOpeningBalances: add StaffCode, backfill, PK change, FK to Users(StaffCode)
IF COL_LENGTH('dbo.tb_YearOpeningBalances','StaffCode') IS NULL
    ALTER TABLE dbo.tb_YearOpeningBalances ADD StaffCode NVARCHAR(40) NULL;
GO
-- Backfill only if UserID columns exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_YearOpeningBalances') AND name='UserID')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_YearOpeningBalances','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE y SET StaffCode = u.StaffCode FROM dbo.tb_YearOpeningBalances y JOIN dbo.tb_Users u ON y.UserID = u.UserID WHERE y.StaffCode IS NULL');
END
GO
DECLARE @yobPk NVARCHAR(200) = (SELECT name FROM sys.key_constraints WHERE parent_object_id=OBJECT_ID('dbo.tb_YearOpeningBalances') AND type='PK');
IF @yobPk IS NOT NULL
BEGIN
    DECLARE @sqlDropYobPk NVARCHAR(500) = N'ALTER TABLE dbo.tb_YearOpeningBalances DROP CONSTRAINT ' + QUOTENAME(@yobPk) + N';';
    EXEC(@sqlDropYobPk);
END
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.tb_YearOpeningBalances') AND name='StaffCode' AND is_nullable=1)
    ALTER TABLE dbo.tb_YearOpeningBalances ALTER COLUMN StaffCode NVARCHAR(40) NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.key_constraints WHERE name='PK_tb_YearOpeningBalances' AND parent_object_id=OBJECT_ID('dbo.tb_YearOpeningBalances'))
    ALTER TABLE dbo.tb_YearOpeningBalances ADD CONSTRAINT PK_tb_YearOpeningBalances PRIMARY KEY CLUSTERED (StaffCode, [Year]);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_YOB_Staff')
    ALTER TABLE dbo.tb_YearOpeningBalances ADD CONSTRAINT FK_tb_YOB_Staff FOREIGN KEY (StaffCode) REFERENCES dbo.tb_Users(StaffCode);
IF COL_LENGTH('dbo.tb_YearOpeningBalances','UserID') IS NOT NULL
    ALTER TABLE dbo.tb_YearOpeningBalances DROP COLUMN UserID;
GO
-- CompensatoryGrants: add StaffCode and CreatedByStaffCode and FKs
IF COL_LENGTH('dbo.tb_CompensatoryGrants','StaffCode') IS NULL
    ALTER TABLE dbo.tb_CompensatoryGrants ADD StaffCode NVARCHAR(40) NULL;
IF COL_LENGTH('dbo.tb_CompensatoryGrants','CreatedByStaffCode') IS NULL
    ALTER TABLE dbo.tb_CompensatoryGrants ADD CreatedByStaffCode NVARCHAR(40) NULL;
GO
-- Backfill only if UserID columns exist
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_CompensatoryGrants') AND name='UserID')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_CompensatoryGrants','StaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE g SET StaffCode = u.StaffCode FROM dbo.tb_CompensatoryGrants g JOIN dbo.tb_Users u ON g.UserID = u.UserID WHERE g.StaffCode IS NULL');
END

IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_CompensatoryGrants') AND name='CreatedBy')
   AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Users') AND name='UserID')
   AND COL_LENGTH('dbo.tb_CompensatoryGrants','CreatedByStaffCode') IS NOT NULL
BEGIN
    EXEC('UPDATE g SET CreatedByStaffCode = u.StaffCode FROM dbo.tb_CompensatoryGrants g JOIN dbo.tb_Users u ON g.CreatedBy = u.UserID WHERE g.CreatedByStaffCode IS NULL');
END
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_CompGrants_Staff')
    ALTER TABLE dbo.tb_CompensatoryGrants ADD CONSTRAINT FK_tb_CompGrants_Staff FOREIGN KEY (StaffCode) REFERENCES dbo.tb_Users(StaffCode);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_CompGrants_CreatedByStaff')
    ALTER TABLE dbo.tb_CompensatoryGrants ADD CONSTRAINT FK_tb_CompGrants_CreatedByStaff FOREIGN KEY (CreatedByStaffCode) REFERENCES dbo.tb_Users(StaffCode);

/* =============================================
   4) Add new FKs to tb_Users.StaffCode
   ============================================= */
-- LeaveBalances
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_LeaveBalances_Staff')
    ALTER TABLE dbo.tb_LeaveBalances ADD CONSTRAINT FK_tb_LeaveBalances_Staff FOREIGN KEY (StaffCode) REFERENCES dbo.tb_Users(StaffCode);
-- LeaveRequests
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_LeaveRequests_RequesterStaff')
    ALTER TABLE dbo.tb_LeaveRequests ADD CONSTRAINT FK_tb_LeaveRequests_RequesterStaff FOREIGN KEY (RequesterStaffCode) REFERENCES dbo.tb_Users(StaffCode);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_LeaveRequests_ReviewerStaff')
    ALTER TABLE dbo.tb_LeaveRequests ADD CONSTRAINT FK_tb_LeaveRequests_ReviewerStaff FOREIGN KEY (ReviewedByStaffCode) REFERENCES dbo.tb_Users(StaffCode);
-- BlackoutDates
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_BlackoutDates_CreatedByStaff')
    ALTER TABLE dbo.tb_BlackoutDates ADD CONSTRAINT FK_tb_BlackoutDates_CreatedByStaff FOREIGN KEY (CreatedByStaffCode) REFERENCES dbo.tb_Users(StaffCode);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name='FK_tb_BlackoutDates_ModifiedByStaff')
    ALTER TABLE dbo.tb_BlackoutDates ADD CONSTRAINT FK_tb_BlackoutDates_ModifiedByStaff FOREIGN KEY (LastModifiedByStaffCode) REFERENCES dbo.tb_Users(StaffCode);

/* =============================================
   5) Drop old int FK columns after migration
   ============================================= */
IF COL_LENGTH('dbo.tb_Departments','ManagerUserID') IS NOT NULL
    ALTER TABLE dbo.tb_Departments DROP COLUMN ManagerUserID;
IF COL_LENGTH('dbo.tb_LeaveBalances','UserID') IS NOT NULL
    ALTER TABLE dbo.tb_LeaveBalances DROP COLUMN UserID;
IF COL_LENGTH('dbo.tb_LeaveRequests','UserID') IS NOT NULL
    ALTER TABLE dbo.tb_LeaveRequests DROP COLUMN UserID;
IF COL_LENGTH('dbo.tb_LeaveRequests','ReviewedBy') IS NOT NULL
    ALTER TABLE dbo.tb_LeaveRequests DROP COLUMN ReviewedBy;
IF COL_LENGTH('dbo.tb_BlackoutDates','CreatedBy') IS NOT NULL
    ALTER TABLE dbo.tb_BlackoutDates DROP COLUMN CreatedBy;
IF COL_LENGTH('dbo.tb_BlackoutDates','LastModifiedBy') IS NOT NULL
    ALTER TABLE dbo.tb_BlackoutDates DROP COLUMN LastModifiedBy;
IF COL_LENGTH('dbo.tb_AuditLog','UserID') IS NOT NULL
    ALTER TABLE dbo.tb_AuditLog DROP COLUMN UserID;

/* =============================================
   6) Finalize tb_Users: drop obsolete columns and update DepartmentID
   ============================================= */
IF COL_LENGTH('dbo.tb_Users','Username') IS NOT NULL
    ALTER TABLE dbo.tb_Users DROP COLUMN Username;
IF COL_LENGTH('dbo.tb_Users','EmployeeCode') IS NOT NULL
    ALTER TABLE dbo.tb_Users DROP COLUMN EmployeeCode;
IF COL_LENGTH('dbo.tb_Users','FullName') IS NOT NULL
    ALTER TABLE dbo.tb_Users DROP COLUMN FullName;
IF COL_LENGTH('dbo.tb_Users','UserID') IS NOT NULL
    ALTER TABLE dbo.tb_Users DROP COLUMN UserID;

-- DepartmentID: change to NVARCHAR(10) and backfill from tb_Staff.Dept
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_tb_Users_DepartmentID' AND object_id=OBJECT_ID('dbo.tb_Users'))
    DROP INDEX IX_tb_Users_DepartmentID ON dbo.tb_Users;
IF COL_LENGTH('dbo.tb_Users','DepartmentID') IS NOT NULL
BEGIN
    ALTER TABLE dbo.tb_Users ALTER COLUMN DepartmentID NVARCHAR(10) NULL;
    IF OBJECT_ID('dbo.tb_Staff','U') IS NOT NULL AND EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.tb_Staff') AND name='Dept')
    BEGIN
        UPDATE u
        SET DepartmentID = s.Dept
        FROM dbo.tb_Users u
        INNER JOIN dbo.tb_Staff s ON s.StaffCode = u.StaffCode;
    END
END

-- Remove tb_Departments entirely (no longer needed)
IF OBJECT_ID('dbo.tb_Departments','U') IS NOT NULL
    DROP TABLE dbo.tb_Departments;

PRINT '✓ Users migrated to StaffCode.';
PRINT '';

/* =============================================
   7) Add per-user/year allocations table
   ============================================= */
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_LeaveYearAllocations]') AND type = N'U')
BEGIN
    CREATE TABLE dbo.tb_LeaveYearAllocations (
        StaffCode NVARCHAR(40) NOT NULL,
        [Year] INT NOT NULL,
        AnnualDays DECIMAL(5,1) NOT NULL,
        SickLeavePaidDays DECIMAL(4,1) NULL,
        CONSTRAINT PK_tb_LeaveYearAllocations PRIMARY KEY CLUSTERED (StaffCode, [Year]),
        CONSTRAINT FK_tb_LeaveYearAllocations_User FOREIGN KEY (StaffCode) REFERENCES dbo.tb_Users(StaffCode)
    );
    PRINT '✓ Created tb_LeaveYearAllocations';
END

/* =============================================
   8) Recreate critical views to use StaffCode
   ============================================= */
-- v_UserProfile
IF OBJECT_ID('dbo.v_UserProfile','V') IS NOT NULL DROP VIEW dbo.v_UserProfile;
GO
CREATE VIEW dbo.v_UserProfile AS
SELECT 
    u.[StaffCode],
    u.[EName],
    u.[CName],
    u.[Email],
    u.[Position],
    u.[Role],
    u.[IsActive],
    u.[CreatedDate],
    u.[LastLogin],
    u.[DepartmentID]
FROM dbo.tb_Users u;
GO

-- v_LeaveRequestDetail
IF OBJECT_ID('dbo.v_LeaveRequestDetail','V') IS NOT NULL DROP VIEW dbo.v_LeaveRequestDetail;
GO
CREATE VIEW dbo.v_LeaveRequestDetail AS
WITH DateAgg AS (
    SELECT 
        rd.[RequestID],
        MIN(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedStartDate],
        MAX(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedEndDate],
        MIN(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedStartDate],
        MAX(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedEndDate]
    FROM dbo.tb_LeaveRequestDates rd
    GROUP BY rd.[RequestID]
)
SELECT 
    lr.[RequestID],
    lr.[RequesterStaffCode] AS [StaffCode],
    u.[EName] AS [EmployeeNameEN],
    u.[CName] AS [EmployeeNameZH],
    u.[Email] AS [EmployeeEmail],
    u.[DepartmentID],
    u.[Position],
    lr.[LeaveTypeID],
    lt.[LeaveTypeName_EN],
    lt.[LeaveTypeName_ZH],
    lt.[ColorCode],
    da.[RequestedStartDate],
    da.[RequestedEndDate],
    lr.[RequestedDaysCount],
    da.[ApprovedStartDate],
    da.[ApprovedEndDate],
    lr.[ApprovedDaysCount],
    lr.[PartialApproval],
    lr.[Reason],
    lr.[Status],
    lr.[ReviewedByStaffCode],
    approver.[EName] AS [ReviewerNameEN],
    lr.[ReviewedDate],
    lr.[ReviewComments],
    lr.[SubmittedDate],
    lr.[LastModifiedDate],
    CASE WHEN lr.[Status] = 'Pending' THEN 1 ELSE 0 END AS [IsEditable]
FROM dbo.tb_LeaveRequests lr
INNER JOIN dbo.tb_Users u ON lr.[RequesterStaffCode] = u.[StaffCode]
INNER JOIN dbo.tb_LeaveTypes lt ON lr.[LeaveTypeID] = lt.[LeaveTypeID]
LEFT JOIN DateAgg da ON da.[RequestID] = lr.[RequestID]
LEFT JOIN dbo.tb_Users approver ON lr.[ReviewedByStaffCode] = approver.[StaffCode];
GO

-- v_TeamCalendar
IF OBJECT_ID('dbo.v_TeamCalendar','V') IS NOT NULL DROP VIEW dbo.v_TeamCalendar;
GO
CREATE VIEW dbo.v_TeamCalendar AS
WITH DateAgg AS (
    SELECT 
        rd.[RequestID],
        MIN(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedStartDate],
        MAX(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedEndDate]
    FROM dbo.tb_LeaveRequestDates rd
    GROUP BY rd.[RequestID]
)
SELECT 
    lr.[RequestID],
    u.[StaffCode],
    u.[EName],
    lt.[LeaveTypeName_EN],
    lt.[LeaveTypeName_ZH],
    lt.[ColorCode],
    da.[ApprovedStartDate],
    da.[ApprovedEndDate],
    lr.[ApprovedDaysCount],
    lr.[Status]
FROM dbo.tb_LeaveRequests lr
INNER JOIN dbo.tb_Users u ON lr.[RequesterStaffCode] = u.[StaffCode]
INNER JOIN dbo.tb_LeaveTypes lt ON lr.[LeaveTypeID] = lt.[LeaveTypeID]
LEFT JOIN DateAgg da ON da.[RequestID] = lr.[RequestID]
WHERE lr.[ApprovedDaysCount] IS NOT NULL AND lr.[ApprovedDaysCount] > 0 AND lr.[Status] IN ('Approved','PartiallyApproved');
GO

-- v_PendingApprovals
IF OBJECT_ID('dbo.v_PendingApprovals','V') IS NOT NULL DROP VIEW dbo.v_PendingApprovals;
GO
CREATE VIEW dbo.v_PendingApprovals AS
WITH DateAgg AS (
    SELECT 
        rd.[RequestID],
        MIN(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedStartDate],
        MAX(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedEndDate]
    FROM dbo.tb_LeaveRequestDates rd
    GROUP BY rd.[RequestID]
)
SELECT 
    lr.[RequestID],
    lr.[RequesterStaffCode] AS [StaffCode],
    u.[EName] AS [EmployeeNameEN],
    u.[CName] AS [EmployeeNameZH],
    u.[DepartmentID],
    u.[Position],
    lt.[LeaveTypeName_EN],
    lt.[LeaveTypeName_ZH],
    lt.[ColorCode],
    da.[RequestedStartDate],
    da.[RequestedEndDate],
    lr.[RequestedDaysCount],
    lr.[Reason],
    lr.[SubmittedDate],
    DATEDIFF(HOUR, lr.[SubmittedDate], GETDATE()) AS [HoursPending],
    lb.[RemainingDays] AS [CurrentBalance]
FROM dbo.tb_LeaveRequests lr
INNER JOIN dbo.tb_Users u ON lr.[RequesterStaffCode] = u.[StaffCode]
INNER JOIN dbo.tb_LeaveTypes lt ON lr.[LeaveTypeID] = lt.[LeaveTypeID]
LEFT JOIN DateAgg da ON da.[RequestID] = lr.[RequestID]
LEFT JOIN dbo.tb_LeaveBalances lb ON lr.[RequesterStaffCode] = lb.[StaffCode] AND lr.[LeaveTypeID] = lb.[LeaveTypeID] AND lb.[Year] = YEAR(GETDATE())
WHERE lr.[Status] = 'Pending';
GO

/* =============================================
   9) Update computed views (by StaffCode)
   ============================================= */
IF OBJECT_ID('dbo.v_AnnualEntitlement','V') IS NOT NULL DROP VIEW dbo.v_AnnualEntitlement;
GO
CREATE VIEW dbo.v_AnnualEntitlement AS
WITH Params AS (
    SELECT 
        COALESCE(ltr.BaseDays, CAST(7.5 AS DECIMAL(5,1))) AS BaseDays,
        COALESCE(ltr.AnnualIncrement, CAST(1.0 AS DECIMAL(4,1))) AS AnnualIncrement,
        COALESCE(ltr.MaxDays, CAST(16.5 AS DECIMAL(5,1))) AS MaxDays,
        COALESCE(ltr.ProRataFirstYear, 1) AS ProRataFirstYear
    FROM dbo.tb_LeaveTypes lt
    LEFT JOIN dbo.tb_LeaveTypeRules ltr ON ltr.LeaveTypeID = lt.LeaveTypeID
    WHERE lt.LeaveTypeName_EN = 'Annual Leave'
), CY AS (
    SELECT YEAR(GETDATE()) AS [Year], CAST(DATEFROMPARTS(YEAR(GETDATE()),1,1) AS DATE) AS Jan1,
           CAST(DATEFROMPARTS(YEAR(GETDATE()),12,31) AS DATE) AS Dec31
)
SELECT 
    u.[StaffCode],
    cy.[Year],
    CAST(
        COALESCE(alloc.AnnualDays,
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
            END
        ) AS DECIMAL(6,2)
    ) AS [AnnualDays],
    COALESCE(yob.[AnnualCarryForward], 0) AS [CarryForward],
    COALESCE((SELECT SUM(g.[Days]) FROM dbo.tb_CompensatoryGrants g WHERE g.[StaffCode] = u.[StaffCode] AND g.[Year] = cy.[Year]), 0) AS [Compensatory],
    CAST(
        (
            CAST(
                COALESCE(alloc.AnnualDays,
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
                    END
                ) AS DECIMAL(6,2)
            )
            + COALESCE(yob.[AnnualCarryForward], 0)
            + COALESCE((SELECT SUM(g.[Days]) FROM dbo.tb_CompensatoryGrants g WHERE g.[StaffCode] = u.[StaffCode] AND g.[Year] = cy.[Year]), 0)
        ) AS DECIMAL(6,2)
    ) AS [AnnualTotal]
FROM dbo.tb_Users u
CROSS JOIN CY cy
CROSS JOIN Params p
LEFT JOIN dbo.tb_YearOpeningBalances yob ON yob.[StaffCode] = u.[StaffCode] AND yob.[Year] = cy.[Year]
LEFT JOIN dbo.tb_LeaveYearAllocations alloc ON alloc.StaffCode = u.StaffCode AND alloc.[Year] = cy.[Year];
GO

IF OBJECT_ID('dbo.v_LeaveTotals','V') IS NOT NULL DROP VIEW dbo.v_LeaveTotals;
GO
CREATE VIEW dbo.v_LeaveTotals AS
WITH CY AS (
    SELECT YEAR(GETDATE()) AS [Year]
), AnnualUsed AS (
    SELECT lr.[RequesterStaffCode] AS StaffCode, COUNT(1) AS AnnualApprovedDays
    FROM dbo.tb_LeaveRequests lr
    INNER JOIN dbo.tb_LeaveTypes lt ON lt.LeaveTypeID = lr.LeaveTypeID AND lt.LeaveTypeName_EN = 'Annual Leave'
    INNER JOIN dbo.tb_LeaveRequestDates rd ON rd.RequestID = lr.RequestID AND rd.DateStatus = 'Approved'
    WHERE YEAR(rd.LeaveDate) = (SELECT [Year] FROM CY)
      AND lr.Status IN ('Approved','PartiallyApproved')
    GROUP BY lr.[RequesterStaffCode]
)
SELECT 
    ent.[StaffCode],
    ent.[Year],
    ent.[AnnualTotal],
    COALESCE(au.[AnnualApprovedDays], 0) AS [AnnualUsed],
    CAST(ent.[AnnualTotal] - COALESCE(au.[AnnualApprovedDays], 0) AS DECIMAL(6,2)) AS [AnnualRemaining]
FROM dbo.v_AnnualEntitlement ent
LEFT JOIN AnnualUsed au ON au.[StaffCode] = ent.[StaffCode];
GO

PRINT 'StaffCode migration completed.';
GO


