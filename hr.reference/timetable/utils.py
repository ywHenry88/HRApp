import pyodbc
from reportlab.lib.pagesizes import A4
from reportlab.platypus import SimpleDocTemplate, Paragraph, LongTable, Spacer, KeepTogether, Table
from reportlab.lib.styles import getSampleStyleSheet
from reportlab.lib import colors
import calendar
from datetime import datetime, timedelta
from io import BytesIO
import holidays
from config import Config
import locale
import re
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

# Register Traditional Chinese font (MingLiU)
try:
    pdfmetrics.registerFont(TTFont('MingLiU', 'C:/Windows/Fonts/mingliub.ttc'))
except Exception as e:
    print(f"Warning: Could not register MingLiU font: {e}. Falling back to SimSun.")
    pdfmetrics.registerFont(TTFont('MingLiU', 'C:/Windows/Fonts/simsun.ttc'))

def get_access_db_connection():
    try:
        conn_str = f"DRIVER={{Microsoft Access Driver (*.mdb, *.accdb)}};DBQ={Config.ACCESS_DB_PATH};"
        conn = pyodbc.connect(conn_str)
        return conn
    except Exception as e:
        raise

def has_chinese(text):
    return bool(re.search('[\u4e00-\u9fff]', text))

def generate_pdf(department, month, year, filename, include_toc=True):
    print(f"Generating PDF for {department} - {month} {year}")
    try:
        conn = get_access_db_connection()
        cursor = conn.cursor()

        cursor.execute("SELECT DEPTID FROM DEPARTMENTS WHERE DEPTNAME = ?", (department,))
        dept_row = cursor.fetchone()
        if not dept_row:
            conn.close()
            return None
        dept_id = dept_row.DEPTID

        cursor.execute("SELECT USERID, Name, SSN FROM USERINFO WHERE DEFAULTDEPTID = ? ORDER BY SSN", (dept_id,))
        employees = cursor.fetchall()

        month_map = {
            'January': 1, 'February': 2, 'March': 3, 'April': 4, 'May': 5, 'June': 6,
            'July': 7, 'August': 8, 'September': 9, 'October': 10, 'November': 11, 'December': 12
        }
        month_num = month_map[month]

        cal = calendar.Calendar(firstweekday=6)
        weeks = cal.monthdatescalendar(year, month_num)
        all_dates = set(date for week in weeks for date in week)
        start_date = min(all_dates)
        end_date = max(all_dates) + timedelta(days=1)

        hk_holidays = holidays.HongKong(years=year)

        checkout_data = {}
        for employee in employees:
            user_id = employee.USERID
            cursor.execute("""
                SELECT CHECKTIME, CHECKTYPE, SENSORID
                FROM CHECKINOUT
                WHERE USERID = ? AND CHECKTIME >= ? AND CHECKTIME < ?
                ORDER BY CHECKTIME
            """, (user_id, start_date, end_date))
            checkouts = cursor.fetchall()
            if checkouts:
                daily_checkouts = {}
                for checkout in checkouts:
                    date_key = checkout.CHECKTIME.date()
                    daily_checkouts.setdefault(date_key, []).append((checkout.CHECKTIME, checkout.SENSORID))
                checkout_data[user_id] = daily_checkouts

        leave_data = {}
        for employee in employees:
            user_id = employee.USERID
            cursor.execute("""
                SELECT usp.STARTSPECDAY, usp.ENDSPECDAY, lc.LEAVENAME
                FROM USER_SPEDAY usp
                INNER JOIN leaveclass lc ON usp.DATEID = lc.LEAVEID
                WHERE usp.USERID = ? AND usp.STARTSPECDAY < ? AND usp.ENDSPECDAY > ?
            """, (user_id, end_date, start_date))
            leaves = cursor.fetchall()
            if leaves:
                leave_days = {}
                for leave in leaves:
                    start = leave.STARTSPECDAY.date() if isinstance(leave.STARTSPECDAY, datetime) else leave.STARTSPECDAY
                    end = leave.ENDSPECDAY.date() if isinstance(leave.ENDSPECDAY, datetime) else leave.ENDSPECDAY
                    leave_name = leave.LEAVENAME
                    for date in all_dates:
                        if start <= date <= end:
                            leave_days[date] = leave_name
                leave_data[user_id] = leave_days

        if not checkout_data and not leave_data:
            conn.close()
            return None

        buffer = BytesIO()
        doc = SimpleDocTemplate(buffer, pagesize=A4, leftMargin=Config.MARGIN_SIZE, rightMargin=Config.MARGIN_SIZE,
                                topMargin=Config.MARGIN_SIZE, bottomMargin=Config.MARGIN_SIZE)
        elements = []
        styles = getSampleStyleSheet()

        if include_toc:
            num_staff = sum(1 for employee in employees if employee.USERID in checkout_data or employee.USERID in leave_data)
            num_rows = num_staff
            available_height = A4[1] - 2 * Config.MARGIN_SIZE
            header_height = 20
            summary_height = 20
            spacer_height = 24
            toc_table_height = available_height - header_height - summary_height - spacer_height

            target_row_height = toc_table_height / num_rows
            font_size = min(max(6, target_row_height / 1.2), 10)
            leading = font_size * 1.2

            toc_style = styles['Normal']
            toc_style.fontSize = font_size
            toc_style.leading = leading

            toc_data = []
            counter = 1
            for employee in employees:
                user_id = employee.USERID
                if user_id not in checkout_data and user_id not in leave_data:
                    continue
                ssn = employee.SSN
                name = employee.Name

                working_days = 0
                leave_types = {}
                for date in all_dates:
                    if date.month != month_num:
                        continue
                    if user_id in leave_data and date in leave_data[user_id]:
                        leave_name = leave_data[user_id][date]
                        leave_types[leave_name] = leave_types.get(leave_name, 0) + 1
                    elif user_id in checkout_data and date in checkout_data[user_id]:
                        working_days += 1

                summary = f"Working Days: {working_days}"
                if leave_types:
                    leave_summary_parts = []
                    for leave, count in leave_types.items():
                        leave_font = 'MingLiU' if has_chinese(leave) else 'Helvetica'
                        leave_summary_parts.append(f"<font face='{leave_font}'>{leave}</font>: {count}")
                    leave_summary = ", ".join(leave_summary_parts)
                    summary += f", Leaves: {leave_summary}"
                else:
                    summary += ", Leaves: None"

                name_font = 'MingLiU' if has_chinese(name) else 'Helvetica'
                staff_label = f"<font face='{name_font}'>{counter:02d} - {ssn} {name}</font> ({summary})"
                toc_entry = Paragraph(f"<link href='#staff_{ssn}' color='blue'>{staff_label}</link>", toc_style)
                toc_data.append([toc_entry])
                counter += 1

            toc_table = Table(toc_data, colWidths=[A4[0] - 2 * Config.MARGIN_SIZE])
            toc_table.setStyle([
                ('FONTSIZE', (0, 0), (-1, -1), font_size),
                ('LEADING', (0, 0), (-1, -1), leading),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ])

            total_working_days = sum(
                sum(1 for date in all_dates if date.month == month_num and user_id in checkout_data and date in checkout_data[user_id] and (user_id not in leave_data or date not in leave_data[user_id]))
                for user_id in checkout_data
            )
            dept_leave_types = {}
            for user_id in leave_data:
                for date, leave_name in leave_data[user_id].items():
                    if date.month == month_num:
                        dept_leave_types[leave_name] = dept_leave_types.get(leave_name, 0) + 1
            dept_summary = f"Department Total - Working Days: {total_working_days}"
            if dept_leave_types:
                dept_leave_summary_parts = []
                for leave, count in dept_leave_types.items():
                    leave_font = 'MingLiU' if has_chinese(leave) else 'Helvetica'
                    dept_leave_summary_parts.append(f"<font face='{leave_font}'>{leave}</font>: {count}")
                dept_leave_summary = ", ".join(dept_leave_summary_parts)
                dept_summary += f", Leaves: {dept_leave_summary}"
            else:
                dept_summary += ", Leaves: None"

            summary_style = styles['Normal']
            summary_style.fontSize = 10
            summary_para = Paragraph(dept_summary, summary_style)

            toc_section = KeepTogether([
                Paragraph("Table of Contents", styles['Heading2']),
                summary_para,
                Spacer(1, 12),
                toc_table,
                Spacer(1, 24)
            ])
            elements.append(toc_section)

        day_names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
        formatted_day_names = [
            Paragraph(f"<b><font color='{Config.SUNDAY_COLOR if day == 'Sun' else 'black'}'>{day}</font></b>", styles['Normal'])
            for day in day_names
        ]

        for employee in employees:
            user_id = employee.USERID
            if user_id not in checkout_data and user_id not in leave_data:
                continue
            ssn = employee.SSN
            name = employee.Name

            working_days = 0
            leave_types = {}
            for date in all_dates:
                if date.month != month_num:
                    continue
                if user_id in leave_data and date in leave_data[user_id]:
                    leave_name = leave_data[user_id][date]
                    leave_types[leave_name] = leave_types.get(leave_name, 0) + 1
                elif user_id in checkout_data and date in checkout_data[user_id]:
                    working_days += 1

            summary = f"Working Days: {working_days}"
            if leave_types:
                leave_summary_parts = []
                for leave, count in leave_types.items():
                    leave_font = 'MingLiU' if has_chinese(leave) else 'Helvetica'
                    leave_summary_parts.append(f"<font face='{leave_font}'>{leave}</font>: {count}")
                leave_summary = ", ".join(leave_summary_parts)
                summary += f", Leaves: {leave_summary}"
            else:
                summary += ", Leaves: None"

            name_font = 'MingLiU' if has_chinese(name) else 'Helvetica'
            emp_style = styles['Heading3']
            emp_style.fontSize = Config.SUBHEADER_FONT_SIZE
            employee_header = Paragraph(
                f"<a name='staff_{ssn}'></a><font face='{name_font}'>{ssn} {name}</font> <font size='10' color='gray'>({summary})</font>",
                emp_style
            )

            table_data = [formatted_day_names]
            out_of_month_cells = []
            sunday_cells = []
            holiday_cells = []
            for week_index, week in enumerate(weeks):
                row = []
                for col_index, date in enumerate(week):
                    day_str = f"{date.day:02d}"
                    if date.month != month_num:
                        out_of_month_cells.append((week_index + 1, col_index))
                        content = f"<font size='{Config.DAY_FONT_SIZE}' color='grey'><b>{day_str}</b></font>"
                    else:
                        is_holiday = date in hk_holidays or date.weekday() == 6
                        day_color = Config.SUNDAY_COLOR if is_holiday else 'black'
                        content = f"<font size='{Config.DAY_FONT_SIZE}' color='{day_color}'><b>{day_str}</b></font>"
                        if col_index == 0:  # Sunday
                            sunday_cells.append((week_index + 1, col_index))
                        if date in hk_holidays:  # Public holiday
                            holiday_cells.append((week_index + 1, col_index))
                    if user_id in leave_data and date in leave_data[user_id]:
                        leave_name = leave_data[user_id][date]
                        leave_font = 'MingLiU' if has_chinese(leave_name) else 'Helvetica'
                        content += f"<br/><font face='{leave_font}' color='{Config.LEAVE_NAME_COLOR}'>{leave_name}</font>"
                    if user_id in checkout_data and date in checkout_data[user_id]:
                        times = checkout_data[user_id][date]
                        formatted_times = []
                        seen = set()
                        for t, sensor_id in times:
                            original_locale = locale.getlocale()
                            locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
                            formatted = t.strftime('%I:%M%p').lower()
                            locale.setlocale(locale.LC_ALL, original_locale)
                            if formatted not in seen:
                                seen.add(formatted)
                                if sensor_id == "1":
                                    formatted_times.append(
                                        f"<font size='{Config.TIME_FONT_SIZE}' color='{Config.TIME_COLOR_SENSOR1}'>{formatted}</font>")
                                else:
                                    formatted_times.append(f"<font size='{Config.TIME_FONT_SIZE}'>{formatted}</font>")
                        content += f"<br/>{'<br/>'.join(formatted_times)}"
                    row.append(Paragraph(content, styles['Normal']))
                table_data.append(row)

            table = LongTable(table_data, colWidths=[74] * 7, repeatRows=1)
            style_commands = [
                ('GRID', (0, 0), (-1, -1), 1, colors.black),
                ('FONTSIZE', (0, 0), (-1, -1), Config.DEFAULT_FONT_SIZE),
                ('VALIGN', (0, 0), (-1, -1), 'TOP'),
                ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
                ('BACKGROUND', (0, 0), (-1, 0), colors.Color(0.8, 0.8, 0.8)),  # Header background
                *[('BACKGROUND', (cell[1], cell[0]), (cell[1], cell[0]), colors.Color(0.9882, 0.8941, 0.9255)) for cell in sunday_cells],  # Sundays
                *[('BACKGROUND', (cell[1], cell[0]), (cell[1], cell[0]), colors.Color(0.9882, 0.8941, 0.9255)) for cell in holiday_cells],  # Holidays
            ]
            for row, col in out_of_month_cells:
                style_commands.append(('BACKGROUND', (col, row), (col, row), colors.Color(0.8, 0.8, 0.8)))
            table.setStyle(style_commands)

            employee_section = KeepTogether([employee_header, Spacer(1, 12), table, Spacer(1, 24)])
            elements.append(employee_section)

        def add_page_info(canvas, doc):
            canvas.saveState()
            canvas.setFont('Helvetica-Bold', Config.HEADER_FONT_SIZE)
            canvas.drawCentredString(A4[0] / 2, 822, "Etak Logistics Limited - Staff's Monthly Duties Timetable")
            header_text = f"{department} Department - {month} {year}"
            canvas.setFont('Helvetica-Bold', 10)
            canvas.drawCentredString(A4[0] / 2, 802, header_text)
            canvas.setFont('Helvetica', 8)
            page_num = f"Page {canvas.getPageNumber()}"
            original_locale = locale.getlocale()
            locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
            print_time = datetime.now().strftime('%Y-%m-%d %I:%M:%S %p')
            locale.setlocale(locale.LC_ALL, original_locale)
            canvas.drawString(40, 36, page_num)
            canvas.drawRightString(A4[0] - 40, 36, print_time)
            canvas.restoreState()

        doc.build(elements, onFirstPage=add_page_info, onLaterPages=add_page_info)
        buffer.seek(0)
        conn.close()
        return buffer
    except Exception as e:
        print(f"Error generating PDF: {e}")
        if 'conn' in locals():
            conn.close()
        return None

if __name__ == "__main__":
    buffer = generate_pdf("Transportation", "January", 2025, "test_timetable.pdf")
    if buffer:
        with open("test_timetable.pdf", "wb") as f:
            f.write(buffer.getvalue())
        print("PDF generated: test_timetable.pdf")
    else:
        print("PDF generation failed")