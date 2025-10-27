// Version: 2.0.0
// Leave Management Routes
// Define routes for leave management endpoints

const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');

const leaveController = require('../controllers/leaveController');
const { verifyToken, requireEmployee } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

// =============================================================================
// VALIDATION RULES
// =============================================================================

const submitLeaveValidation = [
    body('leaveTypeId')
        .notEmpty().withMessage('Leave type is required')
        .isInt({ min: 1 }).withMessage('Invalid leave type'),
    body('startDate')
        .notEmpty().withMessage('Start date is required')
        .isDate().withMessage('Invalid start date format')
        .custom((value) => {
            const startDate = new Date(value);
            const today = new Date();
            today.setHours(0, 0, 0, 0);
            if (startDate < today) {
                throw new Error('Start date cannot be in the past');
            }
            return true;
        }),
    body('endDate')
        .notEmpty().withMessage('End date is required')
        .isDate().withMessage('Invalid end date format')
        .custom((value, { req }) => {
            const startDate = new Date(req.body.startDate);
            const endDate = new Date(value);
            if (endDate < startDate) {
                throw new Error('End date must be equal to or after start date');
            }
            return true;
        }),
    body('reason')
        .optional()
        .isLength({ max: 500 }).withMessage('Reason must not exceed 500 characters')
];

const updateLeaveValidation = [
    param('id')
        .isInt({ min: 1 }).withMessage('Invalid request ID'),
    body('startDate')
        .notEmpty().withMessage('Start date is required')
        .isDate().withMessage('Invalid start date format'),
    body('endDate')
        .notEmpty().withMessage('End date is required')
        .isDate().withMessage('Invalid end date format')
        .custom((value, { req }) => {
            const startDate = new Date(req.body.startDate);
            const endDate = new Date(value);
            if (endDate < startDate) {
                throw new Error('End date must be equal to or after start date');
            }
            return true;
        }),
    body('reason')
        .optional()
        .isLength({ max: 500 }).withMessage('Reason must not exceed 500 characters')
];

const requestIdValidation = [
    param('id')
        .isInt({ min: 1 }).withMessage('Invalid request ID')
];

const historyQueryValidation = [
    query('status')
        .optional()
        .isIn(['Pending', 'Approved', 'Rejected', 'Cancelled']).withMessage('Invalid status'),
    query('leaveTypeId')
        .optional()
        .isInt({ min: 1 }).withMessage('Invalid leave type ID'),
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('offset')
        .optional()
        .isInt({ min: 0 }).withMessage('Offset must be 0 or greater')
];

// =============================================================================
// ROUTES - All routes require authentication
// =============================================================================

// GET /api/leaves/balance - Get leave balance
router.get('/balance',
    verifyToken,
    requireEmployee,
    leaveController.getLeaveBalance
);

// GET /api/leaves/types - Get leave types
router.get('/types',
    verifyToken,
    leaveController.getLeaveTypes
);

// POST /api/leaves/request - Submit leave request
router.post('/request',
    verifyToken,
    requireEmployee,
    submitLeaveValidation,
    validateRequest,
    leaveController.submitLeaveRequest
);

// GET /api/leaves/history - Get leave history
router.get('/history',
    verifyToken,
    requireEmployee,
    historyQueryValidation,
    validateRequest,
    leaveController.getLeaveHistory
);

// GET /api/leaves/request/:id - Get specific leave request
router.get('/request/:id',
    verifyToken,
    requireEmployee,
    requestIdValidation,
    validateRequest,
    leaveController.getLeaveRequestById
);

// PUT /api/leaves/request/:id - Update pending leave request
router.put('/request/:id',
    verifyToken,
    requireEmployee,
    updateLeaveValidation,
    validateRequest,
    leaveController.updateLeaveRequest
);

// DELETE /api/leaves/request/:id - Cancel leave request
router.delete('/request/:id',
    verifyToken,
    requireEmployee,
    requestIdValidation,
    validateRequest,
    leaveController.cancelLeaveRequest
);

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = router;

