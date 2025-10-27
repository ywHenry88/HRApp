# HR Leave Management System

**Version:** 2.4.3  
**Technology Stack:** Node.js + Express + Vue 3 + SQL Server 2012  
**Deployment:** Windows Local Network  
**Target Users:** ~10 users  
**Languages:** English / Traditional Chinese (繁體中文)

## 🆕 What's New in v2.4

**Employee Dashboard Improvements (v2.4.3):**
- Changed to show "Applied" days as the prominent number (more accurate and less confusing)
- Annual Leave: Shows 5 days Applied (instead of 6 remaining)
- Sick Leave: Shows 1 day Applied (instead of 3 remaining)
- "Remaining" calculations shown under each breakdown method for clarity

**Dashboard Refinements (v2.4.2):**
- Smaller font sizes for policy and notes (7px)
- Larger, more visible icons (48×48px with text-lg)

**Dashboard Updates (v2.4.1):**
- Show calculation for estimate: "11 + 7.8 = 18.8 days" for transparency
- Blue borders for Annual and Sick leave cards (visual grouping)
- Policy box simplified: removed border, smaller font

**Dashboard Redesign (v2.4.0):**
- Enhanced readability with dark text on white backgrounds (improved name visibility)
- Consistent data display across all leave types (Applied/Remaining format)
- Unified visual design with left border accent cards
- Complete bilingual support with all Chinese translations
- Streamlined layout by removing redundant Quick Actions
- Professional and organized mobile-first design

**What's New in v2.3:**
- Complete dashboard redesign for employee module
- Cleaner header with integrated date display
- Better organized leave summary section
- Enhanced visual hierarchy and spacing

**What's New in v2.2:**
- **Payment in Lieu (以薪代假)** - Admin can approve leave without deducting leave balance

**What's New in v2.1:**
- Real-time Hong Kong public holidays fetched from official source
  - English: `https://www.1823.gov.hk/common/ical/en.json`
  - Traditional Chinese: `https://www.1823.gov.hk/common/ical/tc.json`
- Demo UI pages updated to highlight holidays dynamically (EN/ZH switch)
- Database: `tb_Holidays` extended with `SourceUID`, `SourceProvider`, `LastSyncedAt`
- New TVP `dbo.HolidayImportType` and `sp_UpsertHolidays_TVP` for bulk sync

---

## 📋 Project Overview

A comprehensive leave management system designed for small to medium-sized organizations. Features mobile-responsive employee interface and desktop admin interface with bilingual support.

### Key Features

✅ **Employee Features (v2.0):**
- Submit leave requests with **consecutive or non-consecutive dates**
- Multi-date selection with calendar picker
- View leave balance in real-time
- Track request history and status (including partial approvals)
- Edit/cancel pending requests
- View team calendar with enhanced views
- **Blackout dates** are automatically blocked
- Bilingual interface (EN/ZH)

✅ **Admin Features (v2.0):**
- Approve/reject leave requests (no date-level modification)
- **Manage blackout dates** - configure dates employees cannot apply
- **Compensatory Leave module** - grant decimal-day compensatory leave to employees [NEW]
- Auto-generate blackout dates (day before holidays)
- Manage employees and departments
- Configure leave types and policies
- Enhanced team calendar (traditional + employee grid views)
- Generate utilization reports
- Dashboard with key metrics
- Desktop-optimized interface

---

## 🏗️ Project Structure

```
HRApp1.0/
├── database/                    # SQL Server database scripts
│   ├── 01_create_schema.sql         # Database schema v2.0 (base tables)
│   ├── 02_seed_data.sql             # Initial data with 10 users
│   ├── 03_create_views.sql          # Core reporting views (v2.0-aligned)
│   ├── 04_create_stored_procedures.sql # Core procedures/functions
│   ├── 05_rules_ddl.sql             # Rules support DDL (hire date, sick paid, comp grants, carry-forward)
│   ├── 06_computed_views.sql        # Computed views (AnnualEntitlement, SickBalance, LeaveTotals)
│   └── 07_business_procedures.sql   # Business procedure stubs (year rollover, comp grants, approve/submit)
│
├── backend/                     # Node.js + Express API
│   ├── config/                       # Database configuration
│   ├── controllers/                  # Business logic
│   ├── middleware/                   # Authentication & validation
│   ├── routes/                       # API route definitions
│   ├── utils/                        # Logging & responses
│   ├── logs/                         # Application logs
│   ├── package.json                  # Dependencies
│   ├── server.js                     # Main server file
│   └── env.example.txt               # Environment template
│
├── frontend/                    # Vue 3 application
│   ├── src/
│   │   ├── views/                    # Page components
│   │   ├── components/               # Reusable components
│   │   ├── stores/                   # Pinia state management
│   │   ├── router/                   # Vue Router configuration
│   │   ├── services/                 # API service layer
│   │   ├── i18n/                     # Internationalization
│   │   ├── assets/                   # CSS and images
│   │   ├── App.vue                   # Root component
│   │   └── main.js                   # Application entry
│   ├── public/                       # Static assets
│   ├── index.html                    # HTML template
│   ├── package.json                  # Dependencies
│   ├── vite.config.js                # Vite configuration
│   ├── tailwind.config.js            # Tailwind CSS config
│   └── postcss.config.js             # PostCSS config
│
├── UI/                          # Original HTML prototype (reference)
│   ├── pages/                        # Prototype HTML pages
│   ├── css/                          # Prototype styles
│   └── js/                           # Prototype JavaScript
│
├── ecosystem.config.js          # PM2 process manager config
├── PRD.md                       # Product Requirements Document
├── DEPLOYMENT_GUIDE.md          # Complete deployment instructions
├── IMPLEMENTATION_STATUS.md     # Current implementation status
└── README.md                    # This file
```

---

## 🚀 Quick Start Guide

### Prerequisites

- Windows 10/11 or Windows Server 2016+
- Node.js v18.0.0 or higher
- SQL Server 2012 or higher
- 4GB RAM minimum (8GB recommended)

### Installation Steps

#### 1. Database Setup

```sql
-- Run these scripts in SQL Server Management Studio (SSMS):
1. database/01_create_schema.sql
2. database/02_seed_data.sql
3. database/03_create_views.sql
4. database/04_create_stored_procedures.sql
5. database/05_rules_ddl.sql
6. database/06_computed_views.sql
7. database/07_business_procedures.sql
```

### Rebuild Database From Scratch (Clean Init)

Run the scripts above in order, then initialize Year Opening Balances for the current year (unlimited carry-forward):

```sql
USE HRLeaveSystemDB;
EXEC dbo.usp_RecalcYearOpeningBalances @Year = YEAR(GETDATE());
```

Optional: prepare next year’s opening balances (dry-run):

```sql
EXEC dbo.usp_RecalcYearOpeningBalances @Year = YEAR(GETDATE()) + 1;
```

#### 2. Backend Setup

```cmd
cd backend
npm install
copy env.example.txt .env
notepad .env  # Configure database connection and JWT secret
```

Update `.env` file:
```env
DB_SERVER=localhost
DB_NAME=HRLeaveSystemDB
DB_USER=hrapp_user
DB_PASSWORD=YourPassword
JWT_SECRET=<generate_random_32_char_string>
```

#### 3. Frontend Setup

```cmd
cd frontend
npm install
npm run build
```

#### 4. Start Application

**Development Mode:**
```cmd
cd backend
npm run dev
```

**Production Mode (with PM2):**
```cmd
cd C:\HRApp1.0
npm install -g pm2
pm2 start ecosystem.config.js
pm2 save
```

#### 5. Access Application

- **Local:** http://localhost:3000
- **Network:** http://[YOUR_IP]:3000
- **Mobile:** http://[YOUR_IP]:3000 (same Wi-Fi)

---

## 👥 Default Credentials

**⚠️ CHANGE THESE IMMEDIATELY AFTER FIRST LOGIN!**

### Admin User
- Username: `admin`
- Password: `Admin@123`

### Employee Users
- Usernames: `jmlin`, `jcxu`, `gfzeng`, `zyzhu`, `djdeng`, `jhlee`, `zxwang`, `yclin`, `bwlin`
- Password (all): `Employee@123`

---

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user
- `POST /api/auth/change-password` - Change password

### Employee Endpoints
- `GET /api/leaves/balance` - Get leave balance
- `POST /api/leaves/request` - Submit leave request (multi-date support)
- `GET /api/leaves/history` - Get leave history
- `PUT /api/leaves/request/:id` - Update request
- `DELETE /api/leaves/request/:id` - Cancel request
- `GET /api/profile` - Get user profile
- `PUT /api/profile` - Update profile
- `GET /api/calendar` - Get team calendar
- `GET /api/leaves/blackout-dates` - Get blackout dates **[NEW v2.0]**

### Admin Endpoints
- `GET /api/admin/dashboard/stats` - Dashboard statistics
- `GET /api/admin/leaves/pending` - Pending approvals
- `PUT /api/admin/leaves/approve/:id` - Approve request (partial approval support) **[ENHANCED v2.0]**
- `PUT /api/admin/leaves/reject/:id` - Reject request
- `GET /api/admin/employees` - List employees
- `POST /api/admin/employees` - Create employee
- `PUT /api/admin/employees/:id` - Update employee
- `GET /api/admin/reports/leave-utilization` - Utilization report
- `GET /api/admin/blackout-dates` - List blackout dates **[NEW v2.0]**
- `POST /api/admin/blackout-dates` - Add blackout date **[NEW v2.0]**
- `DELETE /api/admin/blackout-dates/:id` - Remove blackout date **[NEW v2.0]**
- `POST /api/admin/blackout-dates/generate` - Auto-generate from holidays **[NEW v2.0]**

Full API documentation in [PRD.md](PRD.md)

---

## 🛠️ Development

### Backend Development

```cmd
cd backend
npm run dev
```

Server starts at http://localhost:3000

### Frontend Development

```cmd
cd frontend
npm run dev
```

Development server starts at http://localhost:8080

### Build for Production

```cmd
cd frontend
npm run build
```

Builds to `frontend/dist/` directory

---

## 🔒 Security Features

- JWT token authentication (24-hour expiry)
- Password hashing with bcryptjs (10 salt rounds)
- Role-based access control (Employee/Admin)
- Input validation on all endpoints
- SQL injection prevention (parameterized queries)
- XSS protection (helmet middleware)
- Rate limiting (100 req/min, 5 login attempts/15min)
- Audit logging for sensitive operations

---

## 🌐 Network Configuration

### Windows Firewall

1. Open Windows Firewall: `wf.msc`
2. Create inbound rule for port 3000
3. Allow TCP connections
4. Apply to all profiles

### Access from Mobile Devices

1. Find server IP: `ipconfig`
2. Connect mobile to same Wi-Fi
3. Open browser: `http://[SERVER_IP]:3000`
4. Login and use

---

## 📊 Database Schema (v2.0)

### Core Tables
- **tb_Users** - User accounts and authentication (+ HireDate, SickLeavePaidDays)
- **tb_Departments** - Department information
- **tb_LeaveTypes** - Leave type definitions (+ optional rules in tb_LeaveTypeRules)
- **tb_LeaveBalances** - Employee leave balances
- **tb_LeaveRequests** - Leave request records (ENHANCED with partial approval support)
- **tb_LeaveRequestDates** - Individual date tracking **[NEW v2.0]**
- **tb_Holidays** - Public holidays
- **tb_BlackoutDates** - Dates users cannot apply for leave **[NEW v2.0]**
- **tb_AuditLog** - Audit trail
- **tb_CompensatoryGrants** - Admin-issued compensatory leave grants **[NEW]**
- **tb_YearOpeningBalances** - Carry-forward snapshots per user/year **[NEW]**
- **tb_LeaveTypeRules** - Parameterization for Annual leave rules (base/increment/max); contractual ladders not used

### Views
- v_UserProfile
- v_LeaveBalance
- v_LeaveRequestDetail
- v_TeamCalendar
- v_PendingApprovals
- v_DashboardStats
- v_LeaveUtilization
- v_AnnualEntitlement **[NEW]**
- v_SickBalance **[NEW]**
- v_LeaveTotals **[NEW]**

### Stored Procedures & Functions
- **fn_IsBlackoutDate** - Check if date is blackout **[NEW v2.0]**
- **fn_CalculateWorkingDays** - Calculate working days **[NEW v2.0]**
- **sp_SubmitLeaveRequest** - Submit with multi-date support (ENHANCED)
- **sp_ApproveLeaveRequest** - Partial approval support (ENHANCED)
- **sp_RejectLeaveRequest** - Reject leave request
- **sp_CancelLeaveRequest** - Cancel leave request
- **sp_InitializeLeaveBalances** - Initialize yearly balances
- **sp_GenerateBlackoutDates** - Auto-generate blackout dates **[NEW v2.0]**
- **sp_GetLeaveRequestDetails** - Get complete request details **[NEW v2.0]**
- **usp_RecalcYearOpeningBalances** - Rules: carry-forward snapshot **[NEW]**
- **usp_GrantCompensatoryLeave** - Rules: add compensatory grants **[NEW]**
- **usp_SubmitLeaveRequest** - Stub for submission **[NEW]**
- **usp_ApproveLeaveRequest** - Stub for approval/allocation **[NEW]**

---

## 📱 Responsive Design

### Mobile (Employee Interface)
- Max width: 500px
- Bottom navigation bar
- Touch-optimized buttons (44x44px minimum)
- Swipe gestures supported
- Mobile-first approach

### Desktop (Admin Interface)
- Min width: 1024px
- Sidebar navigation
- Data tables with sorting/filtering
- Multi-column layouts
- Desktop-optimized workflows

---

## 🌍 Bilingual Support

### Supported Languages
- English (EN)
- Traditional Chinese (繁體中文)

### Implementation
- Vue I18n plugin
- Translation files: `src/i18n/en.json`, `src/i18n/zh.json`
- Language toggle in header
- Preference saved in localStorage
- Database stores bilingual field names

---

## 🔧 Maintenance

### Daily Tasks
- Monitor application logs: `pm2 logs`
- Check application status: `pm2 status`

### Weekly Tasks
- Backup database
- Review error logs
- Clear old logs if needed

### Monthly Tasks
- Update npm packages
- Review audit logs
- Check disk space
- Security review

### Backup Strategy
```sql
-- Daily backup
BACKUP DATABASE HRLeaveSystemDB 
TO DISK = 'C:\Backups\HRLeaveSystemDB_Daily.bak'
WITH INIT;
```

---

## 🐛 Troubleshooting

### Cannot connect to database
1. Verify SQL Server is running
2. Check connection string in `.env`
3. Verify SQL Server Authentication enabled
4. Test with SSMS using same credentials

### Port 3000 already in use
```cmd
netstat -ano | findstr :3000
taskkill /PID [PID] /F
```

### Frontend shows white screen
```cmd
cd frontend
npm run build
pm2 restart hr-leave-system
```

### Login fails
```sql
-- Reset admin password
UPDATE tb_Users 
SET PasswordHash = '$2a$10$8YzqvT7H.qzNc3b3jK9eguXKHQWTh0nLQF5GxKV4xK5RZ8PJ5Xnmi'
WHERE Username = 'admin'
```

More troubleshooting in [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)

---

## 📝 Documentation

- **[README.md](README.md)** - This file (Quick start & overview)
- **[RULES.md](RULES.md)** - Core leave logic (authoritative)
  - Annual Leave: no expiry, unlimited carry-forward; statutory 7→14 days ladder; split/pay-in-lieu handled case-by-case by Admin (no auto-enforcement)
- **[docs/AnnualLeave_Examples_TC.md](docs/AnnualLeave_Examples_TC.md)** - Bilingual examples (balances, carry-forward, pro‑rata vs by‑year)
  - Includes partial usage and multi-year carry-forward scenarios
- **[PRD.md](PRD.md)** - Complete product requirements
- **[DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)** - Step-by-step deployment
- **[IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md)** - v2.0 implementation guide **[NEW]**
- **[IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)** - Current progress
- **API Documentation** - See PRD.md Section 5

---

## 🎨 Design System

### Colors
- Primary: `#00AFB9` (Teal)
- Annual Leave: `#00AFB9`
- Sick Leave: `#FF6B6B`
- Personal Leave: `#FFD166`
- Study Leave: `#06D6A0`

### Typography
- Font: System font stack (Segoe UI on Windows)
- Base size: 16px
- Headings: 700 weight

### Components
- Buttons: Rounded (8px), shadow on hover
- Cards: White background, shadow
- Forms: Clear labels, inline validation
- Tables: Sortable, filterable, paginated

---

## 📋 v2.0 Implementation Status

### ✅ Completed
- Database schema with new tables (tb_LeaveRequestDates, tb_BlackoutDates)
- Enhanced stored procedures with partial approval logic
- Blackout date validation functions
- Multi-date submission logic
- Database migration scripts
- Documentation (IMPLEMENTATION_GUIDE.md)

### 🔄 In Progress (See IMPLEMENTATION_GUIDE.md)
- Multi-date calendar picker UI
- Enhanced team calendar views (employee grid view)
- Blackout dates management UI (admin)
- Enhanced approval UI with date selection
- Backend API updates for new endpoints

### 📚 Reference
See [IMPLEMENTATION_GUIDE.md](IMPLEMENTATION_GUIDE.md) for complete implementation details, code samples, and UI specifications.

---

## 🔜 Future Enhancements

### Phase 3 Features
- Email notifications
- Native mobile apps (iOS/Android)
- Advanced reporting with charts
- Leave delegation
- Active Directory integration
- Bulk operations
- Document attachments
- Leave accrual analytics and dashboards
- Department-level admins
- Workflow customization

---

## 📄 License

This project is proprietary software developed for internal use.

---

## 💬 Support

For issues or questions:
1. Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
2. Review [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md)
3. Check application logs: `pm2 logs hr-leave-system`
4. Verify database connectivity
5. Contact system administrator

---

## 📞 Contact

**System Administrator:** [Contact Details]  
**HR Department:** [Contact Details]  
**IT Support:** [Contact Details]

---

**Project Version:** 2.1.0  
**Last Updated:** October 23, 2025  
**Developed By:** Development Team

---

## ⚡ Technology Stack Details

### Backend
- **Runtime:** Node.js v18+
- **Framework:** Express.js 4.18+
- **Database:** SQL Server 2012+
- **Authentication:** JWT (jsonwebtoken)
- **Password Hashing:** bcryptjs
- **Logging:** Winston
- **Security:** Helmet, CORS, express-validator
- **Process Management:** PM2

### Frontend
- **Framework:** Vue 3 (Composition API)
- **Build Tool:** Vite 5
- **State Management:** Pinia 2
- **Routing:** Vue Router 4
- **HTTP Client:** Axios
- **Internationalization:** Vue I18n 9
- **Styling:** Tailwind CSS 3
- **Icons:** Font Awesome 6

### Database
- **Server:** SQL Server 2012+
- **Tables:** 7 core tables
- **Views:** 7 reporting views
- **Stored Procedures:** 6 business logic procedures
- **Indexing:** Optimized for performance

---

**🚀 Ready to Deploy!** Follow [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for complete setup instructions.

