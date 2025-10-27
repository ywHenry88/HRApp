-- Version: 1.0.0
-- HR Leave Management System - Database Views
-- Create useful views for reporting and data access

USE [HRLeaveSystemDB];
GO

PRINT 'Creating database views...';
PRINT '';

-- =============================================================================
-- VIEW: v_UserProfile
-- Description: Complete user profile with department information
-- =============================================================================
IF OBJECT_ID('dbo.v_UserProfile', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_UserProfile];
GO

CREATE VIEW [dbo].[v_UserProfile]
AS
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
FROM [dbo].[tb_Users] u;
GO

PRINT '✓ View v_UserProfile created successfully.';

-- =============================================================================
-- VIEW: v_LeaveBalance
-- Description: Current year leave balances with leave type details
-- =============================================================================
IF OBJECT_ID('dbo.v_LeaveBalance', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_LeaveBalance];
GO

CREATE VIEW [dbo].[v_LeaveBalance]
AS
SELECT 
    lb.[BalanceID],
    lb.[StaffCode],
    u.[EName],
    u.[CName],
    lb.[LeaveTypeID],
    lt.[LeaveTypeName_EN],
    lt.[LeaveTypeName_ZH],
    lt.[ColorCode],
    lt.[IconName],
    lb.[Year],
    lb.[TotalDays],
    lb.[UsedDays],
    lb.[RemainingDays],
    lb.[LastUpdated]
FROM [dbo].[tb_LeaveBalances] lb
INNER JOIN [dbo].[tb_Users] u ON lb.[StaffCode] = u.[StaffCode]
INNER JOIN [dbo].[tb_LeaveTypes] lt ON lb.[LeaveTypeID] = lt.[LeaveTypeID]
WHERE u.[IsActive] = 1 AND lt.[IsActive] = 1;
GO

PRINT '✓ View v_LeaveBalance created successfully.';

-- =============================================================================
-- VIEW: v_LeaveRequestDetail
-- Description: Leave requests with user and approver details
-- =============================================================================
IF OBJECT_ID('dbo.v_LeaveRequestDetail', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_LeaveRequestDetail];
GO

CREATE VIEW [dbo].[v_LeaveRequestDetail]
AS
WITH DateAgg AS (
    SELECT 
        rd.[RequestID],
        MIN(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedStartDate],
        MAX(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedEndDate],
        MIN(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedStartDate],
        MAX(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedEndDate]
    FROM [dbo].[tb_LeaveRequestDates] rd
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
    -- Calculate if request is editable (Pending status only)
    CASE WHEN lr.[Status] = 'Pending' THEN 1 ELSE 0 END AS [IsEditable]
FROM [dbo].[tb_LeaveRequests] lr
INNER JOIN [dbo].[tb_Users] u ON lr.[RequesterStaffCode] = u.[StaffCode]
INNER JOIN [dbo].[tb_LeaveTypes] lt ON lr.[LeaveTypeID] = lt.[LeaveTypeID]
LEFT JOIN DateAgg da ON da.[RequestID] = lr.[RequestID]
LEFT JOIN [dbo].[tb_Users] approver ON lr.[ReviewedByStaffCode] = approver.[StaffCode];
GO

PRINT '✓ View v_LeaveRequestDetail created successfully.';

-- =============================================================================
-- VIEW: v_TeamCalendar
-- Description: Calendar view of all approved leave requests
-- =============================================================================
IF OBJECT_ID('dbo.v_TeamCalendar', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_TeamCalendar];
GO

CREATE VIEW [dbo].[v_TeamCalendar]
AS
WITH DateAgg AS (
    SELECT 
        rd.[RequestID],
        MIN(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedStartDate],
        MAX(CASE WHEN rd.[DateStatus] = 'Approved' THEN rd.[LeaveDate] END) AS [ApprovedEndDate]
    FROM [dbo].[tb_LeaveRequestDates] rd
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
FROM [dbo].[tb_LeaveRequests] lr
INNER JOIN [dbo].[tb_Users] u ON lr.[RequesterStaffCode] = u.[StaffCode]
INNER JOIN [dbo].[tb_LeaveTypes] lt ON lr.[LeaveTypeID] = lt.[LeaveTypeID]
LEFT JOIN DateAgg da ON da.[RequestID] = lr.[RequestID]
WHERE u.[IsActive] = 1
  AND lr.[ApprovedDaysCount] IS NOT NULL
  AND lr.[ApprovedDaysCount] > 0
  AND lr.[Status] IN ('Approved','PartiallyApproved');
GO

PRINT '✓ View v_TeamCalendar created successfully.';

-- =============================================================================
-- VIEW: v_PendingApprovals
-- Description: All pending leave requests for admin approval
-- =============================================================================
IF OBJECT_ID('dbo.v_PendingApprovals', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_PendingApprovals];
GO

CREATE VIEW [dbo].[v_PendingApprovals]
AS
WITH DateAgg AS (
    SELECT 
        rd.[RequestID],
        MIN(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedStartDate],
        MAX(CASE WHEN rd.[DateStatus] IN ('Requested','Approved') THEN rd.[LeaveDate] END) AS [RequestedEndDate]
    FROM [dbo].[tb_LeaveRequestDates] rd
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
    -- Get current leave balance
    lb.[RemainingDays] AS [CurrentBalance]
FROM [dbo].[tb_LeaveRequests] lr
INNER JOIN [dbo].[tb_Users] u ON lr.[RequesterStaffCode] = u.[StaffCode]
INNER JOIN [dbo].[tb_LeaveTypes] lt ON lr.[LeaveTypeID] = lt.[LeaveTypeID]
LEFT JOIN DateAgg da ON da.[RequestID] = lr.[RequestID]
LEFT JOIN [dbo].[tb_LeaveBalances] lb ON lr.[RequesterStaffCode] = lb.[StaffCode] 
    AND lr.[LeaveTypeID] = lb.[LeaveTypeID]
    AND lb.[Year] = YEAR(GETDATE())
WHERE lr.[Status] = 'Pending'
  AND u.[IsActive] = 1;
GO

PRINT '✓ View v_PendingApprovals created successfully.';

-- =============================================================================
-- VIEW: v_DashboardStats
-- Description: Summary statistics for admin dashboard
-- =============================================================================
IF OBJECT_ID('dbo.v_DashboardStats', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_DashboardStats];
GO

CREATE VIEW [dbo].[v_DashboardStats]
AS
SELECT 
    (SELECT COUNT(*) FROM [dbo].[tb_Users] WHERE [IsActive] = 1 AND [Role] = 'Employee') AS [TotalEmployees],
    (SELECT COUNT(*) FROM [dbo].[tb_LeaveRequests] WHERE [Status] = 'Pending') AS [PendingApprovals],
    (SELECT COUNT(DISTINCT lr.[RequesterStaffCode])
     FROM [dbo].[tb_LeaveRequests] lr
     INNER JOIN [dbo].[tb_LeaveRequestDates] rd ON rd.[RequestID] = lr.[RequestID]
     WHERE lr.[Status] IN ('Approved','PartiallyApproved')
       AND rd.[DateStatus] = 'Approved'
       AND rd.[LeaveDate] = CAST(GETDATE() AS DATE)) AS [OnLeaveToday],
    (SELECT COUNT(*) FROM [dbo].[tb_LeaveRequests] 
     WHERE [Status] = 'Pending' 
       AND DATEDIFF(DAY, [SubmittedDate], GETDATE()) > 2) AS [OverdueApprovals];
GO

PRINT '✓ View v_DashboardStats created successfully.';

-- =============================================================================
-- VIEW: v_LeaveUtilization
-- Description: Leave utilization report by employee
-- =============================================================================
IF OBJECT_ID('dbo.v_LeaveUtilization', 'V') IS NOT NULL
    DROP VIEW [dbo].[v_LeaveUtilization];
GO

CREATE VIEW [dbo].[v_LeaveUtilization]
AS
SELECT 
    u.[StaffCode],
    u.[EName],
    u.[CName],
    u.[DepartmentID],
    lt.[LeaveTypeName_EN],
    lt.[LeaveTypeName_ZH],
    lb.[Year],
    lb.[TotalDays],
    lb.[UsedDays],
    lb.[RemainingDays],
    CASE 
        WHEN lb.[TotalDays] > 0 THEN CAST(ROUND((lb.[UsedDays] / lb.[TotalDays]) * 100, 1) AS DECIMAL(5,1))
        ELSE 0
    END AS [UtilizationPercentage]
FROM [dbo].[tb_LeaveBalances] lb
INNER JOIN [dbo].[tb_Users] u ON lb.[StaffCode] = u.[StaffCode]
INNER JOIN [dbo].[tb_LeaveTypes] lt ON lb.[LeaveTypeID] = lt.[LeaveTypeID]
WHERE u.[IsActive] = 1 AND lt.[IsActive] = 1;
GO

PRINT '✓ View v_LeaveUtilization created successfully.';

-- =============================================================================
-- COMPLETION MESSAGE
-- =============================================================================
PRINT '';
PRINT '=============================================================================';
PRINT 'All views created successfully!';
PRINT '=============================================================================';
PRINT '';
PRINT 'Available Views:';
PRINT '  • v_UserProfile - Complete user profiles';
PRINT '  • v_LeaveBalance - Current leave balances';
PRINT '  • v_LeaveRequestDetail - Detailed leave request information';
PRINT '  • v_TeamCalendar - Team calendar with approved leave';
PRINT '  • v_PendingApprovals - Pending requests for approval';
PRINT '  • v_DashboardStats - Dashboard statistics';
PRINT '  • v_LeaveUtilization - Leave utilization reporting';
PRINT '=============================================================================';
PRINT '';

GO

