// Version: 2.0.0
// Calendar Controller
// Handle calendar and holiday operations

const { executeQuery } = require('../config/database');
const { successResponse, serverErrorResponse } = require('../utils/response');
const logger = require('../utils/logger');

// =============================================================================
// GET TEAM CALENDAR
// Get team calendar with all approved leave requests
// =============================================================================

async function getTeamCalendar(req, res) {
    try {
        const { startDate, endDate, month, year } = req.query;
        
        let query = `SELECT * FROM v_TeamCalendar WHERE 1=1`;
        const params = {};
        
        if (startDate && endDate) {
            query += ` AND (StartDate <= @endDate AND EndDate >= @startDate)`;
            params.startDate = startDate;
            params.endDate = endDate;
        } else if (month && year) {
            // Get calendar for specific month/year
            const monthStart = `${year}-${String(month).padStart(2, '0')}-01`;
            const nextMonth = parseInt(month) === 12 ? 1 : parseInt(month) + 1;
            const nextYear = parseInt(month) === 12 ? parseInt(year) + 1 : parseInt(year);
            const monthEnd = `${nextYear}-${String(nextMonth).padStart(2, '0')}-01`;
            
            query += ` AND (StartDate < @monthEnd AND EndDate >= @monthStart)`;
            params.monthStart = monthStart;
            params.monthEnd = monthEnd;
        }
        
        query += ` ORDER BY StartDate, FullName`;
        
        const result = await executeQuery(query, params);
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get team calendar error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET HOLIDAYS
// Get public holidays
// =============================================================================

async function getHolidays(req, res) {
    try {
        const { year } = req.query;
        
        let query = `SELECT 
            HolidayID, HolidayDate, HolidayName_EN, HolidayName_ZH, Year
         FROM tb_Holidays`;
        const params = {};
        
        if (year) {
            query += ` WHERE Year = @year`;
            params.year = year;
        }
        
        query += ` ORDER BY HolidayDate`;
        
        const result = await executeQuery(query, params);
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get holidays error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET ON LEAVE TODAY
// Get employees on leave today
// =============================================================================

async function getOnLeaveToday(req, res) {
    try {
        const today = new Date().toISOString().split('T')[0];
        
        const result = await executeQuery(
            `SELECT 
                u.UserID, u.FullName, u.EmployeeCode,
                lt.LeaveTypeName_EN, lt.LeaveTypeName_ZH, lt.ColorCode,
                lr.StartDate, lr.EndDate, lr.TotalDays
             FROM tb_LeaveRequests lr
             INNER JOIN tb_Users u ON lr.UserID = u.UserID
             INNER JOIN tb_LeaveTypes lt ON lr.LeaveTypeID = lt.LeaveTypeID
             WHERE lr.Status = 'Approved'
               AND @today BETWEEN lr.StartDate AND lr.EndDate
               AND u.IsActive = 1
             ORDER BY u.FullName`,
            { today }
        );
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get on leave today error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    getTeamCalendar,
    getHolidays,
    getOnLeaveToday
};

