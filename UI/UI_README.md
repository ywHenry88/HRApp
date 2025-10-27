# HR Leave Management System - HTML UI Prototype

**Version:** 2.0.0  
**Date:** October 20, 2025  
**Purpose:** Visual confirmation and fine-tuning before Vue.js implementation

---

## 📋 Overview

This folder contains comprehensive HTML UI prototypes for the HR Leave Management System. These static HTML pages are designed for visual confirmation, design review, and user feedback before implementing the full Vue.js application.

### Key Features

✅ **Mobile-First Design** - Employee interface optimized for mobile devices  
✅ **Desktop-Optimized** - Admin interface designed for desktop browsers  
✅ **Bilingual Support** - Full English & Traditional Chinese (繁體中文) translations  
✅ **Responsive Layout** - Works on all screen sizes  
✅ **Interactive Prototypes** - Working navigation and form interactions  
✅ **Production-Ready Design** - Follows the PRD specifications exactly  
✅ **Aligned with RULES.md** - Demo data reflects AnnualTotal, Sick paid, negative balance

---

## 📁 Folder Structure

```
UI/
├── index.html                      # Main entry/welcome page
├── css/
│   └── styles.css                  # Custom styles (v2.0.0)
├── js/
│   ├── app.js                      # Common JavaScript & translations (v2.0.0)
│   └── components.js               # Reusable components
├── pages/
│   ├── login.html                  # Login page (v2.0.0)
│   ├── employee/                   # Employee pages (mobile-first)
│   │   ├── dashboard.html          # Employee dashboard with calendar (v2.0.0)
│   │   ├── leave-request-multi.html # Multi-date leave request (v2.0.0)
│   │   ├── leave-history.html      # Leave history with filters (v2.0.0)
│   │   └── profile.html            # Employee profile (v2.0.0)
│   └── admin/                      # Admin pages (desktop)
│       ├── dashboard.html          # Admin dashboard with stats (v2.0.0)
│       ├── approve-leaves.html     # Approve/reject requests (v2.0.0)
│       ├── manage-employees.html   # Employee management (v2.0.0)
│       ├── leave-settings.html     # Leave types & holidays (v2.0.0)
│       └── reports.html            # Reports (placeholder)
└── prototype/                      # Design reference images
```

---

## 🚀 Quick Start

### 1. Open the Demo

Simply open `index.html` in your web browser:

```bash
# From the UI directory
open index.html
# or
start index.html
# or double-click the file
```

### 2. Demo Credentials

**Admin Access:**
- Username: `admin`
- Password: `Admin@123`

**Employee Access:**
- Username: `jmlin` (or any employee code)
- Password: `Employee@123`

### 3. Navigation

- **Start Demo** → Goes to login page
- **Employee View** → Direct access to employee dashboard
- **Admin View** → Direct access to admin dashboard

---

## 📱 Employee Pages (Mobile-First)

### Dashboard (`employee/dashboard.html`)
- **Features:**
  - Leave balance cards (Annual, Sick, Personal, Study)
  - AnnualTotal breakdown (AnnualDays + CarryForward + Compensatory)
  - Negative remaining highlighted if below zero
  - Pending requests summary
  - Team schedule calendar
  - Quick action buttons
  - Mobile bottom navigation
- **Design:** Max-width 500px, optimized for mobile
- **Key Elements:**
  - Touch-friendly buttons (44x44px minimum)
  - Bottom navigation bar
  - Swipeable calendar
  - Large, readable text

### Leave Request (`employee/leave-request-multi.html`)
- **Features (v2.0):**
  - Multi-date calendar picker (consecutive or non-consecutive days)
  - Leave type selector
  - Date range picker
  - Total selected days counter (all selectable days have same level)
  - Balance validation
  - Reason field (optional)
- **Validation:**
  - Cannot request past dates
  - Checks sufficient balance
  - Weekends/holidays have no special treatment in selection
  - Real-time total selected days count

### Leave History (`employee/leave-history.html`)
- **Features:**
  - Filter by status (Pending/Approved/Rejected)
  - Filter by leave type
  - Expandable request cards
  - Edit/Cancel pending requests
  - Status color coding
- **Interactions:**
  - Quick filters
  - Card expansion
  - Inline actions

### Profile (`employee/profile.html`)
- **Features:**
  - Personal information display
  - Editable fields (Name, Email)
  - Read-only fields (Code, Dept, Position)
  - Language preference
  - Password change
  - Leave statistics
- **Security:**
  - Password complexity validation
  - Confirmation dialogs
  - Secure logout

---

## 💻 Admin Pages (Desktop)

### Dashboard (`admin/dashboard.html`)
- **Layout:** Sidebar + main content (min-width 1024px)
- **Features:**
  - Statistics cards (Pending, Employees, On Leave)
  - Recent requests table
  - Quick approve/reject actions
  - On leave today list
  - Quick action buttons
- **Design:** 
  - 3-column grid layout
  - Sidebar navigation
  - Data tables with hover effects

### Approve Leaves (`admin/approve-leaves.html`)
- **Features:**
  - Comprehensive filters (Search, Status, Type, Dept)
  - Sortable data table
  - Request detail modal
  - Approve/reject with comments (no date-level changes)
  - Bulk selection (UI ready)
- **Workflow:**
  1. Filter/search requests
  2. Click to view details
  3. Review employee info & balance
  4. Approve/reject with comments (admin cannot change requested days)

### Manage Employees (`admin/manage-employees.html`)
- **Features:**
  - Employee card grid
  - Search & filter
  - Add/edit employee modal
  - Leave balance display
  - Status management
- **Form Fields:**
  - Personal info (Name, Code, Email, Dept, Position)
  - Account info (Username, Password, Role, Status)
  - Leave allocation (Annual, Sick, Personal, Study)

### Leave Settings (`admin/leave-settings.html`)
- **Features:**
  - Leave types management
  - Public holidays list
  - Reports generation
  - Tab-based navigation
- **Sections:**
  1. Leave Types - Configure default allocations
  2. Holidays - Manage public holidays
  3. Reports - Generate utilization reports

### Compensatory Leave (`admin/compensatory-leave.html`) [NEW v2.0.3]
- **Purpose:** Admin grants compensatory leave (decimal days allowed) per employee
- **Features:**
  - Add compensatory leave with days (e.g., 2.5) and optional reason
  - Searchable list of compensatory records
  - Delete record action
- **Rules:**
  - Employees apply leave only in whole days; compensatory allocation can be decimal
  - Allocation adds into AnnualTotal balance calculation

---

## 📝 Policy Notes (Admin)

- Annual Leave split and pay-in-lieu are handled case-by-case by Admin. The system does not auto‑enforce rules such as contiguous days when entitlement exceeds 10, nor automatic pay‑in‑lieu conversions. / 年假分拆與以薪代假由管理員逐案處理；系統不自動強制執行「權益>10天需連續放取」或自動以薪代假換算。
- Annual Leave balances do not expire and carry forward indefinitely; UI displays totals accordingly. / 年假無到期且可無限期結轉；介面據此顯示總額。

---

## 🎨 Design System

### Colors

```css
/* Primary Color */
--primary: #00AFB9;           /* Teal */
--primary-hover: #009ba3;     /* Darker teal */
--primary-light: #f0fafb;     /* Light teal background */
--header-color: #4BCBD6;      /* Header background */

/* Leave Type Colors */
--leave-annual: #00AFB9;      /* Annual Leave */
--leave-sick: #FF6B6B;        /* Sick Leave */
/* Personal and Study leave colors removed per latest policy */

/* Status Colors */
--status-pending: #FFA500;    /* Orange */
--status-approved: #10B981;   /* Green */
--status-rejected: #EF4444;   /* Red */
--status-cancelled: #9CA3AF;  /* Gray */
```

### Typography

- **Font:** System font stack (Segoe UI on Windows)
- **Base Size:** 16px
- **Headings:** 700 weight
- **Body:** 400 weight

### Spacing

- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- 2xl: 48px

### Components

- **Buttons:** 8px border-radius, shadow on hover
- **Cards:** White background, shadow, 12px radius
- **Forms:** Clear labels, inline validation
- **Tables:** Sortable, filterable, pagination-ready

---

## 🌐 Bilingual Support

### Language Switching

The language switcher is available in all pages:
- Globe icon in header
- Dropdown with EN / 繁體中文 options
- Saves preference to localStorage
- Immediate UI update

### Translation Coverage

✅ All UI labels and buttons  
✅ Form placeholders  
✅ Error messages  
✅ Success messages  
✅ Navigation items  
✅ Status labels  
✅ Date/time formatting

### Implementation

Located in `js/app.js`:
```javascript
const translations = {
    'key.subkey': {
        en: 'English text',
        zh: '繁體中文文字'
    }
};

// Switch language
function switchLanguage(lang) {
    currentLang = lang;
    localStorage.setItem('preferredLanguage', lang);
    translatePage();
}
```

---

## 📱 Responsive Breakpoints

### Mobile (Employee Interface)
- **320px - 767px:** Primary target
- **Max-width:** 500px for forms
- **Navigation:** Bottom bar
- **Touch targets:** 44x44px minimum

### Tablet
- **768px - 1023px:** Adaptive layout
- **Forms:** Wider containers
- **Tables:** Horizontal scroll if needed

### Desktop (Admin Interface)
- **1024px+:** Optimized for admin
- **Sidebar:** 240px fixed width
- **Content:** Fluid with max-width
- **Grid:** 3-column layouts

---

## 🔧 Technical Details

### Dependencies

**CSS Frameworks:**
- Tailwind CSS 2.2.19 (via CDN)
- Font Awesome 6.4.0 (via CDN)
- Custom CSS: `css/styles.css`

**JavaScript:**
- Vanilla JavaScript (No frameworks)
- ES6+ features
- LocalStorage for preferences

**No Build Process Required:**
- Pure HTML/CSS/JS
- Open directly in browser
- No npm install needed
- No compilation required

### Browser Support

- Chrome 90+
- Firefox 88+
- Safari 14+
- Edge 90+
- Mobile Safari (iOS 14+)
- Chrome Mobile (Android 10+)

---

## ✅ Completed Features

### Employee Interface (Mobile)
- [x] Login page with demo credentials
- [x] Dashboard with leave balance
- [x] Team calendar (month view)
- [x] Leave request form with validation
- [x] Leave history with filters
- [x] Profile with edit capabilities
- [x] Bottom navigation
- [x] Language switcher
- [x] Touch-optimized interactions

### Admin Interface (Desktop)
- [x] Admin dashboard with statistics
- [x] Approve/reject leave requests
- [x] Employee management
- [x] Leave settings & holidays
- [x] Reports (basic layout)
- [x] Sidebar navigation
- [x] Data tables with filters
- [x] Modal dialogs
- [x] Quick actions

### Common Features
- [x] Bilingual support (EN/繁體中文)
- [x] Responsive design
- [x] Form validation
- [x] Status color coding
- [x] Interactive calendars
- [x] Alert notifications
- [x] Smooth transitions
- [x] Accessible markup

---

## 📝 Usage Notes

### For Design Review

1. **Visual Confirmation:**
   - Open each page in browser
   - Test on different screen sizes
   - Verify color scheme
   - Check typography
   - Test language switching

2. **Interaction Testing:**
   - Click all buttons and links
   - Fill out forms
   - Test filters and search
   - Try calendar navigation
   - Test modal dialogs

3. **Responsive Testing:**
   - Test on mobile devices
   - Test on tablets
   - Test on desktop
   - Use browser dev tools
   - Check touch targets

### For Stakeholder Review

- Start with `index.html`
- Follow the demo credentials
- Navigate through all pages
- Test both roles (Employee & Admin)
- Switch languages
- Provide feedback on design and UX

### For Developer Handoff

This prototype provides:
- Complete UI/UX specifications
- Exact layouts and spacing
- Color codes and styles
- Component structure
- Interaction patterns
- Translation keys
- Responsive behavior

**Next Step:** Implement in Vue 3 following this design exactly.

---

## 🔄 Next Steps

### To Production (Vue.js Implementation)

1. **Component Mapping:**
   - Each HTML page → Vue component
   - Shared sections → Reusable components
   - Forms → Separate form components
   - Modals → Global modal component

2. **State Management (Pinia):**
   - `stores/auth.js` - Authentication state
   - `stores/leaves.js` - Leave management
   - `stores/admin.js` - Admin operations

3. **API Integration:**
   - Connect to backend endpoints
   - Replace demo data with real API calls
   - Implement error handling
   - Add loading states

4. **Router Setup:**
   - Define routes matching HTML pages
   - Add route guards (auth)
   - Handle navigation
   - Setup redirects

5. **Testing:**
   - Unit tests for components
   - Integration tests for flows
   - E2E tests for critical paths
   - Accessibility testing

---

## 📞 Support

For questions about the UI prototype:

1. Check this README
2. Review the PRD.md document
3. Examine the HTML/CSS/JS code
4. Test in browser with dev tools

For issues:
- CSS not loading? Check file paths
- JavaScript errors? Check console
- Layout broken? Check browser compatibility
- Missing translations? Check app.js

---

## 📄 License

This prototype is part of the HR Leave Management System project.  
All rights reserved.

---

**Created:** October 20, 2025  
**Version:** 2.0.0  
**Status:** Ready for Review

---

## 🎯 Summary

This HTML UI prototype provides:

✅ Complete visual design for all pages  
✅ Mobile-first employee interface  
✅ Desktop-optimized admin interface  
✅ Bilingual support (EN/繁體中文)  
✅ Interactive prototypes with demo data  
✅ Production-ready design system  
✅ Comprehensive documentation  

**Ready for:** Visual confirmation, stakeholder review, and Vue.js implementation.

---

**Questions?** Review the code, test the pages, and prepare feedback! 🚀

