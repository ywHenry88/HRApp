# Database Alignment Summary
**Version:** 2.1.0  
**Date:** October 27, 2025  
**Database:** HRLeaveSystemDB (SQL Server)

## Overview
This document summarizes the alignment between the UI HTML prototype and the actual SQL Server database structure and data.

## Changes Made

### 1. Employee Data Alignment
**Source:** `tb_Users` table from SQL Server  
**Total Active Employees:** 49

#### Key Changes:
- Replaced all hardcoded employee data with real SQL Server data
- Updated staff codes to match database (e.g., ADMIN001, L003, L006, T012, T013, T016)
- Removed fictional employees (e.g., 林劍明/L888, 徐潔琛/E102, etc.)
- All employee data now matches SQL Server column data types:
  - `StaffCode`: NVARCHAR(40) - Primary Key
  - `EName`, `CName`: NVARCHAR(100)
  - `Email`: NVARCHAR(100)
  - `DepartmentID`: NVARCHAR(10) - Codes: TRANS, WAREH, OFFICE
  - `Position`: NVARCHAR(50)
  - `Role`: NVARCHAR(20) - Values: Admin, Employee
  - `Mobile`: NVARCHAR(50)
  - `EmployType`: NVARCHAR(50)
  - `IsActive`: BIT

### 2. Department Code Mapping
**Source:** `tb_Users.DepartmentID` field

| Database Code | Display Name |
|--------------|-------------|
| TRANS | Transportation |
| WAREH | Warehouse |
| OFFICE | Office |

### 3. Leave Types
**Source:** `tb_LeaveTypes` table

| LeaveTypeID | Name (EN) | Name (ZH) | Default Days | Color | Icon |
|------------|-----------|-----------|--------------|-------|------|
| 1 | Annual Leave | 年假 | 20 | #00AFB9 | calendar-alt |
| 2 | Sick Leave | 病假 | 10 | #FF6B6B | procedures |
| 3 | Personal Leave | 個人假 | 5 | #FFD166 | user-clock |
| 4 | Study Leave | 進修假 | 2 | #06D6A0 | book |

**Data Types:**
- `LeaveTypeID`: INT IDENTITY(1,1)
- `LeaveTypeName_EN`, `LeaveTypeName_ZH`: NVARCHAR(50)
- `DefaultDaysPerYear`: DECIMAL(5,1)
- `ColorCode`: NVARCHAR(7)
- `IconName`: NVARCHAR(50)
- `RequiresApproval`: BIT

### 4. Leave Balances
**Source:** `tb_LeaveBalances` table  
**Current State:** Only ADMIN001 has leave balance data (Year 2025)

**Data Types:**
- `StaffCode`: NVARCHAR(40)
- `LeaveTypeID`: INT
- `Year`: INT
- `TotalDays`, `UsedDays`: DECIMAL(5,1)
- `RemainingDays`: COMPUTED COLUMN (TotalDays - UsedDays)

**Note:** Other employees show 0/0 balances as they have no data in `tb_LeaveBalances` table.

### 5. Public Holidays
**Source:** `tb_Holidays` table  
**Year:** 2025  
**Count:** 17 Hong Kong public holidays

**Data Types:**
- `HolidayDate`: DATE
- `HolidayName_EN`, `HolidayName_ZH`: NVARCHAR(100)
- `Year`: INT
- `IsActive`: BIT

### 6. Leave Requests
**Source:** `tb_LeaveRequests` and `tb_LeaveRequestDates` tables  
**Current State:** No leave request data in database

**Enhanced Schema (v2.0):**
- Support for consecutive and non-consecutive leave dates
- `RequestedDaysCount`: INT - Count of requested working days
- `ApprovedDaysCount`: INT - Count of approved working days
- `PartialApproval`: BIT - Indicates partial approval
- Status values: 'Pending', 'Approved', 'PartiallyApproved', 'Rejected', 'Cancelled'

### 7. Blackout Dates
**Source:** `tb_BlackoutDates` table  
**Current State:** No blackout dates configured

**Data Types:**
- `BlackoutDate`: DATE
- `Reason_EN`, `Reason_ZH`: NVARCHAR(200)
- `IsActive`: BIT
- `CreatedByStaffCode`: NVARCHAR(40)

## Files Modified

### Core Data File
1. **`UI/js/db-data.js`** (NEW)
   - Centralized SQL Server data repository
   - Contains all real employee, leave type, and holiday data
   - Helper functions for data access
   - Aligned with SQL Server data types

### Admin Pages
1. **`UI/pages/admin/manage-employees.html`**
   - Updated with 49 real employees from SQL Server
   - Removed employee editing features (view-only mode)
   - Updated department filters to show SQL codes (TRANS, WAREH, OFFICE)
   - Updated employee count: 48 → 49

2. **`UI/pages/admin/dashboard.html`**
   - Updated total employees: 48 → 49
   - Removed hardcoded sample leave requests (no data in DB)
   - Comments indicate data should come from SQL Server

3. **`UI/index.html`**
   - Updated demo credentials to real staff codes:
     - Admin: ADMIN001 (System Administrator)
     - Employee: L003 (Wong Pak Kun / 黃柏根)
   - Version updated: 2.0.0 → 2.1.0

### Employee Pages (Pending Updates)
The following pages still contain fictional data and need updating:
- `UI/pages/employee/dashboard.html` - Uses fictional L888
- `UI/pages/employee/profile.html` - Uses fictional L888
- `UI/pages/employee/leave-history.html` - Uses fictional data
- `UI/pages/employee/leave-request-multi.html` - Needs real employee data

**Recommended Updates:**
- Change default employee to L003 (Wong Pak Kun)
- Use real staff codes from SQL Server
- Show 0/0 leave balances for employees without data

### Other Admin Pages (Pending Updates)
- `UI/pages/admin/approve-leaves.html` - Update with real employee codes
- `UI/pages/admin/blackout-dates.html` - Currently empty (matching DB)
- `UI/pages/admin/compensatory-leave.html` - Needs real employee data
- `UI/pages/admin/leave-settings.html` - Update with real leave types
- `UI/pages/admin/reports.html` - Update with real employee data

## Database Schema Compliance

### Data Type Mapping
All UI data now correctly maps to SQL Server data types:

| UI Field | SQL Type | Max Length | Nullable |
|----------|----------|------------|----------|
| Staff Code | NVARCHAR | 40 | NO |
| Employee Name (EN) | NVARCHAR | 100 | YES |
| Employee Name (ZH) | NVARCHAR | 100 | YES |
| Email | NVARCHAR | 100 | YES |
| Department ID | NVARCHAR | 10 | YES |
| Position | NVARCHAR | 50 | YES |
| Mobile | NVARCHAR | 50 | YES |
| Leave Days | DECIMAL | 5,1 | NO |
| Holiday Names | NVARCHAR | 100 | NO |
| Status | NVARCHAR | 20 | NO |

### Primary Keys
- Users: `StaffCode` (NVARCHAR(40))
- Leave Types: `LeaveTypeID` (INT IDENTITY)
- Leave Requests: `RequestID` (INT IDENTITY)
- Holidays: `HolidayID` (INT IDENTITY)
- Blackout Dates: `BlackoutID` (INT IDENTITY)

### Foreign Key Relationships
All UI references now use correct foreign key values:
- Employee references use `StaffCode` (not fictional IDs)
- Leave type references use `LeaveTypeID` (1-4)
- Department references use codes (TRANS, WAREH, OFFICE)

## Known Limitations

### 1. Incomplete Leave Balance Data
**Issue:** Only ADMIN001 has leave balance data in `tb_LeaveBalances`  
**Impact:** Employee pages show 0/0 for all leave balances  
**Recommendation:** Run leave balance seeding script for all employees

### 2. No Leave Request Data
**Issue:** No records in `tb_LeaveRequests` or `tb_LeaveRequestDates`  
**Impact:** Approval pages and dashboards show empty state  
**Recommendation:** Create sample leave requests for demo purposes

### 3. No Blackout Dates
**Issue:** `tb_BlackoutDates` table is empty  
**Impact:** Blackout dates page shows empty state  
**Recommendation:** Admin can configure blackout dates through UI

### 4. Email Addresses Missing
**Issue:** Most employees have empty email fields  
**Impact:** Email notifications cannot be sent  
**Recommendation:** Collect and update employee email addresses

## Testing Recommendations

### 1. Data Validation
- [ ] Verify all 49 employees appear in manage-employees page
- [ ] Confirm department filtering works (TRANS, WAREH, OFFICE)
- [ ] Check employee codes match SQL Server exactly
- [ ] Validate leave balance display for ADMIN001

### 2. Functional Testing
- [ ] Test view-only mode in manage-employees (no editing allowed)
- [ ] Verify employee search and filtering
- [ ] Test language switching (EN/繁體中文)
- [ ] Confirm holiday calendar displays correctly

### 3. Database Integration Testing
- [ ] Test with real SQL Server connection
- [ ] Verify data synchronization
- [ ] Test CRUD operations through backend API
- [ ] Validate foreign key constraints

## Next Steps

### Phase 1: Complete Data Alignment (Remaining)
1. Update employee dashboard to use L003 instead of fictional L888
2. Update employee profile page with real data
3. Update leave request pages with real staff codes
4. Update other admin pages with SQL Server data

### Phase 2: Backend Integration
1. Connect UI to backend API endpoints
2. Replace static data with dynamic API calls
3. Implement real-time data updates
4. Add authentication using real staff codes

### Phase 3: Data Population
1. Seed leave balances for all employees
2. Create sample leave requests for testing
3. Configure initial blackout dates
4. Update employee email addresses

### Phase 4: Production Readiness
1. Remove demo/prototype indicators
2. Implement proper error handling
3. Add loading states for API calls
4. Perform security audit

## SQL Server Table Reference

### Tables Aligned
- ✅ `tb_Users` (49 employees)
- ✅ `tb_LeaveTypes` (4 types)
- ✅ `tb_Holidays` (17 holidays for 2025)
- ✅ `tb_LeaveBalances` (ADMIN001 only)
- ⚠️ `tb_LeaveRequests` (empty)
- ⚠️ `tb_LeaveRequestDates` (empty)
- ⚠️ `tb_BlackoutDates` (empty)

### Views Available (Not Yet Used in UI)
- `v_UserProfile`
- `v_LeaveBalance`
- `v_LeaveRequestDetail`
- `v_PendingApprovals`
- `v_TeamCalendar`
- `v_DashboardStats`
- `v_AnnualEntitlement`
- `v_SickBalance`
- `v_LeaveUtilization`

**Recommendation:** Update UI to use these views instead of raw table data for better performance and consistency.

## Version History

### v2.1.0 (Current)
- Created centralized data file (`db-data.js`)
- Aligned employee data with SQL Server (49 employees)
- Updated admin manage-employees page (view-only)
- Updated admin dashboard with real counts
- Updated index page with real credentials
- Documented database alignment

### v2.0.0 (Previous)
- Initial HTML prototype with fictional data
- Basic CRUD UI structure
- Partial approval feature design
- Blackout dates UI design

---

**Document Status:** In Progress  
**Last Updated:** October 27, 2025  
**Updated By:** AI Assistant (via DBHub MCP)

