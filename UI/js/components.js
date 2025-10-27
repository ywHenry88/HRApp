// Version: 1.2.0
// Common components for the Employee Leave System

// Header component for employee pages
function getEmployeeHeader(title) {
    return `
    <header class="top-header">
        <div class="flex items-center">
            <i class="fas fa-home text-xl text-white mr-2"></i>
        </div>
        <div class="logo-header">
            <img src="../images/logo.png" alt="Company Logo" class="h-8">
        </div>
        <div class="header-right">
            <div class="lang-switcher">
                <div class="flex items-center" onclick="toggleLangDropdown()">
                    <i class="fas fa-globe lang-icon"></i>
                    <span class="current-lang ml-1">${currentLang === 'en' ? 'EN' : 'CN'}</span>
                </div>
                <div class="dropdown-menu">
                    <div class="dropdown-item ${currentLang === 'en' ? 'active' : ''}" data-lang="en" onclick="switchLanguage('en')">
                        English
                    </div>
                    <div class="dropdown-item ${currentLang === 'zh' ? 'active' : ''}" data-lang="zh" onclick="switchLanguage('zh')">
                        中文
                    </div>
                </div>
            </div>
            <div class="relative">
                <div class="cursor-pointer" onclick="toggleProfileMenu()">
                    <img class="h-10 w-10 rounded-full object-cover border-2 border-white" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="Profile">
                </div>
                <div id="profileMenu" class="hidden absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                    <a href="../employee/profile.html" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">My Profile</a>
                    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Settings</a>
                    <a href="#" onclick="logout()" class="block px-4 py-2 text-sm text-red-600 hover:bg-gray-100">Logout</a>
                </div>
            </div>
        </div>
    </header>
    `;
}

// Header component for admin pages
function getAdminHeader(title) {
    return `
    <header class="admin-header">
        <div class="flex items-center">
            <i class="fas fa-tachometer-alt text-xl text-white mr-2"></i>
        </div>
        <div class="logo-header">
            <img src="../images/logo.png" alt="Company Logo" class="h-8">
        </div>
        <div class="header-right">
            <div class="lang-switcher">
                <div class="flex items-center" onclick="toggleLangDropdown()">
                    <i class="fas fa-globe lang-icon"></i>
                    <span class="current-lang ml-1">${currentLang === 'en' ? 'EN' : 'CN'}</span>
                </div>
                <div class="dropdown-menu">
                    <div class="dropdown-item ${currentLang === 'en' ? 'active' : ''}" data-lang="en" onclick="switchLanguage('en')">
                        English
                    </div>
                    <div class="dropdown-item ${currentLang === 'zh' ? 'active' : ''}" data-lang="zh" onclick="switchLanguage('zh')">
                        中文
                    </div>
                </div>
            </div>
            <div class="relative">
                <div class="cursor-pointer" onclick="toggleProfileMenu()">
                    <img class="h-10 w-10 rounded-full object-cover border-2 border-white" src="https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="Admin Profile">
                </div>
                <div id="profileMenu" class="hidden absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Admin Profile</a>
                    <a href="#" class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100">Settings</a>
                    <a href="#" onclick="logout()" class="block px-4 py-2 text-sm text-red-600 hover:bg-gray-100">Logout</a>
                </div>
            </div>
        </div>
    </header>
    `;
}

// Sidebar component for admin pages
function getAdminSidebar() {
    return `
    <div class="admin-sidebar">
        <div class="admin-sidebar-header">
            <div class="admin-logo" data-i18n="login.title">Employee Leave System</div>
        </div>
        <nav class="sidebar-nav">
            <a href="dashboard.html" class="sidebar-nav-item" id="nav-dashboard">
                <i class="fas fa-home"></i>
                <span data-i18n="nav.dashboard">Home</span>
            </a>
            <a href="approve-leaves.html" class="sidebar-nav-item" id="nav-approve">
                <i class="fas fa-check-circle"></i>
                <span>Approve Leaves</span>
            </a>
            <a href="compensatory-leave.html" class="sidebar-nav-item" id="nav-compensatory">
                <i class="fas fa-plus-circle"></i>
                <span>Compensatory Leave</span>
            </a>
            <a href="manage-employees.html" class="sidebar-nav-item" id="nav-manage">
                <i class="fas fa-users"></i>
                <span>Manage Employees</span>
            </a>
            <a href="reports.html" class="sidebar-nav-item" id="nav-reports">
                <i class="fas fa-chart-bar"></i>
                <span>Reports</span>
            </a>
            <a href="leave-settings.html" class="sidebar-nav-item" id="nav-settings">
                <i class="fas fa-cog"></i>
                <span>Settings</span>
            </a>
            <a href="#" onclick="logout()" class="sidebar-nav-item mt-auto">
                <i class="fas fa-sign-out-alt"></i>
                <span>Logout</span>
            </a>
        </nav>
    </div>
    `;
}

// Bottom navigation component for employee pages
function getEmployeeBottomNav() {
    return `
    <footer class="bottom-nav">
        <a href="dashboard.html" id="nav-dashboard">
            <svg class="nav-icon" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path>
                <polyline points="9 22 9 12 15 12 15 22"></polyline>
            </svg>
            <span data-i18n="nav.dashboard">Home</span>
        </a>
        <a href="leave-request-multi.html" id="nav-request">
            <svg class="nav-icon" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
            </svg>
            <span data-i18n="nav.leaveRequest">Request</span>
        </a>
        <a href="leave-history.html" id="nav-history">
            <svg class="nav-icon" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="12" cy="12" r="10"></circle>
                <polyline points="12 6 12 12 16 14"></polyline>
            </svg>
            <span data-i18n="nav.history">History</span>
        </a>
        <a href="profile.html" id="nav-profile">
            <svg class="nav-icon" xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
            </svg>
            <span data-i18n="nav.profile">Profile</span>
        </a>
    </footer>
    `;
} 