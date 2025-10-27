// Version: 2.0.0
// PM2 Ecosystem Configuration
// Process management for HR Leave Management System

module.exports = {
  apps: [{
    name: 'hr-leave-system',
    script: './backend/server.js',
    
    // Instances
    instances: 1,
    exec_mode: 'fork', // Use 'cluster' for multiple instances
    
    // Auto-restart configuration
    autorestart: true,
    watch: false, // Set to true for development
    max_memory_restart: '500M',
    
    // Environment variables
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    
    env_development: {
      NODE_ENV: 'development',
      PORT: 3000
    },
    
    // Logging
    error_file: './backend/logs/pm2-error.log',
    out_file: './backend/logs/pm2-out.log',
    log_file: './backend/logs/pm2-combined.log',
    time: true,
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
    
    // Advanced features
    max_restarts: 10,
    min_uptime: '10s',
    listen_timeout: 3000,
    kill_timeout: 5000,
    
    // Cron restart (optional - restart every day at 3 AM)
    // cron_restart: '0 3 * * *',
    
    // Source map support
    source_map_support: true,
    
    // Instance var (for cluster mode)
    instance_var: 'INSTANCE_ID'
  }]
};

