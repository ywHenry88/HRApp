// Version: 2.0.0
// Database Configuration and Connection Pool
// SQL Server connection using mssql package

const sql = require('mssql');
const logger = require('../utils/logger');

// =============================================================================
// DATABASE CONFIGURATION
// All parameters loaded from environment variables
// =============================================================================

const dbConfig = {
    server: process.env.DB_SERVER || 'localhost',
    port: parseInt(process.env.DB_PORT) || 1433,
    database: process.env.DB_NAME || 'HRLeaveSystemDB',
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    options: {
        encrypt: process.env.DB_ENCRYPT === 'true',
        trustServerCertificate: process.env.DB_TRUST_SERVER_CERTIFICATE === 'true',
        enableArithAbort: true,
        connectionTimeout: 30000,
        requestTimeout: 30000,
    },
    pool: {
        max: 10,
        min: 0,
        idleTimeoutMillis: 30000
    }
};

// Connection pool
let pool = null;

// =============================================================================
// GET CONNECTION POOL
// Returns existing pool or creates new one
// =============================================================================

async function getPool() {
    try {
        if (pool && pool.connected) {
            return pool;
        }

        logger.info('Creating new database connection pool...');
        pool = await sql.connect(dbConfig);
        
        logger.info('Database connection pool created successfully');
        
        // Handle pool errors
        pool.on('error', err => {
            logger.error('Database pool error:', err);
        });
        
        return pool;
        
    } catch (error) {
        logger.error('Error creating database pool:', error);
        throw error;
    }
}

// =============================================================================
// TEST DATABASE CONNECTION
// Test if database connection works
// =============================================================================

async function testDatabaseConnection() {
    try {
        const testPool = await getPool();
        const result = await testPool.request().query('SELECT 1 AS test');
        
        if (result.recordset && result.recordset[0].test === 1) {
            logger.info('Database connection test successful');
            return true;
        }
        
        return false;
        
    } catch (error) {
        logger.error('Database connection test failed:', {
            error: error.message,
            code: error.code
        });
        return false;
    }
}

// =============================================================================
// EXECUTE QUERY
// Execute a SQL query with parameters
// =============================================================================

async function executeQuery(query, params = {}) {
    try {
        const currentPool = await getPool();
        const request = currentPool.request();
        
        // Add parameters to request
        Object.keys(params).forEach(key => {
            request.input(key, params[key]);
        });
        
        const result = await request.query(query);
        return result;
        
    } catch (error) {
        logger.error('Query execution error:', {
            error: error.message,
            query: query.substring(0, 100) + '...' // Log first 100 chars
        });
        throw error;
    }
}

// =============================================================================
// EXECUTE STORED PROCEDURE
// Execute a stored procedure with parameters
// =============================================================================

async function executeStoredProcedure(procedureName, params = {}, outputs = {}) {
    try {
        const currentPool = await getPool();
        const request = currentPool.request();
        
        // Add input parameters
        Object.keys(params).forEach(key => {
            const param = params[key];
            if (param.type && param.value !== undefined) {
                request.input(key, param.type, param.value);
            } else {
                request.input(key, param);
            }
        });
        
        // Add output parameters
        Object.keys(outputs).forEach(key => {
            const output = outputs[key];
            request.output(key, output.type, output.value);
        });
        
        const result = await request.execute(procedureName);
        return result;
        
    } catch (error) {
        logger.error('Stored procedure execution error:', {
            error: error.message,
            procedure: procedureName
        });
        throw error;
    }
}

// =============================================================================
// CLOSE CONNECTION POOL
// Close the connection pool (used during shutdown)
// =============================================================================

async function closePool() {
    try {
        if (pool) {
            await pool.close();
            pool = null;
            logger.info('Database connection pool closed');
        }
    } catch (error) {
        logger.error('Error closing database pool:', error);
    }
}

// =============================================================================
// EXPORTS
// =============================================================================

module.exports = {
    sql,
    getPool,
    testDatabaseConnection,
    executeQuery,
    executeStoredProcedure,
    closePool
};

