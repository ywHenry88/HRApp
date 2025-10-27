// Version: 2.0.0
// Admin Routes
// Define routes for administrative endpoints

const express = require('express');
const router = express.Router();
const { body, param, query } = require('express-validator');

const adminController = require('../controllers/adminController');
const { verifyToken, requireAdmin } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

// =============================================================================
// ALL ADMIN ROUTES REQUIRE AUTHENTICATION AND ADMIN ROLE
// =============================================================================

router.use(verifyToken, requireAdmin);

// =============================================================================
// VALIDATION RULES
// =============================================================================

const approveRejectValidation = [
    param('id')
        .isInt({ min: 1 }).withMessage('Invalid request ID'),
    body('comments')
        .optional()
        .isLength({ max: 500 }).withMessage('Comments must not exceed 500 characters')
];

const rejectValidation = [
    param('id')
        .isInt({ min: 1 }).withMessage('Invalid request ID'),
    body('comments')
        .notEmpty().withMessage('Rejection reason is required')
        .isLength({ min: 10, max: 500 }).withMessage('Rejection reason must be between 10 and 500 characters')
];

const createEmployeeValidation = [
    body('username')
        .trim()
        .notEmpty().withMessage('Username is required')
        .isLength({ min: 3, max: 50 }).withMessage('Username must be between 3 and 50 characters')
        .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username can only contain letters, numbers, and underscores'),
    body('password')
        .notEmpty().withMessage('Password is required')
        .isLength({ min: 8 }).withMessage('Password must be at least 8 characters'),
    body('fullName')
        .trim()
        .notEmpty().withMessage('Full name is required')
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters'),
    body('employeeCode')
        .trim()
        .notEmpty().withMessage('Employee code is required')
        .isLength({ min: 3, max: 20 }).withMessage('Employee code must be between 3 and 20 characters'),
    body('email')
        .optional()
        .trim()
        .isEmail().withMessage('Invalid email format'),
    body('departmentId')
        .optional()
        .isInt({ min: 1 }).withMessage('Invalid department ID'),
    body('position')
        .optional()
        .trim()
        .isLength({ max: 50 }).withMessage('Position must not exceed 50 characters'),
    body('role')
        .optional()
        .isIn(['Employee', 'Admin']).withMessage('Role must be either Employee or Admin')
];

const updateEmployeeValidation = [
    param('id')
        .isInt({ min: 1 }).withMessage('Invalid employee ID'),
    body('fullName')
        .trim()
        .notEmpty().withMessage('Full name is required')
        .isLength({ min: 2, max: 100 }).withMessage('Full name must be between 2 and 100 characters'),
    body('email')
        .optional()
        .trim()
        .isEmail().withMessage('Invalid email format'),
    body('departmentId')
        .optional()
        .isInt({ min: 1 }).withMessage('Invalid department ID'),
    body('position')
        .optional()
        .trim()
        .isLength({ max: 50 }).withMessage('Position must not exceed 50 characters'),
    body('role')
        .isIn(['Employee', 'Admin']).withMessage('Role must be either Employee or Admin'),
    body('isActive')
        .isBoolean().withMessage('isActive must be a boolean')
];

const employeeIdValidation = [
    param('id')
        .isInt({ min: 1 }).withMessage('Invalid employee ID')
];

const listQueryValidation = [
    query('limit')
        .optional()
        .isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
    query('offset')
        .optional()
        .isInt({ min: 0 }).withMessage('Offset must be 0 or greater')
];

// =============================================================================
// DASHBOARD ROUTES
// =============================================================================

// GET /api/admin/dashboard/stats - Get dashboard statistics
router.get('/dashboard/stats',
    adminController.getDashboardStats
);

// =============================================================================
// LEAVE APPROVAL ROUTES
// =============================================================================

// GET /api/admin/leaves/pending - Get pending approvals
router.get('/leaves/pending',
    listQueryValidation,
    validateRequest,
    adminController.getPendingApprovals
);

// PUT /api/admin/leaves/approve/:id - Approve leave request
router.put('/leaves/approve/:id',
    approveRejectValidation,
    validateRequest,
    adminController.approveLeaveRequest
);

// PUT /api/admin/leaves/reject/:id - Reject leave request
router.put('/leaves/reject/:id',
    rejectValidation,
    validateRequest,
    adminController.rejectLeaveRequest
);

// =============================================================================
// EMPLOYEE MANAGEMENT ROUTES
// =============================================================================

// GET /api/admin/employees - Get all employees
router.get('/employees',
    listQueryValidation,
    validateRequest,
    adminController.getEmployees
);

// POST /api/admin/employees - Create new employee
router.post('/employees',
    createEmployeeValidation,
    validateRequest,
    adminController.createEmployee
);

// PUT /api/admin/employees/:id - Update employee
router.put('/employees/:id',
    updateEmployeeValidation,
    validateRequest,
    adminController.updateEmployee
);

// =============================================================================
// LEAVE TYPE MANAGEMENT ROUTES
// =============================================================================

// GET /api/admin/leave-types - Get all leave types
router.get('/leave-types',
    adminController.getLeaveTypes
);

// =============================================================================
// DEPARTMENT ROUTES
// =============================================================================

// GET /api/admin/departments - Get all departments
router.get('/departments',
    adminController.getDepartments
);

// =============================================================================
// REPORTING ROUTES
// =============================================================================

// GET /api/admin/reports/leave-utilization - Get leave utilization report
router.get('/reports/leave-utilization',
    adminController.getLeaveUtilization
);

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = router;

