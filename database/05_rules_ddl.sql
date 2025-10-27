-- Version: 1.0.0
-- Rules-support DDL (idempotent) for AnnualTotal, Sick paid, Compensatory grants

USE [HRLeaveSystemDB];
GO

PRINT 'Applying rules-support DDL...';
PRINT '';

-- tb_Users additions ---------------------------------------------------------
IF COL_LENGTH('dbo.tb_Users', 'HireDate') IS NULL
BEGIN
    ALTER TABLE dbo.tb_Users ADD [HireDate] DATE NULL;
    PRINT '✓ Added tb_Users.HireDate';
END
GO

IF COL_LENGTH('dbo.tb_Users', 'SickLeavePaidDays') IS NULL
BEGIN
    ALTER TABLE dbo.tb_Users ADD [SickLeavePaidDays] DECIMAL(4,1) NOT NULL CONSTRAINT DF_tb_Users_SickLeavePaidDays DEFAULT(4.5);
    PRINT '✓ Added tb_Users.SickLeavePaidDays (default 4.5)';
END
GO

-- tb_CompensatoryGrants ------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_CompensatoryGrants]') AND type = N'U')
BEGIN
    CREATE TABLE [dbo].[tb_CompensatoryGrants] (
        [GrantID]       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        [StaffCode]     NVARCHAR(40) NOT NULL,
        [Year]          INT NOT NULL,
        [Days]          DECIMAL(5,2) NOT NULL,
        [Reason]        NVARCHAR(200) NULL,
        [CreatedByStaffCode] NVARCHAR(40) NOT NULL,
        [CreatedDate]   DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [FK_tb_CompGrants_Staff] FOREIGN KEY ([StaffCode]) REFERENCES [dbo].[tb_Users]([StaffCode]),
        CONSTRAINT [FK_tb_CompGrants_CreatedByStaff] FOREIGN KEY ([CreatedByStaffCode]) REFERENCES [dbo].[tb_Users]([StaffCode])
    );
    CREATE NONCLUSTERED INDEX IX_tb_CompensatoryGrants_UserYear ON dbo.tb_CompensatoryGrants([StaffCode],[Year]);
    PRINT '✓ Created tb_CompensatoryGrants';
END
GO

-- tb_YearOpeningBalances -----------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_YearOpeningBalances]') AND type = N'U')
BEGIN
    CREATE TABLE [dbo].[tb_YearOpeningBalances] (
        [StaffCode]         NVARCHAR(40) NOT NULL,
        [Year]              INT NOT NULL,
        [AnnualCarryForward] DECIMAL(5,1) NOT NULL DEFAULT 0,
        [SnapshotDate]      DATETIME NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_tb_YearOpeningBalances] PRIMARY KEY CLUSTERED ([StaffCode],[Year]),
        CONSTRAINT [FK_tb_YOB_Staff] FOREIGN KEY ([StaffCode]) REFERENCES [dbo].[tb_Users]([StaffCode])
    );
    PRINT '✓ Created tb_YearOpeningBalances';
END
GO

-- tb_LeaveTypeRules (optional parameterization) -----------------------------
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[tb_LeaveTypeRules]') AND type = N'U')
BEGIN
    CREATE TABLE [dbo].[tb_LeaveTypeRules] (
        [LeaveTypeID]      INT NOT NULL PRIMARY KEY,
        [BaseDays]         DECIMAL(5,1) NOT NULL,
        [AnnualIncrement]  DECIMAL(4,1) NOT NULL DEFAULT 0,
        [MaxDays]          DECIMAL(5,1) NOT NULL,
        [ProRataFirstYear] BIT NOT NULL DEFAULT 1,
        [AllowDecimals]    BIT NOT NULL DEFAULT 0,
        CONSTRAINT [FK_tb_LTR_LeaveType] FOREIGN KEY ([LeaveTypeID]) REFERENCES [dbo].[tb_LeaveTypes]([LeaveTypeID])
    );
    PRINT '✓ Created tb_LeaveTypeRules';
END
GO

PRINT 'Rules-support DDL completed.';
GO


