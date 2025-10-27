// Version: 2.0.0
// HR Leave Management System - Main Server File
// Node.js + Express Backend

require('dotenv').config();
const express = require('express');
const path = require('path');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

// Import utilities
const logger = require('./utils/logger');
const { testDatabaseConnection } = require('./config/database');

// Import routes
const authRoutes = require('./routes/authRoutes');
const leaveRoutes = require('./routes/leaveRoutes');
const profileRoutes = require('./routes/profileRoutes');
const adminRoutes = require('./routes/adminRoutes');
const calendarRoutes = require('./routes/calendarRoutes');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// =============================================================================
// MIDDLEWARE CONFIGURATION
// =============================================================================

// Security middleware
app.use(helmet({
    contentSecurityPolicy: false, // Allow inline scripts for Vue development
}));

// CORS configuration
app.use(cors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Compression middleware
app.use(compression());

// General rate limiting
const generalLimiter = rateLimit({
    windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
    max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100,
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
});
app.use('/api/', generalLimiter);

// Request logging middleware
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`, {
        ip: req.ip,
        userAgent: req.get('user-agent')
    });
    next();
});

// =============================================================================
// API ROUTES
// =============================================================================

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({
        success: true,
        message: 'HR Leave Management System API is running',
        timestamp: new Date().toISOString(),
        version: '2.0.0'
    });
});

// Authentication routes
app.use('/api/auth', authRoutes);

// Employee leave routes
app.use('/api/leaves', leaveRoutes);

// Profile routes
app.use('/api/profile', profileRoutes);

// Calendar routes
app.use('/api/calendar', calendarRoutes);

// Admin routes
app.use('/api/admin', adminRoutes);

// =============================================================================
// SERVE FRONTEND (PRODUCTION)
// =============================================================================

// Serve static files from Vue build
const frontendPath = path.join(__dirname, '../frontend/dist');
app.use(express.static(frontendPath));

// Catch-all route for Vue Router (SPA)
app.get('*', (req, res) => {
    res.sendFile(path.join(frontendPath, 'index.html'));
});

// =============================================================================
// ERROR HANDLING
// =============================================================================

// 404 handler for API routes
app.use('/api/*', (req, res) => {
    res.status(404).json({
        success: false,
        error: {
            code: 'ROUTE_NOT_FOUND',
            message: `API endpoint not found: ${req.method} ${req.path}`
        }
    });
});

// Global error handler
app.use((err, req, res, next) => {
    logger.error('Unhandled error:', {
        error: err.message,
        stack: err.stack,
        path: req.path,
        method: req.method
    });

    res.status(err.status || 500).json({
        success: false,
        error: {
            code: err.code || 'SERVER_ERROR',
            message: process.env.NODE_ENV === 'production' 
                ? 'An internal server error occurred'
                : err.message
        }
    });
});

// =============================================================================
// START SERVER
// =============================================================================

async function startServer() {
    try {
        // Test database connection
        logger.info('Testing database connection...');
        const dbConnected = await testDatabaseConnection();
        
        if (!dbConnected) {
            logger.error('Failed to connect to database. Server will not start.');
            process.exit(1);
        }
        
        logger.info('Database connection successful');
        
        // Start Express server
        app.listen(PORT, HOST, () => {
            logger.info('=============================================================================');
            logger.info(`HR Leave Management System - Backend Server`);
            logger.info(`Version: 2.0.0`);
            logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`);
            logger.info(`Server running on: http://${HOST}:${PORT}`);
            logger.info(`API Base URL: http://${HOST}:${PORT}/api`);
            logger.info(`Health Check: http://${HOST}:${PORT}/api/health`);
            logger.info('=============================================================================');
        });
        
    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);
    process.exit(1);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
    process.exit(1);
});

// Graceful shutdown
process.on('SIGTERM', () => {
    logger.info('SIGTERM signal received: closing HTTP server');
    server.close(() => {
        logger.info('HTTP server closed');
        process.exit(0);
    });
});

process.on('SIGINT', () => {
    logger.info('SIGINT signal received: closing HTTP server');
    process.exit(0);
});

// Start the server
startServer();

