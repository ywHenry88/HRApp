// Version: 2.0.0
// Validation Middleware
// Input validation using express-validator

const { validationResult } = require('express-validator');
const { validationErrorResponse } = require('../utils/response');

// =============================================================================
// VALIDATE REQUEST
// Middleware to check validation results and return errors
// =============================================================================

function validateRequest(req, res, next) {
    const errors = validationResult(req);
    
    if (!errors.isEmpty()) {
        const formattedErrors = errors.array().map(error => ({
            field: error.path || error.param,
            message: error.msg,
            value: error.value
        }));
        
        return validationErrorResponse(res, formattedErrors);
    }
    
    next();
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    validateRequest
};

