// Version: 2.0.0
// Profile Controller
// Handle user profile operations

const { executeQuery } = require('../config/database');
const { successResponse, errorResponse, serverErrorResponse, notFoundResponse } = require('../utils/response');
const logger = require('../utils/logger');

// =============================================================================
// GET PROFILE
// Get user profile information
// =============================================================================

async function getProfile(req, res) {
    try {
        const { userId } = req.user;
        
        const result = await executeQuery(
            `SELECT * FROM v_UserProfile WHERE UserID = @userId`,
            { userId }
        );
        
        if (result.recordset.length === 0) {
            return notFoundResponse(res, 'User profile');
        }
        
        const profile = result.recordset[0];
        
        return successResponse(res, {
            userId: profile.UserID,
            username: profile.Username,
            fullName: profile.FullName,
            employeeCode: profile.EmployeeCode,
            email: profile.Email,
            position: profile.Position,
            role: profile.Role,
            isActive: profile.IsActive,
            department: profile.DepartmentID ? {
                departmentId: profile.DepartmentID,
                nameEN: profile.DepartmentName_EN,
                nameZH: profile.DepartmentName_ZH
            } : null,
            createdDate: profile.CreatedDate,
            lastLogin: profile.LastLogin
        });
        
    } catch (error) {
        logger.error('Get profile error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// UPDATE PROFILE
// Update user profile information
// =============================================================================

async function updateProfile(req, res) {
    try {
        const { userId, username } = req.user;
        const { fullName, email } = req.body;
        
        // Check if email is already used by another user
        if (email) {
            const emailCheck = await executeQuery(
                `SELECT UserID FROM tb_Users WHERE Email = @email AND UserID != @userId`,
                { email, userId }
            );
            
            if (emailCheck.recordset.length > 0) {
                return errorResponse(res, 'Email is already in use', 'EMAIL_IN_USE', 400);
            }
        }
        
        // Update profile
        await executeQuery(
            `UPDATE tb_Users 
             SET FullName = @fullName,
                 Email = @email,
                 LastModifiedDate = GETDATE()
             WHERE UserID = @userId`,
            {
                userId,
                fullName: fullName || null,
                email: email || null
            }
        );
        
        // Log profile update
        await executeQuery(
            `INSERT INTO tb_AuditLog (UserID, Username, Action, TableName, RecordID, Details, Timestamp)
             VALUES (@userId, @username, 'UpdateProfile', 'tb_Users', @userId, 'Profile updated', GETDATE())`,
            { userId, username }
        );
        
        logger.info(`Profile updated for user: ${username}`);
        
        // Fetch updated profile
        const updatedProfile = await executeQuery(
            `SELECT * FROM v_UserProfile WHERE UserID = @userId`,
            { userId }
        );
        
        const profile = updatedProfile.recordset[0];
        
        return successResponse(res, {
            userId: profile.UserID,
            username: profile.Username,
            fullName: profile.FullName,
            employeeCode: profile.EmployeeCode,
            email: profile.Email,
            position: profile.Position,
            role: profile.Role,
            department: profile.DepartmentID ? {
                departmentId: profile.DepartmentID,
                nameEN: profile.DepartmentName_EN,
                nameZH: profile.DepartmentName_ZH
            } : null
        }, 'Profile updated successfully');
        
    } catch (error) {
        logger.error('Update profile error:', error);
        return serverErrorResponse(res, error, process.env.NODE_ENV !== 'production');
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    getProfile,
    updateProfile
};

