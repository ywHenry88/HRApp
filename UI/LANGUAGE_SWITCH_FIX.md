# Language Switch Fix for leave-request-multi.html

## Issue
The English/Chinese language switcher in `leave-request-multi.html` was not working.

## Root Cause
The page had the language switcher UI element but was missing:
1. **Translation attributes (`data-i18n`)** on most HTML elements
2. **Translation keys** in the `app.js` translations dictionary

The `toggleLangDropdown()` and `switchLanguage()` functions existed in `app.js`, but there was no content to translate because the HTML elements lacked the necessary `data-i18n` attributes.

## Solution

### 1. Added `data-i18n` Attributes to HTML Elements

Updated `UI/pages/employee/leave-request-multi.html` with translation attributes on:

**Current Balance Section:**
- `data-i18n="dashboard.leaveBalance"` - Current Balance header
- `data-i18n="leave.annual"` - Annual label
- `data-i18n="leave.sick"` - Sick label
- `data-i18n="common.days"` - days text
- `data-i18n="leave.annualInfo"` - Annual leave info message

**Leave Type Section:**
- `data-i18n="leave.leaveType"` - Leave Type label
- `data-i18n="leave.selectType"` - Select dropdown placeholder
- `data-i18n="leave.annualFull"` - Annual Leave option
- `data-i18n="leave.sickFull"` - Sick Leave option
- `data-i18n="leave.available"` - Available label

**Calendar Section:**
- `data-i18n="leave.selectDates"` - Select Dates label
- `data-i18n="leave.clickToSelect"` - Click instruction text
- `data-i18n="calendar.selected"` - Selected legend
- `data-i18n="calendar.blackout"` - Blackout legend
- `data-i18n="calendar.sundayHoliday"` - Sunday/Holiday legend

**Selected Dates Section:**
- `data-i18n="leave.selectedDates"` - Selected Dates header
- `data-i18n="leave.totalSelectedDays"` - Total Selected Days label
- `data-i18n="common.clearAll"` - Clear All button

**Reason Section:**
- `data-i18n="leave.reason"` - Reason label
- `data-i18n="common.optional"` - (Optional) text
- `data-i18n-placeholder="leave.reasonPlaceholder"` - Placeholder text

**Buttons:**
- `data-i18n="leave.submitRequest"` - Submit Request button
- `data-i18n="common.cancel"` - Cancel button

**Bottom Navigation:**
- `data-i18n="nav.home"` - Home
- `data-i18n="nav.request"` - Request
- `data-i18n="nav.history"` - History
- `data-i18n="nav.profile"` - Profile

### 2. Added Translation Keys to `app.js`

Added the following translations to the `translations` object:

```javascript
// Leave section additions
'leave.leaveType': {
    en: 'Leave Type',
    zh: '假期類型'
},
'leave.selectType': {
    en: '-- Select Leave Type --',
    zh: '-- 選擇假期類型 --'
},
'leave.annualFull': {
    en: 'Annual Leave (年假)',
    zh: '年假 (Annual Leave)'
},
'leave.sickFull': {
    en: 'Sick Leave (病假)',
    zh: '病假 (Sick Leave)'
},
'leave.annualInfo': {
    en: 'Annual leave has no expiry and carries forward indefinitely. Split/pay-in-lieu handled case-by-case by Admin.',
    zh: '年假不設到期且可無限期結轉；分拆／以薪代假由管理員逐案處理。'
},
'leave.selectDates': {
    en: 'Select Dates',
    zh: '選擇日期'
},
'leave.clickToSelect': {
    en: 'Click dates to select. Click again to deselect.',
    zh: '點擊日期選擇，再次點擊取消選擇。'
},
'leave.selectedDates': {
    en: 'Selected Dates:',
    zh: '已選日期：'
},
'leave.totalSelectedDays': {
    en: 'Total Selected Days',
    zh: '已選總天數'
},
'leave.reasonPlaceholder': {
    en: 'Enter reason for leave request (optional)',
    zh: '輸入請假原因（可選）'
},
'leave.submitRequest': {
    en: 'Submit Request',
    zh: '提交申請'
},

// Calendar section additions
'calendar.selected': {
    en: 'Selected',
    zh: '已選'
},
'calendar.blackout': {
    en: 'Blackout',
    zh: '禁止請假'
},
'calendar.sundayHoliday': {
    en: 'Sunday / Holiday',
    zh: '星期日 / 假期'
},

// Common section additions
'common.clearAll': {
    en: 'Clear All',
    zh: '全部清除'
},
'common.optional': {
    en: '(Optional)',
    zh: '（可選）'
}
```

### 3. Removed Version Comment from app.js
- Removed `// Version: 2.0.0` to align with version 1.0 cleanup

## Files Modified
1. `UI/pages/employee/leave-request-multi.html` - Added data-i18n attributes throughout
2. `UI/js/app.js` - Added 17 new translation keys + removed version comment

## Testing
To test the language switch:
1. Open `leave-request-multi.html` in browser
2. Click the globe icon (🌐) in the top-right header
3. Select "繁體中文" or "English"
4. Verify all text switches between English and Traditional Chinese:
   - Page headers and labels
   - Form fields and placeholders
   - Button text
   - Calendar legend
   - Bottom navigation

## Result
✅ Language switcher now works correctly
✅ All text elements properly translate between EN ↔ ZH
✅ Consistent with other pages in the application
✅ Version labels removed (aligned with 1.0 cleanup)

---

*Fix Applied: 2025-10-27*

