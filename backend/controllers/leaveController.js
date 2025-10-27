// Version: 2.0.0
// Leave Management Controller
// Handle leave requests, history, and balance

const { executeQuery, executeStoredProcedure, sql } = require('../config/database');
const { successResponse, errorResponse, serverErrorResponse, notFoundResponse } = require('../utils/response');
const logger = require('../utils/logger');

// =============================================================================
// GET LEAVE BALANCE
// Get leave balance for current user
// =============================================================================

async function getLeaveBalance(req, res) {
    try {
        const { userId } = req.user;
        const year = req.query.year || new Date().getFullYear();
        
        const result = await executeQuery(
            `SELECT * FROM v_LeaveBalance 
             WHERE UserID = @userId AND Year = @year
             ORDER BY LeaveTypeID`,
            { userId, year }
        );
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get leave balance error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// SUBMIT LEAVE REQUEST
// Submit a new leave request
// =============================================================================

async function submitLeaveRequest(req, res) {
    try {
        const { userId } = req.user;
        const { leaveTypeId, startDate, endDate, reason } = req.body;
        
        // Call stored procedure to submit request
        const result = await executeStoredProcedure(
            'sp_SubmitLeaveRequest',
            {
                UserID: userId,
                LeaveTypeID: leaveTypeId,
                StartDate: startDate,
                EndDate: endDate,
                Reason: reason || null
            },
            {
                RequestID: { type: sql.Int },
                ErrorMessage: { type: sql.NVarChar(500) }
            }
        );
        
        const returnValue = result.returnValue;
        const requestId = result.output.RequestID;
        const errorMessage = result.output.ErrorMessage;
        
        if (returnValue !== 0 || errorMessage) {
            return errorResponse(res, errorMessage || 'Failed to submit leave request', 'SUBMIT_REQUEST_FAILED', 400);
        }
        
        logger.info(`Leave request submitted successfully. RequestID: ${requestId}, UserID: ${userId}`);
        
        // Fetch the created request details
        const requestResult = await executeQuery(
            `SELECT * FROM v_LeaveRequestDetail WHERE RequestID = @requestId`,
            { requestId }
        );
        
        return successResponse(res, requestResult.recordset[0], 'Leave request submitted successfully', 201);
        
    } catch (error) {
        logger.error('Submit leave request error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET LEAVE HISTORY
// Get leave request history for current user
// =============================================================================

async function getLeaveHistory(req, res) {
    try {
        const { userId } = req.user;
        const { status, leaveTypeId, startDate, endDate, limit = 50, offset = 0 } = req.query;
        
        let query = `SELECT * FROM v_LeaveRequestDetail WHERE UserID = @userId`;
        const params = { userId };
        
        // Apply filters
        if (status) {
            query += ` AND Status = @status`;
            params.status = status;
        }
        
        if (leaveTypeId) {
            query += ` AND LeaveTypeID = @leaveTypeId`;
            params.leaveTypeId = leaveTypeId;
        }
        
        if (startDate) {
            query += ` AND StartDate >= @startDate`;
            params.startDate = startDate;
        }
        
        if (endDate) {
            query += ` AND EndDate <= @endDate`;
            params.endDate = endDate;
        }
        
        query += ` ORDER BY SubmittedDate DESC OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`;
        params.offset = parseInt(offset);
        params.limit = parseInt(limit);
        
        const result = await executeQuery(query, params);
        
        // Get total count for pagination
        let countQuery = `SELECT COUNT(*) as total FROM tb_LeaveRequests WHERE UserID = @userId`;
        const countParams = { userId };
        
        if (status) {
            countQuery += ` AND Status = @status`;
            countParams.status = status;
        }
        if (leaveTypeId) {
            countQuery += ` AND LeaveTypeID = @leaveTypeId`;
            countParams.leaveTypeId = leaveTypeId;
        }
        
        const countResult = await executeQuery(countQuery, countParams);
        
        return successResponse(res, {
            requests: result.recordset,
            pagination: {
                total: countResult.recordset[0].total,
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });
        
    } catch (error) {
        logger.error('Get leave history error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET LEAVE REQUEST BY ID
// Get specific leave request details
// =============================================================================

async function getLeaveRequestById(req, res) {
    try {
        const { userId } = req.user;
        const { id } = req.params;
        
        const result = await executeQuery(
            `SELECT * FROM v_LeaveRequestDetail WHERE RequestID = @requestId AND UserID = @userId`,
            { requestId: id, userId }
        );
        
        if (result.recordset.length === 0) {
            return notFoundResponse(res, 'Leave request');
        }
        
        return successResponse(res, result.recordset[0]);
        
    } catch (error) {
        logger.error('Get leave request error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// UPDATE LEAVE REQUEST
// Update pending leave request
// =============================================================================

async function updateLeaveRequest(req, res) {
    try {
        const { userId } = req.user;
        const { id } = req.params;
        const { startDate, endDate, reason } = req.body;
        
        // Check if request exists and belongs to user
        const checkResult = await executeQuery(
            `SELECT Status FROM tb_LeaveRequests WHERE RequestID = @requestId AND UserID = @userId`,
            { requestId: id, userId }
        );
        
        if (checkResult.recordset.length === 0) {
            return notFoundResponse(res, 'Leave request');
        }
        
        const status = checkResult.recordset[0].Status;
        
        if (status !== 'Pending') {
            return errorResponse(res, 'Only pending requests can be updated', 'REQUEST_NOT_EDITABLE', 400);
        }
        
        // Calculate total days (simplified - should use stored procedure)
        const daysDiff = Math.ceil((new Date(endDate) - new Date(startDate)) / (1000 * 60 * 60 * 24)) + 1;
        
        // Update request
        await executeQuery(
            `UPDATE tb_LeaveRequests 
             SET StartDate = @startDate, 
                 EndDate = @endDate, 
                 TotalDays = @totalDays,
                 Reason = @reason,
                 LastModifiedDate = GETDATE()
             WHERE RequestID = @requestId`,
            {
                requestId: id,
                startDate,
                endDate,
                totalDays: daysDiff,
                reason: reason || null
            }
        );
        
        logger.info(`Leave request updated. RequestID: ${id}, UserID: ${userId}`);
        
        // Fetch updated request
        const updatedResult = await executeQuery(
            `SELECT * FROM v_LeaveRequestDetail WHERE RequestID = @requestId`,
            { requestId: id }
        );
        
        return successResponse(res, updatedResult.recordset[0], 'Leave request updated successfully');
        
    } catch (error) {
        logger.error('Update leave request error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// CANCEL LEAVE REQUEST
// Cancel leave request
// =============================================================================

async function cancelLeaveRequest(req, res) {
    try {
        const { userId } = req.user;
        const { id } = req.params;
        
        // Call stored procedure to cancel request
        const result = await executeStoredProcedure(
            'sp_CancelLeaveRequest',
            {
                RequestID: id,
                UserID: userId
            },
            {
                ErrorMessage: { type: sql.NVarChar(500) }
            }
        );
        
        const returnValue = result.returnValue;
        const errorMessage = result.output.ErrorMessage;
        
        if (returnValue !== 0 || errorMessage) {
            return errorResponse(res, errorMessage || 'Failed to cancel leave request', 'CANCEL_REQUEST_FAILED', 400);
        }
        
        logger.info(`Leave request cancelled. RequestID: ${id}, UserID: ${userId}`);
        
        return successResponse(res, null, 'Leave request cancelled successfully');
        
    } catch (error) {
        logger.error('Cancel leave request error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET LEAVE TYPES
// Get all active leave types
// =============================================================================

async function getLeaveTypes(req, res) {
    try {
        const result = await executeQuery(
            `SELECT 
                LeaveTypeID, LeaveTypeName_EN, LeaveTypeName_ZH, 
                DefaultDaysPerYear, RequiresApproval, ColorCode, IconName
             FROM tb_LeaveTypes 
             WHERE IsActive = 1
             ORDER BY LeaveTypeID`
        );
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get leave types error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    getLeaveBalance,
    submitLeaveRequest,
    getLeaveHistory,
    getLeaveRequestById,
    updateLeaveRequest,
    cancelLeaveRequest,
    getLeaveTypes
};

