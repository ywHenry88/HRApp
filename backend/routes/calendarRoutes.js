// Version: 2.0.0
// Calendar Routes
// Define routes for calendar endpoints

const express = require('express');
const router = express.Router();
const { query } = require('express-validator');

const calendarController = require('../controllers/calendarController');
const { verifyToken } = require('../middleware/auth');
const { validateRequest } = require('../middleware/validation');

// =============================================================================
// VALIDATION RULES
// =============================================================================

const calendarQueryValidation = [
    query('startDate')
        .optional()
        .isDate().withMessage('Invalid start date format'),
    query('endDate')
        .optional()
        .isDate().withMessage('Invalid end date format'),
    query('month')
        .optional()
        .isInt({ min: 1, max: 12 }).withMessage('Month must be between 1 and 12'),
    query('year')
        .optional()
        .isInt({ min: 2020, max: 2100 }).withMessage('Year must be between 2020 and 2100')
];

const holidayQueryValidation = [
    query('year')
        .optional()
        .isInt({ min: 2020, max: 2100 }).withMessage('Year must be between 2020 and 2100')
];

// =============================================================================
// ROUTES - All routes require authentication
// =============================================================================

// GET /api/calendar - Get team calendar
router.get('/',
    verifyToken,
    calendarQueryValidation,
    validateRequest,
    calendarController.getTeamCalendar
);

// GET /api/calendar/holidays - Get public holidays
router.get('/holidays',
    verifyToken,
    holidayQueryValidation,
    validateRequest,
    calendarController.getHolidays
);

// GET /api/calendar/on-leave-today - Get employees on leave today
router.get('/on-leave-today',
    verifyToken,
    calendarController.getOnLeaveToday
);

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = router;

