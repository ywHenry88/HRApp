# HR Leave Management System - Deployment Guide

**Version:** 2.0.0  
**Date:** October 16, 2025

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Database Setup](#database-setup)
3. [Backend Setup](#backend-setup)
4. [Frontend Setup](#frontend-setup)
5. [PM2 Configuration](#pm2-configuration)
6. [Network Configuration](#network-configuration)
7. [Testing](#testing)
8. [Troubleshooting](#troubleshooting)
9. [Maintenance](#maintenance)

---

## Prerequisites

### Hardware Requirements
- **CPU:** 2 cores minimum (4 cores recommended)
- **RAM:** 4GB minimum (8GB recommended)
- **Disk:** 50GB available space (SSD preferred)
- **Network:** 1Gbps LAN connection

### Software Requirements
- **OS:** Windows 10/11 Pro or Windows Server 2016+
- **Node.js:** v18.0.0 or higher (LTS recommended)
- **SQL Server:** 2012 or higher
- **Git:** (Optional, for version control)

---

## Database Setup

### Step 1: Install SQL Server

1. If not already installed, download and install SQL Server 2012 or higher
2. Enable SQL Server Authentication (Mixed Mode)
3. Remember the SA password

### Step 2: Create Database User

Open SQL Server Management Studio (SSMS) and run:

```sql
-- Create login
CREATE LOGIN hrapp_user WITH PASSWORD = 'YourSecurePassword123!';

-- Create user in HRLeaveSystemDB (after database creation)
USE HRLeaveSystemDB;
CREATE USER hrapp_user FOR LOGIN hrapp_user;

-- Grant permissions
ALTER ROLE db_datareader ADD MEMBER hrapp_user;
ALTER ROLE db_datawriter ADD MEMBER hrapp_user;
ALTER ROLE db_ddladmin ADD MEMBER hrapp_user;
GRANT EXECUTE TO hrapp_user;
```

### Step 3: Run Database Scripts

Navigate to the `database` folder and run the scripts in order:

1. **01_create_schema.sql**
   ```
   Open in SSMS
   Execute (F5)
   Verify: 7 tables created
   ```

2. **02_seed_data.sql**
   ```
   Open in SSMS
   Execute (F5)
   Verify: Sample data inserted
   ```

3. **03_create_views.sql**
   ```
   Open in SSMS
   Execute (F5)
   Verify: 7 views created
   ```

4. **04_create_stored_procedures.sql**
5. **05_rules_ddl.sql**
6. **06_computed_views.sql**
7. **07_business_procedures.sql**
   ```
   Open in SSMS
   Execute (F5)
   Verify: 6 stored procedures created
   ```

### Step 4: Verify Database

Run this query to verify setup:

```sql
USE HRLeaveSystemDB;

SELECT 'Tables' as Type, COUNT(*) as Count FROM sys.tables
UNION ALL
SELECT 'Views', COUNT(*) FROM sys.views WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Stored Procedures', COUNT(*) FROM sys.procedures WHERE is_ms_shipped = 0
UNION ALL
SELECT 'Users', COUNT(*) FROM tb_Users
UNION ALL
SELECT 'Departments', COUNT(*) FROM tb_Departments;
```

Expected results (after all scripts):
- Tables: 12+
- Views: 10+
- Stored Procedures: 8+
- Users: 10
- Departments: 6

---

## Backend Setup

### Step 1: Install Node.js

1. Download Node.js LTS from https://nodejs.org/
2. Run installer (accept all defaults)
3. Verify installation:
   ```cmd
   node --version
   npm --version
   ```

### Step 2: Install Backend Dependencies

1. Open Command Prompt as Administrator
2. Navigate to the project directory:
   ```cmd
   cd C:\HRApp1.0
   cd backend
   ```

3. Install dependencies:
   ```cmd
   npm install
   ```

4. Wait for installation to complete (may take 2-5 minutes)

### Step 3: Configure Environment Variables

1. Copy the environment template:
   ```cmd
   copy env.example.txt .env
   ```

2. Edit `.env` file with Notepad:
   ```cmd
   notepad .env
   ```

3. Update the following values:

   ```env
   # Server Configuration
   NODE_ENV=production
   PORT=3000
   HOST=0.0.0.0
   
   # Database Configuration
   DB_SERVER=localhost
   DB_PORT=1433
   DB_NAME=HRLeaveSystemDB
   DB_USER=hrapp_user
   DB_PASSWORD=YourSecurePassword123!
   DB_ENCRYPT=false
   DB_TRUST_SERVER_CERTIFICATE=true
   
   # JWT Authentication (IMPORTANT: Generate a strong secret!)
   JWT_SECRET=<GENERATE_A_RANDOM_32_CHARACTER_STRING>
   JWT_EXPIRES_IN=24h
   
   # Logging
   LOG_LEVEL=info
   
   # CORS
   CORS_ORIGIN=*
   ```

4. To generate a secure JWT secret, run:
   ```cmd
   node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
   ```
   Copy the output and paste it as `JWT_SECRET`

5. Save and close the file

### Step 4: Test Backend

1. Start the backend in development mode:
   ```cmd
   npm run dev
   ```

2. Look for these messages:
   ```
   Database connection successful
   HR Leave Management System - Backend Server
   Server running on: http://0.0.0.0:3000
   ```

3. Test the health endpoint:
   - Open browser
   - Navigate to: `http://localhost:3000/api/health`
   - Should see JSON response with "success": true

4. Stop the server: Press `Ctrl + C`

---

## Frontend Setup

### Step 1: Navigate to Frontend Directory

```cmd
cd C:\HRApp1.0\frontend
```

### Step 2: Install Frontend Dependencies

```cmd
npm install
```

Wait for installation to complete (may take 5-10 minutes)

### Step 3: Configure API URL

1. Edit `frontend/.env` (or create if it doesn't exist):
   ```env
   VITE_API_BASE_URL=http://localhost:3000/api
   ```

2. For network access, use your server's IP:
   ```env
   VITE_API_BASE_URL=http://192.168.1.100:3000/api
   ```

### Step 4: Build Frontend

```cmd
npm run build
```

This creates production files in `frontend/dist` directory

Wait for build to complete (1-3 minutes)

---

## PM2 Configuration

### Step 1: Install PM2 Globally

```cmd
npm install -g pm2
npm install -g pm2-windows-service
```

### Step 2: Start Application with PM2

1. Navigate to project root:
   ```cmd
   cd C:\HRApp1.0
   ```

2. Start the application:
   ```cmd
   pm2 start ecosystem.config.js
   ```

3. Save PM2 configuration:
   ```cmd
   pm2 save
   ```

4. Verify the application is running:
   ```cmd
   pm2 list
   ```

### Step 3: Install as Windows Service

1. Install PM2 as a Windows service:
   ```cmd
   pm2-service-install
   ```

2. During installation, accept defaults:
   - PM2_HOME: Press Enter (uses default)
   - PM2_SERVICE_SCRIPTS: Press Enter
   - PM2_SERVICE_PM2_DIR: Press Enter

3. Start the PM2 service:
   ```cmd
   pm2-service-start
   ```

4. Verify service is running:
   ```cmd
   pm2 list
   ```

### Step 4: PM2 Management Commands

```cmd
# View logs
pm2 logs hr-leave-system

# View logs in real-time
pm2 logs hr-leave-system --lines 100

# Restart application
pm2 restart hr-leave-system

# Stop application
pm2 stop hr-leave-system

# Delete application from PM2
pm2 delete hr-leave-system

# Monitor application
pm2 monit

# Application status
pm2 status
```

---

## Network Configuration

### Step 1: Get Server IP Address

```cmd
ipconfig
```

Look for "IPv4 Address" under your network adapter (e.g., 192.168.1.100)

### Step 2: Configure Windows Firewall

1. Open Windows Firewall:
   - Press `Win + R`
   - Type: `wf.msc`
   - Press Enter

2. Click "Inbound Rules" → "New Rule"

3. Configure rule:
   - Rule Type: Port
   - Protocol: TCP
   - Specific local ports: 3000
   - Action: Allow the connection
   - Profile: Check all (Domain, Private, Public)
   - Name: HR Leave System

4. Click Finish

### Step 3: Test Network Access

1. From another computer on the same network:
   - Open browser
   - Navigate to: `http://[SERVER_IP]:3000`
   - Example: `http://192.168.1.100:3000`

2. From mobile device:
   - Connect to same Wi-Fi network
   - Open mobile browser
   - Navigate to: `http://[SERVER_IP]:3000`

---

## Testing

### Test 1: Health Check

```
URL: http://[SERVER_IP]:3000/api/health
Expected: {"success": true, "message": "..."}
```

### Test 2: Admin Login

1. Navigate to: `http://[SERVER_IP]:3000`
2. Click "Desktop Admin View"
3. Login with:
   - Username: `admin`
   - Password: `Admin@123`
4. Should redirect to Admin Dashboard

### Test 3: Employee Login (Mobile)

1. From mobile device, navigate to: `http://[SERVER_IP]:3000`
2. Click "Mobile Employee View"
3. Login with:
   - Username: `jmlin`
   - Password: `Employee@123`
4. Should redirect to Employee Dashboard

### Test 4: Submit Leave Request

1. Login as employee
2. Click "Request Leave"
3. Fill in form:
   - Leave Type: Annual Leave
   - Start Date: Tomorrow
   - End Date: Day after tomorrow
   - Reason: Test request
4. Submit
5. Should see success message

### Test 5: Approve Leave (Admin)

1. Login as admin
2. Go to "Approve Leaves"
3. Find the test request
4. Click "Approve"
5. Add comments
6. Confirm
7. Should see success message

---

## Troubleshooting

### Problem: Cannot connect to database

**Symptoms:**
- Backend fails to start
- Error: "Failed to connect to database"

**Solutions:**
1. Verify SQL Server is running:
   - Open Services (services.msc)
   - Find "SQL Server (MSSQLSERVER)"
   - Ensure status is "Running"

2. Check connection string in `.env`:
   - Verify DB_SERVER, DB_PORT, DB_NAME
   - Verify DB_USER and DB_PASSWORD
   - Check SQL Server Authentication is enabled

3. Test connection with SSMS:
   - Try to connect with same credentials
   - If fails, password may be wrong

### Problem: Port 3000 already in use

**Symptoms:**
- Error: "EADDRINUSE: address already in use :::3000"

**Solutions:**
1. Find process using port 3000:
   ```cmd
   netstat -ano | findstr :3000
   ```

2. Kill the process:
   ```cmd
   taskkill /PID [PID_NUMBER] /F
   ```

3. Or change PORT in `.env` to different number (e.g., 3001)

### Problem: Frontend shows white screen

**Symptoms:**
- Browser shows blank page
- No errors in browser console

**Solutions:**
1. Verify frontend was built:
   ```cmd
   dir C:\HRApp1.0\frontend\dist
   ```
   Should see index.html and assets folder

2. Rebuild frontend:
   ```cmd
   cd C:\HRApp1.0\frontend
   npm run build
   ```

3. Restart PM2:
   ```cmd
   pm2 restart hr-leave-system
   ```

### Problem: Login fails with "Invalid credentials"

**Symptoms:**
- Correct username/password rejected

**Solutions:**
1. Verify user exists in database:
   ```sql
   SELECT Username, Role, IsActive FROM tb_Users WHERE Username = 'admin'
   ```

2. Reset admin password:
   ```sql
   -- Password: Admin@123
   UPDATE tb_Users 
   SET PasswordHash = '$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi'
   WHERE Username = 'admin'
   ```

3. Check JWT_SECRET is set in `.env`

### Problem: PM2 service not starting after reboot

**Symptoms:**
- Application stops after Windows restart

**Solutions:**
1. Verify PM2 service is installed:
   ```cmd
   sc query PM2
   ```

2. Reinstall PM2 service:
   ```cmd
   pm2-service-uninstall
   pm2-service-install
   ```

3. Ensure configuration is saved:
   ```cmd
   pm2 save
   ```

---

## Maintenance

### Daily Tasks

1. **Monitor logs:**
   ```cmd
   pm2 logs --lines 50
   ```

2. **Check application status:**
   ```cmd
   pm2 status
   ```

### Weekly Tasks

1. **Backup database:**
   ```sql
   BACKUP DATABASE HRLeaveSystemDB 
   TO DISK = 'C:\Backups\HRLeaveSystemDB_Weekly.bak'
   WITH INIT;
   ```

2. **Review error logs:**
   ```cmd
   type C:\HRApp1.0\backend\logs\error.log
   ```

3. **Clear old logs (if needed):**
   ```cmd
   pm2 flush
   ```

### Monthly Tasks

1. **Update Node.js packages:**
   ```cmd
   cd C:\HRApp1.0\backend
   npm outdated
   npm update
   ```

2. **Review audit logs:**
   ```sql
   SELECT TOP 100 * FROM tb_AuditLog 
   ORDER BY Timestamp DESC
   ```

3. **Check disk space:**
   ```cmd
   dir C:\HRApp1.0 /s
   ```

### Security Best Practices

1. **Change default passwords immediately:**
   - Admin user
   - Employee users
   - Database user

2. **Regular backups:**
   - Database: Daily
   - Application files: Weekly
   - Store backups off-server

3. **Keep system updated:**
   - Windows Updates
   - SQL Server patches
   - Node.js LTS versions

4. **Monitor access:**
   - Review login attempts
   - Check for unusual activity
   - Monitor failed authentications

---

## Default Credentials (CHANGE IMMEDIATELY)

### Admin User
- Username: `admin`
- Password: `Admin@123`

### Employee Users
- Usernames: `jmlin`, `jcxu`, `gfzeng`, `zyzhu`, `djdeng`, `jhlee`, `zxwang`, `yclin`, `bwlin`
- Password (all): `Employee@123`

**⚠️ IMPORTANT: Change all passwords on first login!**

---

## Support

For issues or questions:
1. Check this deployment guide
2. Review logs: `pm2 logs hr-leave-system`
3. Check database connectivity
4. Verify firewall settings
5. Contact system administrator

---

**Deployment Guide Version:** 2.0.0  
**Last Updated:** October 16, 2025

