// Version: 2.1.0
// HR Leave Management System - SQL Server Database Data
// Database: HRLeaveSystemDB
// Source: Real data from SQL Server tables via DBHub MCP
// =============================================================================
// This file contains real data from SQL Server to align the UI with actual database structure
// =============================================================================

// DEPARTMENT MAPPING (DepartmentID codes from SQL Server)
const DEPARTMENTS = {
    'TRANS': 'Transportation',
    'WAREH': 'Warehouse', 
    'OFFICE': 'Office'
};

// LEAVE TYPES (from tb_LeaveTypes)
// Data types: LeaveTypeID (int), LeaveTypeName_EN/ZH (nvarchar 50), DefaultDaysPerYear (decimal 5,1), ColorCode (nvarchar 7)
const LEAVE_TYPES = [
    { id: 1, nameEN: 'Annual Leave', nameZH: '年假', defaultDays: 20, color: '#00AFB9', icon: 'calendar-alt', requiresApproval: true },
    { id: 2, nameEN: 'Sick Leave', nameZH: '病假', defaultDays: 10, color: '#FF6B6B', icon: 'procedures', requiresApproval: true },
    { id: 3, nameEN: 'Personal Leave', nameZH: '個人假', defaultDays: 5, color: '#FFD166', icon: 'user-clock', requiresApproval: true },
    { id: 4, nameEN: 'Study Leave', nameZH: '進修假', defaultDays: 2, color: '#06D6A0', icon: 'book', requiresApproval: true }
];

// EMPLOYEES (from tb_Users - 49 active employees)
// Data types: StaffCode (nvarchar 40), EName/CName (nvarchar 100), Email (nvarchar 100), DepartmentID (nvarchar 10), 
// Position (nvarchar 50), Role (nvarchar 20), IsActive (bit), Mobile (nvarchar 50), EmployType (nvarchar 50)
const EMPLOYEES = [
    { staffCode: 'ADMIN001', eName: 'System Administrator', cName: '系統管理員', email: 'admin@company.com', dept: 'OFFICE', position: 'Administrator', role: 'Admin', isActive: true, mobile: '90000001', employType: 'FULL(5.5)' },
    { staffCode: 'L003', eName: 'Wong Pak Kun', cName: '黃柏根', email: '', dept: 'TRANS', position: 'Training Officer(5.5天)', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5)' },
    { staffCode: 'L006', eName: 'Ling Chi Wai', cName: '凌志偉', email: '', dept: 'TRANS', position: 'Supervisor', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L016', eName: 'Lam Wai Ho', cName: '林偉豪', email: '', dept: 'OFFICE', position: 'Manager', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5)' },
    { staffCode: 'L021', eName: 'Lam Wing Fat', cName: '林詠發', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L079', eName: 'Yeung Chi Man', cName: '楊志文', email: '', dept: 'TRANS', position: '跟車送貨員', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L097', eName: 'Seto Ka Ming', cName: '司徒家明', email: '', dept: 'OFFICE', position: 'Manager', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5)' },
    { staffCode: 'L099', eName: 'Ip Man Pan', cName: '葉文賓', email: '', dept: 'WAREH', position: 'Supervisor', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L131', eName: 'Lam Wing Shing', cName: '林永誠', email: '', dept: 'TRANS', position: '跟車送貨員', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L132', eName: 'Wan Yim Lung', cName: '尹炎瓏', email: '', dept: 'TRANS', position: 'Supervisor', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5)' },
    { staffCode: 'L152', eName: 'Chan Chun Man', cName: '陳俊民', email: '', dept: 'OFFICE', position: 'C.S', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L153', eName: 'Chu Cheuk Kit', cName: '朱卓傑', email: '', dept: 'WAREH', position: 'Supervisor', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L154', eName: 'Tang Wai Kin', cName: '鄧偉建', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L159', eName: 'Wong Kam Yip', cName: '黃金業', email: '', dept: 'WAREH', position: '倉務員（5.5 天)', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L163', eName: 'Li Chik Ping', cName: '李植平', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L167', eName: 'Wong Hei Wai', cName: '黃熙威', email: '', dept: 'WAREH', position: '倉務員（5.5 天)', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L168', eName: 'Yuen Hui Sze', cName: '袁墟斯', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L170', eName: 'Li Jianhua', cName: '李健華', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5)' },
    { staffCode: 'L173', eName: 'Yu Ka Man', cName: '余嘉文', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L175', eName: 'Cheung Yuk Kwan', cName: '張玉君', email: '', dept: 'OFFICE', position: '清潔員', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L198', eName: 'Yu Wai Man', cName: '余偉文', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L210', eName: 'Lo Ka Yan', cName: '盧家欣', email: '', dept: 'OFFICE', position: '', role: 'Employee', isActive: true, mobile: '93009444', employType: 'FULL(5.5)' },
    { staffCode: 'L212', eName: 'Zeng Yunlong', cName: '曾雲龍', email: '', dept: 'WAREH', position: '', role: 'Employee', isActive: true, mobile: '68993819', employType: 'FULL(5.5)' },
    { staffCode: 'L213', eName: 'Lam Ping Man', cName: '林炳文', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '53744773', employType: 'FULL(6)' },
    { staffCode: 'L214', eName: 'Ip Kim Ming', cName: '葉劍明', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '90885966', employType: 'FULL(6)' },
    { staffCode: 'L217', eName: 'Wong Man Hei', cName: '王汶熙', email: '', dept: 'WAREH', position: '', role: 'Employee', isActive: true, mobile: '54005122', employType: 'FULL(5.5)' },
    { staffCode: 'L224', eName: 'Tang Yin Chiu', cName: '鄧演潮', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '67317860', employType: 'FULL(6)' },
    { staffCode: 'L231', eName: 'KHAN, Mohammad Saeed', cName: 'KHAN M S', email: '', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '5170 7525', employType: 'FULL(6)' },
    { staffCode: 'L234', eName: 'Chan Wai Sum', cName: '陳偉森', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '67393922', employType: 'FULL(6)' },
    { staffCode: 'L237', eName: 'Chik Ka Hin', cName: '植嘉軒', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L239', eName: 'Chui Yan Shun', cName: '徐人舜', email: '', dept: 'WAREH', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L240', eName: 'Leung Cheuk Yin', cName: '梁卓然', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '6688 2961', employType: 'FULL(6)' },
    { staffCode: 'L248', eName: 'Lam Kam Wan', cName: '林錦雲', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L249', eName: 'Jiang Jianyu', cName: '江劍羽', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L250', eName: 'Yuen Ho Yin', cName: '袁浩賢', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L251', eName: 'Wong Ping Wo', cName: '黃炳和', email: '', dept: 'WAREH', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(5.5)' },
    { staffCode: 'L252', eName: 'Poon Yam Fai', cName: '潘任輝', email: 'paulpoon0852@gmail.com', dept: 'TRANS', position: '司機', role: 'Employee', isActive: true, mobile: '98537959', employType: 'FULL(6)' },
    { staffCode: 'L255', eName: 'Cheung Sung Wai', cName: '張崇瑋', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '', employType: 'FULL(6)' },
    { staffCode: 'L256', eName: 'Tsang Kwong Fat', cName: '曾廣發', email: '844656942fatfat@gmail.com', dept: 'WAREH', position: '', role: 'Employee', isActive: true, mobile: '6902 6663', employType: 'FULL(5.5)' },
    { staffCode: 'L258', eName: 'Wong Chi Hin', cName: '黃子軒', email: '', dept: 'TRANS', position: 'wong_chihin@yahoo.com.hk', role: 'Employee', isActive: true, mobile: '94224496', employType: 'FULL(5)' },
    { staffCode: 'L259', eName: 'Kwong He Kevin', cName: '鄺致林', email: '', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '64882079', employType: 'FULL(6)' },
    { staffCode: 'L261', eName: 'Wong Cheong Moon', cName: '黃昌滿', email: 'simonwong719@msn.com', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '96577655', employType: 'FULL(6)' },
    { staffCode: 'L262', eName: 'Ng Pak Hin', cName: '吳柏軒', email: 'nphin.7.0409@gmail.com', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '53007532', employType: 'FULL(5)' },
    { staffCode: 'L264', eName: 'Ng Siu Fung', cName: '吳少峰', email: 'fn9332521643@gmail.com', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '93325216', employType: 'FULL(5)' },
    { staffCode: 'L265', eName: 'So Wun Ming', cName: '蘇煥銘', email: 'amwgah1@yahoo.com.hk', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '55921212', employType: 'FULL(5)' },
    { staffCode: 'L266', eName: 'Chan Yun Kit', cName: '陳潤傑', email: 'kitkitkit201212@gmail.com', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '9706 8266', employType: 'FULL(6)' },
    { staffCode: 'T012', eName: 'Hui Ka Wai', cName: '許家偉', email: 'trucklinkco@yahoo.com.hk', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '66633070', employType: 'FULL(5)' },
    { staffCode: 'T013', eName: 'Lee Hon Wing', cName: '李漢榮', email: 'leehonwing102@gmail.com', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '54997493', employType: 'FULL(5)' },
    { staffCode: 'T016', eName: 'Chan Ka Wun', cName: '陳嘉媛', email: 'kawunchan08@Gmail.com', dept: 'TRANS', position: '', role: 'Employee', isActive: true, mobile: '46203238', employType: 'FULL(5)' }
];

// LEAVE BALANCES (from tb_LeaveBalances for year 2025)
// Data types: StaffCode (nvarchar 40), LeaveTypeID (int), Year (int), TotalDays/UsedDays/RemainingDays (decimal 5,1)
// Note: Currently only ADMIN001 has leave balances in the database. Others default to 0.
const LEAVE_BALANCES = {
    'ADMIN001': {
        annual: { total: 20, used: 0, remaining: 20 },
        sick: { total: 10, used: 0, remaining: 10 },
        personal: { total: 5, used: 0, remaining: 5 },
        study: { total: 2, used: 0, remaining: 2 }
    }
    // Other employees: No leave balance data in current database (would need to be seeded)
};

// HOLIDAYS (from tb_Holidays - Hong Kong Public Holidays 2025)
// Data types: HolidayDate (date), HolidayName_EN/ZH (nvarchar 100), Year (int), IsActive (bit)
const HOLIDAYS_2025 = [
    { date: '2025-01-01', nameEN: "New Year's Day", nameZH: '元旦' },
    { date: '2025-01-29', nameEN: 'Lunar New Year', nameZH: '農曆新年' },
    { date: '2025-01-30', nameEN: 'Lunar New Year', nameZH: '農曆新年' },
    { date: '2025-01-31', nameEN: 'Lunar New Year', nameZH: '農曆新年' },
    { date: '2025-04-04', nameEN: 'Ching Ming Festival', nameZH: '清明節' },
    { date: '2025-04-18', nameEN: 'Good Friday', nameZH: '耶穌受難節' },
    { date: '2025-04-19', nameEN: 'Day after Good Friday', nameZH: '耶穌受難節翌日' },
    { date: '2025-04-21', nameEN: 'Easter Monday', nameZH: '復活節星期一' },
    { date: '2025-05-01', nameEN: 'Labour Day', nameZH: '勞動節' },
    { date: '2025-05-05', nameEN: "Buddha's Birthday", nameZH: '佛誕' },
    { date: '2025-05-31', nameEN: 'Tuen Ng Festival', nameZH: '端午節' },
    { date: '2025-07-01', nameEN: 'Hong Kong SAR Establishment Day', nameZH: '香港特別行政區成立紀念日' },
    { date: '2025-10-01', nameEN: 'National Day', nameZH: '國慶日' },
    { date: '2025-10-07', nameEN: 'Mid-Autumn Festival', nameZH: '中秋節' },
    { date: '2025-10-11', nameEN: 'Chung Yeung Festival', nameZH: '重陽節' },
    { date: '2025-12-25', nameEN: 'Christmas Day', nameZH: '聖誕節' },
    { date: '2025-12-26', nameEN: 'Boxing Day', nameZH: '聖誕節後第一個週日' }
];

// HELPER FUNCTIONS
// Get employee by staff code
function getEmployee(staffCode) {
    return EMPLOYEES.find(emp => emp.staffCode === staffCode);
}

// Get employee full name (bilingual)
function getEmployeeFullName(staffCode, lang = 'en') {
    const emp = getEmployee(staffCode);
    if (!emp) return 'Unknown';
    return lang === 'zh' ? `${emp.cName} (${emp.staffCode})` : `${emp.eName} (${emp.staffCode})`;
}

// Get department name
function getDepartmentName(deptCode) {
    return DEPARTMENTS[deptCode] || deptCode;
}

// Get leave balance for employee
function getLeaveBalance(staffCode) {
    return LEAVE_BALANCES[staffCode] || {
        annual: { total: 0, used: 0, remaining: 0 },
        sick: { total: 0, used: 0, remaining: 0 },
        personal: { total: 0, used: 0, remaining: 0 },
        study: { total: 0, used: 0, remaining: 0 }
    };
}

// Get total employee count
function getTotalEmployeeCount() {
    return EMPLOYEES.filter(emp => emp.isActive).length;
}

// Export for use in other scripts (if using modules)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        DEPARTMENTS,
        LEAVE_TYPES,
        EMPLOYEES,
        LEAVE_BALANCES,
        HOLIDAYS_2025,
        getEmployee,
        getEmployeeFullName,
        getDepartmentName,
        getLeaveBalance,
        getTotalEmployeeCount
    };
}

