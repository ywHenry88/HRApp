import pyodbc
from config import Config
import calendar

calendar.setfirstweekday(calendar.SUNDAY)

def get_hr_db_connection():
    return pyodbc.connect(Config.HR_DB_PATH)

def fetch_leave_data(year, month, departments, show_official_only):
    conn = get_hr_db_connection()
    cursor = conn.cursor()

    dept_filter = ""
    if departments:
        dept_list = ",".join([f"'{dept}'" for dept in departments])
        dept_filter = f" AND Dept IN ({dept_list}) "
    else:
        dept_filter = " AND Dept = '' "

    def execute_leave_query(query, params):
        cursor.execute(query, params)
        result = {}
        for row in cursor.fetchall():
            day = row.LDay
            leave_id = row.LeaveID
            if day not in result:
                result[day] = {}
            if leave_id not in result[day]:
                result[day][leave_id] = {
                    'staff': [],
                    'leave_type': row.LeaveType,
                    'status': 'On Hold' if 'IsMst = 0' in query else 'Approved'
                }
            result[day][leave_id]['staff'].append({
                'staff_code': row.StaffCode,
                'staff_name': row.StaffName
            })
        return result

    on_hold_leaves = {}
    if not show_official_only:
        query_on_hold = f"""
        SELECT 
            DAY(ld.LeaveDate) AS LDay, 
            l.StaffCode, 
            CASE WHEN LTRIM(RTRIM(s.CName)) = '' THEN s.EName ELSE s.CName END AS StaffName, 
            l.LeaveType,
            l.LeaveID
        FROM tb_Leave l
        INNER JOIN tb_Staff s ON s.StaffCode = l.StaffCode
        INNER JOIN tb_LeaveDtl ld ON l.LeaveID = ld.LeaveID
        WHERE l.IsMst = 0
        AND YEAR(ld.LeaveDate) = ?
        AND MONTH(ld.LeaveDate) = ?
        AND l.LeaveType <> 7
        {dept_filter}
        ORDER BY ld.LeaveDate, StaffName
        """
        on_hold_leaves = execute_leave_query(query_on_hold, (year, month))

    on_hold_official_leaves = execute_leave_query(f"""
        SELECT 
            DAY(ld.LeaveDate) AS LDay, 
            l.StaffCode, 
            CASE WHEN LTRIM(RTRIM(s.CName)) = '' THEN s.EName ELSE s.CName END AS StaffName, 
            l.LeaveType,
            l.LeaveID
        FROM tb_Leave l
        INNER JOIN tb_Staff s ON s.StaffCode = l.StaffCode
        INNER JOIN tb_LeaveDtl ld ON l.LeaveID = ld.LeaveID
        WHERE l.IsMst = 0
        AND YEAR(ld.LeaveDate) = ?
        AND MONTH(ld.LeaveDate) = ?
        AND l.LeaveType = 7
        {dept_filter}
        ORDER BY ld.LeaveDate, StaffName
    """, (year, month))

    approved_leaves = {}
    if not show_official_only:
        query_approved = f"""
        SELECT 
            DAY(ld.LeaveDate) AS LDay, 
            l.StaffCode, 
            CASE WHEN LTRIM(RTRIM(s.CName)) = '' THEN s.EName ELSE s.CName END AS StaffName, 
            l.LeaveType,
            l.LeaveID
        FROM tb_Leave l
        INNER JOIN tb_Staff s ON s.StaffCode = l.StaffCode
        INNER JOIN tb_LeaveDtl ld ON l.LeaveID = ld.LeaveID
        WHERE l.IsMst = 1
        AND YEAR(ld.LeaveDate) = ?
        AND MONTH(ld.LeaveDate) = ?
        AND l.LeaveType <> 7
        {dept_filter}
        ORDER BY ld.LeaveDate, StaffName
        """
        approved_leaves = execute_leave_query(query_approved, (year, month))

    approved_official_leaves = execute_leave_query(f"""
        SELECT 
            DAY(ld.LeaveDate) AS LDay, 
            l.StaffCode, 
            CASE WHEN LTRIM(RTRIM(s.CName)) = '' THEN s.EName ELSE s.CName END AS StaffName, 
            l.LeaveType,
            l.LeaveID
        FROM tb_Leave l
        INNER JOIN tb_Staff s ON s.StaffCode = l.StaffCode
        INNER JOIN tb_LeaveDtl ld ON l.LeaveID = ld.LeaveID
        WHERE l.IsMst = 1
        AND YEAR(ld.LeaveDate) = ?
        AND MONTH(ld.LeaveDate) = ?
        AND l.LeaveType = 7
        {dept_filter}
        ORDER BY ld.LeaveDate, StaffName
    """, (year, month))

    cursor.close()
    conn.close()

    return on_hold_leaves, on_hold_official_leaves, approved_leaves, approved_official_leaves

def get_leave_type_description(leave_type, full_str=False):
    # Match the Select Case logic for leave types
    if leave_type == 1:
        return "Annual (No Paid)" if full_str else "NP"
    elif leave_type == 2:
        return "Annual" if full_str else "AL"
    elif leave_type == 3:
        return "Sick Leave (Paid)" if full_str else "SP"
    elif leave_type == 4:
        return "Sick Leave (Annual)" if full_str else "SA"
    elif leave_type == 5:
        return "Sick Leave (No Paid)" if full_str else "SN"
    elif leave_type == 6:
        return "Sick Leave (Others)" if full_str else "SO"
    elif leave_type == 7:
        return "Official Leave" if full_str else "例"  # Official Leave short code
    elif leave_type == 0:
        return "Others" if full_str else "OT"
    else:
        return ""