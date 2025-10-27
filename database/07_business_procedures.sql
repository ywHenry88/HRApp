-- Version: 1.1.0
-- Core stored procedure stubs for business logic

USE [HRLeaveSystemDB];
GO

PRINT 'Creating business procedure stubs...';
PRINT '';

-- usp_RecalcYearOpeningBalances ---------------------------------------------
IF OBJECT_ID('dbo.usp_RecalcYearOpeningBalances', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_RecalcYearOpeningBalances;
GO

CREATE PROCEDURE dbo.usp_RecalcYearOpeningBalances
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @PrevYear INT = @Year - 1;

    ;WITH Params AS (
        SELECT 
            COALESCE(ltr.BaseDays, CAST(7.5 AS DECIMAL(5,1))) AS BaseDays,
            COALESCE(ltr.AnnualIncrement, CAST(1.0 AS DECIMAL(4,1))) AS AnnualIncrement,
            COALESCE(ltr.MaxDays, CAST(16.5 AS DECIMAL(5,1))) AS MaxDays,
            COALESCE(ltr.ProRataFirstYear, 1) AS ProRataFirstYear
        FROM dbo.tb_LeaveTypes lt
        LEFT JOIN dbo.tb_LeaveTypeRules ltr ON ltr.LeaveTypeID = lt.LeaveTypeID
        WHERE lt.LeaveTypeName_EN = 'Annual Leave'
    ), Dates AS (
        SELECT CAST(DATEFROMPARTS(@PrevYear,1,1) AS DATE) AS Jan1Prev,
               CAST(DATEFROMPARTS(@PrevYear,12,31) AS DATE) AS Dec31Prev
    ), PrevComp AS (
        SELECT g.[StaffCode], SUM(g.[Days]) AS CompDays
        FROM dbo.tb_CompensatoryGrants g
        WHERE g.[Year] = @PrevYear
        GROUP BY g.[StaffCode]
    ), PrevUsed AS (
        SELECT lr.[RequesterStaffCode] AS StaffCode, COUNT(1) AS UsedDays
        FROM dbo.tb_LeaveRequests lr
        INNER JOIN dbo.tb_LeaveTypes lt ON lt.LeaveTypeID = lr.LeaveTypeID AND lt.LeaveTypeName_EN = 'Annual Leave'
        INNER JOIN dbo.tb_LeaveRequestDates rd ON rd.RequestID = lr.RequestID AND rd.DateStatus = 'Approved'
        WHERE YEAR(rd.LeaveDate) = @PrevYear
          AND lr.Status IN ('Approved','PartiallyApproved')
        GROUP BY lr.[RequesterStaffCode]
    ), PrevCarry AS (
        SELECT y.[StaffCode], COALESCE(y.[AnnualCarryForward], 0) AS Carry
        FROM dbo.tb_YearOpeningBalances y
        WHERE y.[Year] = @PrevYear
    )
    MERGE dbo.tb_YearOpeningBalances AS tgt
    USING (
        SELECT 
            u.[StaffCode],
            @Year AS [Year],
            -- Compute previous year's entitlement per user (calendar-year basis)
            CAST(
                CASE 
                    WHEN u.HireDate IS NULL THEN p.BaseDays
                    WHEN YEAR(u.HireDate) = @PrevYear AND p.ProRataFirstYear = 1 THEN
                        p.BaseDays * (
                            CAST(DATEDIFF(DAY, CASE WHEN u.HireDate > d.Jan1Prev THEN u.HireDate ELSE d.Jan1Prev END, d.Dec31Prev) + 1 AS DECIMAL(9,4)) / 365.0
                        )
                    WHEN YEAR(u.HireDate) < @PrevYear THEN
                        CASE 
                            WHEN (p.BaseDays + (@PrevYear - (YEAR(u.HireDate) + 1)) * p.AnnualIncrement) > p.MaxDays THEN p.MaxDays
                            ELSE p.BaseDays + (@PrevYear - (YEAR(u.HireDate) + 1)) * p.AnnualIncrement
                        END
                    ELSE p.BaseDays
                END AS DECIMAL(6,2)
            ) AS PrevEntitlement,
            COALESCE(pc.CompDays, 0) AS PrevComp,
            COALESCE(pu.UsedDays, 0) AS PrevUsed,
            COALESCE(py.Carry, 0) AS PrevCarry
        FROM dbo.tb_Users u
        CROSS JOIN Params p
        CROSS JOIN Dates d
        LEFT JOIN PrevComp pc ON pc.[StaffCode] = u.[StaffCode]
        LEFT JOIN PrevUsed pu ON pu.[StaffCode] = u.[StaffCode]
        LEFT JOIN PrevCarry py ON py.[StaffCode] = u.[StaffCode]
    ) AS src
    ON (tgt.[StaffCode] = src.[StaffCode] AND tgt.[Year] = src.[Year])
    WHEN MATCHED THEN
        UPDATE SET tgt.[AnnualCarryForward] = CASE WHEN (src.PrevCarry + src.PrevEntitlement + src.PrevComp - src.PrevUsed) < 0 THEN 0 ELSE (src.PrevCarry + src.PrevEntitlement + src.PrevComp - src.PrevUsed) END
    WHEN NOT MATCHED THEN
        INSERT ([StaffCode],[Year],[AnnualCarryForward])
        VALUES (src.[StaffCode], src.[Year], CASE WHEN (src.PrevCarry + src.PrevEntitlement + src.PrevComp - src.PrevUsed) < 0 THEN 0 ELSE (src.PrevCarry + src.PrevEntitlement + src.PrevComp - src.PrevUsed) END);
END
GO

-- usp_GrantCompensatoryLeave -------------------------------------------------
IF OBJECT_ID('dbo.usp_GrantCompensatoryLeave', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_GrantCompensatoryLeave;
GO

CREATE PROCEDURE dbo.usp_GrantCompensatoryLeave
    @StaffCode NVARCHAR(40),
    @Year INT,
    @Days DECIMAL(5,2),
    @Reason NVARCHAR(200) = NULL,
    @AdminStaffCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.tb_CompensatoryGrants ([StaffCode],[Year],[Days],[Reason],[CreatedByStaffCode])
    VALUES (@StaffCode, @Year, @Days, @Reason, @AdminStaffCode);

    -- Audit example (optional):
    INSERT INTO dbo.tb_AuditLog ([StaffCode],[Action],[EntityType],[EntityID],[Details])
    VALUES (@AdminStaffCode, N'GrantCompensatory', N'User', NULL, CONCAT(N'StaffCode=', @StaffCode, N', Year=', @Year, N', Days=', @Days, N', Reason=', @Reason));
END
GO

-- usp_SubmitLeaveRequest (stub) ---------------------------------------------
IF OBJECT_ID('dbo.usp_SubmitLeaveRequest', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_SubmitLeaveRequest;
GO

CREATE PROCEDURE dbo.usp_SubmitLeaveRequest
    @RequesterStaffCode NVARCHAR(40),
    @LeaveTypeID INT,
    @Reason NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    -- Insert into master request with Pending status; dates to be added separately via detail table or TVP version
    INSERT INTO dbo.tb_LeaveRequests ([RequesterStaffCode],[LeaveTypeID],[RequestedDaysCount],[Reason],[Status])
    VALUES (@RequesterStaffCode, @LeaveTypeID, 0, @Reason, N'Pending');

    SELECT SCOPE_IDENTITY() AS NewRequestID;
END
GO

-- usp_ApproveLeaveRequest (stub) --------------------------------------------
IF OBJECT_ID('dbo.usp_ApproveLeaveRequest', 'P') IS NOT NULL
    DROP PROCEDURE dbo.usp_ApproveLeaveRequest;
GO

CREATE PROCEDURE dbo.usp_ApproveLeaveRequest
    @RequestID INT,
    @ReviewerStaffCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    -- Placeholder: set ApprovedDaysCount from existing Approved dates in tb_LeaveRequestDates
    UPDATE lr
    SET 
        lr.[ApprovedDaysCount] = x.ApprovedDays,
        lr.[Status] = CASE WHEN x.ApprovedDays > 0 THEN N'Approved' ELSE N'Rejected' END,
        lr.[ReviewedByStaffCode] = @ReviewerStaffCode,
        lr.[ReviewedDate] = GETDATE()
    FROM dbo.tb_LeaveRequests lr
    CROSS APPLY (
        SELECT COUNT(1) AS ApprovedDays
        FROM dbo.tb_LeaveRequestDates rd
        WHERE rd.RequestID = lr.RequestID AND rd.DateStatus = 'Approved'
    ) x
    WHERE lr.RequestID = @RequestID;

    -- Audit example (optional)
    INSERT INTO dbo.tb_AuditLog ([StaffCode],[Action],[EntityType],[EntityID],[Details])
    VALUES (@ReviewerStaffCode, N'ApproveRequest', N'Request', @RequestID, N'Auto status set from Approved dates');
END
GO

PRINT 'Business procedure stubs created.';
GO


