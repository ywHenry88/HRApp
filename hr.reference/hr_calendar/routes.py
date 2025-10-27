from flask import render_template, request, send_file, session, url_for
from hr_calendar import hr_calendar_bp
from hr_calendar.utils import fetch_leave_data, get_leave_type_description, get_hr_db_connection
from utils import login_required
import calendar
from datetime import datetime, date
import holidays
from holidays.constants import OPTIONAL, PUBLIC
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, Table, Spacer
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from io import BytesIO
import re
import locale

# Register Chinese font (SimSun)
pdfmetrics.registerFont(TTFont('SimSun', 'C:/Windows/Fonts/simsun.ttc'))

# Function to detect Chinese characters
def has_chinese(text):
    return bool(re.search('[\u4e00-\u9fff]', text))

@hr_calendar_bp.route('/', methods=['GET', 'POST'])
@login_required
def display_calendar():
    # Ensure the calendar starts on Sunday
    calendar.setfirstweekday(calendar.SUNDAY)

    current_date = datetime.now()
    year = current_date.year
    month = current_date.month
    departments = ['TRANS', 'WAREH', 'OFFICE']
    show_official_only = False

    # Get the current view from the session, default to 'traditional'
    current_view = session.get('calendar_view', 'traditional')

    # Get sorting parameters from session or query
    sort_field = session.get('sort_field', 'StaffCode')  # Default to StaffCode
    sort_direction = session.get('sort_direction', 'ASC')  # Default to ascending

    # Check if sorting is requested via query parameter
    if 'sort' in request.args:
        new_sort_field = request.args.get('sort')
        if new_sort_field in ['StaffCode', 'EName']:
            # If clicking the same field, toggle direction; otherwise, reset to ASC
            if new_sort_field == sort_field:
                sort_direction = 'DESC' if sort_direction == 'ASC' else 'ASC'
            else:
                sort_field = new_sort_field
                sort_direction = 'ASC'
            # Update session
            session['sort_field'] = sort_field
            session['sort_direction'] = sort_direction
        # Preserve other query parameters
        year = int(request.args.get('year', current_date.year))
        month = int(request.args.get('month', current_date.month))
        departments = request.args.getlist('departments') or departments
        show_official_only = request.args.get('show_official_only', 'off') == 'on'

    if request.method == 'POST':
        month_year = request.form.get('month_year')
        if month_year:
            try:
                date_obj = datetime.strptime(month_year, '%Y-%m')
                year = date_obj.year
                month = date_obj.month
            except ValueError:
                pass

        departments = []
        if request.form.get('chkTrans'):
            departments.append('TRANS')
        if request.form.get('chkWareh'):
            departments.append('WAREH')
        if request.form.get('chkOffice'):
            departments.append('OFFICE')
        show_official_only = request.form.get('chkShow') == 'on'

        # Update the current view based on the form submission
        current_view = request.form.get('current_view', 'traditional')
        session['calendar_view'] = current_view

    # Generate the calendar with Sunday as the first day
    cal = calendar.monthcalendar(year, month)
    days_in_month = calendar.monthrange(year, month)[1]
    on_hold_leaves, on_hold_official_leaves, approved_leaves, approved_official_leaves = fetch_leave_data(
        year, month, departments, show_official_only
    )

    # Initialize Hong Kong holidays with Hong Kong locale (Traditional Chinese)
    locale.setlocale(locale.LC_ALL, 'zh_HK.UTF-8')  # Set locale to Chinese (Traditional, Hong Kong)
    hk_holidays = holidays.HongKong(years=year, language='zh_HK', categories=(OPTIONAL, PUBLIC))

    # Prepare data for Traditional View
    leave_data = {}
    holiday_days = set()
    holiday_names = {}  # Map day to holiday name
    for day in range(1, 32):
        leave_data[day] = {}
        for leave_dict in [on_hold_leaves, on_hold_official_leaves, approved_leaves, approved_official_leaves]:
            if day in leave_dict:
                for leave_id, data in leave_dict[day].items():
                    key = (data['leave_type'], data['status'])
                    if key not in leave_data[day]:
                        leave_data[day][key] = {
                            'staff': [],
                            'leave_type': data['leave_type'],
                            'status': data['status'],
                            'short_description': get_leave_type_description(data['leave_type'])  # Short form
                        }
                    leave_data[day][key]['staff'].extend(data['staff'])

        try:
            check_date = date(year, month, day)
            if check_date in hk_holidays:
                holiday_days.add(day)
                holiday_names[day] = hk_holidays.get(check_date)  # Get the holiday name
        except ValueError:
            continue

    # Calculate day of the week for each day in the month (0 = Sunday, 6 = Saturday)
    days_of_week = {}
    for day in range(1, days_in_month + 1):
        try:
            date_obj = date(year, month, day)
            # weekday() returns 0 (Monday) to 6 (Sunday); adjust to 0 (Sunday) to 6 (Saturday)
            day_of_week = (date_obj.weekday() + 1) % 7
            days_of_week[day] = day_of_week
        except ValueError:
            continue

    # Prepare data for Employee Grid View
    # Fetch all staff members with their CName and EName
    conn = get_hr_db_connection()
    cursor = conn.cursor()
    dept_filter = ""
    if departments:
        dept_list = ",".join([f"'{dept}'" for dept in departments])
        dept_filter = f" WHERE Dept IN ({dept_list}) "
    # Sort by the selected field and direction
    query = f"""
    SELECT StaffCode, CName, EName
    FROM tb_Staff
    {dept_filter}
    ORDER BY {sort_field} {sort_direction}
    """
    cursor.execute(query)
    staff_list = cursor.fetchall()
    cursor.close()
    conn.close()

    # Build staff_leave_data with full names and leave information, only for staff with leaves
    staff_leave_data = []
    staff_dict = {}  # To keep track of staff members with leave applications
    # First, populate leave data to identify staff with applications
    for day in range(1, days_in_month + 1):
        for leave_dict in [on_hold_leaves, on_hold_official_leaves, approved_leaves, approved_official_leaves]:
            if day in leave_dict:
                for leave_id, data in leave_dict[day].items():
                    for staff in data['staff']:
                        staff_code = staff['staff_code']
                        if staff_code not in staff_dict:
                            # Initialize the staff entry
                            staff_dict[staff_code] = {
                                'staff_code': staff_code,
                                'leaves': {d: None for d in range(1, days_in_month + 1)}
                            }
                        staff_dict[staff_code]['leaves'][day] = {
                            'leave_type': data['leave_type'],
                            'status': data['status'],
                            'short_description': get_leave_type_description(data['leave_type'])
                        }

    # Now, add staff details only for those with leave applications, in the order of staff_list
    for staff in staff_list:
        staff_code = staff.StaffCode
        if staff_code in staff_dict:  # Only include staff with leave applications
            cname = staff.CName.strip() if staff.CName else ""
            ename = staff.EName.strip() if staff.EName else ""
            display_name = f"{staff_code} {cname} {ename}".strip()
            staff_dict[staff_code]['staff_name'] = display_name
            staff_dict[staff_code]['ename'] = ename  # Store EName for sorting reference
            # Add to staff_leave_data in the order of staff_list
            staff_leave_data.append(staff_dict[staff_code])

    # Temporarily set locale to English for month name formatting
    original_locale = locale.getlocale()
    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
    month_name = datetime(year, month, 1).strftime('%b %Y')
    locale.setlocale(locale.LC_ALL, original_locale)  # Restore original locale

    return render_template(
        'calendar.html',
        calendar=cal,
        leave_data=leave_data,
        month_name=month_name,
        year=year,
        month=month,
        departments=departments,
        show_official_only=show_official_only,
        holiday_days=holiday_days,
        holiday_names=holiday_names,
        staff_leave_data=staff_leave_data,
        days_in_month=days_in_month,
        days_of_week=days_of_week,
        current_view=current_view,
        sort_field=sort_field,
        sort_direction=sort_direction
    )

@hr_calendar_bp.route('/staff_leaves/<staff_code>/<int:year>/<int:month>', methods=['GET'])
@login_required
def staff_leaves(staff_code, year, month):
    conn = get_hr_db_connection()
    cursor = conn.cursor()

    query = """
    SELECT 
        ld.LeaveDate, 
        l.StaffCode, 
        CASE WHEN LTRIM(RTRIM(s.CName)) = '' THEN s.EName ELSE s.CName END AS StaffName, 
        l.LeaveType, 
        l.LeaveID, 
        l.IsMst
    FROM tb_Leave l
    INNER JOIN tb_Staff s ON s.StaffCode = l.StaffCode
    INNER JOIN tb_LeaveDtl ld ON l.LeaveID = ld.LeaveID
    WHERE l.StaffCode = ?
    AND YEAR(ld.LeaveDate) = ?
    AND MONTH(ld.LeaveDate) = ?
    ORDER BY ld.LeaveDate
    """
    cursor.execute(query, (staff_code, year, month))
    rows = cursor.fetchall()

    leave_applications = []
    for row in rows:
        from datetime import datetime as dt, date
        if isinstance(row.LeaveDate, (dt, date)):
            leave_date = row.LeaveDate
        else:
            leave_date = dt.strptime(row.LeaveDate, '%Y-%m-%d')

        leave_applications.append({
            'date': leave_date.strftime('%Y-%m-%d'),
            'staff_code': row.StaffCode,
            'staff_name': row.StaffName,
            'leave_type': row.LeaveType,
            'leave_id': row.LeaveID,
            'status': 'Approved' if row.IsMst == 1 else 'On Hold',
            'full_description': get_leave_type_description(row.LeaveType, full_str=True)  # Full description
        })

    cursor.close()
    conn.close()

    # Temporarily set locale to English for month name formatting
    original_locale = locale.getlocale()
    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
    month_name = datetime(year, month, 1).strftime('%B %Y')
    locale.setlocale(locale.LC_ALL, original_locale)  # Restore original locale

    return render_template('staff_leaves.html',
                           staff_name=leave_applications[0]['staff_name'] if leave_applications else staff_code,
                           leave_applications=leave_applications,
                           month_name=month_name,
                           year=year,
                           month=month)

@hr_calendar_bp.route('/generate_pdf', methods=['POST'])
@login_required
def generate_calendar_pdf():
    year = int(request.form['year'])
    month = int(request.form['month'])
    departments = request.form.getlist('departments')
    show_official_only = request.form.get('show_official_only') == 'on'
    filename = request.form.get('filename', f'hr_leave_calendar_{year}_{month:02d}.pdf')

    # Fetch leave data
    on_hold_leaves, on_hold_official_leaves, approved_leaves, approved_official_leaves = fetch_leave_data(
        year, month, departments, show_official_only
    )

    # Initialize Hong Kong holidays with Hong Kong locale (Traditional Chinese)
    locale.setlocale(locale.LC_ALL, 'zh_HK.UTF-8')  # Set locale to Chinese (Traditional, Hong Kong)
    hk_holidays = holidays.HongKong(years=year, language='zh_HK')

    # Prepare calendar data
    cal = calendar.monthcalendar(year, month)
    leave_data = {}
    holiday_days = set()
    holiday_names = {}  # Map day to holiday name
    holiday_cells = []  # Track holiday cell positions
    sunday_cells = []  # Track Sunday cell positions
    for day in range(1, 32):
        leave_data[day] = {}
        for leave_dict in [on_hold_leaves, on_hold_official_leaves, approved_leaves, approved_official_leaves]:
            if day in leave_dict:
                for leave_id, data in leave_dict[day].items():
                    key = (data['leave_type'], data['status'])
                    if key not in leave_data[day]:
                        leave_data[day][key] = {
                            'staff': [],
                            'leave_type': data['leave_type'],
                            'status': data['status'],
                            'short_description': get_leave_type_description(data['leave_type'])  # Short form
                        }
                    leave_data[day][key]['staff'].extend(data['staff'])

        try:
            check_date = date(year, month, day)
            if check_date in hk_holidays:
                holiday_days.add(day)
                holiday_names[day] = hk_holidays.get(check_date)  # Get the holiday name
        except ValueError:
            continue

    # Generate PDF
    buffer = BytesIO()
    doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=36, rightMargin=36, topMargin=36, bottomMargin=36)
    elements = []
    styles = getSampleStyleSheet()

    # Define styles
    header_style = styles['Heading1']
    header_style.fontName = 'Helvetica'  # Explicitly set to English font
    header_style.fontSize = 16
    header_style.alignment = 1

    normal_style = styles['Normal']
    normal_style.fontName = 'Helvetica'  # Default to Helvetica for English content
    normal_style.fontSize = 8
    normal_style.alignment = 0  # Left alignment
    normal_style.leading = 8  # Single line spacing (matches font size)

    # Title with month name in English
    original_locale = locale.getlocale()
    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
    month_name = datetime(year, month, 1).strftime('%B %Y')
    locale.setlocale(locale.LC_ALL, original_locale)  # Restore original locale

    elements.append(Paragraph(f"HR Leave Calendar - {month_name}", header_style))
    elements.append(Spacer(1, 12))

    # Calendar table data
    table_data = [['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']]
    row_idx = 1
    for week in cal:
        row = []
        col_idx = 0
        for day in week:
            if day == 0:
                row.append('')
            else:
                font = 'SimSun' if has_chinese(str(day)) else 'Helvetica'
                # Always color Sundays red, and also color holidays red
                if col_idx == 0 or day in holiday_days:  # Sunday or holiday
                    content = f"<b><font color='#ff0000'>{day}</font></b>"
                    if col_idx == 0:  # Sunday
                        sunday_cells.append((row_idx, col_idx))
                    if day in holiday_days:  # Holiday
                        holiday_cells.append((row_idx, col_idx))
                        holiday_name = holiday_names.get(day, '')
                        content += f"<br/><font face='SimSun' size='5' color='#ff0000'>{holiday_name}</font>"
                else:
                    content = f"<b>{day}</b>"
                if day in leave_data:
                    leave_text = []
                    for key, leave in leave_data[day].items():
                        staff_names = "<br/>".join(staff['staff_name'] for staff in leave['staff'])
                        font = 'SimSun' if has_chinese(staff_names) else 'Helvetica'
                        leave_type = leave['short_description']
                        leave_text.append(f"<font face='{font}'>{staff_names}: {leave_type}</font>")
                    content += "<br/>" + "<br/>".join(leave_text)
                row.append(Paragraph(content, normal_style))
            col_idx += 1
        table_data.append(row)
        row_idx += 1

    # Create table without background colors, left-aligned content
    table = Table(table_data, colWidths=[80] * 7, repeatRows=1)
    table.setStyle([
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('FONTSIZE', (0, 0), (-1, -1), 8),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),  # Left alignment for all cells
        ('BACKGROUND', (0, 0), (-1, 0), colors.lightgrey),  # Header only
        *[('BACKGROUND', (cell[1], cell[0]), (cell[1], cell[0]), colors.Color(0.9882, 0.8941, 0.9255)) for cell in
          sunday_cells],  # Pink #fce4ec
        *[('BACKGROUND', (cell[1], cell[0]), (cell[1], cell[0]), colors.Color(0.9882, 0.8941, 0.9255)) for cell in
          holiday_cells],  # Pink #fce4ec
    ])
    elements.append(table)

    # Build PDF
    doc.build(elements)
    buffer.seek(0)
    return send_file(buffer, as_attachment=True, download_name=filename)