# Employee Dashboard Update - Version 2.2.1

**Date:** October 28, 2025  
**File:** `UI/pages/employee/dashboard.html`  
**Status:** ✅ COMPLETE

---

## 📋 Changes Summary

### 1. ✅ Removed "From SQL Server tb_Users" Text
- **Location:** Welcome section
- **Before:** Displayed database source reference below employee name
- **After:** Removed to clean up the UI

### 2. ✅ Moved Today's Date to Top Header
- **Location:** Top header, before global language icon
- **Before:** Date was in the welcome section below employee name
- **After:** Date now displays in top-right header: `Monday, October 20, 2025`
- **Purpose:** Better visibility and consistent header layout

### 3. ✅ Added Hire Date and Current Period Display
- **Location:** Welcome section, below employee name
- **Added Information:**
  - **Hire date (入職日期):** `01/01/2025`
  - **Current period (當前服務期間):** `2025-01-01 → 2025-12-31`
- **Format:** Bilingual labels with clear formatting

### 4. ✅ Updated Annual Leave Display
- **Location:** Leave Balance section, Annual Leave card

**Before:**
```
14.5 / 16.5 days
Breakdown: X + Y + Z − W
```

**After:**
```
5 / 11 days (按年授予)
11 + 7.8 = 18.8 days (按比例估算)

ℹ️ 5 days applied in current period
當前期間已申請5天（不含以薪代假）
```

**Key Changes:**
- Shows **5 / 11 days (按年授予)** - Used/Total in current grant period
- Shows **11 + 7.8 = 18.8 days (按比例估算)** - Prorated calculation
- Clear explanation that 5 days are already applied in current period
- Excludes payment in lieu (以薪代假) from the count
- Simplified, cleaner display without complex breakdown

### 5. ✅ Updated Sick Leave Display
- **Location:** Leave Balance section, Sick Leave card
- **Before:** `8 / 10 Days`
- **After:** `1 / 4 days`
- **Purpose:** Shows realistic example data

---

## 🎨 Visual Layout Changes

### Top Header (New Layout)
```
┌────────────────────────────────────────────────┐
│ 🏠 Home    [Today's Date] 🌐 EN 👤            │
└────────────────────────────────────────────────┘
```

### Welcome Section (Updated)
```
┌─────────────────────────────────────────────┐
│ Welcome, Wong Pak Kun (黃柏根) L003         │
│                                              │
│ Hire date (入職日期): 01/01/2025            │
│ Current period (當前服務期間):              │
│     2025-01-01 → 2025-12-31                 │
└─────────────────────────────────────────────┘
```

### Annual Leave Card (New Format)
```
┌───────────────────────────────────────┐
│ 📅 Annual Leave                       │
│                                        │
│ 5 / 11 days (按年授予)                │
│ 11 + 7.8 = 18.8 days (按比例估算)     │
│ ─────────────────────────────────────  │
│ ℹ️ 5 days applied in current period   │
│    當前期間已申請5天（不含以薪代假）   │
└───────────────────────────────────────┘
```

---

## 📊 Data Displayed

### Annual Leave Explanation

| Field | Value | Meaning |
|-------|-------|---------|
| **5** | Used | Days already applied in current period (2025-01-01 → 2025-12-31) |
| **11** | Total Granted | Total annual leave granted for current period (按年授予) |
| **11 + 7.8** | Calculation | Granted (11) + Prorated accrual (7.8) |
| **18.8** | Prorated Total | Total including estimated accrual (按比例估算) |

**Important Notes:**
- The **5 days** applied does NOT include any approved "payment in lieu" (以薪代假) requests
- **按年授予 (Granted Annually)**: Actual usable balance
- **按比例估算 (Prorated Estimate)**: Display-only reference including current year progress

### Sick Leave
- **1 day used** / **4 days total**
- Simple display format maintained

---

## 🔍 Technical Details

### Updated HTML Structure

**Date in Header:**
```html
<div class="header-right">
    <!-- Today's Date -->
    <div class="text-white text-xs mr-3" id="currentDate">Monday, October 20, 2025</div>
    
    <!-- Language Switcher -->
    <div class="lang-switcher relative">
        ...
    </div>
</div>
```

**Hire Date & Current Period:**
```html
<div class="text-sm text-gray-600 mt-2">
    <p><span class="font-medium">Hire date (入職日期):</span> 
       <span id="hireDate">01/01/2025</span></p>
    <p class="mt-1"><span class="font-medium">Current period (當前服務期間):</span> 
       <span id="currentPeriod">2025-01-01 → 2025-12-31</span></p>
</div>
```

**Annual Leave Card:**
```html
<div class="text-[11px] leading-relaxed text-gray-700">
    <div class="mb-1">
        <span class="font-semibold text-[#00AFB9]">5</span> / 
        <span class="font-semibold">11</span> days
        <span class="text-[10px] text-gray-500">(按年授予)</span>
    </div>
    <div class="text-[10px] text-gray-600">
        11 + 7.8 = <span class="font-semibold">18.8</span> days
        <span class="text-gray-500">(按比例估算)</span>
    </div>
</div>
<div class="mt-2 pt-2 border-t border-gray-200 text-[10px] text-gray-500">
    <i class="fas fa-info-circle mr-1"></i>5 days applied in current period
    <br/>
    <span class="text-[9px]">當前期間已申請5天（不含以薪代假）</span>
</div>
```

---

## 🎯 Business Logic Clarification

### Leave Counting Rules

1. **Applied Days (5)**: 
   - Count only regular approved leave applications
   - Exclude any "payment in lieu" (以薪代假) approvals
   - Specific to current service period (服務期間)

2. **按年授予 (Granted Annually) (11)**:
   - Total leave entitlement for the current year
   - Actual usable balance
   - Based on contract or policy

3. **按比例估算 (Prorated Estimate) (18.8)**:
   - Display calculation only
   - Shows progress: Granted (11) + Current year accrual (7.8)
   - For reference, not actual available balance

---

## ✅ Testing Checklist

- [x] Date displays correctly in top header
- [x] Date removed from welcome section
- [x] Database reference text removed
- [x] Hire date displays correctly
- [x] Current period displays correctly
- [x] Annual leave shows "5 / 11 days (按年授予)"
- [x] Annual leave shows "11 + 7.8 = 18.8 days (按比例估算)"
- [x] Explanation text shows correctly (bilingual)
- [x] Sick leave shows "1 / 4 days"
- [x] No linter errors
- [x] Responsive layout maintained

---

## 📱 Responsive Behavior

All changes maintain mobile-first responsive design:
- Text sizes adjusted for mobile viewing
- Proper spacing and padding maintained
- Header remains sticky at top
- Cards stack properly on small screens

---

## 🔄 Related Files

No other files need to be updated for this change. This is a UI-only update to improve clarity and user experience.

---

**Version:** 2.2.1  
**Last Updated:** October 28, 2025  
**Status:** ✅ Complete and ready for use

