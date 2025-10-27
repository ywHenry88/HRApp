-- Version: 1.0.0
-- HR Leave Management System - Seed Data
-- This script populates initial data for testing and production use
-- Run after 01_create_schema.sql

-- =============================================================================
-- PARAMETERS
-- Default admin password: Admin@123 (change after first login)
-- Password hash generated with bcryptjs (10 salt rounds)
-- =============================================================================

USE [HRLeaveSystemDB];
GO

PRINT 'Starting seed data insertion...';
PRINT '';

-- =============================================================================
-- SEED DATA: tb_Departments
-- =============================================================================
PRINT 'Skipping departments seeding (tb_Departments removed).';
PRINT '';

-- =============================================================================
-- SEED DATA: tb_LeaveTypes
-- Default leave types with bilingual names and color codes
-- =============================================================================
PRINT 'Inserting leave types...';

SET IDENTITY_INSERT [dbo].[tb_LeaveTypes] ON;

MERGE INTO [dbo].[tb_LeaveTypes] AS Target
USING (VALUES
    (1, N'Annual Leave', N'年假', 20.0, 1, 1, N'#00AFB9', N'calendar-alt'),
    (2, N'Sick Leave', N'病假', 10.0, 1, 1, N'#FF6B6B', N'procedures'),
    (3, N'Personal Leave', N'個人假', 5.0, 1, 1, N'#FFD166', N'user-clock'),
    (4, N'Study Leave', N'進修假', 2.0, 1, 1, N'#06D6A0', N'book')
) AS Source ([LeaveTypeID], [LeaveTypeName_EN], [LeaveTypeName_ZH], [DefaultDaysPerYear], 
              [RequiresApproval], [IsActive], [ColorCode], [IconName])
ON Target.[LeaveTypeID] = Source.[LeaveTypeID]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([LeaveTypeID], [LeaveTypeName_EN], [LeaveTypeName_ZH], [DefaultDaysPerYear], 
            [RequiresApproval], [IsActive], [ColorCode], [IconName])
    VALUES (Source.[LeaveTypeID], Source.[LeaveTypeName_EN], Source.[LeaveTypeName_ZH], 
            Source.[DefaultDaysPerYear], Source.[RequiresApproval], Source.[IsActive], 
            Source.[ColorCode], Source.[IconName]);

SET IDENTITY_INSERT [dbo].[tb_LeaveTypes] OFF;

PRINT '✓ Leave types inserted successfully.';
PRINT '';

-- =============================================================================
-- SEED DATA: tb_Users
-- NOTE: Password hash for "Admin@123" using bcryptjs with 10 salt rounds
-- Password should be changed on first login
-- =============================================================================
PRINT 'Inserting users (StaffCode model)...';

MERGE INTO [dbo].[tb_Users] AS Target
USING (VALUES
    ('ADMIN001', N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'System Administrator', NULL, N'admin@company.com', 'OFFICE', N'Administrator', N'Admin', 1),
    ('L888',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Lin Jianming', N'林劍明', N'jmlin@company.com', 'OFFICE',  N'Marketing Specialist', N'Employee', 1),
    ('E001',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Xu Renchen', N'徐人琛', N'jcxu@company.com', 'OFFICE',  N'IT Specialist', N'Employee', 1),
    ('E002',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Zeng Guangfa', N'曾廣發', N'gfzeng@company.com', 'SALES',   N'Sales Manager', N'Employee', 1),
    ('E003',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Zhu Zhuoyi', N'朱卓倚', N'zyzhu@company.com', 'FIN',     N'Accountant', N'Employee', 1),
    ('E004',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Deng Dejian', N'鄧德建', N'djdeng@company.com', 'WAREH',   N'Operations Manager', N'Employee', 1),
    ('E005',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Lee Jianhua', N'李健華', N'jhlee@company.com', 'OFFICE', N'Developer', N'Employee', 1),
    ('E006',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Wang Zixuan', N'王子軒', N'zxwang@company.com', 'SALES',   N'Sales Representative', N'Employee', 1),
    ('E007',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Lin Yongcheng', N'林永誠', N'yclin@company.com', 'OFFICE', N'Marketing Coordinator', N'Employee', 1),
    ('E008',     N'$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi', N'Lin Bingwen', N'林炳文', N'bwlin@company.com', 'FIN',     N'Financial Analyst', N'Employee', 1)
) AS Source ([StaffCode], [PasswordHash], [EName], [CName], [Email], [DepartmentID], [Position], [Role], [IsActive])
ON Target.[StaffCode] = Source.[StaffCode]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([StaffCode], [PasswordHash], [EName], [CName], [Email], [DepartmentID], [Position], [Role], [IsActive])
    VALUES (Source.[StaffCode], Source.[PasswordHash], Source.[EName], Source.[CName], Source.[Email], Source.[DepartmentID], Source.[Position], Source.[Role], Source.[IsActive]);

PRINT '✓ Users inserted successfully.';
PRINT '';

-- =============================================================================
-- SEED DATA: tb_LeaveBalances
-- Initialize leave balances for current year for all employees
-- =============================================================================
PRINT 'Initializing leave balances...';

DECLARE @CurrentYear INT = YEAR(GETDATE());

-- Insert leave balances for all active employees
INSERT INTO [dbo].[tb_LeaveBalances] ([StaffCode], [LeaveTypeID], [Year], [TotalDays], [UsedDays])
SELECT 
    u.[StaffCode],
    lt.[LeaveTypeID],
    @CurrentYear,
    lt.[DefaultDaysPerYear],
    CASE 
        -- Simulate some used leave for demo purposes (only for non-admin employees)
        WHEN u.[Role] = 'Employee' AND lt.[LeaveTypeID] = 1 THEN 5.0  -- Annual: 5 days used
        WHEN u.[Role] = 'Employee' AND lt.[LeaveTypeID] = 2 THEN 2.0  -- Sick: 2 days used
        WHEN u.[Role] = 'Employee' AND lt.[LeaveTypeID] = 3 THEN 2.0  -- Personal: 2 days used
        WHEN u.[Role] = 'Employee' AND lt.[LeaveTypeID] = 4 THEN 0.0  -- Study: 0 days used
        ELSE 0.0
    END
FROM [dbo].[tb_Users] u
CROSS JOIN [dbo].[tb_LeaveTypes] lt
WHERE u.[IsActive] = 1
  AND lt.[IsActive] = 1
  AND NOT EXISTS (
      SELECT 1 FROM [dbo].[tb_LeaveBalances] lb
      WHERE lb.[StaffCode] = u.[StaffCode]
        AND lb.[LeaveTypeID] = lt.[LeaveTypeID]
        AND lb.[Year] = @CurrentYear
  );

PRINT '✓ Leave balances initialized successfully.';
PRINT '';

-- =============================================================================
-- SEED DATA: tb_Holidays (2025 Hong Kong Public Holidays)
-- =============================================================================
PRINT 'Inserting public holidays...';

MERGE INTO [dbo].[tb_Holidays] AS Target
USING (VALUES
    (N'2025-01-01', N'New Year''s Day', N'元旦', 2025),
    (N'2025-01-29', N'Lunar New Year', N'農曆新年', 2025),
    (N'2025-01-30', N'Lunar New Year', N'農曆新年', 2025),
    (N'2025-01-31', N'Lunar New Year', N'農曆新年', 2025),
    (N'2025-04-04', N'Ching Ming Festival', N'清明節', 2025),
    (N'2025-04-18', N'Good Friday', N'耶穌受難節', 2025),
    (N'2025-04-19', N'Day after Good Friday', N'耶穌受難節翌日', 2025),
    (N'2025-04-21', N'Easter Monday', N'復活節星期一', 2025),
    (N'2025-05-01', N'Labour Day', N'勞動節', 2025),
    (N'2025-05-05', N'Buddha''s Birthday', N'佛誕', 2025),
    (N'2025-05-31', N'Dragon Boat Festival', N'端午節', 2025),
    (N'2025-07-01', N'Hong Kong SAR Establishment Day', N'香港特別行政區成立紀念日', 2025),
    (N'2025-10-01', N'National Day', N'國慶日', 2025),
    (N'2025-10-07', N'Day after Mid-Autumn Festival', N'中秋節翌日', 2025),
    (N'2025-10-11', N'Chung Yeung Festival', N'重陽節', 2025),
    (N'2025-12-25', N'Christmas Day', N'聖誕節', 2025),
    (N'2025-12-26', N'Boxing Day', N'聖誕節後第一個周日', 2025)
) AS Source ([HolidayDate], [HolidayName_EN], [HolidayName_ZH], [Year])
ON Target.[HolidayDate] = Source.[HolidayDate]
WHEN NOT MATCHED BY TARGET THEN
    INSERT ([HolidayDate], [HolidayName_EN], [HolidayName_ZH], [Year])
    VALUES (Source.[HolidayDate], Source.[HolidayName_EN], Source.[HolidayName_ZH], Source.[Year]);

PRINT '✓ Public holidays inserted successfully.';
PRINT '';

-- =============================================================================
-- SEED DATA: tb_LeaveRequests (Sample data for demonstration)
-- =============================================================================
PRINT 'Inserting sample leave requests (v2.0)...';

IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_LeaveRequests])
BEGIN
    DECLARE @reqId INT;

    -- Pending request: user 2, Annual, 3 requested dates
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate])
    VALUES ('E001', 1, 3, NULL, N'Family vacation', N'Pending', 0, GETDATE());
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-11-10', 'Requested'),
        (@reqId, '2025-11-11', 'Requested'),
        (@reqId, '2025-11-12', 'Requested');

    -- Pending request: user 3, Sick, 1 requested date
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate])
    VALUES ('E001', 2, 1, NULL, N'Medical appointment', N'Pending', 0, GETDATE());
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-10-25', 'Requested');

    -- Pending request: user 4, Annual, 4 requested dates
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate])
    VALUES ('E002', 1, 4, NULL, N'Travel abroad', N'Pending', 0, DATEADD(DAY, -1, GETDATE()));
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-11-15', 'Requested'),
        (@reqId, '2025-11-16', 'Requested'),
        (@reqId, '2025-11-19', 'Requested'),
        (@reqId, '2025-11-20', 'Requested');

    -- Approved request (past): user 2, Annual, 5 approved dates
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate],[ReviewedByStaffCode],[ReviewedDate],[ReviewComments])
    VALUES ('E001', 1, 5, 5, N'Summer break', N'Approved', 0, DATEADD(DAY, -45, GETDATE()), 'ADMIN001', DATEADD(DAY, -44, GETDATE()), N'Approved');
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-09-01', 'Approved'),
        (@reqId, '2025-09-02', 'Approved'),
        (@reqId, '2025-09-03', 'Approved'),
        (@reqId, '2025-09-04', 'Approved'),
        (@reqId, '2025-09-05', 'Approved');

    -- Approved request (past): user 5, Sick, 2 approved dates
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate],[ReviewedByStaffCode],[ReviewedDate],[ReviewComments])
    VALUES ('E003', 2, 2, 2, N'Flu', N'Approved', 0, DATEADD(DAY, -60, GETDATE()), 'ADMIN001', DATEADD(DAY, -59, GETDATE()), N'Approved');
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-08-15', 'Approved'),
        (@reqId, '2025-08-16', 'Approved');

    -- Approved request (past): user 6, Personal, 1 approved date
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate],[ReviewedByStaffCode],[ReviewedDate],[ReviewComments])
    VALUES ('E004', 3, 1, 1, N'Personal matters', N'Approved', 0, DATEADD(DAY, -90, GETDATE()), 'ADMIN001', DATEADD(DAY, -89, GETDATE()), N'Approved');
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-07-10', 'Approved');

    -- Rejected request: user 7, Annual, 3 dates rejected
    INSERT INTO [dbo].[tb_LeaveRequests]
    ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[ApprovedDaysCount],[Reason],[Status],[PartialApproval],[SubmittedDate],[ReviewedByStaffCode],[ReviewedDate],[ReviewComments])
    VALUES ('E005', 1, 3, 0, N'Holiday', N'Rejected', 0, DATEADD(DAY, -15, GETDATE()), 'ADMIN001', DATEADD(DAY, -14, GETDATE()), N'Insufficient staffing during this period. Please select alternative dates.');
    SET @reqId = SCOPE_IDENTITY();
    INSERT INTO [dbo].[tb_LeaveRequestDates] ([RequestID],[LeaveDate],[DateStatus]) VALUES
        (@reqId, '2025-10-01', 'Rejected'),
        (@reqId, '2025-10-03', 'Rejected'),
        (@reqId, '2025-10-05', 'Rejected');

    PRINT '✓ Sample leave requests inserted successfully.';
END
ELSE
BEGIN
    PRINT 'Sample leave requests already exist. Skipping insert.';
END

PRINT '';

-- =============================================================================
-- SEED DATA: tb_AuditLog (Sample audit entries)
-- =============================================================================
PRINT 'Inserting sample audit log entries...';

INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [EntityType], [EntityID], [Details], [Timestamp])
VALUES
    ('ADMIN001', 'Login', NULL, NULL, 'Admin login successful', DATEADD(HOUR, -2, GETDATE())),
    ('E001', 'Login', NULL, NULL, 'User login successful', DATEADD(HOUR, -1, GETDATE())),
    ('E001', 'CreateRequest', 'Request', NULL, 'Leave request created (sample data)', DATEADD(MINUTE, -30, GETDATE()));

PRINT '✓ Sample audit log entries inserted successfully.';
PRINT '';

-- =============================================================================
-- VERIFICATION: Display summary of inserted data
-- =============================================================================
PRINT '';
PRINT '=============================================================================';
PRINT 'SEED DATA INSERTION COMPLETED SUCCESSFULLY';
PRINT '=============================================================================';
PRINT '';

PRINT 'Summary of inserted data:';
PRINT '-------------------------';

SELECT 'Users', COUNT(*) FROM [dbo].[tb_Users]
UNION ALL
SELECT 'Leave Types', COUNT(*) FROM [dbo].[tb_LeaveTypes]
UNION ALL
SELECT 'Leave Balances', COUNT(*) FROM [dbo].[tb_LeaveBalances]
UNION ALL
SELECT 'Leave Requests', COUNT(*) FROM [dbo].[tb_LeaveRequests]
UNION ALL
SELECT 'Holidays', COUNT(*) FROM [dbo].[tb_Holidays]
UNION ALL
SELECT 'Audit Log', COUNT(*) FROM [dbo].[tb_AuditLog];

PRINT '';
PRINT '=============================================================================';
PRINT 'DEFAULT CREDENTIALS:';
PRINT '=============================================================================';
PRINT 'Admin User:';
PRINT '  Username: admin';
PRINT '  Password: Admin@123';
PRINT '';
PRINT 'Employee Users (all have same password):';
PRINT '  Username: jmlin, jcxu, gfzeng, zyzhu, djdeng, jhlee, zxwang, yclin, bwlin';
PRINT '  Password: Employee@123';
PRINT '';
PRINT '⚠️  IMPORTANT: Change these passwords after first login!';
PRINT '=============================================================================';
PRINT '';

GO

