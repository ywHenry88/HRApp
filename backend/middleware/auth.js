// Version: 2.0.0
// Authentication Middleware
// JWT token verification and role-based access control

const jwt = require('jsonwebtoken');
const { unauthorizedResponse, forbiddenResponse } = require('../utils/response');
const logger = require('../utils/logger');

// =============================================================================
// VERIFY JWT TOKEN
// Middleware to verify JWT token and attach user to request
// =============================================================================

function verifyToken(req, res, next) {
    try {
        // Get token from Authorization header
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return unauthorizedResponse(res, 'No token provided');
        }
        
        const token = authHeader.substring(7); // Remove 'Bearer ' prefix
        
        // Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Attach user info to request
        req.user = {
            userId: decoded.userId,
            username: decoded.username,
            role: decoded.role,
            employeeCode: decoded.employeeCode
        };
        
        next();
        
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            return unauthorizedResponse(res, 'Invalid token');
        }
        
        if (error.name === 'TokenExpiredError') {
            return unauthorizedResponse(res, 'Token expired');
        }
        
        logger.error('Token verification error:', error);
        return unauthorizedResponse(res, 'Authentication failed');
    }
}

// =============================================================================
// REQUIRE ADMIN ROLE
// Middleware to check if user has admin role
// =============================================================================

function requireAdmin(req, res, next) {
    if (!req.user) {
        return unauthorizedResponse(res, 'Authentication required');
    }
    
    if (req.user.role !== 'Admin') {
        logger.warn(`Access denied for user ${req.user.username} (role: ${req.user.role})`);
        return forbiddenResponse(res, 'Admin access required');
    }
    
    next();
}

// =============================================================================
// REQUIRE EMPLOYEE ROLE (or Admin)
// Middleware to check if user has employee or admin role
// =============================================================================

function requireEmployee(req, res, next) {
    if (!req.user) {
        return unauthorizedResponse(res, 'Authentication required');
    }
    
    if (req.user.role !== 'Employee' && req.user.role !== 'Admin') {
        return forbiddenResponse(res, 'Employee access required');
    }
    
    next();
}

// =============================================================================
// OPTIONAL AUTH
// Middleware to attach user if token is present, but don't require it
// =============================================================================

function optionalAuth(req, res, next) {
    try {
        const authHeader = req.headers.authorization;
        
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            
            req.user = {
                userId: decoded.userId,
                username: decoded.username,
                role: decoded.role,
                employeeCode: decoded.employeeCode
            };
        }
        
        next();
        
    } catch (error) {
        // Ignore errors in optional auth
        next();
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    verifyToken,
    requireAdmin,
    requireEmployee,
    optionalAuth
};

