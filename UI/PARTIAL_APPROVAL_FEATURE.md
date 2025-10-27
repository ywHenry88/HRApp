# Partial Approval Feature - Complete Implementation

**Version:** 2.0.0  
**Date:** October 20, 2025  
**Status:** ✅ FULLY IMPLEMENTED IN HTML UI

---

## 📋 Overview

The **Partial Approval** feature allows administrators to approve specific dates from a leave request instead of all-or-nothing approval. This provides flexibility in managing leave requests when only some requested dates can be approved.

### Key Concept

> **"Final approved days are confirmed by Admin, the approved days may or may not be same as applied days."**

**Example:**
- Employee requests: Oct 20, 21, 22 (3 days)
- Admin approves: Oct 20, 21 only (2 days)
- Result: Partial approval - 2 out of 3 days approved

---

## 🎯 Feature Requirements

### Employee Perspective
1. ✅ Can apply for consecutive OR non-consecutive days in a single request
2. ✅ See clearly which dates were approved vs not approved
3. ✅ Understand partial approval status in leave history
4. ✅ Receive clear feedback about final approved days

### Admin Perspective
1. ✅ View all requested dates with checkboxes
2. ✅ Select/deselect individual dates for approval
3. ✅ See working day count update in real-time
4. ✅ Option to approve all or selected dates only
5. ✅ Add comments explaining partial approval decision

---

## 💾 Database Implementation

### New/Modified Tables

#### 1. `tb_LeaveRequestDates` (NEW)
Stores individual dates for each request:
```sql
CREATE TABLE tb_LeaveRequestDates (
    RequestDateID INT IDENTITY(1,1) PRIMARY KEY,
    RequestID INT NOT NULL,
    LeaveDate DATE NOT NULL,
    DateStatus NVARCHAR(20) NOT NULL DEFAULT 'Requested',
        -- Values: 'Requested', 'Approved', 'Rejected', 'Removed'
    IsWorkingDay BIT NOT NULL DEFAULT 1,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    LastModifiedDate DATETIME NULL,
    
    CONSTRAINT UK_tb_LeaveRequestDates UNIQUE (RequestID, LeaveDate),
    CONSTRAINT FK_tb_LeaveRequestDates_Request FOREIGN KEY (RequestID) 
        REFERENCES tb_LeaveRequests(RequestID) ON DELETE CASCADE
);
```

#### 2. `tb_LeaveRequests` (ENHANCED)
Added fields for partial approval tracking:
```sql
ALTER TABLE tb_LeaveRequests ADD
    ApprovedDaysCount INT NULL,           -- Actual approved working days
    PartialApproval BIT NOT NULL DEFAULT 0, -- Flag for partial approval
    LastModifiedDate DATETIME NULL;
```

---

## 🔧 Backend API Implementation

### Approve Leave Request (Enhanced)

**Endpoint:** `PUT /api/admin/leaves/approve/:id`

**Request Body:**
```json
{
  "approvedDates": ["2025-10-20", "2025-10-21"],  // Specific dates to approve
  "comments": "Approved only 2 days due to workload"
}
```

**OR for full approval:**
```json
{
  "approvedDates": null,  // null = approve all requested dates
  "comments": "Approved"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Leave request partially approved",
  "data": {
    "requestId": 123,
    "requestedDays": 3,
    "approvedDays": 2,
    "partialApproval": true,
    "approvedDates": ["2025-10-20", "2025-10-21"],
    "notApprovedDates": ["2025-10-22"]
  }
}
```

---

## 🎨 UI Implementation

### 1. Admin Approval Modal (`approve-leaves.html`)

#### A. Requested Dates Section

Visual display with checkboxes:

```html
<div class="mb-6">
    <div class="flex items-center justify-between mb-3">
        <h4 class="text-sm font-medium text-gray-600">
            <i class="fas fa-calendar-check text-[#00AFB9] mr-1"></i>
            Requested Dates 
            <span class="text-xs bg-yellow-100 text-yellow-800 px-2 py-0.5 rounded ml-2">v2.0</span>
        </h4>
        <div class="text-xs text-gray-500">
            <span class="font-medium text-gray-700" id="selectedDatesCount">0</span> selected
        </div>
    </div>
    
    <!-- Info banner -->
    <div class="bg-blue-50 border border-blue-200 rounded-lg p-3 mb-3">
        <p class="text-xs text-blue-700">
            <i class="fas fa-info-circle mr-1"></i>
            <strong>Partial Approval:</strong> You can approve specific dates instead of all-or-nothing. 
            Uncheck dates you don't want to approve.
        </p>
    </div>
    
    <!-- Date list with checkboxes -->
    <div class="bg-gray-50 rounded-lg p-3 max-h-64 overflow-y-auto">
        <div class="space-y-2">
            <!-- Each requested date -->
            <label class="flex items-center p-2 hover:bg-white rounded cursor-pointer">
                <input type="checkbox" checked 
                    class="requested-date-checkbox w-4 h-4 text-[#00AFB9] rounded" 
                    data-date="2025-11-15" 
                    data-working-day="true">
                <span class="ml-3 flex-1">
                    <span class="text-sm font-medium text-gray-800">2025-11-15</span>
                    <span class="text-xs text-gray-500 ml-2">(Monday)</span>
                    <span class="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded ml-2">
                        Working Day
                    </span>
                </span>
            </label>
            <!-- More dates... -->
        </div>
    </div>
    
    <!-- Working days counter -->
    <div class="mt-3 flex items-center justify-between p-3 bg-[#00AFB9] bg-opacity-10 rounded-lg">
        <div>
            <p class="text-xs text-gray-600">Working Days to Approve:</p>
            <p class="text-lg font-bold text-[#00AFB9]" id="approvalWorkingDays">3</p>
        </div>
        <button onclick="toggleAllDates()" class="text-xs text-[#00AFB9] hover:text-[#009ba3] font-medium">
            <i class="fas fa-check-double mr-1"></i>Select All / None
        </button>
    </div>
</div>
```

#### B. Action Buttons

Three approval options:

```html
<div class="space-y-2">
    <!-- Primary: Approve selected dates -->
    <button onclick="approveSelectedDates()" 
        class="w-full bg-green-500 hover:bg-green-600 text-white font-medium py-3 px-6 rounded-lg">
        <i class="fas fa-check-circle mr-2"></i>
        Approve Selected Dates
        <span class="ml-2 text-xs bg-green-600 bg-opacity-50 px-2 py-1 rounded" 
            id="approveButtonCount">(3)</span>
    </button>
    
    <!-- Secondary options -->
    <div class="grid grid-cols-2 gap-2">
        <button onclick="approveAllDates()" 
            class="bg-[#00AFB9] hover:bg-[#009ba3] text-white font-medium py-2 px-4 rounded-lg text-sm">
            <i class="fas fa-check-double mr-1"></i>Approve All
        </button>
        <button onclick="rejectFromModal()" 
            class="bg-red-500 hover:bg-red-600 text-white font-medium py-2 px-4 rounded-lg text-sm">
            <i class="fas fa-times mr-1"></i>Reject All
        </button>
    </div>
</div>
```

#### C. JavaScript Functions

```javascript
// Update counts when checkboxes change
function updateApprovalCounts() {
    const checkboxes = document.querySelectorAll('.requested-date-checkbox');
    let selectedCount = 0;
    let workingDaysCount = 0;

    checkboxes.forEach(checkbox => {
        if (checkbox.checked) {
            selectedCount++;
            if (checkbox.dataset.workingDay === 'true') {
                workingDaysCount++;
            }
        }
    });

    document.getElementById('selectedDatesCount').textContent = selectedCount;
    document.getElementById('approvalWorkingDays').textContent = workingDaysCount;
    document.getElementById('approveButtonCount').textContent = `(${workingDaysCount})`;
}

// Approve only selected dates (PARTIAL APPROVAL)
function approveSelectedDates() {
    const checkboxes = document.querySelectorAll('.requested-date-checkbox:checked');
    const selectedDates = Array.from(checkboxes).map(cb => cb.dataset.date);
    const comments = document.getElementById('adminComments').value;

    if (selectedDates.length === 0) {
        showAlert('Please select at least one date to approve', 'error');
        return;
    }

    // API call: PUT /api/admin/leaves/approve/:id
    // Body: { approvedDates: selectedDates, comments }
    
    const workingDaysCount = Array.from(checkboxes)
        .filter(cb => cb.dataset.workingDay === 'true').length;

    showAlert(`Approved ${workingDaysCount} working days successfully!`, 'success');
    // Refresh page or update UI
}

// Approve all dates (FULL APPROVAL)
function approveAllDates() {
    const comments = document.getElementById('adminComments').value;
    
    // API call: PUT /api/admin/leaves/approve/:id
    // Body: { approvedDates: null, comments }  // null = approve all

    showAlert('All dates approved successfully!', 'success');
}

// Toggle all checkboxes
function toggleAllDates() {
    const checkboxes = document.querySelectorAll('.requested-date-checkbox');
    const firstCheckbox = checkboxes[0];
    const newState = !firstCheckbox.checked;
    
    checkboxes.forEach(checkbox => {
        checkbox.checked = newState;
    });
    
    updateApprovalCounts();
}

// Add event listeners
document.addEventListener('DOMContentLoaded', function() {
    const checkboxes = document.querySelectorAll('.requested-date-checkbox');
    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', updateApprovalCounts);
    });
    
    updateApprovalCounts();
});
```

---

### 2. Employee Leave History (`leave-history.html`)

#### Partial Approval Display

Visual indicators for partial approval:

```javascript
// In createRequestCard function:

// Show partial approval badge next to days count
<div class="flex items-center text-sm">
    <i class="fas fa-clock text-gray-400 w-5"></i>
    <span class="text-gray-700">${request.days} ${request.days === 1 ? 'day' : 'days'} requested</span>
    ${request.status === 'approved' && request.partialApproval ? `
        <span class="ml-2 px-2 py-0.5 bg-orange-100 text-orange-700 text-xs rounded-full font-medium">
            <i class="fas fa-info-circle mr-1"></i>Only ${request.approvedDays} approved
        </span>
    ` : ''}
</div>

// Show detailed breakdown of approved/not approved dates
${request.status === 'approved' && request.partialApproval && request.requestedDates && request.approvedDates ? `
    <div class="mt-3 p-3 bg-yellow-50 border border-yellow-200 rounded">
        <p class="text-xs font-medium text-yellow-800 mb-2">
            <i class="fas fa-exclamation-triangle mr-1"></i>Partial Approval
        </p>
        <div class="text-xs text-gray-700 space-y-1">
            <div><strong>Approved Dates:</strong> ${request.approvedDates.map(d => formatDate(d)).join(', ')}</div>
            <div class="text-red-600">
                <strong>Not Approved:</strong> ${request.requestedDates.filter(d => !request.approvedDates.includes(d)).map(d => formatDate(d)).join(', ') || 'None'}
            </div>
        </div>
    </div>
` : ''}
```

#### Sample Data Structure

```javascript
{
    id: 3,
    type: 'personal',
    typeName: 'Annual Leave',
    startDate: '2025-09-20',
    endDate: '2025-09-22',
    days: 3,  // Requested 3 days
    reason: 'Personal matters',
    status: 'approved',
    submittedDate: '2025-09-15',
    approvedDate: '2025-09-16',
    approver: 'Admin',
    comments: 'Approved only 2 days due to workload',
    
    // v2.0 Partial Approval fields
    partialApproval: true,  // Flag indicating partial approval
    approvedDays: 2,  // Only 2 working days approved
    requestedDates: ['2025-09-20', '2025-09-21', '2025-09-22'],
    approvedDates: ['2025-09-20', '2025-09-21']  // 2025-09-22 not approved
}
```

---

## 📊 Visual Examples

### Admin View - Partial Approval Modal

```
┌─────────────────────────────────────────────────────────┐
│ Leave Request Details                              [X]   │
├─────────────────────────────────────────────────────────┤
│                                                           │
│ 📋 Employee: John Doe                                    │
│    Department: Engineering                               │
│                                                           │
│ 📅 Requested Dates                           v2.0        │
│    3 selected                                            │
│                                                           │
│    ℹ️ Partial Approval: You can approve specific dates   │
│      instead of all-or-nothing.                          │
│                                                           │
│    ┌─────────────────────────────────────────────┐      │
│    │ ☑️ 2025-11-15 (Monday) [Working Day]        │      │
│    │ ☑️ 2025-11-16 (Tuesday) [Working Day]       │      │
│    │ ☐ 2025-11-19 (Friday) [Working Day]         │      │
│    └─────────────────────────────────────────────┘      │
│                                                           │
│    Working Days to Approve: 2    [✓✓ Select All/None]  │
│                                                           │
│ 💬 Admin Comments:                                       │
│    ┌─────────────────────────────────────────────┐      │
│    │ Approved only 2 days due to workload        │      │
│    └─────────────────────────────────────────────┘      │
│                                                           │
│    ┌─────────────────────────────────────────────┐      │
│    │   ✓ Approve Selected Dates (2)              │      │
│    └─────────────────────────────────────────────┘      │
│    ┌────────────────────┬────────────────────────┐      │
│    │ ✓✓ Approve All     │ ✗ Reject All           │      │
│    └────────────────────┴────────────────────────┘      │
└─────────────────────────────────────────────────────────┘
```

### Employee View - Partial Approval Status

```
┌─────────────────────────────────────────────────────────┐
│ Annual Leave 年假                              ⚠️ Approved│
├─────────────────────────────────────────────────────────┤
│ 📅 2025-09-20 - 2025-09-22                               │
│ 🕐 3 days requested [ℹ️ Only 2 approved]                │
│ 💬 Personal matters                                      │
│ ✉️ Submitted: 2025-09-15                                 │
│ ✅ Approved by Admin on 2025-09-16                       │
│                                                           │
│ ⚠️ Partial Approval                                      │
│ ✅ Approved Dates: Sep 20, Sep 21                        │
│ ❌ Not Approved: Sep 22                                  │
│                                                           │
│ 💬 Admin Comment: Approved only 2 days due to workload  │
└─────────────────────────────────────────────────────────┘
```

---

## ✅ Testing Checklist

### Admin Testing
- [ ] Can view all requested dates in modal
- [ ] Can select/deselect individual dates
- [ ] Working days counter updates correctly
- [ ] Can approve selected dates only
- [ ] Can approve all dates at once
- [ ] Can reject all dates
- [ ] Comments field works
- [ ] "Select All/None" toggle works
- [ ] Visual feedback for selected dates

### Employee Testing
- [ ] Can see "Only X approved" badge for partial approvals
- [ ] Can see detailed breakdown of approved vs not approved dates
- [ ] Partial approval warning is visible
- [ ] Admin comments are displayed
- [ ] Status badge shows "Approved" (not rejected)
- [ ] Leave balance reflects only approved days

---

## 🔄 Workflow Example

### Scenario: Partial Approval

1. **Employee submits request:**
   - Dates: Oct 20, 21, 22 (3 working days)
   - Type: Annual Leave
   - Reason: "Family vacation"

2. **Admin reviews:**
   - Opens approval modal
   - Sees 3 dates with checkboxes (all checked by default)
   - Workload issue on Oct 22
   - **Unchecks** Oct 22
   - Working days counter shows: 2 days
   - Adds comment: "Can only approve 2 days due to project deadline"
   - Clicks "Approve Selected Dates (2)"

3. **System processes:**
   - Updates `tb_LeaveRequestDates`:
     - Oct 20: DateStatus = 'Approved'
     - Oct 21: DateStatus = 'Approved'
     - Oct 22: DateStatus = 'Rejected'
   - Updates `tb_LeaveRequests`:
     - Status = 'Approved'
     - PartialApproval = 1
     - ApprovedDaysCount = 2
   - Updates `tb_LeaveBalances`:
     - Deducts only 2 days (not 3)

4. **Employee sees:**
   - Status: Approved ⚠️
   - Badge: "Only 2 approved"
   - Partial Approval warning box
   - Approved: Oct 20, 21
   - Not Approved: Oct 22
   - Admin comment visible

---

## 📝 Documentation Updates

### Files Updated
1. ✅ `README.md` - Feature overview and key concepts
2. ✅ `IMPLEMENTATION_GUIDE.md` - Technical implementation details
3. ✅ `UI/pages/admin/approve-leaves.html` - Admin approval UI
4. ✅ `UI/pages/employee/leave-history.html` - Employee history with partial approval display
5. ✅ `database/01_create_schema.sql` - Database schema with new fields
6. ✅ `database/04_create_stored_procedures.sql` - Enhanced procedures
7. ✅ `UI/PARTIAL_APPROVAL_FEATURE.md` - This document (complete feature documentation)

---

## 🚀 Status

**Status:** ✅ COMPLETE (HTML UI Implementation)

**What's Done:**
- ✅ Admin approval modal with checkbox UI
- ✅ Real-time working days counter
- ✅ JavaScript functions for partial approval
- ✅ Employee history with partial approval display
- ✅ Visual indicators and badges
- ✅ Sample data with partial approval examples
- ✅ Complete documentation

**Next Steps (Backend Implementation):**
- [ ] Implement `PUT /api/admin/leaves/approve/:id` with partial approval logic
- [ ] Update leave balance calculation to use approved days only
- [ ] Add validation for at least one date must be approved
- [ ] Test with SQL Server stored procedures
- [ ] Integration testing

---

## 📞 Support

For questions about this feature, refer to:
- `IMPLEMENTATION_GUIDE.md` - Backend implementation details
- `database/04_create_stored_procedures.sql` - Database logic
- This file - Complete UI implementation guide

**Version:** 2.0.0  
**Last Updated:** October 20, 2025  
**Feature Status:** UI Complete, Backend Pending

