# Implementation Guide - Version 2.1 Updates

**Date:** October 23, 2025  
**Status:** Database & Procedures Complete | UI prototype updated with real-time holidays

---

## ✅ COMPLETED (Ready to Use)

### 1. Database Schema (v2.0)
**File:** `database/01_create_schema.sql`

**New Tables:**
- ✅ `tb_LeaveRequestDates` - Individual date tracking
- ✅ `tb_BlackoutDates` - Blackout date management
- ✅ Enhanced `tb_LeaveRequests` - Added RequestedDaysCount, ApprovedDaysCount, PartialApproval

**To Deploy:**
```sql
-- Execute in SQL Server Management Studio
USE master;
GO
-- Run: database/01_create_schema.sql
```

### 2. Stored Procedures (v2.1)
**Files:**
- `database/04_create_stored_procedures.sql` (core v2.0)
- `database/07_business_procedures.sql` (rules stubs)

**Procedures:**
- ✅ `sp_SubmitLeaveRequest` - Multi-date submission with blackout validation
- ✅ `sp_ApproveLeaveRequest` - Partial approval support
- ✅ `sp_GenerateBlackoutDates` - Auto-generate from holidays
- ✅ `fn_IsBlackoutDate` - Helper function
- ✅ `fn_CalculateWorkingDays` - Helper function
- ✅ `sp_UpsertHolidays_TVP` - Merge holidays from TVP (new in v2.1)

**To Deploy:**
```sql
USE HRLeaveSystemDB;
GO
-- Run: database/04_create_stored_procedures.sql
```

### 3. Documentation
- ✅ `IMPLEMENTATION_GUIDE.md` - This file
- ✅ `README.md` - Updated with v2.0 features
- ✅ `RULES.md` - Core leave logic (authoritative)

---

## 🔄 PENDING IMPLEMENTATION

### UI Components (Priority Order)

#### 1. Multi-Date Leave Request Form (Updated with real-time holidays)
**Location:** `UI/pages/employee/leave-request-multi.html`

**Features to Implement:**
- Calendar-based date picker
- Multi-select dates (consecutive/non-consecutive)
- Real-time blackout date display
- Visual indicators:
  ```
  ❌ Red = Blackout (cannot select)
  🔴 Light Pink = Weekends
  🟡 Light Yellow = Holidays
  ✅ Green = Selected dates
  ```
- Working days counter
- Submit with date array

**Holiday Source (Real-Time):**
- EN: `https://www.1823.gov.hk/common/ical/en.json`
- 繁: `https://www.1823.gov.hk/common/ical/tc.json`

**Helper Functions (in `UI/js/app.js`, v2.1):**
- `ensureHolidaysLoaded()`, `getHolidaySet()`, `fetchHKHolidays(lang)`, `getHolidayNamesByDate(date)`

**Sample Code Structure:**
```html
<div class="calendar-picker">
    <div class="calendar-month">
        <button onclick="prevMonth()">◀</button>
        <span id="currentMonth">November 2025</span>
        <button onclick="nextMonth()">▶</button>
    </div>
    <div class="calendar-grid" id="calendarGrid">
        <!-- Generate 7x6 grid for month -->
    </div>
    <div class="selected-dates">
        <h4>Selected Dates:</h4>
        <ul id="selectedDatesList"></ul>
        <p>Total Working Days: <strong id="workingDaysCount">0</strong></p>
    </div>
</div>
```

#### 2. Enhanced Team Calendar
**Location:** `UI/pages/admin/team-calendar.html` or `UI/pages/employee/team-calendar.html`

**Based on:** `hr.reference/hr_calendar/` design

**Two Views:**

**A. Traditional Calendar View:**
```html
<table class="calendar">
    <thead>
        <tr>
            <th>Sun</th><th>Mon</th>...
        </tr>
    </thead>
    <tbody>
        <tr>
            <td class="day">
                <div class="date-number">1</div>
                <div class="leave-entries">
                    <span class="leave-badge annual">John: AL</span>
                    <span class="leave-badge sick">Mary: SL</span>
                </div>
            </td>
            ...
        </tr>
    </tbody>
</table>
```

**B. Employee Grid View:**
```html
<table class="employee-grid">
    <thead>
        <tr>
            <th>Employee</th>
            <th>1</th><th>2</th>...<th>31</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>John (L888)</td>
            <td></td>
            <td class="leave annual">AL</td>
            <td class="leave annual">AL</td>
            ...
        </tr>
    </tbody>
</table>
```

**Features:**
- Toggle between views
- Department filter
- Status filter (On Hold/Approved)
- Sortable employee list
- Click cell for details
- Export to PDF

#### 3. Blackout Dates Management
**Location:** `UI/pages/admin/blackout-dates.html`

**Features:**
- Calendar view showing blackout dates
- List view with search/filter
- Add/Edit/Delete blackout dates
- "Generate from Holidays" button
- Bilingual reason entry

**CRUD Operations:**
```javascript
// Add blackout date
POST /api/admin/blackout-dates
{
    blackoutDate: "2025-12-24",
    reason_en: "Day before Christmas",
    reason_zh: "聖誕節前一天"
}

// Delete blackout date
DELETE /api/admin/blackout-dates/:id

// Auto-generate
POST /api/admin/blackout-dates/generate
{ year: 2025 }
```

#### 4. Approval UI (Simplified)
**Location:** `UI/pages/admin/approve-leaves.html`

**Update:** Simplify actions to approve or reject only with comments. Remove date selection UI from modal.

---

#### 5. Compensatory Leave Module (NEW)
**Location:** `UI/pages/admin/compensatory-leave.html`

**Features:**
- Add compensatory leave with decimal days and optional reason
- Search and list records; delete action

**Backend API (to add):**
```
POST /api/admin/compensatory-leave { userId, days, reason }
GET  /api/admin/compensatory-leave?userId=&year=
DELETE /api/admin/compensatory-leave/:id
```

---

## 🔧 Backend API Updates Needed (after DB complete)

### Employee Endpoints

#### POST `/api/leaves/request`
```javascript
// In leaveController.js
router.post('/request', async (req, res) => {
    const { leaveTypeId, leaveDates, reason } = req.body;
    const userId = req.user.userId;
    
    // Convert date array to comma-separated string
    const dateString = leaveDates.join(',');
    
    // Call stored procedure
    const result = await executeSP('sp_SubmitLeaveRequest', {
        UserID: userId,
        LeaveTypeID: leaveTypeId,
        LeaveDates: dateString,
        Reason: reason
    });
    
    // Handle result codes
    if (result.returnValue === 0) {
        return res.json({
            success: true,
            data: { requestId: result.output.RequestID }
        });
    } else {
        // Map error codes to messages
        const errorMessages = {
            '-5': 'One or more dates are blackout dates',
            '-8': 'Insufficient leave balance'
        };
        return res.json({
            success: false,
            error: errorMessages[result.returnValue] || 'Failed to submit'
        });
    }
});
```

#### GET `/api/leaves/blackout-dates`
```javascript
router.get('/blackout-dates', async (req, res) => {
    const { year, month } = req.query;
    
    const query = `
        SELECT BlackoutDate, Reason_EN, Reason_ZH
        FROM tb_BlackoutDates
        WHERE IsActive = 1
        AND YEAR(BlackoutDate) = @Year
        AND (@Month IS NULL OR MONTH(BlackoutDate) = @Month)
        ORDER BY BlackoutDate
    `;
    
    const result = await executeQuery(query, { Year: year, Month: month });
    res.json({ success: true, data: result });
});
```

### Admin Endpoints

#### PUT `/api/admin/leaves/approve/:id`
```javascript
router.put('/approve/:id', async (req, res) => {
    const requestId = req.params.id;
    const { approvedDates, comments } = req.body;
    const adminId = req.user.userId;
    
    // approvedDates can be null (approve all) or array of dates
    const dateString = approvedDates ? approvedDates.join(',') : null;
    
    const result = await executeSP('sp_ApproveLeaveRequest', {
        RequestID: requestId,
        ApprovedBy: adminId,
        ApprovedDates: dateString,
        Comments: comments
    });
    
    if (result.returnValue === 0) {
        return res.json({
            success: true,
            message: 'Leave request approved'
        });
    }
});
```

#### Blackout Dates CRUD
```javascript
// GET all
router.get('/blackout-dates', async (req, res) => {...});

// POST new
router.post('/blackout-dates', async (req, res) => {
    const { blackoutDate, reason_en, reason_zh } = req.body;
    const adminId = req.user.userId;
    
    const query = `
        INSERT INTO tb_BlackoutDates 
        (BlackoutDate, Reason_EN, Reason_ZH, CreatedBy)
        VALUES (@Date, @ReasonEN, @ReasonZH, @CreatedBy)
    `;
    
    await executeQuery(query, {
        Date: blackoutDate,
        ReasonEN: reason_en,
        ReasonZH: reason_zh,
        CreatedBy: adminId
    });
    
    res.json({ success: true });
});

// DELETE
router.delete('/blackout-dates/:id', async (req, res) => {
    const query = `
        DELETE FROM tb_BlackoutDates 
        WHERE BlackoutID = @ID
    `;
    await executeQuery(query, { ID: req.params.id });
    res.json({ success: true });
});

// POST generate
router.post('/blackout-dates/generate', async (req, res) => {
    const { year } = req.body;
    const adminId = req.user.userId;
    
    const result = await executeSP('sp_GenerateBlackoutDates', {
        Year: year,
        CreatedBy: adminId
    });
    
    res.json({
        success: true,
        data: { created: result.returnValue }
    });
});
```

---

## 🎨 CSS Styles Needed

### For Multi-Date Picker
```css
.calendar-picker {
    background: white;
    border-radius: 12px;
    padding: 1rem;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.calendar-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
    gap: 4px;
}

.calendar-day {
    aspect-ratio: 1;
    border: 1px solid #e5e7eb;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.2s;
}

.calendar-day:hover:not(.disabled) {
    background: #f3f4f6;
}

.calendar-day.weekend {
    background: #fce4ec;
}

.calendar-day.holiday {
    background: #fff3cd;
}

.calendar-day.blackout {
    background: #fee2e2;
    cursor: not-allowed;
    position: relative;
}

.calendar-day.blackout::after {
    content: '❌';
    position: absolute;
    top: 2px;
    right: 2px;
    font-size: 10px;
}

.calendar-day.selected {
    background: #10b981;
    color: white;
    font-weight: bold;
}

.calendar-day.disabled {
    opacity: 0.3;
    cursor: not-allowed;
}
```

### For Employee Grid View
```css
.employee-grid {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
}

.employee-grid th,
.employee-grid td {
    border: 1px solid #e5e7eb;
    padding: 8px 4px;
    text-align: center;
}

.employee-grid th:first-child,
.employee-grid td:first-child {
    text-align: left;
    position: sticky;
    left: 0;
    background: white;
    font-weight: 600;
    min-width: 150px;
}

.employee-grid .leave {
    font-weight: bold;
    font-size: 10px;
}

.employee-grid .leave.annual {
    background: rgba(0,175,185,0.2);
    color: #00AFB9;
}

.employee-grid .leave.sick {
    background: rgba(255,107,107,0.2);
    color: #FF6B6B;
}

.employee-grid .leave.personal {
    background: rgba(255,209,102,0.2);
    color: #FFD166;
}

.employee-grid .leave.study {
    background: rgba(6,214,160,0.2);
    color: #06D6A0;
}
```

---

## 🧪 Testing Checklist

Before deployment, test:

- [ ] Submit multi-date leave request (consecutive)
- [ ] Submit multi-date leave request (non-consecutive)
- [ ] Try to select blackout date (should prevent)
- [ ] Submit request with more days than balance (should error)
- [ ] Admin approves all dates
- [ ] Admin approves some dates (partial approval)
- [ ] Admin rejects all dates
- [ ] View team calendar in both views
- [ ] Filter calendar by department
- [ ] Add blackout date manually
- [ ] Generate blackout dates from holidays
- [ ] Delete blackout date
- [ ] View leave history showing partial approval

---

## 📝 User Training Notes

### For Employees
1. **Multi-Date Selection:**
   - "You can now select multiple dates for one leave request"
   - "Click dates on calendar - they turn green when selected"
   - "Red X dates cannot be selected (blackout dates)"
   - "You can select non-consecutive dates (e.g., Mon, Wed, Fri)"

2. **Approval:**
   - "Admin approves or rejects requests as a whole"
   - "Check the status and comments in your leave history"

### For Admins
1. **Approval Process:**
   - "Approve or reject entire requests"
   - "Add comments to explain decisions"

2. **Blackout Dates:**
   - "Configure dates employees cannot request"
   - "Auto-generate: day before holidays"
   - "Add custom blackout dates as needed"

3. **Compensatory Leave:**
   - "Grant compensatory leave in decimal days (e.g., 2.5)"
   - "Use the Compensatory Leave module in Admin sidebar"

---

## 🚀 Quick Start (After UI Implementation)

1. **Deploy Database:**
   ```sql
   -- Run: database/01_create_schema.sql
   -- Run: database/04_create_stored_procedures.sql
   ```

2. **Generate Initial Blackout Dates:**
   ```sql
   EXEC sp_GenerateBlackoutDates @Year = 2025, @CreatedBy = 1;
   ```

3. **(Optional) Sync Holidays from 1823 into Database:**
```sql
-- Prepare TVP rows (example)
DECLARE @tvp dbo.HolidayImportType;
INSERT INTO @tvp(HolidayDate, HolidayName_EN, HolidayName_ZH, [Year], SourceUID, SourceProvider)
VALUES ('2025-01-01','The first day of January','元旦',2025,'20250101@1823.gov.hk','1823.gov.hk');

DECLARE @ins INT, @upd INT;
EXEC dbo.sp_UpsertHolidays_TVP @Holidays=@tvp, @InsertedCount=@ins OUTPUT, @UpdatedCount=@upd OUTPUT;
SELECT Inserted=@ins, Updated=@upd;
```

3. **Update Backend:**
   - Add new API endpoints
   - Update controllers

4. **Deploy Frontend:**
   - Upload new UI pages
   - Update existing pages

5. **Test:**
   - Run through testing checklist
   - Verify all scenarios work

6. **Train Users:**
   - Demo new features
   - Provide user guide

---

## 📞 Support

**Database Issues:**
- Check stored procedure return codes
- Review tb_AuditLog for errors
- Verify blackout dates loaded correctly

**UI Issues:**
- Check browser console for JavaScript errors
- Verify API endpoints returning correct data
- Test in different browsers

**Business Logic:**
- Refer to database schema documentation
- Check stored procedure logic in `database/04_create_stored_procedures.sql`
- Review validation rules in PRD.md

---

**Status:** Database & Procedures ✅ Complete | UI prototype ✅ Updated  
**Version:** 2.1.0  
**Last Updated:** October 23, 2025

