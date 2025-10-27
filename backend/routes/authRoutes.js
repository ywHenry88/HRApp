// Version: 2.0.0
// Authentication Routes
// Define routes for authentication endpoints

const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const rateLimit = require('express-rate-limit');

const authController = require('../controllers/authController');
const { verifyToken } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

// =============================================================================
// RATE LIMITING FOR LOGIN
// Prevent brute force attacks
// =============================================================================

const loginLimiter = rateLimit({
    windowMs: parseInt(process.env.LOGIN_RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.LOGIN_RATE_LIMIT_MAX_ATTEMPTS) || 5,
    message: {
        success: false,
        error: {
            code: 'RATE_LIMIT_EXCEEDED',
            message: 'Too many login attempts. Please try again later.'
        }
    },
    standardHeaders: true,
    legacyHeaders: false,
});

// =============================================================================
// VALIDATION RULES
// =============================================================================

const loginValidation = [
    body('username')
        .trim()
        .notEmpty().withMessage('Username is required')
        .isLength({ min: 3, max: 50 }).withMessage('Username must be between 3 and 50 characters'),
    body('password')
        .notEmpty().withMessage('Password is required')
        .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
];

const changePasswordValidation = [
    body('currentPassword')
        .notEmpty().withMessage('Current password is required'),
    body('newPassword')
        .notEmpty().withMessage('New password is required')
        .isLength({ min: 8 }).withMessage('New password must be at least 8 characters')
        .matches(/^(?=.*[A-Za-z])(?=.*\d)/).withMessage('Password must contain at least one letter and one number'),
    body('confirmPassword')
        .notEmpty().withMessage('Confirm password is required')
        .custom((value, { req }) => value === req.body.newPassword)
        .withMessage('Passwords do not match')
];

// =============================================================================
// ROUTES
// =============================================================================

// POST /api/auth/login - User login
router.post('/login', 
    loginLimiter,
    loginValidation,
    validateRequest,
    authController.login
);

// POST /api/auth/logout - User logout
router.post('/logout',
    verifyToken,
    authController.logout
);

// GET /api/auth/me - Get current user information
router.get('/me',
    verifyToken,
    authController.getCurrentUser
);

// POST /api/auth/change-password - Change password
router.post('/change-password',
    verifyToken,
    changePasswordValidation,
    validateRequest,
    authController.changePassword
);

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = router;

