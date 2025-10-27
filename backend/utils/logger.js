// Version: 2.0.0
// Logging Utility using Winston
// Structured logging for the application

const winston = require('winston');
const path = require('path');

// =============================================================================
// WINSTON LOGGER CONFIGURATION
// =============================================================================

const logLevel = process.env.LOG_LEVEL || 'info';
const logDir = path.join(__dirname, '../logs');

// Custom log format
const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
);

// Console format for development
const consoleFormat = winston.format.combine(
    winston.format.colorize(),
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ timestamp, level, message, ...metadata }) => {
        let msg = `${timestamp} [${level}]: ${message}`;
        if (Object.keys(metadata).length > 0) {
            msg += ` ${JSON.stringify(metadata)}`;
        }
        return msg;
    })
);

// Create logger instance
const logger = winston.createLogger({
    level: logLevel,
    format: logFormat,
    defaultMeta: { service: 'hr-leave-system' },
    transports: [
        // Error log file
        new winston.transports.File({
            filename: process.env.LOG_FILE_ERROR || path.join(logDir, 'error.log'),
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        
        // Combined log file
        new winston.transports.File({
            filename: process.env.LOG_FILE_COMBINED || path.join(logDir, 'combined.log'),
            maxsize: 5242880, // 5MB
            maxFiles: 5,
        }),
        
        // Console output
        new winston.transports.Console({
            format: consoleFormat
        })
    ],
    exitOnError: false
});

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = logger;

