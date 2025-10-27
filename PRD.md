# Product Requirements Document (PRD)
# HR Leave Management System

**Version:** 2.1.0  
**Date:** October 23, 2025  
**Author:** Development Team  
**Status:** In Development (HTML UI Complete, v2.0.2 Features Added)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Product Overview](#product-overview)
3. [System Architecture](#system-architecture)
4. [User Roles & Personas](#user-roles--personas)
5. [Functional Requirements](#functional-requirements)
6. [Technical Requirements](#technical-requirements)
7. [User Interface Requirements](#user-interface-requirements)
8. [Security Requirements](#security-requirements)
9. [Performance Requirements](#performance-requirements)
10. [Deployment Requirements](#deployment-requirements)
11. [Success Metrics](#success-metrics)
12. [Future Enhancements](#future-enhancements)

---

## Executive Summary

The HR Leave Management System is a web-based application designed to streamline the leave request and approval process for small to medium-sized organizations (~10 users). The system provides a mobile-first interface for employees to request and track leave, and a desktop interface for administrators to manage approvals, employees, and system settings.

### Key Objectives
- Simplify leave request submission for employees
- Streamline approval workflow for administrators
- Provide real-time visibility into leave balances
- Support bilingual interface (English/Traditional Chinese)
- Deploy on local Windows network for data privacy
- Easy maintenance and minimal infrastructure requirements

---

## 🆕 Version 2.1 Updates

This version introduces real-time Hong Kong public holidays and supporting database changes:

### Version 2.1.0 Updates (October 23, 2025)
- Real-time Hong Kong public holidays fetched directly from official 1823 data source
  - EN: `https://www.1823.gov.hk/common/ical/en.json`
  - 繁: `https://www.1823.gov.hk/common/ical/tc.json`
- UI prototype updates:
  - Employee multi-date calendar highlights holidays dynamically
  - Admin Approvals calculates working days excluding weekends/holidays in real time
  - Leave Settings page renders bilingual holiday table from source
- Database design:
  - `tb_Holidays` extended with `SourceUID`, `SourceProvider`, `LastSyncedAt`
  - New TVP `dbo.HolidayImportType` for bulk import
  - New stored procedure `sp_UpsertHolidays_TVP` to merge incoming holidays by date

---

## 🆕 Version 2.0 New Features

### Version 2.0.3 Updates (October 21, 2025)
Business rules alignment and admin constraints (RULES.md is authoritative):

1) AnnualTotal calculation and field design
- AnnualDays per year is based on admin input at hire year, pro-rated for join date in first year: n * (days_remaining_in_year / 365)
- Yearly increment: starting 2024, +1 day per year until capped at m (e.g., 16.5)
- BalanceFromLastYear carry forward is added
- CompensatoryLeave allocated by admin (decimal allowed) is added
- Example: 2024 = 7.5+1=8.5; 2025 = 7.5+2=9.5; AnnualTotal = AnnualDays + BalanceFromLastYear + CompensatoryLeave

2) Paid Sick Leave rule
- Each staff receives SickLeavePaid (e.g., 4.5 days) per year (field: tb_Users.SickLeavePaid)
- Sick days beyond SickLeavePaid are deducted from AnnualTotal (count as annual leave)

3) Application unit
- Employee leave applications must be whole days
- Admin may allocate compensatory leave with decimals (e.g., 2.5)

4) Data modeling guidelines
- Store AnnualDays per year in a historical table to avoid recalculation iteration; do not mutate prior years
- Suggested tables/fields:
  - tb_LeaveYearAllocations(UserID, Year, AnnualDays, SickLeavePaid)
  - tb_LeaveBalances(UserID, Year, BalanceFromLastYear, CompensatoryLeave, AnnualTotalCached)
  - AnnualTotalCached is updated by stored procedure when allocations/compensatory change

5) Admin approval scope
- Admin can only approve/reject requests and add comments; cannot change leave days or requested dates in approval UI
- Partial approval is represented as an outcome (approved subset of requested dates) via `tb_LeaveRequestDates`, not by selecting dates in UI

6) New Admin Module: Compensatory Leave
- Admin page to add/delete compensatory leave records per user with decimal days
- Records contribute to AnnualTotal

UI updates:
- Added `UI/pages/admin/compensatory-leave.html`
- Updated sidebars to include Compensatory Leave
- Simplified `admin/approve-leaves.html` actions to approve/reject only

---

### Version 2.0.2 Updates (October 20, 2025)
**Employee Self-Service Enhancements:**

#### Edit & Delete Pending Leave Requests
**User Need:** Employees need ability to modify or remove leave requests before admin review.

**Solution:**
- ✅ Edit button on pending requests in leave history
- ✅ Delete button with confirmation dialog
- ✅ Form pre-fills with existing data for editing
- ✅ Only pending requests can be modified (approved/rejected are locked)
- ✅ Smart validation prevents editing finalized requests
- ✅ localStorage-based data transfer between pages

**Benefits:**
- Self-service reduces admin workload
- Employees fix mistakes without canceling and resubmitting
- Clear protection of approved/historical records
- Better user experience and flexibility

---

### Version 2.0.1 Updates (October 20, 2025)
**Admin Interface Improvements:**

#### Enhanced Employee Management
**User Need:** Better visibility and organization of employee data for admins.

**Solution:**
- ✅ Table view with sortable columns (ID, Name, Department)
- ✅ Default sort by employee ID/code
- ✅ View toggle between table and grid layouts
- ✅ High-visibility "Add Employee" button (yellow background)
- ✅ Personal info editing disabled (view-only for data integrity)
- ✅ Updated department examples: Transportation, Warehouse, Office

**Benefits:**
- Faster scanning of employee data
- Professional table layout for data management
- Prevents accidental personal info changes
- Better visual hierarchy with prominent action buttons

---

### Version 2.0.0 Core Features

### 1. Multi-Date Selection (Non-Consecutive Days)
**User Need:** Employees often need to take non-consecutive days off (e.g., Monday, Wednesday, Friday) in a single leave request.

**Solution:**
- ✅ Interactive calendar picker for date selection
- ✅ Select multiple dates (consecutive or non-consecutive) in one request
- ✅ Visual indicators for working days, weekends, holidays, and blackout dates
- ✅ Real-time working days calculation
- ✅ Individual date tracking in `tb_LeaveRequestDates` table

**Benefits:**
- Reduces multiple form submissions
- Clearer view of requested dates
- Better tracking and reporting

### 2. Approval by Admin (UI Simplified)
Admins approve or reject entire requests with comments. Date-level UI is not presented; backend tracks per-date statuses for auditing and partial-approval outcomes.

### 3. Blackout Dates Management
**User Need:** Certain dates should be restricted from leave applications (e.g., day before holidays, critical business days).

**Solution:**
- ✅ `tb_BlackoutDates` table for flexible date configuration
- ✅ Admin interface to add/edit/delete blackout dates
- ✅ Auto-generation feature (e.g., day before all holidays)
- ✅ Bilingual reasons (English/Chinese) for each blackout date
- ✅ Automatic validation during leave submission
- ✅ Visual indicators in calendar (❌ icon)

**Benefits:**
- Prevents problematic leave patterns
- Reduces manual rejection of certain dates
- Clear policy enforcement
- Configurable by admins without code changes

### 4. Enhanced Calendar Views
**User Need:** Better visualization of team leave patterns and availability.

**Solution:**
- ✅ Maintained traditional calendar view
- ✅ Employee grid view showing all staff leave on one screen
- ✅ Reference implementation from existing `hr_calendar` system
- ✅ Color-coded leave types
- ✅ Quick visibility into team availability

**Benefits:**
- Better team coordination
- Easier conflict identification
- Quick overview of monthly patterns

### 5. Enhanced Database Schema
**New Tables:**
- `tb_LeaveRequestDates` - Individual date tracking for granular approval
- `tb_BlackoutDates` - Configurable restricted dates

**Enhanced Tables:**
- `tb_LeaveRequests` - Added `RequestedDaysCount`, `ApprovedDaysCount`, `PartialApproval` fields

**New Stored Procedures/Functions:**
- `fn_IsBlackoutDate` - Check if date is restricted
- `fn_CalculateWorkingDays` - Calculate working days between dates
- `sp_GenerateBlackoutDates` - Auto-generate blackout dates from holidays
- Enhanced `sp_SubmitLeaveRequest` - Multi-date submission with validation
- Enhanced `sp_ApproveLeaveRequest` - Partial approval support

---

## Product Overview

### Problem Statement
Organizations need an efficient way to manage employee leave requests without complex enterprise solutions. Current manual processes (email, spreadsheets) lead to tracking errors, delayed approvals, and poor visibility into team availability.

### Solution
A lightweight, user-friendly leave management system that:
- Runs on a single Windows machine (local network)
- Requires minimal technical expertise to maintain
- Provides mobile-responsive interface for on-the-go access
- Supports bilingual users in English and Traditional Chinese
- Connects to existing SQL Server 2012 infrastructure

### Target Users
- **Employees (8-9 users)**: Submit and track leave requests via mobile or desktop
- **Administrators (1-2 users)**: Approve requests, manage employees, configure system

---

## System Architecture

### Technology Stack

**Frontend:**
- Vue 3 (Composition API)
- Vue Router 4 for navigation
- Pinia for state management
- Tailwind CSS for styling
- Vue I18n for internationalization
- Axios for HTTP requests
- Vite as build tool

**Backend:**
- Node.js v18+ with Express.js framework
- mssql package for SQL Server connectivity
- bcryptjs for password hashing (10 salt rounds)
- jsonwebtoken (JWT) for authentication
- express-validator for input validation
- cors for cross-origin resource sharing
- helmet for security headers
- compression for response compression
- winston for logging

**Database:**
- SQL Server 2012+
- 9 core tables with proper indexing (v2.0: added 2 new tables)
- Stored procedures for complex operations (v2.0: enhanced with partial approval)
- Views for reporting
- Functions for date calculations (v2.0: new)

**Deployment:**
- Windows 10/11 or Windows Server on local network
- PM2 for Node.js process management
- pm2-windows-service for auto-start on boot
- Static IP or hostname for network access

### Architecture Diagram
```
[Mobile Devices] ──┐
                   ├──> [Local Network] ──> [Windows Machine]
[Desktop PCs] ─────┘                         ├─> [Node.js/Express API:3000]
                                             ├─> [Vue Frontend (served by Express)]
                                             └─> [SQL Server 2012]
```

---

## User Roles & Personas

### 1. Employee (Standard User)
**Profile:** Lin Jianming (林劍明), Marketing Specialist, L888

**Goals:**
- Quickly submit leave requests from mobile phone
- Check remaining leave balance
- View status of pending requests
- Edit or cancel pending requests before approval
- View team calendar to coordinate leave

**Pain Points:**
- Doesn't want to use desktop for simple tasks
- Needs quick visibility into available leave days
- Wants to know immediately if request is approved

**Access Level:**
- Own leave data (balance, history, requests)
- Team calendar (read-only)
- Personal profile editing

---

### 2. Administrator/Manager
**Profile:** HR Manager or Department Head

**Goals:**
- Review and approve/reject leave requests efficiently
- Monitor team leave schedules
- Manage employee records and leave allocations
- Configure leave types and policies
- Generate reports for planning

**Pain Points:**
- Needs to approve requests quickly without delays
- Must prevent scheduling conflicts
- Requires visibility into all team absences
- Needs to audit leave usage

**Access Level:**
- All employee data (read/write)
- All leave requests (approve/reject)
- System configuration (leave types, holidays)
- Reports and analytics

---

## Functional Requirements

### FR-1: Authentication & Authorization

#### FR-1.1: User Login
**Priority:** P0 (Critical)

**User Parameters:**
- Username (string, 3-50 characters, required)
- Password (string, 8-128 characters, required)

**Functionality:**
1. User enters username and password
2. System validates credentials against database
3. On success:
   - Generate JWT token (24-hour expiry)
   - Store token in localStorage
   - Redirect to appropriate dashboard (employee/admin based on role)
4. On failure:
   - Display error message in current language
   - Log failed attempt with timestamp
   - Rate limit: max 5 attempts per 15 minutes per username

**Acceptance Criteria:**
- Login form displays in selected language (EN/ZH)
- Password field masked
- "Remember me" option keeps session for 7 days
- Invalid credentials show clear error message
- Admin users redirect to desktop layout
- Employee users redirect to mobile-optimized layout

---

#### FR-1.2: Session Management
**Priority:** P0 (Critical)

**Functionality:**
1. JWT token includes: userId, username, role, issuedAt, expiresAt
2. Token stored in localStorage
3. All API requests include Authorization header: `Bearer <token>`
4. Backend middleware validates token on protected routes
5. Invalid/expired tokens return 401 Unauthorized
6. Frontend automatically redirects to login on 401

**Token Refresh:**
- Tokens expire after 24 hours
- User must log in again (no automatic refresh for simplicity)
- Warning message 5 minutes before expiry (optional)

---

#### FR-1.3: User Logout
**Priority:** P0 (Critical)

**Functionality:**
1. User clicks logout button
2. Clear JWT token from localStorage
3. Clear Pinia stores
4. Redirect to login page
5. Log logout event with timestamp

---

#### FR-1.4: Password Change
**Priority:** P1 (High)

**User Parameters:**
- Current password (required)
- New password (8-128 chars, required)
- Confirm new password (must match)

**Functionality:**
1. Validate current password
2. Verify new password meets requirements:
   - Minimum 8 characters
   - At least one letter and one number (recommended)
3. Hash new password with bcrypt
4. Update database
5. Invalidate current JWT token
6. Require re-login

---

### FR-2: Employee Features

#### FR-2.1: Employee Dashboard
**Priority:** P0 (Critical)

**Display Components:**
1. **Welcome Header**
   - Employee name and code
   - Current date

2. **Leave Balance Cards** (Grid: 2x2)
   - Annual Leave: Remaining/Total days, icon, color-coded
     - Show breakdown line: AnnualDays + CarryForward + Compensatory − Used (per RULES.md)
   - Sick Leave: Remaining/Total days, icon, color-coded
     - Show SickPaid entitlement/used/remaining (per RULES.md)
   - Personal Leave: Remaining/Total days, icon, color-coded
   - Study Leave: Remaining/Total days, icon, color-coded

3. **Pending Requests Summary**
   - Count of pending requests
   - Link to view all

4. **Employee Schedule Calendar**
   - Current month view
   - Day-by-day grid (Sun-Sat)
   - Show employees on leave each day
   - Highlight public holidays
   - Month navigation (prev/next buttons)

5. **Quick Actions**
   - Request Leave button
   - View History button

**Acceptance Criteria:**
- Dashboard loads within 2 seconds
- All data reflects current user's information
- Leave balances update in real-time after approval
- Calendar shows team members' leave (names only)
- Responsive design: mobile-first, max-width 500px
- Language toggle affects all text immediately
- Annual card shows breakdown and highlights negative remaining in red
- Sick card shows paid entitlement/used/remaining; note overflow uses Annual

---

#### FR-2.2: Leave Request Submission (v2.0 Enhanced)
**Priority:** P0 (Critical)

**User Parameters:**
- Leave Type (dropdown, required): Annual, Sick, Personal, Study
- **Selected Dates (multi-date calendar picker, required):** One or more dates (v2.0)
  - Can select consecutive dates (e.g., Mon-Fri)
  - Can select non-consecutive dates (e.g., Mon, Wed, Fri)
  - Cannot select past dates
  - Cannot select blackout dates
- Reason (textarea, 0-500 characters, optional)

**Functionality (v2.0):**
1. **Calendar-Based Date Selection:**
   - Display monthly calendar grid
   - Visual indicators for:
     - Today (blue border)
     - Weekends (pink background)
     - Public holidays (yellow background)
     - Blackout dates (red background with ❌ - cannot select)
     - Selected dates (teal background)
   - Click to select/deselect individual dates
   - Month navigation (previous/next buttons)

2. **Real-Time Validation:**
   - Calculate total selected days automatically (no distinction between weekends/holidays)
   - Display selected dates list with day names
   - Show total working days count
   - Validate against blackout dates (auto-blocked)
   - Validate sufficient leave balance against total selected days
   - "Clear All" option to reset selection

3. **Blackout Date Validation (v2.0 NEW):**
   - Check selected dates against `tb_BlackoutDates` table
   - Prevent selection of restricted dates
   - Display reason for blackout (EN/ZH) on hover
   - By default, day before holidays is blackout

4. **Submission:**
   - Submit request with array of selected dates to API
   - Backend stores each date in `tb_LeaveRequestDates` table
   - On success:
     - Show success message
     - Redirect to leave history
     - Request status: "Pending"
   - On error:
     - Display validation errors
     - Highlight invalid dates

**Business Rules (v2.0):**
- Cannot request leave in the past
- Cannot request more working days than available balance
- Cannot select blackout dates
- Weekends excluded from working day count
- Public holidays excluded from working day count
- Minimum 1 working day, maximum 30 working days per request
- Each selected date tracked individually in database
- Non-consecutive dates allowed in single request

**API Request Format (v2.0):**
```json
{
  "leaveTypeId": 1,
  "leaveDates": ["2025-11-15", "2025-11-16", "2025-11-18"],
  "reason": "Personal matters"
}
```

**API Response:**
```json
{
  "success": true,
  "message": "Leave request submitted successfully",
  "requestId": 123,
  "requestedDays": 3,
  "workingDays": 3
}
```

**Acceptance Criteria (v2.0):**
- ✅ Calendar grid displays correctly on mobile (responsive)
- ✅ Touch targets minimum 44x44px for date cells
- ✅ Visual feedback on date selection (color change)
- ✅ Blackout dates clearly marked and non-selectable
- ✅ Selected dates list updates in real-time
- ✅ Total selected days count accurate (all selectable days same level)
- ✅ Balance validation before submission
- ✅ Can select non-consecutive dates (e.g., Mon, Thu, Fri)
- ✅ Clear error messages for validation failures
- ✅ Success confirmation with request number
- ✅ Bilingual calendar and labels (EN/ZH)
- ✅ Month navigation works smoothly
- ✅ "Clear All" resets all selections

**Database Impact (v2.0):**
- Each selected date stored in `tb_LeaveRequestDates` with:
  - `RequestID` (FK to tb_LeaveRequests)
  - `LeaveDate` (DATE)
  - `DateStatus` ('Requested', 'Approved', 'Rejected', 'Removed')
  - `IsWorkingDay` (BIT)
- Enables granular approval (admin can approve some dates, reject others)

---

#### FR-2.3: Leave History (v2.0 Enhanced - Partial Approval Display)
**Priority:** P0 (Critical)

**Display Components:**
1. **Filter Options**
   - Status: All / Pending / Approved / Rejected
   - Leave Type: All / Annual / Sick / Personal / Study
   - Date Range: Last 30 days / Last 3 months / Last year / Custom

2. **Request List** (Most recent first)
   - Each item shows:
     - Leave type (icon + name)
     - Start date - End date (formatted)
     - Total days requested
     - **Partial Approval Indicator (v2.0 NEW):**
       - Orange badge: "Only X approved" (if partial approval)
       - Shows approved days vs requested days
     - Status badge (color-coded)
     - Submitted date
     - Approval date (if applicable)
     - Approver name (if applicable)
     - Reason (expandable)
     - **Admin comments** (if provided)

3. **Partial Approval Detail (v2.0 NEW):**
   When request is partially approved, show expanded section:
   - Yellow warning box with heading "⚠️ Partial Approval"
   - **Approved Dates:** List of approved dates (green checkmarks)
   - **Not Approved:** List of rejected dates (red X marks)
   - **Admin Comment:** Explanation for partial approval
   - Example:
     ```
     ⚠️ Partial Approval
     ✅ Approved Dates: Nov 15, Nov 16
     ❌ Not Approved: Nov 19
     💬 Admin Comment: "Project deadline on Nov 19, can only approve 2 days"
     ```

4. **Actions** (based on status)
   - **Pending**: Edit button, Cancel button
   - **Approved (Full)**: View only
   - **Approved (Partial)**: View details, See approved dates
   - **Rejected**: View reason, Resubmit button

**Functionality (v2.0):**
- Click request card to expand details
- Partial approval shows detailed breakdown automatically
- Click pending request to edit
- Cancel button shows confirmation dialog
- Pull-to-refresh on mobile
- Infinite scroll or pagination (10 items per page)
- **Badge colors:**
  - Pending: Yellow
  - Approved (Full): Green
  - Approved (Partial): Orange
  - Rejected: Red

**Data Display (v2.0):**
```
Request Card Example (Partial Approval):

┌─────────────────────────────────────────┐
│ Personal Leave 個人假         ✅ Approved │
│                                          │
│ 📅 2025-09-20 - 2025-09-22              │
│ 🕐 3 days requested                     │
│    ⚠️ Only 2 approved  ← NEW BADGE     │
│                                          │
│ 💬 Personal matters                     │
│ ✉️ Submitted: 2025-09-15                │
│ ✅ Approved by Admin on 2025-09-16      │
│                                          │
│ ┌────────────────────────────────────┐ │
│ │ ⚠️ Partial Approval               │ │  ← NEW SECTION
│ │                                    │ │
│ │ ✅ Approved Dates:                │ │
│ │    • Sep 20, 2025                 │ │
│ │    • Sep 21, 2025                 │ │
│ │                                    │ │
│ │ ❌ Not Approved:                   │ │
│ │    • Sep 22, 2025                 │ │
│ └────────────────────────────────────┘ │
│                                          │
│ 💬 Admin Comment: "Approved only 2      │
│    days due to workload"                │
└─────────────────────────────────────────┘
```

**Acceptance Criteria (v2.0):**
- ✅ List updates immediately after actions
- ✅ Filters work in combination
- ✅ Clear status indicators (colors + text)
- ✅ Edit mode prefills form with existing data
- ✅ Cancel requires confirmation
- ✅ **Partial approval badge visible and clear**
- ✅ **Approved vs not approved dates clearly distinguished**
- ✅ **Admin comments displayed for partial approvals**
- ✅ **Orange badge indicates partial approval**
- ✅ **Yellow warning box draws attention to partial details**
- ✅ **Working days count shows approved days, not requested**

---

#### FR-2.4: Edit Pending Leave Request (v2.0.2 Enhanced)
**Priority:** P0 (Critical)

**User Parameters:**
- Leave Type (pre-filled, can be changed)
- Selected Dates (pre-filled on calendar, can be modified)
- Reason (pre-filled, can be modified)

**Functionality (v2.0.2):**
1. **Edit Button Display:**
   - Edit button appears only for pending requests in leave history
   - Button: Teal background, white text, edit icon
   - Locked for approved/rejected requests (no button shown)

2. **Edit Workflow:**
   - Click Edit button on pending request
   - System stores request data in localStorage
   - Redirects to `leave-request-multi.html?edit=<id>`
   - Page title changes to "Edit Leave Request"
   - Submit button text changes to "Update Request"

3. **Form Pre-filling:**
   - Leave type dropdown pre-selected with existing type
   - Calendar dates pre-selected (highlights existing dates)
   - Reason textarea pre-filled with existing text
   - Character counter reflects existing reason length
   - Leave balance display updates based on selected type

4. **Allow Changes:**
   - Leave Type: Can be changed to any available type
   - Selected Dates: Can add, remove, or change dates using calendar
   - Reason: Can modify or clear reason text
   - Month Navigation: Can navigate to different months

5. **Validation (Same as New Request):**
   - Cannot select past dates
   - Cannot select blackout dates
   - Must have sufficient leave balance for selected type
   - Real-time working days calculation
   - Minimum 1 date required

6. **Update Submission:**
   - Click "Update Request" button
   - Backend API: `PUT /api/leaves/request/:id`
   - Update all `tb_LeaveRequestDates` records
   - Update `tb_LeaveRequests` with new data
   - Keep original submission date unchanged
   - Update last modified date and user

7. **Success Handling:**
   - Show success message: "Leave request updated successfully!"
   - Redirect to leave history after 1.5 seconds
   - Updated request appears with "Pending" status
   - Admin sees updated request in approval queue

**Protection Rules (v2.0.2):**
- **Can Edit:** Only requests with status = "Pending"
- **Cannot Edit:** Requests with status = "Approved" or "Rejected"
- **Error Message:** "Only pending requests can be edited"
- **Visual Cue:** Edit button hidden for non-pending requests

**Data Transfer Method:**
```javascript
// Step 1: Store request in localStorage (leave-history.html)
localStorage.setItem('editLeaveRequest', JSON.stringify({
    id: 1,
    type: 'annual',
    startDate: '2025-11-15',
    endDate: '2025-11-19',
    reason: 'Family vacation',
    requestedDates: ['2025-11-15', '2025-11-16', ...]
}));

// Step 2: Redirect with edit parameter
window.location.href = 'leave-request-multi.html?edit=1';

// Step 3: Load and parse data (leave-request-multi.html)
const editData = localStorage.getItem('editLeaveRequest');
const request = JSON.parse(editData);
// Pre-fill form...
localStorage.removeItem('editLeaveRequest'); // Clean up
```

**API Request Format:**
```json
PUT /api/leaves/request/:id
{
  "leaveTypeId": 1,
  "leaveDates": ["2025-11-15", "2025-11-16", "2025-11-17"],
  "reason": "Updated reason for leave"
}
```

**API Response:**
```json
{
  "success": true,
  "message": "Leave request updated successfully",
  "data": {
    "requestId": 1,
    "status": "pending",
    "requestedDays": 3,
    "workingDays": 3,
    "updatedAt": "2025-10-20T15:30:00Z"
  }
}
```

**Acceptance Criteria (v2.0.2):**
- ✅ Edit button visible only for pending requests
- ✅ Form loads with all existing data pre-filled
- ✅ Page title shows "Edit Leave Request"
- ✅ Submit button shows "Update Request"
- ✅ Calendar shows pre-selected dates
- ✅ Can modify any field (type, dates, reason)
- ✅ Validation same as new request submission
- ✅ Success message confirms update
- ✅ Updated request appears in history immediately
- ✅ Cannot edit approved/rejected requests
- ✅ Clear error message if attempting to edit non-pending
- ✅ Original submission date preserved
- ✅ Works on mobile and desktop

---

#### FR-2.5: Delete Leave Request (v2.0.2 Enhanced)
**Priority:** P0 (Critical)

**User Parameters:**
- Request ID (selected from leave history)

**Functionality (v2.0.2):**
1. **Delete Button Display:**
   - Delete button appears only for pending requests in leave history
   - Button: Red background, white text, trash icon
   - Locked for approved/rejected requests (no button shown)
   - Positioned next to Edit button

2. **Delete Workflow:**
   - Click Delete button on pending request
   - Show detailed confirmation dialog
   - Display full request information:
     - Leave type
     - Date range
     - Number of days
     - Warning: "This action cannot be undone"
   - Confirm / Cancel buttons

3. **Validation:**
   - Only pending requests can be deleted
   - Approved requests cannot be deleted (historical record)
   - Rejected requests cannot be deleted (audit trail)
   - Error message if attempting to delete non-pending

4. **On Confirmation:**
   - Backend API: `DELETE /api/leaves/request/:id`
   - Permanently remove from `tb_LeaveRequests`
   - Remove all associated `tb_LeaveRequestDates` records
   - Log deletion in `tb_AuditLog` with timestamp
   - No leave balance restoration (was pending, not approved)
   - Show success message

5. **Success Handling:**
   - Remove request from leave history list immediately
   - Show success message: "Leave request deleted successfully"
   - If no more requests, show empty state
   - Cannot be undone

**Protection Rules (v2.0.2):**
- **Can Delete:** Only requests with status = "Pending"
- **Cannot Delete:** Requests with status = "Approved" (historical/attendance record)
- **Cannot Delete:** Requests with status = "Rejected" (audit trail)
- **Error Message:** "Only pending requests can be deleted"
- **Visual Cue:** Delete button hidden for non-pending requests

**Confirmation Dialog Content:**
```
Are you sure you want to delete this leave request?

Type: Annual Leave
Dates: Nov 15, 2025 - Nov 19, 2025
Days: 5

This action cannot be undone.

[Cancel] [Delete]
```

**API Request Format:**
```http
DELETE /api/leaves/request/:id
Authorization: Bearer <jwt_token>
```

**API Response:**
```json
{
  "success": true,
  "message": "Leave request deleted successfully",
  "data": {
    "requestId": 1,
    "deletedAt": "2025-10-20T15:30:00Z"
  }
}
```

**Business Rules:**
- Only pending requests can be permanently deleted
- Approved requests must remain for attendance records
- Rejected requests must remain for audit trail
- Deletion is logged in audit table for compliance
- No leave balance adjustment (request was never approved)
- Cannot be undone - this is a hard delete

**Acceptance Criteria (v2.0.2):**
- ✅ Delete button visible only for pending requests
- ✅ Confirmation dialog shows complete request details
- ✅ Clear warning that action cannot be undone
- ✅ Request removed from database permanently
- ✅ Request removed from UI immediately
- ✅ Success message confirms deletion
- ✅ Cannot delete approved/rejected requests
- ✅ Clear error message if attempting to delete non-pending
- ✅ Deletion logged in audit trail
- ✅ Empty state displays if no requests remain
- ✅ Works on mobile and desktop

**Note on Approved Requests:**
For future enhancement, consider adding "Cancel Approved Request" feature:
- Only for future-dated approved requests
- Requires admin approval to cancel
- Restores leave balance
- Marks as "Cancelled" status (not deleted)
- Remains in history for audit purposes

---

#### FR-2.6: User Profile
**Priority:** P2 (Medium)

**Display Fields:**
- Full Name (editable)
- Employee Code (read-only)
- Email (editable)
- Department (read-only)
- Position (read-only)
- Preferred Language (editable): English / 中文
- Password Change button

**Functionality:**
1. Display current user information
2. Allow editing of editable fields
3. Validate email format
4. Update profile in database
5. Show success message

**Acceptance Criteria:**
- Clear indication of read-only vs editable fields
- Email validation before save
- Language preference updates interface immediately
- Profile picture placeholder (future enhancement)

---

### FR-3: Admin Features

#### FR-3.1: Admin Dashboard
**Priority:** P0 (Critical)

**Display Components:**
1. **Statistics Cards** (Grid: 3 columns)
   - Pending Approvals: Count + View all link
   - Total Employees: Count + View all link
   - On Leave Today: Count + View all link

2. **Recent Leave Requests Table**
   - Columns: Employee (name + photo), Type, Duration, Status, Actions
   - Show 5-10 most recent pending requests
   - Actions: Approve / Reject buttons
   - View all link to approval page

3. **On Leave Today List**
   - Employee name + photo
   - Leave type
   - Return date

4. **Quick Actions Grid** (2x2)
   - Approve Leaves
   - Manage Employees
   - View Reports
   - Settings

5. **Team Schedule Calendar**
   - Same calendar as employee view
   - Shows all employees on leave

**Acceptance Criteria:**
- Desktop layout (min-width 1024px)
- Sidebar navigation always visible
- Statistics update in real-time
- Quick approve/reject from dashboard
- Responsive table on smaller desktop screens

---

#### FR-3.2: Approve/Reject Leave Requests (Simplified)
**Priority:** P0 (Critical)

**Display Components:**
1. **Pending Requests Table**
   - Columns: Employee, Type, Start Date, End Date, Days, Reason, Submitted Date, Actions
   - Sort by submitted date (oldest first)
   - Filter by: Leave type, Employee, Department, Date range

2. **Request Detail Modal (Simplified)**
   - **Employee Information:**
     - Name, code, department, position
     - Current leave balance
     - Leave history (last 3 requests)
   
   - **Request Details:**
     - Leave type
     - Duration (date range or non-consecutive)
     - Total days requested
     - Reason for leave
     - Submitted date
   
   - **Dates Summary:**
     - Show originally requested dates and counts for transparency
     - Partial approval can be reflected in outcome (subset approved) without date-picking UI
   
   - **Action Buttons:**
     - **Primary:** "Approve" (approve request based on requested dates)
     - **Secondary:** "Reject" (reject entire request)

**Functionality:**
1. Admin views request details modal
2. Admin reviews requested dates list and totals
3. Admin sets comments (optional) and clicks Approve or Reject
4. **Backend Processing:**
   - Approve: mark requested dates as approved; compute partial outcome if some dates invalidated by rules; update counts
   - Reject: mark all dates rejected; update request status
5. Show success message and update lists

---

#### FR-3.3: Manage Employees (v2.0.1 Enhanced)
**Priority:** P1 (High)

**Display Components (v2.0.1):**

1. **View Toggle & Add Employee Button**
   - View toggle buttons: Table (default) / Grid
   - Icons: Table (📊) / Grid (⊞)
   - Active view highlighted in teal
   - **Add Employee button:**
     - Yellow background (#FFD500) for high visibility
     - Dark text for contrast
     - Bold font with shadow effect
     - Icon: user-plus
     - Positioned top-right

2. **Table View (Default, v2.0.1 NEW)**
   - **Columns:** ID (Employee Code), Name, Department, Position, Email, Annual Leave, Status, Actions
   - **Sortable columns:** ID, Name, Department (click header to sort)
   - **Default sort:** By employee ID/code (ascending)
   - Search by name/code/email (top-left)
   - Filter by: Department, Status (Active/Inactive)
   - Row hover effects
   - Actions column: View (👁️), Activate/Deactivate toggle
   - Professional table layout with alternating row colors
   - Shows more data at once compared to grid
   - Better for scanning and comparison

3. **Grid View (Alternative)**
   - 3-column grid on desktop
   - Employee cards with:
     - Avatar/initial circle
     - Name and employee code
     - Department badge
     - Position
     - Status badge
     - Leave balance summary
     - View Details button
     - Activate/Deactivate button
   - More visual, card-based layout
   - Better for mobile/touch devices

4. **Department Examples (v2.0.1 Updated):**
   - Transportation (e.g., Driver, Dispatcher)
   - Warehouse (e.g., Supervisor, Foreman, Clerk)
   - Office (e.g., Specialist, Manager, Coordinator)

5. **Employee Detail View (Read-Only, v2.0.1)**
   - **Personal info editing DISABLED**
   - Click "View Details" to see information in alert/modal
   - Display fields:
     - Name, Employee Code, Email
     - Department, Position, Status
     - Leave balances (Annual, Sick, Personal, Study)
   - Note displayed: "Personal info editing is disabled"
   - Status toggle still available (Activate/Deactivate)

6. **Add Employee Modal** (For new employees only)
   - Personal Information:
     - Full Name (required, 2-100 chars)
     - Employee Code (required, unique, 3-20 chars)
     - Email (required, valid format)
     - Department (dropdown): Transportation / Warehouse / Office
     - Position (text, 2-50 chars)
   - Account Information:
     - Username (required, unique, 3-50 chars)
     - Password (required for new)
     - Role (dropdown): Employee / Admin
     - Status (toggle): Active / Inactive
   - Leave Allocation:
     - Annual Leave: Days per year
     - Sick Leave: Days per year
     - Personal Leave: Days per year
     - Study Leave: Days per year

**Functionality - View Toggle (v2.0.1 NEW):**
1. Click Table/Grid toggle button
2. Active button highlighted in teal
3. Switch display mode instantly
4. Preserve current filters and search
5. Sort state maintained in table view
6. User preference can be saved (future enhancement)

**Functionality - Sort Table (v2.0.1 NEW):**
1. Click column header (ID, Name, or Department)
2. First click: Sort ascending
3. Second click: Sort descending
4. Sort icon indicator shows current state
5. Default: Sorted by ID ascending

**Functionality - Add Employee:**
1. Click Add New Employee (yellow button)
2. Modal opens with blank form
3. Fill in all required fields
4. Validate all inputs:
   - Check username/employee code uniqueness
   - Email format validation
   - Password minimum 8 characters
5. Hash password with bcrypt
6. Create user record in database
7. Initialize leave balances for current year
8. Show success message
9. Close modal and refresh employee list

**Functionality - View Employee (v2.0.1 NEW - Read-Only):**
1. Click "View Details" button on employee
2. Display alert or modal with all information
3. Show read-only data:
   - Name, Code, Email
   - Department, Position
   - Status
   - All leave balances
4. Display note: "Personal info editing is disabled"
5. No save button (view-only)
6. Close to return to list

**Functionality - Edit Employee (v2.0.1 DISABLED):**
- **Personal information editing is DISABLED**
- Prevents accidental data changes
- Maintains data integrity
- If edit attempted, show message:
  - "Personal information editing is currently disabled"
  - "To view employee details, click the View Details button"
- Only status can be changed (activate/deactivate)

**Functionality - Activate/Deactivate Employee:**
1. Click Activate/Deactivate button
2. Show confirmation dialog:
   - "Are you sure you want to activate/deactivate [Employee Name]?"
3. On confirmation:
   - Update status in database
   - API: `PUT /api/admin/employees/:id/status`
4. Status effects:
   - **Inactive:** User cannot log in (authentication fails)
   - **Inactive:** Leave requests remain in history (read-only)
   - **Inactive:** Leave balance frozen
   - **Active:** User can log in and submit requests
5. Show success message
6. Button text/color updates (Deactivate ↔ Activate)
7. Status badge updates

**API Endpoints:**
```
GET /api/admin/employees
  - Returns list of all employees with filters

GET /api/admin/employees/:id
  - Returns single employee details (read-only)

POST /api/admin/employees
  - Creates new employee with leave allocations

PUT /api/admin/employees/:id/status
  - Updates employee status (active/inactive)
```

**Acceptance Criteria (v2.0.1):**
- ✅ Table view is default
- ✅ Table sorted by employee ID by default
- ✅ Can sort by ID, Name, Department columns
- ✅ View toggle switches between table and grid
- ✅ Add Employee button highly visible (yellow)
- ✅ View Details shows read-only information
- ✅ Personal info editing disabled with clear message
- ✅ Status toggle works (activate/deactivate)
- ✅ Confirmation dialog prevents accidental status changes
- ✅ Username and Employee Code must be unique
- ✅ Email format validated
- ✅ Password minimum 8 characters for new employees
- ✅ Default role is Employee
- ✅ New employees start with configured leave allocations
- ✅ Inactive employees cannot log in
- ✅ Search and filters work in both views
- ✅ Department dropdown shows Transportation/Warehouse/Office
- ✅ Pagination for large employee lists (>20)
- ✅ Responsive: table scrolls horizontally on smaller screens

---

#### FR-3.4: Leave Settings (Leave Type Management)
**Priority:** P2 (Medium)

**Display Components:**
1. **Leave Types List**
   - Table columns: Name (EN/ZH), Default Days, Requires Approval, Status, Color, Actions
   - Add New Leave Type button

2. **Leave Type Form**
   - Leave Type Name (English) (required, 2-50 chars)
   - Leave Type Name (繁體中文) (required, 2-50 chars)
   - Default Days Per Year (number, 0-365)
   - Requires Approval (checkbox, default: true)
   - Active Status (checkbox, default: true)
   - Color Code (color picker): For UI display
   - Icon (dropdown): Select from Font Awesome icons

**Functionality:**
1. View all leave types
2. Add new leave type
3. Edit existing leave type
4. Deactivate leave type (cannot delete if in use)
5. Changes apply to new leave allocations only

**Predefined Leave Types:**
- Annual Leave (年假): 20 days, #00AFB9, calendar-alt icon
- Sick Leave (病假): 10 days, #FF6B6B, procedures icon
- Personal Leave (個人假): 5 days, #FFD166, user-clock icon
- Study Leave (進修假): 2 days, #06D6A0, book icon

**Acceptance Criteria:**
- Both English and Chinese names required
- Color preview in table
- Icon preview in table
- Cannot delete leave types with existing requests
- Deactivated types not available for new requests

---

#### FR-3.5: Reports
**Priority:** P2 (Medium)

**Report Types:**

1. **Leave Summary Report**
   - Filter by: Date range, Department, Leave type
   - Group by: Employee / Department / Leave type
   - Show: Total days taken, Remaining balance, Utilization %
   - Export: CSV, PDF (future)

2. **Team Availability Report**
   - Date range selection
   - Show daily headcount available vs on leave
   - Identify potential understaffing days
   - Export: CSV

3. **Employee Leave History Report**
   - Select employee
   - Show all leave requests (all statuses)
   - Total days per leave type
   - Export: CSV

4. **Audit Log Report** (Admin only)
   - Filter by: Date range, Action type, User
   - Show: Timestamp, User, Action, Details
   - Export: CSV

**Acceptance Criteria:**
- Reports generate within 5 seconds
- Clear visualizations (tables, charts)
- Export preserves formatting
- Date range validation

---

### FR-4: Calendar & Scheduling

#### FR-4.1: Team Calendar View
**Priority:** P1 (High)

**Display Components:**
- Month view (default)
- Day cells show:
  - Date number
  - Public holiday indicator
  - Employees on leave (name badges)
  - Color coding by leave type
- Month navigation (prev/next buttons)
- Jump to specific month/year

**Functionality:**
1. Display current month by default
2. Show all approved leave requests
3. Highlight public holidays
4. Click date to see details:
   - List of employees on leave that day
   - Leave types
   - Contact information
5. Color-code by leave type (matches leave type colors)

**Acceptance Criteria:**
- Calendar loads within 2 seconds
- Responsive on mobile (horizontal scroll if needed)
- Clear visual hierarchy
- Employee names readable (truncate if needed)
- Public holidays clearly distinguished

---

#### FR-4.2: Holiday Management
**Priority:** P2 (Medium)

**Display Components:**
1. **Holiday List**
   - Table: Date, Name (EN/ZH), Year, Actions
   - Filter by year
   - Add New Holiday button

2. **Holiday Form**
   - Date (date picker, required)
   - Name (English) (required)
   - Name (繁體中文) (required)
   - Year (auto-filled from date, read-only)

**Functionality:**
1. View all holidays
2. Add new holiday
3. Edit existing holiday
4. Delete holiday (confirmation required)
5. Holidays exclude from leave day calculations

**Common Hong Kong Holidays (Examples):**
- New Year's Day (元旦)
- Lunar New Year (農曆新年)
- Ching Ming Festival (清明節)
- Easter (復活節)
- Labour Day (勞動節)
- Buddha's Birthday (佛誕)
- Dragon Boat Festival (端午節)
- Hong Kong SAR Establishment Day (香港特別行政區成立紀念日)
- Mid-Autumn Festival (中秋節)
- National Day (國慶日)
- Chung Yeung Festival (重陽節)
- Christmas (聖誕節)

**Acceptance Criteria:**
- Holidays appear in calendar view
- Holidays excluded from leave calculations
- Import holidays from file (future enhancement)
- Recurring holiday templates (future enhancement)

---

## Technical Requirements

### TR-1: Database Requirements

#### Database Server
- SQL Server 2012 or higher
- SQL Server Authentication enabled
- Database: `HRLeaveSystemDB`
- Collation: Chinese_Traditional_Stroke_CI_AS
- Full recovery mode
- Automated daily backups

#### Database Schema (v2.0)
**9 Core Tables:**
1. `tb_Users` - User accounts and profiles
2. `tb_Departments` - Department definitions
3. `tb_LeaveTypes` - Leave type configurations
4. `tb_LeaveBalances` - Employee leave balances
5. `tb_LeaveRequests` - Leave request records (v2.0: enhanced with partial approval)
6. **`tb_LeaveRequestDates`** - Individual date tracking (v2.0: NEW)
7. **`tb_BlackoutDates`** - Restricted dates configuration (v2.0: NEW)
8. `tb_Holidays` - Public holidays
9. `tb_AuditLog` - System audit trail

**7 Views:**
- Employee leave summary
- Department utilization
- Pending approvals
- Leave history
- Team calendar data
- Balance reports
- Audit reports

**Stored Procedures (v2.0 Enhanced):**
- `sp_SubmitLeaveRequest` - Multi-date submission with blackout validation
- `sp_ApproveLeaveRequest` - Partial approval support
- `sp_RejectLeaveRequest` - Reject leave request
- `sp_CancelLeaveRequest` - Cancel pending request
- `sp_UpdateLeaveBalance` - Adjust balances
- `sp_GetEmployeeLeaveHistory` - Retrieve history
- `sp_GetDepartmentUtilization` - Calculate usage
- `sp_GenerateBlackoutDates` - Auto-generate from holidays (v2.0: NEW)

**Functions (v2.0 NEW):**
- `fn_IsBlackoutDate` - Check if date is restricted
- `fn_CalculateWorkingDays` - Calculate working days excluding weekends/holidays

#### Performance
- Indexes on all foreign keys
- Indexes on date columns (especially LeaveDate in tb_LeaveRequestDates)
- Query execution time < 500ms for most queries
- Support concurrent connections: 10-20

---

### TR-2: Backend API Requirements

#### Framework & Dependencies
```json
{
  "express": "^4.18.0",
  "mssql": "^10.0.0",
  "bcryptjs": "^2.4.3",
  "jsonwebtoken": "^9.0.0",
  "express-validator": "^7.0.0",
  "cors": "^2.8.5",
  "helmet": "^7.1.0",
  "compression": "^1.7.4",
  "dotenv": "^16.0.0",
  "winston": "^3.11.0"
}
```

#### API Response Format
**Success Response:**
```json
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}
```

**Error Response:**
```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": [] // Validation errors if applicable
  }
}
```

#### Error Codes
- `AUTH_INVALID_CREDENTIALS`: Invalid username or password
- `AUTH_TOKEN_EXPIRED`: JWT token expired
- `AUTH_UNAUTHORIZED`: User not authorized for this action
- `VALIDATION_ERROR`: Input validation failed
- `INSUFFICIENT_BALANCE`: Not enough leave balance
- `INVALID_DATE_RANGE`: Invalid date range
- `RESOURCE_NOT_FOUND`: Requested resource not found
- `DUPLICATE_ENTRY`: Duplicate username/employee code
- `SERVER_ERROR`: Internal server error

#### Logging
- Use winston for structured logging
- Log levels: error, warn, info, debug
- Log to files: `logs/error.log`, `logs/combined.log`
- Rotate logs daily, keep 14 days
- Log format: timestamp, level, message, metadata

---

### TR-3: Frontend Requirements

#### Framework & Dependencies
```json
{
  "vue": "^3.3.0",
  "vue-router": "^4.2.0",
  "pinia": "^2.1.0",
  "axios": "^1.6.0",
  "vue-i18n": "^9.8.0",
  "tailwindcss": "^3.4.0",
  "@headlessui/vue": "^1.7.0"
}
```

#### Browser Support
- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile Safari (iOS 14+)
- Chrome Mobile (Android 10+)

#### Responsive Breakpoints
- Mobile: 320px - 767px (primary employee interface)
- Tablet: 768px - 1023px
- Desktop: 1024px+ (admin interface optimized for this)

#### Performance
- First Contentful Paint < 1.5s
- Time to Interactive < 3s
- Bundle size < 500KB (gzipped)
- Lazy load routes
- Image optimization (if used)

---

### TR-4: Security Requirements

#### Authentication
- JWT tokens with HS256 algorithm
- Token expiry: 24 hours
- Secure token storage: localStorage (acceptable for local network)
- HTTPS enforced in production (optional for local network)

#### Password Policy
- Minimum length: 8 characters
- Recommended: Mix of letters and numbers
- Hashed with bcryptjs (10 salt rounds)
- Never logged or exposed in API responses

#### Input Validation
- Server-side validation for all inputs
- Client-side validation for UX
- Sanitize all user inputs
- Parameterized SQL queries (prevent SQL injection)
- XSS protection via helmet

#### Authorization
- Role-based access control (RBAC)
- Middleware checks user role on protected routes
- Employees can only access own data
- Admins can access all data

#### Rate Limiting
- Login endpoint: 5 attempts per 15 minutes per IP
- API endpoints: 100 requests per minute per user
- 429 status code when limit exceeded

---

## User Interface Requirements

### UI-1: Design System

#### Color Palette
```css
/* Primary Colors */
--primary: #00AFB9;        /* Teal - main brand color */
--primary-hover: #009ba3;  /* Darker teal for hover states */
--primary-light: #f0fafb;  /* Light teal for backgrounds */

/* Leave Type Colors */
--leave-annual: #00AFB9;   /* Annual Leave */
--leave-sick: #FF6B6B;     /* Sick Leave */
--leave-personal: #FFD166; /* Personal Leave */
--leave-study: #06D6A0;    /* Study Leave */

/* Status Colors */
--status-pending: #FFA500;  /* Orange */
--status-approved: #10B981; /* Green */
--status-rejected: #EF4444; /* Red */
--status-cancelled: #9CA3AF; /* Gray */

/* Neutral Colors */
--gray-50: #F9FAFB;
--gray-100: #F3F4F6;
--gray-200: #E5E7EB;
--gray-600: #4B5563;
--gray-800: #1F2937;
--white: #FFFFFF;
```

#### Typography
- Font Family: System font stack (Segoe UI on Windows)
- Base Size: 16px
- Headings: 700 weight, 1.2 line height
- Body: 400 weight, 1.5 line height
- Code: Monospace

#### Spacing Scale
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- 2xl: 48px

#### Border Radius
- sm: 4px
- md: 8px
- lg: 12px
- full: 9999px (circles)

#### Shadows
- sm: 0 1px 2px rgba(0,0,0,0.05)
- md: 0 4px 6px rgba(0,0,0,0.1)
- lg: 0 10px 15px rgba(0,0,0,0.1)

---

### UI-2: Mobile Interface (Employee)

#### Layout
- Maximum width: 500px
- Center aligned on larger screens
- Bottom navigation bar (fixed)
- Top header (fixed) with logo, user icon, language toggle
- Scrollable content area with padding

#### Navigation
- Bottom tab bar with 4 items:
  - Home (dashboard icon)
  - Request (calendar-plus icon)
  - History (history icon)
  - Profile (user icon)
- Active state: Primary color fill
- Icons: Font Awesome 6.4.0

#### Touch Targets
- Minimum size: 44x44px
- Spacing between targets: 8px
- Buttons with adequate padding

#### Forms
- Full-width inputs
- Large touch-friendly controls
- Date picker optimized for mobile
- Clear button labels
- Inline validation messages

---

### UI-3: Desktop Interface (Admin)

#### Layout
- Sidebar navigation (fixed left, 240px width)
- Main content area (scrollable)
- Top header with search, notifications, user menu
- No bottom navigation

#### Sidebar Navigation
- Logo at top
- Menu items with icons and labels
- Active state: Background color + border
- Collapsible (future enhancement)

#### Content Layout
- Grid system: 12 columns
- Cards for grouping content
- Tables for data display
- Responsive down to 1024px

#### Data Tables
- Sortable columns (click header)
- Pagination (10/25/50/100 per page)
- Search/filter bar above table
- Row hover effects
- Actions column (right-aligned)

---

### UI-4: Bilingual Interface

#### Language Toggle
- Globe icon in header
- Dropdown with EN / 中文 options
- Saves preference to localStorage
- Immediate UI update on change

#### Text Direction
- Left-to-right for both languages
- Traditional Chinese characters (not Simplified)

#### Translation Coverage
- All UI labels and buttons
- Form placeholders
- Error messages
- Success messages
- Navigation items
- Status labels
- Date/time formatting (locale-aware)

#### Fallback
- If translation missing, show English
- Log missing translations for review

---

## Security Requirements

### SEC-1: Data Protection
- Database backups: Daily, retain 30 days
- Backup location: Separate drive/network location
- Test restore quarterly
- Personal data encrypted at rest (future enhancement)

### SEC-2: Access Control
- Network isolation: Local network only (no internet access)
- Windows Firewall rules: Allow port 3000 from LAN only
- User sessions: Auto-logout after 24 hours
- Failed login tracking: Lock after 5 attempts

### SEC-3: Audit Trail
- Log all sensitive operations in tb_AuditLog:
  - User login/logout
  - Leave request submission
  - Leave approval/rejection
  - Employee creation/modification
  - System setting changes
- Retain audit logs for 1 year

### SEC-4: Code Security
- No hardcoded credentials
- Environment variables for sensitive config
- Dependencies regularly updated
- No sensitive data in logs
- API keys not committed to source control

---

## Performance Requirements

### PERF-1: Response Time
- API endpoints: < 500ms (95th percentile)
- Page load: < 2 seconds (initial)
- Page transitions: < 500ms (SPA navigation)
- Database queries: < 200ms (average)

### PERF-2: Scalability
- Current users: 10
- Design supports: Up to 50 users
- Concurrent users: 10-15
- Database size: < 1GB expected (first 5 years)

### PERF-3: Availability
- Target uptime: 99% (business hours)
- Planned maintenance: Outside business hours
- Automatic restart on failure (PM2)
- Health check endpoint: `/api/health`

---

## Deployment Requirements

### DEP-1: Server Requirements

**Hardware:**
- CPU: 2 cores minimum (4 recommended)
- RAM: 4GB minimum (8GB recommended)
- Disk: 50GB available space (SSD preferred)
- Network: 1Gbps LAN connection

**Software:**
- OS: Windows 10/11 Pro or Windows Server 2016+
- Node.js: v18.0.0 or higher
- SQL Server: 2012 or higher
- PM2: Latest version
- Git: For version control (optional)

---

### DEP-2: Installation Steps

1. **Prepare Database**
   - Create database: `HRLeaveSystemDB`
   - Run DB scripts in order:
     1) 01_create_schema.sql
     2) 02_seed_data.sql
     3) 03_create_views.sql
     4) 04_create_stored_procedures.sql
     5) 05_rules_ddl.sql
     6) 06_computed_views.sql
     7) 07_business_procedures.sql
   - Configure SQL Server authentication
   - Note connection string

2. **Install Node.js**
   - Download from nodejs.org
   - Install LTS version (18.x or 20.x)
   - Verify: `node --version`

3. **Install Application**
   - Clone/copy application files to `C:\HRLeaveSystem`
   - Navigate to backend directory
   - Run: `npm install`
   - Navigate to frontend directory
   - Run: `npm install`

4. **Configure Environment**
   - Copy `backend\.env.example` to `backend\.env`
   - Update database connection string
   - Set JWT secret (random string)
   - Set PORT (default: 3000)

5. **Build Frontend**
   - Navigate to frontend directory
   - Run: `npm run build`
   - Dist files served by Express backend

6. **Install PM2**
   - Run: `npm install -g pm2`
   - Run: `npm install -g pm2-windows-service`
   - Configure PM2 ecosystem file

7. **Start Application**
   - Run: `pm2 start ecosystem.config.js`
   - Run: `pm2 save`
   - Install Windows service: `pm2-service-install`

8. **Configure Firewall**
   - Allow inbound port 3000
   - Restrict to local network IP range

9. **Test Access**
   - From server: `http://localhost:3000`
   - From network: `http://[server-ip]:3000`
   - Test login with admin credentials

---

### DEP-3: Configuration Files

**backend/.env**
```env
# Server
NODE_ENV=production
PORT=3000
HOST=0.0.0.0

# Database
DB_SERVER=localhost
DB_PORT=1433
DB_NAME=HRLeaveSystemDB
DB_USER=hrapp_user
DB_PASSWORD=your_secure_password
DB_ENCRYPT=false
DB_TRUST_SERVER_CERTIFICATE=true

# JWT
JWT_SECRET=your_random_secret_key_here
JWT_EXPIRES_IN=24h

# Logging
LOG_LEVEL=info
```

**ecosystem.config.js** (PM2)
```javascript
module.exports = {
  apps: [{
    name: 'hr-leave-system',
    script: './backend/server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production'
    },
    error_file: './logs/pm2-error.log',
    out_file: './logs/pm2-out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss Z'
  }]
}
```

---

## Success Metrics

### Usage Metrics
- Active users per week: Target 80%+ of employees
- Leave requests submitted: Track monthly volume
- Average approval time: Target < 24 hours
- Mobile vs desktop usage: Expect 70% mobile

### Performance Metrics
- Page load time: < 2 seconds
- API response time: < 500ms
- System uptime: > 99% during business hours
- Zero data loss incidents

### User Satisfaction
- User feedback surveys (quarterly)
- Support tickets/issues: Track and resolve
- Feature requests: Collect and prioritize

---

## Future Enhancements

### Phase 2 Features
1. **Email Notifications**
   - Leave request submitted notification
   - Approval/rejection notification
   - Upcoming leave reminders

2. **Mobile App**
   - Native iOS/Android apps
   - Push notifications
   - Offline mode

3. **Advanced Reporting**
   - Dashboard widgets
   - Customizable reports
   - Data visualization charts
   - Excel export with formatting

4. **Leave Delegation**
   - Delegate approval authority
   - Multi-level approval workflow
   - Auto-approve rules

5. **Integration**
   - Import employees from Active Directory
   - Export to payroll systems
   - Sync with Outlook calendar

6. **Bulk Operations**
   - Bulk approve/reject
   - Bulk import employees
   - Bulk leave allocation

7. **Enhanced Calendar**
   - Year view
   - Week view
   - Print-friendly format
   - Export to PDF/Excel

8. **Document Attachments**
   - Attach medical certificates
   - Attach supporting documents
   - File preview

9. **Leave Carry Forward**
   - Auto-rollover unused leave
   - Carry forward policies
   - Expiry tracking

10. **Department-Level Admins**
    - Department managers approve own team
    - Department-specific reports
    - Department-level settings

---

## Appendix

### A. Glossary
- **Leave Balance**: Remaining days available for a specific leave type
- **Leave Request**: Application for time off
- **Approval Workflow**: Process of reviewing and approving leave
- **JWT**: JSON Web Token for authentication
- **RBAC**: Role-Based Access Control

### B. References
- Vue 3 Documentation: https://vuejs.org
- Express.js Documentation: https://expressjs.com
- SQL Server Documentation: https://docs.microsoft.com/sql
- Tailwind CSS: https://tailwindcss.com

### C. Change Log

**Version 2.0.2 - October 20, 2025**
- Added employee edit pending leave requests feature
- Added employee delete pending leave requests feature
- Edit workflow uses localStorage for data transfer
- Delete requires confirmation with full request details
- Only pending requests can be edited/deleted
- Approved and rejected requests are protected
- Backend API endpoints: `PUT /api/leaves/request/:id`, `DELETE /api/leaves/request/:id`

**Version 2.0.1 - October 20, 2025**
- Enhanced admin employee management interface
- Added table view with sortable columns (default view)
- Added view toggle between table and grid layouts
- Default sort by employee ID/code
- Changed Add Employee button to high-visibility yellow
- Disabled personal info editing (view-only mode)
- Updated department examples to Transportation, Warehouse, Office
- Added activate/deactivate employee status toggle

**Version 2.0.0 - October 20, 2025**
- Multi-date selection for leave requests (consecutive and non-consecutive)
- Partial approval by admin with flexible date selection
- Blackout dates management and validation
- Enhanced calendar views with visual indicators
- Added `tb_LeaveRequestDates` and `tb_BlackoutDates` tables
- Calendar-based admin approval interface with 2-column layout
- Real-time working days calculation
- Complete rewrite with Vue 3 + Node.js backend
- Migrated from prototype to production system
- Added comprehensive database schema
- Implemented JWT authentication
- Added bilingual support (EN/ZH)
- Mobile-first responsive design

---

**Document Prepared By:** Development Team  
**Approval Required From:** HR Manager, IT Manager  
**Review Date:** Quarterly

---

