// Version: 2.0.0
// Admin Controller
// Handle administrative operations

const bcrypt = require('bcryptjs');
const { executeQuery, executeStoredProcedure, sql } = require('../config/database');
const { successResponse, errorResponse, serverErrorResponse, notFoundResponse } = require('../utils/response');
const logger = require('../utils/logger');

// =============================================================================
// GET DASHBOARD STATISTICS
// Get summary statistics for admin dashboard
// =============================================================================

async function getDashboardStats(req, res) {
    try {
        const result = await executeQuery(`SELECT * FROM v_DashboardStats`);
        
        if (result.recordset.length === 0) {
            return successResponse(res, {
                totalEmployees: 0,
                pendingApprovals: 0,
                onLeaveToday: 0,
                overdueApprovals: 0
            });
        }
        
        return successResponse(res, result.recordset[0]);
        
    } catch (error) {
        logger.error('Get dashboard stats error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET PENDING APPROVALS
// Get all pending leave requests for approval
// =============================================================================

async function getPendingApprovals(req, res) {
    try {
        const { limit = 50, offset = 0, departmentId, leaveTypeId } = req.query;
        
        let query = `SELECT * FROM v_PendingApprovals WHERE 1=1`;
        const params = {};
        
        if (departmentId) {
            query += ` AND DepartmentID = @departmentId`;
            params.departmentId = departmentId;
        }
        
        if (leaveTypeId) {
            query += ` AND LeaveTypeID = @leaveTypeId`;
            params.leaveTypeId = leaveTypeId;
        }
        
        query += ` ORDER BY SubmittedDate ASC OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`;
        params.offset = parseInt(offset);
        params.limit = parseInt(limit);
        
        const result = await executeQuery(query, params);
        
        // Get total count
        let countQuery = `SELECT COUNT(*) as total FROM v_PendingApprovals WHERE 1=1`;
        const countParams = {};
        
        if (departmentId) {
            countQuery += ` AND DepartmentID = @departmentId`;
            countParams.departmentId = departmentId;
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
        logger.error('Get pending approvals error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// APPROVE LEAVE REQUEST
// Approve a leave request
// =============================================================================

async function approveLeaveRequest(req, res) {
    try {
        const { userId, username } = req.user;
        const { id } = req.params;
        const { comments } = req.body;
        
        // Call stored procedure to approve request
        const result = await executeStoredProcedure(
            'sp_ApproveLeaveRequest',
            {
                RequestID: id,
                ApproverID: userId,
                Comments: comments || null
            },
            {
                ErrorMessage: { type: sql.NVarChar(500) }
            }
        );
        
        const returnValue = result.returnValue;
        const errorMessage = result.output.ErrorMessage;
        
        if (returnValue !== 0 || errorMessage) {
            return errorResponse(res, errorMessage || 'Failed to approve leave request', 'APPROVE_REQUEST_FAILED', 400);
        }
        
        logger.info(`Leave request approved. RequestID: ${id}, ApproverID: ${userId}`);
        
        return successResponse(res, null, 'Leave request approved successfully');
        
    } catch (error) {
        logger.error('Approve leave request error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// REJECT LEAVE REQUEST
// Reject a leave request
// =============================================================================

async function rejectLeaveRequest(req, res) {
    try {
        const { userId, username } = req.user;
        const { id } = req.params;
        const { comments } = req.body;
        
        if (!comments || comments.trim().length < 10) {
            return errorResponse(res, 'Rejection reason is required (minimum 10 characters)', 'REJECTION_REASON_REQUIRED', 400);
        }
        
        // Call stored procedure to reject request
        const result = await executeStoredProcedure(
            'sp_RejectLeaveRequest',
            {
                RequestID: id,
                ApproverID: userId,
                Comments: comments
            },
            {
                ErrorMessage: { type: sql.NVarChar(500) }
            }
        );
        
        const returnValue = result.returnValue;
        const errorMessage = result.output.ErrorMessage;
        
        if (returnValue !== 0 || errorMessage) {
            return errorResponse(res, errorMessage || 'Failed to reject leave request', 'REJECT_REQUEST_FAILED', 400);
        }
        
        logger.info(`Leave request rejected. RequestID: ${id}, ApproverID: ${userId}`);
        
        return successResponse(res, null, 'Leave request rejected successfully');
        
    } catch (error) {
        logger.error('Reject leave request error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET ALL EMPLOYEES
// Get list of all employees
// =============================================================================

async function getEmployees(req, res) {
    try {
        const { search, departmentId, isActive, limit = 50, offset = 0 } = req.query;
        
        let query = `SELECT * FROM v_UserProfile WHERE 1=1`;
        const params = {};
        
        if (search) {
            query += ` AND (FullName LIKE @search OR EmployeeCode LIKE @search OR Email LIKE @search)`;
            params.search = `%${search}%`;
        }
        
        if (departmentId) {
            query += ` AND DepartmentID = @departmentId`;
            params.departmentId = departmentId;
        }
        
        if (isActive !== undefined) {
            query += ` AND IsActive = @isActive`;
            params.isActive = isActive === 'true' ? 1 : 0;
        }
        
        query += ` ORDER BY FullName OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY`;
        params.offset = parseInt(offset);
        params.limit = parseInt(limit);
        
        const result = await executeQuery(query, params);
        
        // Get total count
        let countQuery = `SELECT COUNT(*) as total FROM tb_Users WHERE 1=1`;
        const countParams = {};
        
        if (search) {
            countQuery += ` AND (FullName LIKE @search OR EmployeeCode LIKE @search OR Email LIKE @search)`;
            countParams.search = `%${search}%`;
        }
        if (departmentId) {
            countQuery += ` AND DepartmentID = @departmentId`;
            countParams.departmentId = departmentId;
        }
        if (isActive !== undefined) {
            countQuery += ` AND IsActive = @isActive`;
            countParams.isActive = isActive === 'true' ? 1 : 0;
        }
        
        const countResult = await executeQuery(countQuery, countParams);
        
        return successResponse(res, {
            employees: result.recordset,
            pagination: {
                total: countResult.recordset[0].total,
                limit: parseInt(limit),
                offset: parseInt(offset)
            }
        });
        
    } catch (error) {
        logger.error('Get employees error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// CREATE EMPLOYEE
// Create a new employee
// =============================================================================

async function createEmployee(req, res) {
    try {
        const { username: adminUsername } = req.user;
        const {
            username, password, fullName, employeeCode, email,
            departmentId, position, role = 'Employee',
            leaveAllocations
        } = req.body;
        
        // Check if username already exists
        const usernameCheck = await executeQuery(
            `SELECT UserID FROM tb_Users WHERE Username = @username`,
            { username }
        );
        
        if (usernameCheck.recordset.length > 0) {
            return errorResponse(res, 'Username already exists', 'DUPLICATE_USERNAME', 400);
        }
        
        // Check if employee code already exists
        const codeCheck = await executeQuery(
            `SELECT UserID FROM tb_Users WHERE EmployeeCode = @employeeCode`,
            { employeeCode }
        );
        
        if (codeCheck.recordset.length > 0) {
            return errorResponse(res, 'Employee code already exists', 'DUPLICATE_EMPLOYEE_CODE', 400);
        }
        
        // Hash password
        const passwordHash = await bcrypt.hash(password, 10);
        
        // Insert user
        const result = await executeQuery(
            `INSERT INTO tb_Users 
             (Username, PasswordHash, FullName, EmployeeCode, Email, DepartmentID, Position, Role, IsActive, CreatedDate)
             VALUES 
             (@username, @passwordHash, @fullName, @employeeCode, @email, @departmentId, @position, @role, 1, GETDATE());
             SELECT SCOPE_IDENTITY() AS UserID;`,
            {
                username,
                passwordHash,
                fullName,
                employeeCode,
                email: email || null,
                departmentId: departmentId || null,
                position: position || null,
                role
            }
        );
        
        const newUserId = result.recordset[0].UserID;
        
        // Initialize leave balances
        const currentYear = new Date().getFullYear();
        
        if (leaveAllocations && Array.isArray(leaveAllocations)) {
            for (const allocation of leaveAllocations) {
                await executeQuery(
                    `INSERT INTO tb_LeaveBalances (UserID, LeaveTypeID, Year, TotalDays, UsedDays, LastUpdated)
                     VALUES (@userId, @leaveTypeId, @year, @totalDays, 0, GETDATE())`,
                    {
                        userId: newUserId,
                        leaveTypeId: allocation.leaveTypeId,
                        year: currentYear,
                        totalDays: allocation.days
                    }
                );
            }
        } else {
            // Use default allocations
            await executeStoredProcedure(
                'sp_InitializeLeaveBalances',
                { UserID: newUserId, Year: currentYear },
                { ErrorMessage: { type: sql.NVarChar(500) } }
            );
        }
        
        // Log employee creation
        await executeQuery(
            `INSERT INTO tb_AuditLog (UserID, Username, Action, TableName, RecordID, Details, Timestamp)
             VALUES (@userId, @username, 'CreateEmployee', 'tb_Users', @newUserId, 'Employee created', GETDATE())`,
            { userId: req.user.userId, username: adminUsername, newUserId }
        );
        
        logger.info(`Employee created: ${username} by admin ${adminUsername}`);
        
        // Fetch created employee
        const createdEmployee = await executeQuery(
            `SELECT * FROM v_UserProfile WHERE UserID = @userId`,
            { userId: newUserId }
        );
        
        return successResponse(res, createdEmployee.recordset[0], 'Employee created successfully', 201);
        
    } catch (error) {
        logger.error('Create employee error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// UPDATE EMPLOYEE
// Update employee information
// =============================================================================

async function updateEmployee(req, res) {
    try {
        const { userId: adminUserId, username: adminUsername } = req.user;
        const { id } = req.params;
        const {
            fullName, email, departmentId, position, role, isActive
        } = req.body;
        
        // Check if employee exists
        const employeeCheck = await executeQuery(
            `SELECT UserID FROM tb_Users WHERE UserID = @userId`,
            { userId: id }
        );
        
        if (employeeCheck.recordset.length === 0) {
            return notFoundResponse(res, 'Employee');
        }
        
        // Check if email is used by another user
        if (email) {
            const emailCheck = await executeQuery(
                `SELECT UserID FROM tb_Users WHERE Email = @email AND UserID != @userId`,
                { email, userId: id }
            );
            
            if (emailCheck.recordset.length > 0) {
                return errorResponse(res, 'Email is already in use', 'EMAIL_IN_USE', 400);
            }
        }
        
        // Update employee
        await executeQuery(
            `UPDATE tb_Users 
             SET FullName = @fullName,
                 Email = @email,
                 DepartmentID = @departmentId,
                 Position = @position,
                 Role = @role,
                 IsActive = @isActive,
                 LastModifiedDate = GETDATE()
             WHERE UserID = @userId`,
            {
                userId: id,
                fullName,
                email: email || null,
                departmentId: departmentId || null,
                position: position || null,
                role,
                isActive: isActive ? 1 : 0
            }
        );
        
        // Log employee update
        await executeQuery(
            `INSERT INTO tb_AuditLog (UserID, Username, Action, TableName, RecordID, Details, Timestamp)
             VALUES (@adminUserId, @adminUsername, 'UpdateEmployee', 'tb_Users', @employeeId, 'Employee updated', GETDATE())`,
            { adminUserId, adminUsername, employeeId: id }
        );
        
        logger.info(`Employee updated: UserID ${id} by admin ${adminUsername}`);
        
        // Fetch updated employee
        const updatedEmployee = await executeQuery(
            `SELECT * FROM v_UserProfile WHERE UserID = @userId`,
            { userId: id }
        );
        
        return successResponse(res, updatedEmployee.recordset[0], 'Employee updated successfully');
        
    } catch (error) {
        logger.error('Update employee error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET LEAVE TYPES (ADMIN)
// Get all leave types for management
// =============================================================================

async function getLeaveTypes(req, res) {
    try {
        const result = await executeQuery(
            `SELECT * FROM tb_LeaveTypes ORDER BY LeaveTypeID`
        );
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get leave types (admin) error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET DEPARTMENTS
// Get all departments
// =============================================================================

async function getDepartments(req, res) {
    try {
        const result = await executeQuery(
            `SELECT 
                d.DepartmentID, d.DepartmentName_EN, d.DepartmentName_ZH, 
                d.ManagerUserID, d.IsActive,
                u.FullName as ManagerName
             FROM tb_Departments d
             LEFT JOIN tb_Users u ON d.ManagerUserID = u.UserID
             ORDER BY d.DepartmentName_EN`
        );
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get departments error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET LEAVE UTILIZATION REPORT
// Get leave utilization statistics
// =============================================================================

async function getLeaveUtilization(req, res) {
    try {
        const { year, departmentId } = req.query;
        const currentYear = year || new Date().getFullYear();
        
        let query = `SELECT * FROM v_LeaveUtilization WHERE Year = @year`;
        const params = { year: currentYear };
        
        if (departmentId) {
            query += ` AND DepartmentID = @departmentId`;
            params.departmentId = departmentId;
        }
        
        query += ` ORDER BY FullName, LeaveTypeName_EN`;
        
        const result = await executeQuery(query, params);
        
        return successResponse(res, result.recordset);
        
    } catch (error) {
        logger.error('Get leave utilization error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    getDashboardStats,
    getPendingApprovals,
    approveLeaveRequest,
    rejectLeaveRequest,
    getEmployees,
    createEmployee,
    updateEmployee,
    getLeaveTypes,
    getDepartments,
    getLeaveUtilization
};

