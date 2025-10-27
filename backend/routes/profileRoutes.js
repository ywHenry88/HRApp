// Version: 2.0.0
// Profile Routes
// Define routes for user profile endpoints

const express = require('express');
const router = express.Router();
const { body } = require('express-validator');

const profileController = require('../controllers/profileController');
const { verifyToken } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

// =============================================================================
// VALIDATION RULES
// =============================================================================

const updateProfileValidation = [
    body('fullName')
        .optional()
        .trim()
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters'),
    body('email')
        .optional()
        .trim()
        .isEmail().withMessage('Invalid email format')
        .isLength({ max: 100 }).withMessage('Email must not exceed 100 characters')
];

// =============================================================================
// ROUTES - All routes require authentication
// =============================================================================

// GET /api/profile - Get user profile
router.get('/',
    verifyToken,
    profileController.getProfile
);

// PUT /api/profile - Update user profile
router.put('/',
    verifyToken,
    updateProfileValidation,
    validateRequest,
    profileController.updateProfile
);

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = router;

