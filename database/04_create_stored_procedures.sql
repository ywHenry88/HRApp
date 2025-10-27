-- Version: 2.0.0
-- HR Leave Management System - Enhanced Stored Procedures
-- SQL Server 2012+
-- 
-- ENHANCEMENTS (v2.0):
-- 1. Support multiple date selection (consecutive/non-consecutive)
-- 2. Blackout date validation
-- 3. Partial approval support
-- =============================================================================

USE [HRLeaveSystemDB];
GO

-- =============================================================================
-- FUNCTION: fn_IsBlackoutDate
-- Description: Checks if a date is a blackout date
-- Parameters:
--   @CheckDate - Date to check
-- Returns: 1 if blackout date, 0 otherwise
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_IsBlackoutDate]') AND type in (N'FN', N'IF', N'TF'))
    DROP FUNCTION [dbo].[fn_IsBlackoutDate];
GO

CREATE FUNCTION [dbo].[fn_IsBlackoutDate]
(
    @CheckDate DATE
)
RETURNS BIT
AS
BEGIN
    DECLARE @IsBlackout BIT = 0;
    
    IF EXISTS (
        SELECT 1 
        FROM [dbo].[tb_BlackoutDates]
        WHERE [BlackoutDate] = @CheckDate
        AND [IsActive] = 1
    )
    BEGIN
        SET @IsBlackout = 1;
    END
    
    RETURN @IsBlackout;
END
GO

PRINT 'Function fn_IsBlackoutDate created successfully.';
GO

-- =============================================================================
-- FUNCTION: fn_CalculateWorkingDays
-- Description: Calculates working days between two dates (excludes weekends and holidays)
-- Parameters:
--   @StartDate - Start date
--   @EndDate - End date
-- Returns: Number of working days
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_CalculateWorkingDays]') AND type in (N'FN', N'IF', N'TF'))
    DROP FUNCTION [dbo].[fn_CalculateWorkingDays];
GO

CREATE FUNCTION [dbo].[fn_CalculateWorkingDays]
(
    @StartDate DATE,
    @EndDate DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @WorkingDays INT = 0;
    DECLARE @CurrentDate DATE = @StartDate;
    
    WHILE @CurrentDate <= @EndDate
    BEGIN
        -- Check if it's a weekday (Monday-Friday)
        IF DATEPART(WEEKDAY, @CurrentDate) NOT IN (1, 7) -- Not Sunday or Saturday
        BEGIN
            -- Check if it's not a holiday
            IF NOT EXISTS (
                SELECT 1 
                FROM [dbo].[tb_Holidays]
                WHERE [HolidayDate] = @CurrentDate
                AND [IsActive] = 1
            )
            BEGIN
                SET @WorkingDays = @WorkingDays + 1;
            END
        END
        
        SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
    END
    
    RETURN @WorkingDays;
END
GO

PRINT 'Function fn_CalculateWorkingDays created successfully.';
GO

-- =============================================================================
-- STORED PROCEDURE: sp_SubmitLeaveRequest
-- Description: Submit a new leave request with multiple dates
-- Parameters:
--   @RequesterStaffCode - User requesting leave (StaffCode)
--   @LeaveTypeID - Type of leave
--   @LeaveDates - Comma-separated list of dates (YYYY-MM-DD format)
--   @Reason - Reason for leave (optional)
--   @RequestID - OUTPUT: Generated request ID
-- Returns: 0 = Success, negative = Error code
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_SubmitLeaveRequest]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_SubmitLeaveRequest];
GO

CREATE PROCEDURE [dbo].[sp_SubmitLeaveRequest]
    @RequesterStaffCode NVARCHAR(40),
    @LeaveTypeID INT,
    @LeaveDates NVARCHAR(MAX),  -- Comma-separated: '2025-11-15,2025-11-16,2025-11-19'
    @Reason NVARCHAR(500) = NULL,
    @RequestID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validate user
        IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_Users] WHERE [StaffCode] = @RequesterStaffCode AND [IsActive] = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -1; -- User not found or inactive
        END
        
        -- Validate leave type
        IF NOT EXISTS (SELECT 1 FROM [dbo].[tb_LeaveTypes] WHERE [LeaveTypeID] = @LeaveTypeID AND [IsActive] = 1)
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -2; -- Leave type not found or inactive
        END
        
        -- Parse and validate dates
        DECLARE @DateTable TABLE (
            LeaveDate DATE,
            IsWorkingDay BIT,
            IsBlackout BIT,
            RowNum INT
        );
        
        DECLARE @CurrentDate DATE;
        DECLARE @DateString NVARCHAR(20);
        DECLARE @Pos INT;
        DECLARE @WorkingDaysCount INT = 0;
        
        -- Split comma-separated dates
        DECLARE @Dates NVARCHAR(MAX) = @LeaveDates + ',';
        
        WHILE CHARINDEX(',', @Dates) > 0
        BEGIN
            SET @Pos = CHARINDEX(',', @Dates);
            SET @DateString = LTRIM(RTRIM(SUBSTRING(@Dates, 1, @Pos - 1)));
            
            IF LEN(@DateString) > 0
            BEGIN
                SET @CurrentDate = TRY_CONVERT(DATE, @DateString);
                
                IF @CurrentDate IS NULL
                BEGIN
                    ROLLBACK TRANSACTION;
                    RETURN -3; -- Invalid date format
                END
                
                -- Check if date is in the past
                IF @CurrentDate < CAST(GETDATE() AS DATE)
                BEGIN
                    ROLLBACK TRANSACTION;
                    RETURN -4; -- Cannot apply for past dates
                END
                
                -- Check if it's a working day
                DECLARE @IsWorkingDay BIT = 1;
                DECLARE @IsBlackout BIT = 0;
                
                -- Check weekend
                IF DATEPART(WEEKDAY, @CurrentDate) IN (1, 7) -- Sunday or Saturday
                    SET @IsWorkingDay = 0;
                
                -- Check holiday
                IF EXISTS (SELECT 1 FROM [dbo].[tb_Holidays] WHERE [HolidayDate] = @CurrentDate AND [IsActive] = 1)
                    SET @IsWorkingDay = 0;
                
                -- Check blackout date
                SET @IsBlackout = [dbo].[fn_IsBlackoutDate](@CurrentDate);
                
                IF @IsBlackout = 1
                BEGIN
                    ROLLBACK TRANSACTION;
                    RETURN -5; -- Date is a blackout date
                END
                
                -- Count working days
                IF @IsWorkingDay = 1
                    SET @WorkingDaysCount = @WorkingDaysCount + 1;
                
                -- Insert into temp table
                INSERT INTO @DateTable (LeaveDate, IsWorkingDay, IsBlackout, RowNum)
                VALUES (@CurrentDate, @IsWorkingDay, @IsBlackout, @@ROWCOUNT);
            END
            
            SET @Dates = SUBSTRING(@Dates, @Pos + 1, LEN(@Dates));
        END
        
        -- Validate at least one date provided
        IF NOT EXISTS (SELECT 1 FROM @DateTable)
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -6; -- No valid dates provided
        END
        
        -- Check sufficient leave balance
        DECLARE @Year INT = YEAR(GETDATE());
        DECLARE @RemainingDays DECIMAL(5,1);
        
        SELECT @RemainingDays = [RemainingDays]
        FROM [dbo].[tb_LeaveBalances]
        WHERE [StaffCode] = @RequesterStaffCode
        AND [LeaveTypeID] = @LeaveTypeID
        AND [Year] = @Year;
        
        IF @RemainingDays IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -7; -- No leave balance found
        END
        
        IF @WorkingDaysCount > @RemainingDays
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -8; -- Insufficient leave balance
        END
        
        -- Create leave request
        INSERT INTO [dbo].[tb_LeaveRequests] (
            [RequesterStaffCode],
            [LeaveTypeID],
            [RequestedDaysCount],
            [Reason],
            [Status],
            [SubmittedDate]
        )
        VALUES (
            @RequesterStaffCode,
            @LeaveTypeID,
            @WorkingDaysCount,
            @Reason,
            'Pending',
            GETDATE()
        );
        
        SET @RequestID = SCOPE_IDENTITY();
        
        -- Insert individual dates
        INSERT INTO [dbo].[tb_LeaveRequestDates] (
            [RequestID],
            [LeaveDate],
            [DateStatus],
            [IsWorkingDay]
        )
        SELECT 
            @RequestID,
            [LeaveDate],
            'Requested',
            [IsWorkingDay]
        FROM @DateTable;
        
        -- Log the action
        INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [EntityType], [EntityID], [Details])
        VALUES (@RequesterStaffCode, 'SubmitLeaveRequest', 'LeaveRequest', @RequestID, 
                'Submitted leave request for ' + CAST(@WorkingDaysCount AS NVARCHAR) + ' working days');
        
        COMMIT TRANSACTION;
        RETURN 0; -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Log error
        INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [Details])
        VALUES (@RequesterStaffCode, 'Error', ERROR_MESSAGE());
        
        RETURN -99; -- General error
    END CATCH
END
GO

PRINT 'Stored Procedure sp_SubmitLeaveRequest created successfully.';
GO

-- =============================================================================
-- STORED PROCEDURE: sp_ApproveLeaveRequest
-- Description: Approve leave request (full or partial approval)
-- Parameters:
--   @RequestID - Request to approve
--   @ApprovedBy - Admin user ID
--   @ApprovedDates - Comma-separated list of approved dates (NULL = approve all)
--   @Comments - Admin comments
-- Returns: 0 = Success, negative = Error code
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_ApproveLeaveRequest]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_ApproveLeaveRequest];
GO

CREATE PROCEDURE [dbo].[sp_ApproveLeaveRequest]
    @RequestID INT,
    @ApprovedByStaffCode NVARCHAR(40),
    @ApprovedDates NVARCHAR(MAX) = NULL,  -- NULL = approve all, otherwise comma-separated dates
    @Comments NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validate request exists and is pending
        DECLARE @RequesterStaffCode NVARCHAR(40), @LeaveTypeID INT, @RequestedDaysCount INT, @Status NVARCHAR(20);
        
        SELECT @RequesterStaffCode = [RequesterStaffCode], @LeaveTypeID = [LeaveTypeID], 
               @RequestedDaysCount = [RequestedDaysCount], @Status = [Status]
        FROM [dbo].[tb_LeaveRequests]
        WHERE [RequestID] = @RequestID;
        
        IF @RequesterStaffCode IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -1; -- Request not found
        END
        
        IF @Status <> 'Pending'
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -2; -- Request not pending
        END
        
        -- Determine if partial approval
        DECLARE @IsPartialApproval BIT = 0;
        DECLARE @ApprovedDaysCount INT = 0;
        
        IF @ApprovedDates IS NULL
        BEGIN
            -- Approve all requested dates
            UPDATE [dbo].[tb_LeaveRequestDates]
            SET [DateStatus] = 'Approved',
                [LastModifiedDate] = GETDATE()
            WHERE [RequestID] = @RequestID
            AND [DateStatus] = 'Requested'
            AND [IsWorkingDay] = 1;
            
            SET @ApprovedDaysCount = @@ROWCOUNT;
        END
        ELSE
        BEGIN
            -- Partial approval - approve only specified dates
            DECLARE @ApproveDateTable TABLE (LeaveDate DATE);
            DECLARE @DateString NVARCHAR(20), @CurrentDate DATE, @Pos INT;
            DECLARE @Dates NVARCHAR(MAX) = @ApprovedDates + ',';
            
            -- Parse approved dates
            WHILE CHARINDEX(',', @Dates) > 0
            BEGIN
                SET @Pos = CHARINDEX(',', @Dates);
                SET @DateString = LTRIM(RTRIM(SUBSTRING(@Dates, 1, @Pos - 1)));
                
                IF LEN(@DateString) > 0
                BEGIN
                    SET @CurrentDate = TRY_CONVERT(DATE, @DateString);
                    IF @CurrentDate IS NOT NULL
                        INSERT INTO @ApproveDateTable VALUES (@CurrentDate);
                END
                
                SET @Dates = SUBSTRING(@Dates, @Pos + 1, LEN(@Dates));
            END
            
            -- Update approved dates
            UPDATE d
            SET d.[DateStatus] = 'Approved',
                d.[LastModifiedDate] = GETDATE()
            FROM [dbo].[tb_LeaveRequestDates] d
            INNER JOIN @ApproveDateTable a ON d.[LeaveDate] = a.[LeaveDate]
            WHERE d.[RequestID] = @RequestID
            AND d.[IsWorkingDay] = 1;
            
            SET @ApprovedDaysCount = @@ROWCOUNT;
            
            -- Mark rejected dates
            UPDATE [dbo].[tb_LeaveRequestDates]
            SET [DateStatus] = 'Rejected',
                [LastModifiedDate] = GETDATE()
            WHERE [RequestID] = @RequestID
            AND [DateStatus] = 'Requested'
            AND [LeaveDate] NOT IN (SELECT [LeaveDate] FROM @ApproveDateTable);
            
            -- Check if partial
            IF @ApprovedDaysCount < @RequestedDaysCount
                SET @IsPartialApproval = 1;
        END
        
        -- Update leave request
        UPDATE [dbo].[tb_LeaveRequests]
        SET [Status] = CASE 
                          WHEN @ApprovedDaysCount = 0 THEN 'Rejected'
                          WHEN @IsPartialApproval = 1 THEN 'PartiallyApproved'
                          ELSE 'Approved'
                      END,
            [ApprovedDaysCount] = @ApprovedDaysCount,
            [PartialApproval] = @IsPartialApproval,
            [ReviewedDate] = GETDATE(),
            [ReviewedByStaffCode] = @ApprovedByStaffCode,
            [ReviewComments] = @Comments,
            [LastModifiedDate] = GETDATE()
        WHERE [RequestID] = @RequestID;
        
        -- Update leave balance
        IF @ApprovedDaysCount > 0
        BEGIN
            UPDATE [dbo].[tb_LeaveBalances]
            SET [UsedDays] = [UsedDays] + @ApprovedDaysCount,
                [LastUpdated] = GETDATE()
            WHERE [StaffCode] = @RequesterStaffCode
            AND [LeaveTypeID] = @LeaveTypeID
            AND [Year] = YEAR(GETDATE());
        END
        
        -- Log the action
        INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [EntityType], [EntityID], [Details])
        VALUES (@ApprovedByStaffCode, 'ApproveLeaveRequest', 'LeaveRequest', @RequestID, 
                'Approved ' + CAST(@ApprovedDaysCount AS NVARCHAR) + ' days (Partial: ' + 
                CAST(@IsPartialApproval AS NVARCHAR(1)) + ')');
        
        COMMIT TRANSACTION;
        RETURN 0; -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [Details])
        VALUES (@ApprovedByStaffCode, 'Error', ERROR_MESSAGE());
        
        RETURN -99; -- General error
    END CATCH
END
GO

PRINT 'Stored Procedure sp_ApproveLeaveRequest created successfully.';
GO

-- =============================================================================
-- STORED PROCEDURE: sp_RejectLeaveRequest
-- Description: Reject a leave request
-- Parameters:
--   @RequestID - Request to reject
--   @RejectedBy - Admin user ID
--   @Comments - Rejection reason
-- Returns: 0 = Success, negative = Error code
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_RejectLeaveRequest]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_RejectLeaveRequest];
GO

CREATE PROCEDURE [dbo].[sp_RejectLeaveRequest]
    @RequestID INT,
    @RejectedByStaffCode NVARCHAR(40),
    @Comments NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Validate request exists and is pending
        DECLARE @Status NVARCHAR(20);
        
        SELECT @Status = [Status]
        FROM [dbo].[tb_LeaveRequests]
        WHERE [RequestID] = @RequestID;
        
        IF @Status IS NULL
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -1; -- Request not found
        END
        
        IF @Status <> 'Pending'
        BEGIN
            ROLLBACK TRANSACTION;
            RETURN -2; -- Request not pending
        END
        
        -- Update all dates to rejected
        UPDATE [dbo].[tb_LeaveRequestDates]
        SET [DateStatus] = 'Rejected',
            [LastModifiedDate] = GETDATE()
        WHERE [RequestID] = @RequestID;
        
        -- Update leave request
        UPDATE [dbo].[tb_LeaveRequests]
        SET [Status] = 'Rejected',
            [ReviewedDate] = GETDATE(),
            [ReviewedByStaffCode] = @RejectedByStaffCode,
            [ReviewComments] = @Comments,
            [LastModifiedDate] = GETDATE()
        WHERE [RequestID] = @RequestID;
        
        -- Log the action
        INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [EntityType], [EntityID], [Details])
        VALUES (@RejectedByStaffCode, 'RejectLeaveRequest', 'LeaveRequest', @RequestID, 'Leave request rejected');
        
        COMMIT TRANSACTION;
        RETURN 0; -- Success
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [Details])
        VALUES (@RejectedByStaffCode, 'Error', ERROR_MESSAGE());
        
        RETURN -99; -- General error
    END CATCH
END
GO

PRINT 'Stored Procedure sp_RejectLeaveRequest created successfully.';
GO

-- =============================================================================
-- STORED PROCEDURE: sp_GenerateBlackoutDates
-- Description: Auto-generate blackout dates (day before holidays)
-- Parameters:
--   @Year - Year to generate for
--   @CreatedBy - Admin user ID
-- Returns: Number of blackout dates created
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GenerateBlackoutDates]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GenerateBlackoutDates];
GO

CREATE PROCEDURE [dbo].[sp_GenerateBlackoutDates]
    @Year INT,
    @CreatedByStaffCode NVARCHAR(40)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @CreatedCount INT = 0;
    
    -- Create blackout dates for day before each holiday
    INSERT INTO [dbo].[tb_BlackoutDates] (
        [BlackoutDate],
        [Reason_EN],
        [Reason_ZH],
        [IsActive],
        [CreatedByStaffCode]
    )
    SELECT DISTINCT
        DATEADD(DAY, -1, h.[HolidayDate]) AS BlackoutDate,
        'Day before ' + h.[HolidayName_EN] AS Reason_EN,
        h.[HolidayName_ZH] + ' 前一天' AS Reason_ZH,
        1,
        @CreatedByStaffCode
    FROM [dbo].[tb_Holidays] h
    WHERE h.[Year] = @Year
    AND h.[IsActive] = 1
    AND DATEADD(DAY, -1, h.[HolidayDate]) >= CAST(GETDATE() AS DATE)
    AND NOT EXISTS (
        SELECT 1 
        FROM [dbo].[tb_BlackoutDates] bd
        WHERE bd.[BlackoutDate] = DATEADD(DAY, -1, h.[HolidayDate])
    );
    
    SET @CreatedCount = @@ROWCOUNT;
    
    -- Log the action
    INSERT INTO [dbo].[tb_AuditLog] ([StaffCode], [Action], [Details])
    VALUES (@CreatedByStaffCode, 'GenerateBlackoutDates', 
            'Generated ' + CAST(@CreatedCount AS NVARCHAR) + ' blackout dates for year ' + CAST(@Year AS NVARCHAR));
    
    RETURN @CreatedCount;
END
GO

PRINT 'Stored Procedure sp_GenerateBlackoutDates created successfully.';
GO

-- =============================================================================
-- STORED PROCEDURE: sp_GetLeaveRequestDetails
-- Description: Get complete details of a leave request including all dates
-- Parameters:
--   @RequestID - Request ID
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_GetLeaveRequestDetails]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_GetLeaveRequestDetails];
GO

CREATE PROCEDURE [dbo].[sp_GetLeaveRequestDetails]
    @RequestID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get request header
    SELECT 
        r.[RequestID],
        r.[RequesterStaffCode],
        u.[EName],
        u.[CName],
        r.[LeaveTypeID],
        lt.[LeaveTypeName_EN],
        lt.[LeaveTypeName_ZH],
        r.[RequestedDaysCount],
        r.[ApprovedDaysCount],
        r.[Reason],
        r.[Status],
        r.[PartialApproval],
        r.[SubmittedDate],
        r.[ReviewedDate],
        r.[ReviewedByStaffCode],
        reviewer.[EName] AS ReviewerNameEN,
        r.[ReviewComments]
    FROM [dbo].[tb_LeaveRequests] r
    INNER JOIN [dbo].[tb_Users] u ON r.[RequesterStaffCode] = u.[StaffCode]
    INNER JOIN [dbo].[tb_LeaveTypes] lt ON r.[LeaveTypeID] = lt.[LeaveTypeID]
    LEFT JOIN [dbo].[tb_Users] reviewer ON r.[ReviewedByStaffCode] = reviewer.[StaffCode]
    WHERE r.[RequestID] = @RequestID;
    
    -- Get request dates
    SELECT 
        [RequestDateID],
        [RequestID],
        [LeaveDate],
        [DateStatus],
        [IsWorkingDay],
        DATENAME(WEEKDAY, [LeaveDate]) AS DayOfWeek
    FROM [dbo].[tb_LeaveRequestDates]
    WHERE [RequestID] = @RequestID
    ORDER BY [LeaveDate];
END
GO

PRINT 'Stored Procedure sp_GetLeaveRequestDetails created successfully.';
GO

PRINT '';
PRINT '=============================================================================';
PRINT 'Enhanced Stored Procedures created successfully!';
PRINT 'Version: 2.0.0';
PRINT '=============================================================================';
PRINT 'Created Functions:';
PRINT '- fn_IsBlackoutDate';
PRINT '- fn_CalculateWorkingDays';
PRINT '';
PRINT 'Created Stored Procedures:';
PRINT '- sp_SubmitLeaveRequest (ENHANCED)';
PRINT '- sp_ApproveLeaveRequest (ENHANCED)';
PRINT '- sp_RejectLeaveRequest';
PRINT '- sp_GenerateBlackoutDates (NEW)';
PRINT '- sp_GetLeaveRequestDetails (NEW)';
PRINT '=============================================================================';
GO

-- =============================================================================
-- STORED PROCEDURE: sp_UpsertHolidays_TVP (NEW)
-- Version: 2.0.0
-- Description:
--   Upserts holidays provided as a TVP (dbo.HolidayImportType), merging by HolidayDate.
--   Updates bilingual names, year, IsActive=1, SourceUID, SourceProvider, LastSyncedAt.
--   Returns number of inserted and updated rows.
-- Parameters:
--   @Holidays TVP - dbo.HolidayImportType
--   @InsertedCount INT OUTPUT
--   @UpdatedCount INT OUTPUT
-- =============================================================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_UpsertHolidays_TVP]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [dbo].[sp_UpsertHolidays_TVP];
GO

CREATE PROCEDURE [dbo].[sp_UpsertHolidays_TVP]
    @Holidays [dbo].[HolidayImportType] READONLY,
    @InsertedCount INT OUTPUT,
    @UpdatedCount INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    IF OBJECT_ID('tempdb..#MergeActions') IS NOT NULL DROP TABLE #MergeActions;
    CREATE TABLE #MergeActions (MergeAction NVARCHAR(10));

    ;WITH SourceCTE AS (
        SELECT 
            h.HolidayDate,
            h.HolidayName_EN,
            h.HolidayName_ZH,
            h.[Year],
            h.SourceUID,
            h.SourceProvider
        FROM @Holidays h
    )
    MERGE [dbo].[tb_Holidays] AS Target
    USING SourceCTE AS Source
        ON Target.[HolidayDate] = Source.[HolidayDate]
    WHEN MATCHED THEN
        UPDATE SET 
            Target.[HolidayName_EN] = Source.[HolidayName_EN],
            Target.[HolidayName_ZH] = Source.[HolidayName_ZH],
            Target.[Year]           = Source.[Year],
            Target.[IsActive]       = 1,
            Target.[SourceUID]      = Source.[SourceUID],
            Target.[SourceProvider] = Source.[SourceProvider],
            Target.[LastSyncedAt]   = GETDATE(),
            Target.[LastModifiedDate] = GETDATE()
    WHEN NOT MATCHED BY TARGET THEN
        INSERT (
            [HolidayDate], [HolidayName_EN], [HolidayName_ZH], [Year], [IsActive],
            [SourceUID], [SourceProvider], [LastSyncedAt], [CreatedDate]
        )
        VALUES (
            Source.[HolidayDate], Source.[HolidayName_EN], Source.[HolidayName_ZH], Source.[Year], 1,
            Source.[SourceUID], Source.[SourceProvider], GETDATE(), GETDATE()
        )
    OUTPUT $action INTO #MergeActions;

    SELECT @InsertedCount = COUNT(*) FROM #MergeActions WHERE MergeAction = 'INSERT';
    SELECT @UpdatedCount  = COUNT(*) FROM #MergeActions WHERE MergeAction = 'UPDATE';
END
GO

PRINT 'Stored Procedure sp_UpsertHolidays_TVP created successfully.';
GO