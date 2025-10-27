-- Version: 2.0.0
-- HR Leave Management System - Database Schema Creation
-- SQL Server 2012+
-- Database: HRLeaveSystemDB
-- 
-- ENHANCEMENTS (v2.0):
-- 1. Support for consecutive and non-consecutive leave dates
-- 2. Admin can approve different dates than requested
-- 3. Blackout dates management (dates users cannot apply for leave)
-- =============================================================================
-- PARAMETERS (Update these before running)
-- =============================================================================
-- Database Name: HRLeaveSystemDB
-- Collation: Chinese_Traditional_Stroke_CI_AS
-- =============================================================================

USE [master];
GO

-- Create database if not exists
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'HRLeaveSystemDB')
BEGIN
    DECLARE @targetCollation SYSNAME = N'Chinese_Traditional_Stroke_CI_AS';
    IF EXISTS (SELECT 1 FROM sys.fn_helpcollations() WHERE name = @targetCollation)
    BEGIN
        DECLARE @sqlCreate NVARCHAR(MAX) = N'CREATE DATABASE [HRLeaveSystemDB] COLLATE ' + @targetCollation + N';';
        EXEC(@sqlCreate);
        PRINT 'Database HRLeaveSystemDB created successfully with requested collation.';
    END
    ELSE
    BEGIN
        CREATE DATABASE [HRLeaveSystemDB];
        PRINT 'Database HRLeaveSystemDB created with server default collation (requested collation not available).';
    END
END
ELSE
BEGIN
    PRINT 'Database HRLeaveSystemDB already exists.';
END
GO

USE [HRLeaveSystemDB];
GO

PRINT 'tb_Departments removed - using DepartmentID NVARCHAR(10) codes on tb_Users.';
GO

-- =============================================================================
-- TABLE: tb_Users
-- Description: Stores user authentication and profile information
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_Users]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_Users] (
        [StaffCode]         NVARCHAR(40) NOT NULL,
        [PasswordHash]      NVARCHAR(255) NOT NULL,
        [EName]             NVARCHAR(100) NULL,
        [CName]             NVARCHAR(100) NULL,
        [Email]             NVARCHAR(100) NULL,
        [DepartmentID]      NVARCHAR(10) NULL,  -- Codes: TRANS/OFFICE/WAREH
        [Position]          NVARCHAR(50) NULL,
        [Role]              NVARCHAR(20) NOT NULL DEFAULT 'Employee',
        [IsActive]          BIT NOT NULL DEFAULT 1,
        [CreatedDate]       DATETIME NOT NULL DEFAULT GETDATE(),
        [LastLogin]         DATETIME NULL,
        [LastModifiedDate]  DATETIME NULL,
        [HireDate]          DATE NULL,
        [SickLeavePaidDays] DECIMAL(4,1) NOT NULL DEFAULT 4.5,
        [Mobile]            NVARCHAR(50) NULL,
        [EmployType]        NVARCHAR(50) NULL,
        CONSTRAINT [PK_tb_Users] PRIMARY KEY CLUSTERED ([StaffCode] ASC)
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_Users_IsActive] ON [dbo].[tb_Users]([IsActive]);
    
    PRINT 'Table tb_Users (StaffCode PK) created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_LeaveTypes
-- Description: Stores leave type definitions (Annual, Sick, Personal, etc.)
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_LeaveTypes]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_LeaveTypes] (
        [LeaveTypeID]        INT IDENTITY(1,1) NOT NULL,
        [LeaveTypeName_EN]   NVARCHAR(50) NOT NULL,
        [LeaveTypeName_ZH]   NVARCHAR(50) NOT NULL,
        [DefaultDaysPerYear] DECIMAL(5,1) NOT NULL DEFAULT 0,
        [RequiresApproval]   BIT NOT NULL DEFAULT 1,
        [IsActive]           BIT NOT NULL DEFAULT 1,
        [ColorCode]          NVARCHAR(7) NOT NULL DEFAULT '#00AFB9', -- Hex color for UI
        [IconName]           NVARCHAR(50) NULL, -- Font Awesome icon name
        [CreatedDate]        DATETIME NOT NULL DEFAULT GETDATE(),
        [LastModifiedDate]   DATETIME NULL,
        
        CONSTRAINT [PK_tb_LeaveTypes] PRIMARY KEY CLUSTERED ([LeaveTypeID] ASC)
    );
    
    PRINT 'Table tb_LeaveTypes created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_LeaveBalances
-- Description: Stores leave balances for each user and leave type per year
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_LeaveBalances]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_LeaveBalances] (
        [BalanceID]      INT IDENTITY(1,1) NOT NULL,
        [StaffCode]      NVARCHAR(40) NOT NULL,
        [LeaveTypeID]    INT NOT NULL,
        [Year]           INT NOT NULL,
        [TotalDays]      DECIMAL(5,1) NOT NULL DEFAULT 0,
        [UsedDays]       DECIMAL(5,1) NOT NULL DEFAULT 0,
        [RemainingDays]  AS ([TotalDays] - [UsedDays]) PERSISTED,
        [LastUpdated]    DATETIME NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT [PK_tb_LeaveBalances] PRIMARY KEY CLUSTERED ([BalanceID] ASC),
        CONSTRAINT [UK_tb_LeaveBalances_StaffLeaveYear] UNIQUE NONCLUSTERED 
            ([StaffCode], [LeaveTypeID], [Year]),
        CONSTRAINT [FK_tb_LeaveBalances_Staff] FOREIGN KEY ([StaffCode]) 
            REFERENCES [dbo].[tb_Users]([StaffCode]),
        CONSTRAINT [FK_tb_LeaveBalances_LeaveType] FOREIGN KEY ([LeaveTypeID]) 
            REFERENCES [dbo].[tb_LeaveTypes]([LeaveTypeID])
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveBalances_StaffCode] ON [dbo].[tb_LeaveBalances]([StaffCode]);
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveBalances_Year] ON [dbo].[tb_LeaveBalances]([Year]);
    
    PRINT 'Table tb_LeaveBalances created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_LeaveRequests (ENHANCED v2.0)
-- Description: Master table for leave applications
-- CHANGES: 
-- - Added RequestedDaysCount and ApprovedDaysCount
-- - Added PartialApproval flag to support partial approval
-- - Removed StartDate/EndDate/TotalDays (now stored in tb_LeaveRequestDates)
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_LeaveRequests]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_LeaveRequests] (
        [RequestID]          INT IDENTITY(1,1) NOT NULL,
        [RequesterStaffCode] NVARCHAR(40) NOT NULL,
        [LeaveTypeID]        INT NOT NULL,
        [RequestedDaysCount] INT NOT NULL,              -- NEW: Count of requested working days
        [ApprovedDaysCount]  INT NULL,                  -- NEW: Count of approved working days
        [Reason]             NVARCHAR(500) NULL,
        [Status]             NVARCHAR(20) NOT NULL DEFAULT 'Pending', 
                             -- Status: 'Pending', 'Approved', 'PartiallyApproved', 'Rejected', 'Cancelled'
        [PartialApproval]    BIT NOT NULL DEFAULT 0,    -- NEW: True if admin approved different dates
        [SubmittedDate]      DATETIME NOT NULL DEFAULT GETDATE(),
        [ReviewedDate]       DATETIME NULL,
        [ReviewedByStaffCode] NVARCHAR(40) NULL,
        [ReviewComments]     NVARCHAR(500) NULL,
        [LastModifiedDate]   DATETIME NULL,
        
        CONSTRAINT [PK_tb_LeaveRequests] PRIMARY KEY CLUSTERED ([RequestID] ASC),
        CONSTRAINT [FK_tb_LeaveRequests_Requester] FOREIGN KEY ([RequesterStaffCode]) 
            REFERENCES [dbo].[tb_Users]([StaffCode]),
        CONSTRAINT [FK_tb_LeaveRequests_LeaveType] FOREIGN KEY ([LeaveTypeID]) 
            REFERENCES [dbo].[tb_LeaveTypes]([LeaveTypeID]),
        CONSTRAINT [FK_tb_LeaveRequests_ReviewedByStaff] FOREIGN KEY ([ReviewedByStaffCode]) 
            REFERENCES [dbo].[tb_Users]([StaffCode])
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveRequests_Requester] ON [dbo].[tb_LeaveRequests]([RequesterStaffCode]);
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveRequests_Status] ON [dbo].[tb_LeaveRequests]([Status]);
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveRequests_SubmittedDate] ON [dbo].[tb_LeaveRequests]([SubmittedDate]);
    
    PRINT 'Table tb_LeaveRequests created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_LeaveRequestDates (NEW v2.0)
-- Description: Detail table storing individual dates for each leave request
-- Purpose: Supports consecutive and non-consecutive leave dates
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_LeaveRequestDates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_LeaveRequestDates] (
        [RequestDateID]  INT IDENTITY(1,1) NOT NULL,
        [RequestID]      INT NOT NULL,
        [LeaveDate]      DATE NOT NULL,
        [DateStatus]     NVARCHAR(20) NOT NULL DEFAULT 'Requested',
                         -- Status: 'Requested', 'Approved', 'Rejected', 'Removed'
        [IsWorkingDay]   BIT NOT NULL DEFAULT 1,    -- 1 = Working day, 0 = Weekend/Holiday
        [CreatedDate]    DATETIME NOT NULL DEFAULT GETDATE(),
        [LastModifiedDate] DATETIME NULL,
        
        CONSTRAINT [PK_tb_LeaveRequestDates] PRIMARY KEY CLUSTERED ([RequestDateID] ASC),
        CONSTRAINT [UK_tb_LeaveRequestDates] UNIQUE NONCLUSTERED ([RequestID], [LeaveDate]),
        CONSTRAINT [FK_tb_LeaveRequestDates_Request] FOREIGN KEY ([RequestID]) 
            REFERENCES [dbo].[tb_LeaveRequests]([RequestID]) 
            ON DELETE CASCADE    -- Delete dates when request is deleted
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveRequestDates_RequestID] 
        ON [dbo].[tb_LeaveRequestDates]([RequestID]);
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveRequestDates_LeaveDate] 
        ON [dbo].[tb_LeaveRequestDates]([LeaveDate]);
    CREATE NONCLUSTERED INDEX [IX_tb_LeaveRequestDates_DateStatus] 
        ON [dbo].[tb_LeaveRequestDates]([DateStatus]);
    
    PRINT 'Table tb_LeaveRequestDates created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_Holidays
-- Description: Stores public holidays
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_Holidays]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_Holidays] (
        [HolidayID]        INT IDENTITY(1,1) NOT NULL,
        [HolidayDate]      DATE NOT NULL,
        [HolidayName_EN]   NVARCHAR(100) NOT NULL,
        [HolidayName_ZH]   NVARCHAR(100) NOT NULL,
        [Year]             INT NOT NULL,
        [IsActive]         BIT NOT NULL DEFAULT 1,
        [SourceUID]        NVARCHAR(64) NULL,      -- UID from source (e.g., 1823 iCal JSON)
        [SourceProvider]   NVARCHAR(50) NULL,      -- e.g., '1823.gov.hk'
        [LastSyncedAt]     DATETIME NULL,          -- Last sync time from online source
        [CreatedDate]      DATETIME NOT NULL DEFAULT GETDATE(),
        [LastModifiedDate] DATETIME NULL,
        
        CONSTRAINT [PK_tb_Holidays] PRIMARY KEY CLUSTERED ([HolidayID] ASC),
        CONSTRAINT [UK_tb_Holidays_Date] UNIQUE NONCLUSTERED ([HolidayDate] ASC)
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_Holidays_Year] ON [dbo].[tb_Holidays]([Year]);
    CREATE NONCLUSTERED INDEX [IX_tb_Holidays_Date] ON [dbo].[tb_Holidays]([HolidayDate]);
    CREATE NONCLUSTERED INDEX [IX_tb_Holidays_SourceUID] ON [dbo].[tb_Holidays]([SourceUID]) WHERE [SourceUID] IS NOT NULL;
    
    PRINT 'Table tb_Holidays created successfully.';
END
GO

-- =============================================================================
-- UPGRADE: Add new columns to tb_Holidays for online source metadata (idempotent)
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_Holidays]') AND type in (N'U'))
BEGIN
    IF COL_LENGTH('dbo.tb_Holidays', 'SourceUID') IS NULL
    BEGIN
        ALTER TABLE [dbo].[tb_Holidays] ADD [SourceUID] NVARCHAR(64) NULL;
    END
    IF COL_LENGTH('dbo.tb_Holidays', 'SourceProvider') IS NULL
    BEGIN
        ALTER TABLE [dbo].[tb_Holidays] ADD [SourceProvider] NVARCHAR(50) NULL;
    END
    IF COL_LENGTH('dbo.tb_Holidays', 'LastSyncedAt') IS NULL
    BEGIN
        ALTER TABLE [dbo].[tb_Holidays] ADD [LastSyncedAt] DATETIME NULL;
    END
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_tb_Holidays_SourceUID' AND object_id = OBJECT_ID('[dbo].[tb_Holidays]'))
    BEGIN
        CREATE NONCLUSTERED INDEX [IX_tb_Holidays_SourceUID]
            ON [dbo].[tb_Holidays]([SourceUID])
            WHERE [SourceUID] IS NOT NULL;
    END
END
GO

-- =============================================================================
-- TYPE: HolidayImportType (for TVP upsert from integration jobs)
-- =============================================================================
IF TYPE_ID(N'dbo.HolidayImportType') IS NULL
BEGIN
    CREATE TYPE [dbo].[HolidayImportType] AS TABLE
    (
        [HolidayDate]    DATE NOT NULL,
        [HolidayName_EN] NVARCHAR(100) NOT NULL,
        [HolidayName_ZH] NVARCHAR(100) NOT NULL,
        [Year]           INT NOT NULL,
        [SourceUID]      NVARCHAR(64) NULL,
        [SourceProvider] NVARCHAR(50) NULL
    );
    PRINT 'Type dbo.HolidayImportType created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_BlackoutDates (NEW v2.0)
-- Description: Stores dates that users cannot apply for leave
-- Purpose: Admin can configure blackout periods
-- Default Rule: Day before public holidays
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_BlackoutDates]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_BlackoutDates] (
        [BlackoutID]     INT IDENTITY(1,1) NOT NULL,
        [BlackoutDate]   DATE NOT NULL,
        [Reason_EN]      NVARCHAR(200) NOT NULL,
        [Reason_ZH]      NVARCHAR(200) NOT NULL,
        [IsActive]       BIT NOT NULL DEFAULT 1,
        [CreatedByStaffCode] NVARCHAR(40) NOT NULL,
        [CreatedDate]    DATETIME NOT NULL DEFAULT GETDATE(),
        [LastModifiedByStaffCode] NVARCHAR(40) NULL,
        [LastModifiedDate] DATETIME NULL,
        
        CONSTRAINT [PK_tb_BlackoutDates] PRIMARY KEY CLUSTERED ([BlackoutID] ASC),
        CONSTRAINT [UK_tb_BlackoutDates_Date] UNIQUE NONCLUSTERED ([BlackoutDate]),
        CONSTRAINT [FK_tb_BlackoutDates_CreatedByStaff] FOREIGN KEY ([CreatedByStaffCode]) 
            REFERENCES [dbo].[tb_Users]([StaffCode]),
        CONSTRAINT [FK_tb_BlackoutDates_ModifiedByStaff] FOREIGN KEY ([LastModifiedByStaffCode]) 
            REFERENCES [dbo].[tb_Users]([StaffCode])
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_BlackoutDates_Date] 
        ON [dbo].[tb_BlackoutDates]([BlackoutDate]);
    CREATE NONCLUSTERED INDEX [IX_tb_BlackoutDates_IsActive] 
        ON [dbo].[tb_BlackoutDates]([IsActive]);
    
    PRINT 'Table tb_BlackoutDates created successfully.';
END
GO

-- =============================================================================
-- TABLE: tb_AuditLog
-- Description: Audit trail for all sensitive operations
-- =============================================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_AuditLog]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[tb_AuditLog] (
        [LogID]         BIGINT IDENTITY(1,1) NOT NULL,
        [StaffCode]     NVARCHAR(40) NULL,
        [Action]        NVARCHAR(50) NOT NULL,
        [EntityType]    NVARCHAR(50) NULL,
        [EntityID]      INT NULL,
        [Details]       NVARCHAR(MAX) NULL,
        [IPAddress]     NVARCHAR(45) NULL,
        [Timestamp]     DATETIME NOT NULL DEFAULT GETDATE(),
        
        CONSTRAINT [PK_tb_AuditLog] PRIMARY KEY CLUSTERED ([LogID] ASC)
    );
    
    -- Create indexes
    CREATE NONCLUSTERED INDEX [IX_tb_AuditLog_StaffCode] ON [dbo].[tb_AuditLog]([StaffCode]);
    CREATE NONCLUSTERED INDEX [IX_tb_AuditLog_Timestamp] ON [dbo].[tb_AuditLog]([Timestamp]);
    CREATE NONCLUSTERED INDEX [IX_tb_AuditLog_Action] ON [dbo].[tb_AuditLog]([Action]);
    
    PRINT 'Table tb_AuditLog created successfully.';
END
GO

-- =============================================================================
-- Add foreign key constraint for Department Manager after Users table exists
-- =============================================================================
-- Departments table removed; no manager FK required.
GO

-- =============================================================================
-- COMPLETION MESSAGE
-- =============================================================================
PRINT '';
PRINT '=============================================================================';
PRINT 'Database schema creation completed successfully!';
PRINT 'Database: HRLeaveSystemDB';
PRINT 'Version: 2.0.0';
PRINT '=============================================================================';
PRINT 'Total Tables: 9';
PRINT '- tb_Departments';
PRINT '- tb_Users';
PRINT '- tb_LeaveTypes';
PRINT '- tb_LeaveBalances';
PRINT '- tb_LeaveRequests (ENHANCED)';
PRINT '- tb_LeaveRequestDates (NEW)';
PRINT '- tb_Holidays';
PRINT '- tb_BlackoutDates (NEW)';
PRINT '- tb_AuditLog';
PRINT '=============================================================================';
PRINT 'NEW FEATURES in v2.0:';
PRINT '1. tb_LeaveRequestDates - Support for non-consecutive leave dates';
PRINT '2. tb_BlackoutDates - Configurable dates users cannot apply for leave';
PRINT '3. Enhanced tb_LeaveRequests - Tracks requested vs approved days';
PRINT '4. Partial approval support - Admin can approve different dates';
PRINT '=============================================================================';
PRINT '';
PRINT 'Next Steps:';
PRINT '1. Run 02_seed_data.sql to populate initial data';
PRINT '2. Run 03_create_views.sql to create reporting views';
PRINT '3. Run 04_create_stored_procedures.sql to create stored procedures';
PRINT '=============================================================================';
GO

