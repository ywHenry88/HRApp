// Common JavaScript for HR Leave Management System
// Description: Handles language switching, translations, and common utilities
// Dependencies: None (Vanilla JavaScript)

/**
 * TRANSLATION DICTIONARY
 * Bilingual support for English and Traditional Chinese (繁體中文)
 * Usage: translations['key.subkey'][currentLang]
 */
const translations = {
    // Login Page
    'login.title': {
        en: 'HR Leave Management System',
        zh: 'HR 請假管理系統'
    },
    'login.subtitle': {
        en: 'Employee & Admin Portal',
        zh: '員工及管理員入口'
    },
    'login.username': {
        en: 'Username',
        zh: '用戶名'
    },
    'login.password': {
        en: 'Password',
        zh: '密碼'
    },
    'login.rememberMe': {
        en: 'Remember me',
        zh: '記住我'
    },
    'login.forgotPassword': {
        en: 'Forgot Password?',
        zh: '忘記密碼？'
    },
    'login.button': {
        en: 'Login',
        zh: '登錄'
    },
    'login.demoTitle': {
        en: 'Demo Credentials:',
        zh: '測試帳號：'
    },
    'login.demoAdmin': {
        en: 'Admin',
        zh: '管理員'
    },
    'login.demoEmployee': {
        en: 'Employee',
        zh: '員工'
    },
    'login.demoAdminUser': {
        en: 'admin',
        zh: 'admin'
    },
    'login.demoEmployeeUser': {
        en: 'user',
        zh: 'user'
    },
    'login.footer': {
        en: 'Secure Login',
        zh: '安全登錄'
    },
    
    // Dashboard
    'dashboard.title': {
        en: 'Home',
        zh: '主頁'
    },
    'dashboard.welcome': {
        en: 'Welcome',
        zh: '歡迎'
    },
    'dashboard.leaveBalance': {
        en: 'Leave Balance',
        zh: '剩餘假期'
    },
    'dashboard.pendingRequests': {
        en: 'Pending Requests',
        zh: '待處理請求'
    },
    'dashboard.awaitingApproval': {
        en: 'Awaiting Approval',
        zh: '等待批准'
    },
    'dashboard.viewAll': {
        en: 'View all',
        zh: '查看全部'
    },
    'dashboard.requestLeave': {
        en: 'Request Leave',
        zh: '申請請假'
    },
    'dashboard.viewHistory': {
        en: 'View History',
        zh: '查看歷史'
    },
    'dashboard.teamSchedule': {
        en: 'Team Schedule',
        zh: '團隊排班'
    },
    'dashboard.viewDetails': {
        en: 'View details',
        zh: '查看詳情'
    },

    // Leave Types
    'leave.annual': {
        en: 'Annual Leave',
        zh: '年假'
    },
    'leave.sick': {
        en: 'Sick Leave',
        zh: '病假'
    },
    'leave.personal': {
        en: 'Annual Leave',
        zh: '年假'
    },
    'leave.study': {
        en: 'Sick Leave',
        zh: '病假'
    },

    // Leave Request Form
    'leave.title': {
        en: 'Leave Request',
        zh: '請假申請'
    },
    'leave.currentBalance': {
        en: 'Current Balance',
        zh: '當前餘額'
    },
    'leave.type': {
        en: 'Leave Type',
        zh: '假期類型'
    },
    'leave.startDate': {
        en: 'Start Date',
        zh: '開始日期'
    },
    'leave.endDate': {
        en: 'End Date',
        zh: '結束日期'
    },
    'leave.totalDays': {
        en: 'Total Working Days',
        zh: '總工作天數'
    },
    'leave.excludes': {
        en: 'Excludes weekends',
        zh: '不包括週末'
    },
    'leave.andHolidays': {
        en: '& public holidays',
        zh: '及公眾假期'
    },
    'leave.reason': {
        en: 'Reason',
        zh: '原因'
    },
    'leave.submit': {
        en: 'Submit Request',
        zh: '提交申請'
    },
    'leave.available': {
        en: 'Available',
        zh: '可用'
    },
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
    
    // Calendar
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
    
    // Leave History
    'history.title': {
        en: 'Leave History',
        zh: '請假歷史'
    },
    'history.filterByStatus': {
        en: 'Filter by Status',
        zh: '按狀態篩選'
    },
    'history.filterByType': {
        en: 'Filter by Type',
        zh: '按類型篩選'
    },
    'history.all': {
        en: 'All',
        zh: '全部'
    },
    'history.noRequests': {
        en: 'No leave requests found',
        zh: '找不到請假記錄'
    },

    // Status
    'status.pending': {
        en: 'Pending',
        zh: '待處理'
    },
    'status.approved': {
        en: 'Approved',
        zh: '已批准'
    },
    'status.rejected': {
        en: 'Rejected',
        zh: '已拒絕'
    },
    
    // Profile
    'profile.title': {
        en: 'My Profile',
        zh: '我的個人資料'
    },
    'profile.personalInfo': {
        en: 'Personal Information',
        zh: '個人資料'
    },
    'profile.fullName': {
        en: 'Full Name',
        zh: '全名'
    },
    'profile.employeeCode': {
        en: 'Employee Code',
        zh: '員工編號'
    },
    'profile.email': {
        en: 'Email',
        zh: '電子郵件'
    },
    'profile.department': {
        en: 'Department',
        zh: '部門'
    },
    'profile.position': {
        en: 'Position',
        zh: '職位'
    },
    'profile.joinDate': {
        en: 'Join Date',
        zh: '入職日期'
    },
    'profile.preferences': {
        en: 'Preferences',
        zh: '偏好設置'
    },
    'profile.language': {
        en: 'Preferred Language',
        zh: '首選語言'
    },
    'profile.security': {
        en: 'Account Security',
        zh: '帳戶安全'
    },
    'profile.changePassword': {
        en: 'Change Password',
        zh: '更改密碼'
    },
    'profile.passwordHint': {
        en: 'Update your account password',
        zh: '更新您的帳戶密碼'
    },
    'profile.currentPassword': {
        en: 'Current Password',
        zh: '當前密碼'
    },
    'profile.newPassword': {
        en: 'New Password',
        zh: '新密碼'
    },
    'profile.confirmPassword': {
        en: 'Confirm New Password',
        zh: '確認新密碼'
    },
    'profile.passwordRequirement': {
        en: 'Minimum 8 characters',
        zh: '最少8個字符'
    },
    'profile.leaveStats': {
        en: 'Leave Statistics',
        zh: '請假統計'
    },
    'profile.totalRequests': {
        en: 'Total Requests',
        zh: '總申請數'
    },
    'profile.approved': {
        en: 'Approved',
        zh: '已批准'
    },
    'profile.pending': {
        en: 'Pending',
        zh: '待處理'
    },
    'profile.totalDays': {
        en: 'Total Days',
        zh: '總天數'
    },
    
    // Navigation
    'nav.home': {
        en: 'Home',
        zh: '主頁'
    },
    'nav.request': {
        en: 'Request',
        zh: '申請'
    },
    'nav.history': {
        en: 'History',
        zh: '歷史'
    },
    'nav.profile': {
        en: 'Profile',
        zh: '個人資料'
    },
    'nav.logout': {
        en: 'Logout',
        zh: '登出'
    },

    // Calendar
    'calendar.sun': {
        en: 'Sun',
        zh: '日'
    },
    'calendar.mon': {
        en: 'Mon',
        zh: '一'
    },
    'calendar.tue': {
        en: 'Tue',
        zh: '二'
    },
    'calendar.wed': {
        en: 'Wed',
        zh: '三'
    },
    'calendar.thu': {
        en: 'Thu',
        zh: '四'
    },
    'calendar.fri': {
        en: 'Fri',
        zh: '五'
    },
    'calendar.sat': {
        en: 'Sat',
        zh: '六'
    },

    // Admin
    'admin.dashboard': {
        en: 'Dashboard',
        zh: '儀表板'
    },
    'admin.approveLeaves': {
        en: 'Approve Leaves',
        zh: '批准請假'
    },
    'admin.manageEmployees': {
        en: 'Manage Employees',
        zh: '管理員工'
    },
    'admin.settings': {
        en: 'Leave Settings',
        zh: '請假設置'
    },
    'admin.compensatory': {
        en: 'Compensatory Leave',
        zh: '補假管理'
    },
    'admin.reports': {
        en: 'Reports',
        zh: '報告'
    },
    'admin.pendingApprovals': {
        en: 'Pending Approvals',
        zh: '待批准'
    },
    'admin.totalEmployees': {
        en: 'Total Employees',
        zh: '員工總數'
    },
    'admin.onLeaveToday': {
        en: 'On Leave Today',
        zh: '今日請假'
    },
    'admin.recentRequests': {
        en: 'Recent Leave Requests',
        zh: '最近請假申請'
    },
    'admin.quickActions': {
        en: 'Quick Actions',
        zh: '快速操作'
    },
    'admin.addEmployee': {
        en: 'Add Employee',
        zh: '新增員工'
    },
    'admin.generateReport': {
        en: 'Generate Report',
        zh: '生成報告'
    },
    'admin.employee': {
        en: 'Employee',
        zh: '員工'
    },
    'admin.type': {
        en: 'Type',
        zh: '類型'
    },
    'admin.duration': {
        en: 'Duration',
        zh: '期間'
    },
    'admin.status': {
        en: 'Status',
        zh: '狀態'
    },
    'admin.actions': {
        en: 'Actions',
        zh: '操作'
    },
    'admin.approve': {
        en: 'Approve',
        zh: '批准'
    },
    'admin.reject': {
        en: 'Reject',
        zh: '拒絕'
    },
    'admin.search': {
        en: 'Search',
        zh: '搜索'
    },
    'admin.leaveType': {
        en: 'Leave Type',
        zh: '假期類型'
    },
    'admin.compDays': {
        en: 'Compensatory Days',
        zh: '補假天數'
    },
    'admin.addComp': {
        en: 'Add Compensatory Leave',
        zh: '新增補假'
    },
    'admin.dates': {
        en: 'Dates',
        zh: '日期'
    },
    'admin.days': {
        en: 'Days',
        zh: '天數'
    },
    'admin.submitted': {
        en: 'Submitted',
        zh: '提交日期'
    },
    'admin.noRequests': {
        en: 'No leave requests found',
        zh: '找不到請假申請'
    },
    'admin.requestDetails': {
        en: 'Leave Request Details',
        zh: '請假申請詳情'
    },
    'admin.employeeInfo': {
        en: 'Employee Information',
        zh: '員工資料'
    },
    'admin.name': {
        en: 'Name',
        zh: '姓名'
    },
    'admin.currentBalance': {
        en: 'Current Balance',
        zh: '當前餘額'
    },
    'admin.requestInfo': {
        en: 'Request Information',
        zh: '申請資料'
    },
    'admin.comments': {
        en: 'Admin Comments',
        zh: '管理員備註'
    },
    'admin.noEmployees': {
        en: 'No employees found',
        zh: '找不到員工'
    },
    'admin.personalInfo': {
        en: 'Personal Information',
        zh: '個人資料'
    },
    'admin.fullName': {
        en: 'Full Name',
        zh: '全名'
    },
    'admin.username': {
        en: 'Username',
        zh: '用戶名'
    },
    'admin.password': {
        en: 'Password',
        zh: '密碼'
    },
    'admin.role': {
        en: 'Role',
        zh: '角色'
    },
    'admin.accountInfo': {
        en: 'Account Information',
        zh: '帳戶資料'
    },
    'admin.leaveAllocation': {
        en: 'Leave Allocation',
        zh: '假期分配'
    },
    'admin.blackoutDates': {
        en: 'Blackout Dates',
        zh: '禁止請假日期'
    },
    'admin.blackoutManagement': {
        en: 'Blackout Dates Management',
        zh: '禁止請假日期管理'
    },

    // Common
    'common.cancel': {
        en: 'Cancel',
        zh: '取消'
    },
    'common.save': {
        en: 'Save',
        zh: '保存'
    },
    'common.edit': {
        en: 'Edit',
        zh: '編輯'
    },
    'common.delete': {
        en: 'Delete',
        zh: '刪除'
    },
    'common.view': {
        en: 'View',
        zh: '查看'
    },
    'common.loading': {
        en: 'Loading...',
        zh: '載入中...'
    },
    'common.error': {
        en: 'Error',
        zh: '錯誤'
    },
    'common.success': {
        en: 'Success',
        zh: '成功'
    },
    'common.days': {
        en: 'days',
        zh: '天'
    },
    'common.from': {
        en: 'From',
        zh: '從'
    },
    'common.to': {
        en: 'To',
        zh: '至'
    },
    'common.clearAll': {
        en: 'Clear All',
        zh: '全部清除'
    },
    'common.optional': {
        en: '(Optional)',
        zh: '（可選）'
    }
};

/**
 * CURRENT LANGUAGE
 * Default to Traditional Chinese, can be changed by user
 */
let currentLang = localStorage.getItem('preferredLanguage') || 'zh';

/**
 * TRANSLATE PAGE
 * Translates all elements with data-i18n attribute
 */
function translatePage() {
    document.querySelectorAll('[data-i18n]').forEach(element => {
        const key = element.getAttribute('data-i18n');
        if (translations[key] && translations[key][currentLang]) {
            element.textContent = translations[key][currentLang];
        }
    });

    // Update placeholders
    document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
        const key = element.getAttribute('data-i18n-placeholder');
    if (translations[key] && translations[key][currentLang]) {
            element.placeholder = translations[key][currentLang];
        }
    });

    // Update current language display
    const langText = document.getElementById('currentLangText');
    if (langText) {
        langText.textContent = currentLang === 'en' ? 'EN' : '中';
    }
}

/**
 * SWITCH LANGUAGE
 * Changes the current language and updates all text
 * @param {string} lang - Language code ('en' or 'zh')
 */
function switchLanguage(lang) {
    currentLang = lang;
    localStorage.setItem('preferredLanguage', lang);
    translatePage();
        
        // Update active state in dropdown
    document.querySelectorAll('.lang-switcher .dropdown-item').forEach(item => {
        if (item.dataset.lang === lang) {
                item.classList.add('active');
            } else {
                item.classList.remove('active');
            }
        });
    
    // Hide dropdown
    const dropdown = document.getElementById('langDropdown');
    if (dropdown) {
        dropdown.classList.remove('show');
    }

    // Notify pages to re-render language-dependent UI
    try {
        window.dispatchEvent(new CustomEvent('languageChanged', { detail: { lang } }));
    } catch (e) {
        // ignore
    }
}

/**
 * TOGGLE LANGUAGE DROPDOWN
 * Shows/hides the language selector dropdown
 */
function toggleLangDropdown() {
    const dropdown = document.getElementById('langDropdown');
    if (dropdown) {
        dropdown.classList.toggle('show');
    }
}

/**
 * CLOSE DROPDOWNS ON OUTSIDE CLICK
 * Closes language dropdown when clicking outside
 */
document.addEventListener('click', function(event) {
    const langSwitcher = event.target.closest('.lang-switcher');
    if (!langSwitcher) {
        const dropdown = document.getElementById('langDropdown');
        if (dropdown && dropdown.classList.contains('show')) {
            dropdown.classList.remove('show');
        }
    }
});

/**
 * INITIALIZE ON PAGE LOAD
 * Translates page and sets up event listeners
 */
document.addEventListener('DOMContentLoaded', function() {
    // Translate page
    translatePage();
    
    // Set active language in dropdown
    document.querySelectorAll('.lang-switcher .dropdown-item').forEach(item => {
        if (item.dataset.lang === currentLang) {
            item.classList.add('active');
        }
    });
});

// Demo-only: Populate AnnualTotal breakdown on employee dashboard to reflect RULES.md
document.addEventListener('DOMContentLoaded', function() {
    try {
        var annualDaysEl = document.getElementById('annualDays');
        if (!annualDaysEl) return; // not on dashboard

        // Sample parameters (demo): base 7.5, hire 2022-11-01, year current, increment +1, max 16.5
        var base = 7.5;
        var increment = 1.0;
        var maxDays = 16.5;
        var hireDate = new Date('2022-11-01');
        var now = new Date();
        var year = now.getFullYear();

        function calcAnnualDays(y) {
            var jan1 = new Date(y, 0, 1);
            var dec31 = new Date(y, 11, 31);
            if (hireDate.getFullYear() === y) {
                var start = hireDate > jan1 ? hireDate : jan1;
                var days = Math.floor((dec31 - start) / 86400000) + 1;
                return +(base * (days / 365)).toFixed(2);
            }
            if (hireDate.getFullYear() < y) {
                var seniority = Math.max(0, y - (hireDate.getFullYear() + 1));
                return Math.min(maxDays, base + seniority * increment);
            }
            return base;
        }

        var annualDays = calcAnnualDays(year);
        var carryForward = 3.0;
        var compDays = 4.0;
        var annualTotal = +(annualDays + carryForward + compDays).toFixed(2);
        var annualUsed = 2.0; // approved days YTD
        var annualRemaining = +(annualTotal - annualUsed).toFixed(2);

        document.getElementById('annualDays').textContent = annualDays.toString();
        document.getElementById('carryForward').textContent = carryForward.toString();
        document.getElementById('compDays').textContent = compDays.toString();
        document.getElementById('annualUsed').textContent = annualUsed.toString();
        document.getElementById('annualTotal').textContent = annualTotal.toString();
        var remainingEl = document.getElementById('annualRemaining');
        if (remainingEl) {
            remainingEl.textContent = annualRemaining.toString();
            if (annualRemaining < 0) {
                remainingEl.style.color = '#EF4444';
                remainingEl.title = 'Overdrawn';
            }
        }
    } catch (e) {
        // ignore demo calc errors
    }
});

/**
 * FORMAT DATE
 * Formats date string for display
 * @param {string} dateStr - Date string (YYYY-MM-DD)
 * @returns {string} Formatted date
 */
function formatDate(dateStr) {
    const date = new Date(dateStr);
    const options = { year: 'numeric', month: 'short', day: 'numeric' };
    return date.toLocaleDateString(currentLang === 'zh' ? 'zh-TW' : 'en-US', options);
}

/**
 * SHOW NOTIFICATION
 * Displays a notification message
 * @param {string} message - Message to display
 * @param {string} type - Type of notification (success, error, info)
 */
function showNotification(message, type = 'info') {
    const colors = {
        success: 'bg-green-500',
        error: 'bg-red-500',
        info: 'bg-blue-500',
        warning: 'bg-yellow-500'
    };

    const notification = document.createElement('div');
    notification.className = `fixed top-4 right-4 z-50 px-6 py-3 rounded-lg shadow-lg ${colors[type] || colors.info} text-white text-sm font-medium animate-fade-in`;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.remove();
    }, 3000);
}

// Export functions for use in other scripts
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        translations,
        translatePage,
        switchLanguage,
        toggleLangDropdown,
        formatDate,
        showNotification
    };
}

// =============================================================================
// Version: 2.1.0
// PARAMETERS
// - sourceEn: English JSON endpoint (default: https://www.1823.gov.hk/common/ical/en.json)
// - sourceZh: Traditional Chinese JSON endpoint (default: https://www.1823.gov.hk/common/ical/tc.json)
// FUNCTIONS
// - fetchHKHolidays(lang): Fetches and parses holidays, returns array [{ date, name, uid, year }]
// - getHolidaySet(): Returns Set of 'YYYY-MM-DD' for quick lookup
// - ensureHolidaysLoaded(): Ensures holidays are loaded before use
// Notes: Caches results in-memory per session; UI pages should call ensureHolidaysLoaded().
// =============================================================================
(function () {
    const sourceEn = 'https://www.1823.gov.hk/common/ical/en.json';
    const sourceZh = 'https://www.1823.gov.hk/common/ical/tc.json';

    let holidaysEn = null; // Array of { date, name, uid, year }
    let holidaysZh = null;
    let holidaySet = null; // Set of date strings for quick lookup
    let yearMapEn = null; // {YYYY: {YYYY-MM-DD: name}}
    let yearMapZh = null;

    function yyyymmddToIso(yyyymmdd) {
        if (!yyyymmdd || yyyymmdd.length !== 8) return null;
        return `${yyyymmdd.substring(0,4)}-${yyyymmdd.substring(4,6)}-${yyyymmdd.substring(6,8)}`;
    }

    async function fetchJson(url) {
        // Simple sessionStorage cache (12h TTL) to speed up repeat loads
        try {
            const cacheKey = `holidays_cache_${url}`;
            const tsKey = `${cacheKey}_ts`;
            const ttlMs = 12 * 60 * 60 * 1000; // 12 hours
            const now = Date.now();
            const cached = sessionStorage.getItem(cacheKey);
            const ts = sessionStorage.getItem(tsKey);
            if (cached && ts && (now - parseInt(ts, 10)) < ttlMs) {
                return JSON.parse(cached);
            }
        } catch (_) {}

        // Try direct fetch first
        try {
            const res = await fetch(url, { cache: 'no-cache' });
            if (res.ok) {
                const json = await res.json();
                try {
                    const cacheKey = `holidays_cache_${url}`;
                    const tsKey = `${cacheKey}_ts`;
                    sessionStorage.setItem(cacheKey, JSON.stringify(json));
                    sessionStorage.setItem(tsKey, String(Date.now()));
                } catch (_) {}
                return json;
            }
        } catch (_) {
            // fall through to proxies
        }

        // Fallback via public CORS proxies (demo-only)
        const proxies = [
            (u) => `https://cors.isomorphic-git.org/${u}`,
            (u) => `https://api.allorigins.win/raw?url=${encodeURIComponent(u)}`,
            (u) => `https://r.jina.ai/${u.startsWith('https://') ? u : 'https://' + u}`
        ];

        for (const to of proxies) {
            const proxied = to(url);
            try {
                const res = await fetch(proxied, { cache: 'no-cache' });
                if (!res.ok) continue;
                const text = await res.text();
                // Some proxies return text/plain; parse JSON manually
                const json = JSON.parse(text);
                try {
                    const cacheKey = `holidays_cache_${url}`;
                    const tsKey = `${cacheKey}_ts`;
                    sessionStorage.setItem(cacheKey, JSON.stringify(json));
                    sessionStorage.setItem(tsKey, String(Date.now()));
                } catch (_) {}
                return json;
            } catch (_) {
                // try next proxy
            }
        }
        throw new Error(`Failed to fetch ${url} via CORS proxies`);
    }

    function parseVCalendar(json) {
        try {
            const vcal = Array.isArray(json.vcalendar) ? json.vcalendar[0] : null;
            const events = vcal && Array.isArray(vcal.vevent) ? vcal.vevent : [];
            return events.map(ev => {
                const start = Array.isArray(ev.dtstart) ? ev.dtstart[0] : ev.dtstart;
                const date = yyyymmddToIso(start);
                const name = ev.summary || '';
                const uid = ev.uid || null;
                const year = date ? parseInt(date.substring(0,4), 10) : null;
                return { date, name, uid, year };
            }).filter(x => !!x.date);
        } catch (_) {
            return [];
        }
    }

    async function fetchHKHolidays(lang) {
        const url = lang === 'zh' ? sourceZh : sourceEn;
        const raw = await fetchJson(url);
        return parseVCalendar(raw);
    }

    async function ensureHolidaysLoaded() {
        if (holidaySet && holidaysEn && holidaysZh && yearMapEn && yearMapZh) return;

        // Try load from localStorage first for instant availability
        try {
            const enLS = localStorage.getItem('holidays_list_en');
            const zhLS = localStorage.getItem('holidays_list_zh');
            const ymEn = localStorage.getItem('holidays_yearmap_en');
            const ymZh = localStorage.getItem('holidays_yearmap_zh');
            if (enLS && zhLS && ymEn && ymZh) {
                holidaysEn = JSON.parse(enLS);
                holidaysZh = JSON.parse(zhLS);
                yearMapEn = JSON.parse(ymEn);
                yearMapZh = JSON.parse(ymZh);
                holidaySet = new Set([...holidaysEn, ...holidaysZh].map(h => h.date));
                return;
            }
        } catch (_) {}

        const [enData, zhData] = await Promise.all([
            holidaysEn ? Promise.resolve(holidaysEn) : fetchHKHolidays('en'),
            holidaysZh ? Promise.resolve(holidaysZh) : fetchHKHolidays('zh')
        ]);
        holidaysEn = enData;
        holidaysZh = zhData;
        holidaySet = new Set([...enData, ...zhData].map(h => h.date));

        // Build and persist per-year maps for fast lookup across pages
        yearMapEn = buildYearMap(enData);
        yearMapZh = buildYearMap(zhData);
        try {
            localStorage.setItem('holidays_list_en', JSON.stringify(holidaysEn));
            localStorage.setItem('holidays_list_zh', JSON.stringify(holidaysZh));
            localStorage.setItem('holidays_yearmap_en', JSON.stringify(yearMapEn));
            localStorage.setItem('holidays_yearmap_zh', JSON.stringify(yearMapZh));
        } catch (_) {}
    }

    function getHolidaySet() {
        return holidaySet || new Set();
    }

    function getHolidayNamesByDate(dateStr) {
        const en = (holidaysEn || []).find(h => h.date === dateStr);
        const zh = (holidaysZh || []).find(h => h.date === dateStr);
        return { en: en ? en.name : null, zh: zh ? zh.name : null };
    }

    function buildYearMap(list) {
        const map = {};
        for (const h of list) {
            const y = h.year || (h.date ? h.date.substring(0,4) : null);
            if (!y) continue;
            if (!map[y]) map[y] = {};
            map[y][h.date] = h.name;
        }
        return map;
    }

    function getHolidayNameFast(dateStr, lang) {
        try {
            const y = dateStr.substring(0,4);
            const ym = (lang === 'zh' ? (yearMapZh || JSON.parse(localStorage.getItem('holidays_yearmap_zh') || '{}'))
                                      : (yearMapEn || JSON.parse(localStorage.getItem('holidays_yearmap_en') || '{}')));
            return (ym && ym[y] && ym[y][dateStr]) || null;
        } catch (_) {
            return null;
        }
    }

    // Expose to window
    window.fetchHKHolidays = fetchHKHolidays;
    window.ensureHolidaysLoaded = ensureHolidaysLoaded;
    window.getHolidaySet = getHolidaySet;
    window.getHolidayNamesByDate = getHolidayNamesByDate;
    window.getHolidayNameFast = getHolidayNameFast;
})();
