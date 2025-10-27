// Version: 2.0.0
// Authentication Controller
// Handle user authentication and authorization

const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { executeQuery } = require('../config/database');
const { successResponse, errorResponse, serverErrorResponse } = require('../utils/response');
const logger = require('../utils/logger');

// =============================================================================
// LOGIN
// Authenticate user and return JWT token
// =============================================================================

async function login(req, res) {
    try {
        const { username, password } = req.body;
        
        // Query user from database
        const result = await executeQuery(
            `SELECT 
                UserID, Username, PasswordHash, FullName, EmployeeCode, 
                Email, Role, IsActive, DepartmentID
             FROM tb_Users 
             WHERE Username = @username`,
            { username }
        );
        
        // Check if user exists
        if (result.recordset.length === 0) {
            logger.warn(`Login attempt with invalid username: ${username}`);
            return errorResponse(res, 'Invalid username or password', 'AUTH_INVALID_CREDENTIALS', 401);
        }
        
        const user = result.recordset[0];
        
        // Check if user is active
        if (!user.IsActive) {
            logger.warn(`Login attempt for inactive user: ${username}`);
            return errorResponse(res, 'Account is inactive', 'AUTH_ACCOUNT_INACTIVE', 401);
        }
        
        // Verify password
        const isPasswordValid = await bcrypt.compare(password, user.PasswordHash);
        
        if (!isPasswordValid) {
            logger.warn(`Login attempt with invalid password for user: ${username}`);
            return errorResponse(res, 'Invalid username or password', 'AUTH_INVALID_CREDENTIALS', 401);
        }
        
        // Generate JWT token
        const token = jwt.sign(
            {
                userId: user.UserID,
                username: user.Username,
                role: user.Role,
                employeeCode: user.EmployeeCode
            },
            process.env.JWT_SECRET,
            { expiresIn: process.env.JWT_EXPIRES_IN || '24h' }
        );
        
        // Update last login timestamp
        await executeQuery(
            `UPDATE tb_Users SET LastLogin = GETDATE() WHERE UserID = @userId`,
            { userId: user.UserID }
        );
        
        // Log successful login
        await executeQuery(
            `INSERT INTO tb_AuditLog (UserID, Username, Action, Details, IPAddress, Timestamp)
             VALUES (@userId, @username, 'Login', 'User login successful', @ip, GETDATE())`,
            {
                userId: user.UserID,
                username: user.Username,
                ip: req.ip || 'unknown'
            }
        );
        
        logger.info(`User logged in successfully: ${username} (${user.Role})`);
        
        // Return user data and token
        return successResponse(res, {
            token,
            user: {
                userId: user.UserID,
                username: user.Username,
                fullName: user.FullName,
                employeeCode: user.EmployeeCode,
                email: user.Email,
                role: user.Role,
                departmentId: user.DepartmentID
            }
        }, 'Login successful');
        
    } catch (error) {
        logger.error('Login error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// LOGOUT
// Log user logout (token invalidation handled on client side)
// =============================================================================

async function logout(req, res) {
    try {
        const { userId, username } = req.user;
        
        // Log logout event
        await executeQuery(
            `INSERT INTO tb_AuditLog (UserID, Username, Action, Details, Timestamp)
             VALUES (@userId, @username, 'Logout', 'User logout', GETDATE())`,
            { userId, username }
        );
        
        logger.info(`User logged out: ${username}`);
        
        return successResponse(res, null, 'Logout successful');
        
    } catch (error) {
        logger.error('Logout error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// GET CURRENT USER
// Get currently authenticated user information
// =============================================================================

async function getCurrentUser(req, res) {
    try {
        const { userId } = req.user;
        
        // Query user from database with department info
        const result = await executeQuery(
            `SELECT 
                u.UserID, u.Username, u.FullName, u.EmployeeCode, u.Email, 
                u.Role, u.Position, u.IsActive, u.CreatedDate, u.LastLogin,
                d.DepartmentID, d.DepartmentName_EN, d.DepartmentName_ZH
             FROM tb_Users u
             LEFT JOIN tb_Departments d ON u.DepartmentID = d.DepartmentID
             WHERE u.UserID = @userId`,
            { userId }
        );
        
        if (result.recordset.length === 0) {
            return errorResponse(res, 'User not found', 'USER_NOT_FOUND', 404);
        }
        
        const user = result.recordset[0];
        
        return successResponse(res, {
            userId: user.UserID,
            username: user.Username,
            fullName: user.FullName,
            employeeCode: user.EmployeeCode,
            email: user.Email,
            role: user.Role,
            position: user.Position,
            isActive: user.IsActive,
            department: user.DepartmentID ? {
                departmentId: user.DepartmentID,
                nameEN: user.DepartmentName_EN,
                nameZH: user.DepartmentName_ZH
            } : null,
            createdDate: user.CreatedDate,
            lastLogin: user.LastLogin
        });
        
    } catch (error) {
        logger.error('Get current user error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// CHANGE PASSWORD
// Change user password
// =============================================================================

async function changePassword(req, res) {
    try {
        const { userId, username } = req.user;
        const { currentPassword, newPassword } = req.body;
        
        // Get current password hash
        const result = await executeQuery(
            `SELECT PasswordHash FROM tb_Users WHERE UserID = @userId`,
            { userId }
        );
        
        if (result.recordset.length === 0) {
            return errorResponse(res, 'User not found', 'USER_NOT_FOUND', 404);
        }
        
        const currentHash = result.recordset[0].PasswordHash;
        
        // Verify current password
        const isCurrentPasswordValid = await bcrypt.compare(currentPassword, currentHash);
        
        if (!isCurrentPasswordValid) {
            logger.warn(`Failed password change attempt for user: ${username}`);
            return errorResponse(res, 'Current password is incorrect', 'AUTH_INVALID_PASSWORD', 401);
        }
        
        // Hash new password
        const newPasswordHash = await bcrypt.hash(newPassword, 10);
        
        // Update password
        await executeQuery(
            `UPDATE tb_Users SET PasswordHash = @passwordHash WHERE UserID = @userId`,
            { userId, passwordHash: newPasswordHash }
        );
        
        // Log password change
        await executeQuery(
            `INSERT INTO tb_AuditLog (UserID, Username, Action, Details, Timestamp)
             VALUES (@userId, @username, 'ChangePassword', 'Password changed successfully', GETDATE())`,
            { userId, username }
        );
        
        logger.info(`Password changed successfully for user: ${username}`);
        
        return successResponse(res, null, 'Password changed successfully. Please login again.');
        
    } catch (error) {
        logger.error('Change password error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    login,
    logout,
    getCurrentUser,
    changePassword
};

