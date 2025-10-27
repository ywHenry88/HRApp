// Version: 2.0.0
// Response Utility Functions
// Standardized API response formats

// =============================================================================
// SUCCESS RESPONSE
// =============================================================================

function successResponse(res, data, message = 'Success', statusCode = 200) {
    return res.status(statusCode).json({
        success: true,
        data: data,
        message: message
    });
}

// =============================================================================
// ERROR RESPONSE
// =============================================================================

function errorResponse(res, message, code = 'ERROR', statusCode = 400, details = null) {
    const response = {
        success: false,
        error: {
            code: code,
            message: message
        }
    };
    
    if (details) {
        response.error.details = details;
    }
    
    return res.status(statusCode).json(response);
}

// =============================================================================
// VALIDATION ERROR RESPONSE
// =============================================================================

function validationErrorResponse(res, errors) {
    return res.status(400).json({
        success: false,
        error: {
            code: 'VALIDATION_ERROR',
            message: 'Validation failed',
            details: errors
        }
    });
}

// =============================================================================
// UNAUTHORIZED RESPONSE
// =============================================================================

function unauthorizedResponse(res, message = 'Unauthorized access') {
    return res.status(401).json({
        success: false,
        error: {
            code: 'AUTH_UNAUTHORIZED',
            message: message
        }
    });
}

// =============================================================================
// FORBIDDEN RESPONSE
// =============================================================================

function forbiddenResponse(res, message = 'Access forbidden') {
    return res.status(403).json({
        success: false,
        error: {
            code: 'AUTH_FORBIDDEN',
            message: message
        }
    });
}

// =============================================================================
// NOT FOUND RESPONSE
// =============================================================================

function notFoundResponse(res, resource = 'Resource') {
    return res.status(404).json({
        success: false,
        error: {
            code: 'RESOURCE_NOT_FOUND',
            message: `${resource} not found`
        }
    });
}

// =============================================================================
// SERVER ERROR RESPONSE
// =============================================================================

function serverErrorResponse(res, error, isDevelopment = false) {
    return res.status(500).json({
        success: false,
        error: {
            code: 'SERVER_ERROR',
            message: isDevelopment ? error.message : 'An internal server error occurred',
            ...(isDevelopment && { stack: error.stack })
        }
    });
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    successResponse,
    errorResponse,
    validationErrorResponse,
    unauthorizedResponse,
    forbiddenResponse,
    notFoundResponse,
    serverErrorResponse
};

