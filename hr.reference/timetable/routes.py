from flask import render_template, request, send_file, session, flash, redirect, url_for
from timetable import timetable_bp
from timetable.utils import generate_pdf, get_access_db_connection
from utils import login_required
from datetime import datetime
import locale

@timetable_bp.route('/', methods=['GET'])
@login_required
def timetable_form():
    try:
        conn = get_access_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT DEPTNAME FROM DEPARTMENTS")
        departments = [row.DEPTNAME for row in cursor.fetchall()]
        conn.close()
    except Exception as e:
        flash("Error retrieving departments. Please try again later.", "error")
        return render_template('timetable_form.html', departments=[], month_year="", department="", is_mobile=False)

    # Default to current month and year
    current_date = datetime.now()
    year = current_date.year

    # Temporarily set locale to English for month name formatting
    original_locale = locale.getlocale()
    locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
    month = current_date.strftime('%B')  # Full month name in English (e.g., "April")
    month_year_default = f"{year:04d}-{current_date.month:02d}"  # Format for <input type="month">
    locale.setlocale(locale.LC_ALL, original_locale)  # Restore original locale

    # Set default department to "Transportation"
    default_department = "Transportation"

    # Get the is_mobile session variable (default to False if not set)
    is_mobile = session.get('is_mobile', False)

    if request.method == 'GET' and 'month_year' in request.args:
        try:
            month_year = request.args.get('month_year')
            date_obj = datetime.strptime(month_year, '%Y-%m')
            year = date_obj.year
            # Temporarily set locale to English for month name formatting
            original_locale = locale.getlocale()
            locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
            month = date_obj.strftime('%B')  # Convert to full month name in English
            locale.setlocale(locale.LC_ALL, original_locale)  # Restore original locale
        except ValueError:
            pass  # Fallback to current year/month if invalid

    return render_template('timetable_form.html', departments=departments, month_year=month_year_default,
                           department=default_department, is_mobile=is_mobile)

@timetable_bp.route('/generate_pdf', methods=['POST'])
@login_required
def generate_pdf_route():
    try:
        department = request.form['department']
        month_year = request.form['month_year']  # Get single month_year input
        include_toc = request.form.get('include_toc') == 'on'  # Get the checkbox value

        # Parse month_year into month and year
        try:
            date_obj = datetime.strptime(month_year, '%Y-%m')
            year = date_obj.year
            # Temporarily set locale to English for month name formatting
            original_locale = locale.getlocale()
            locale.setlocale(locale.LC_ALL, 'en_US.UTF-8')
            month = date_obj.strftime('%B')  # Convert to full month name in English (e.g., "April")
            locale.setlocale(locale.LC_ALL, original_locale)  # Restore original locale
        except ValueError as e:
            flash("Invalid month and year format.", "error")
            return redirect(url_for('timetable.timetable_form'))

        filename = request.form['filename']
        pdf_buffer = generate_pdf(department, month, year, filename, include_toc=include_toc)
        if pdf_buffer:
            return send_file(pdf_buffer, as_attachment=True, download_name=filename)
        else:
            flash("Department not found or no data available.", "error")
            return redirect(url_for('timetable.timetable_form'))
    except Exception as e:
        flash(f"An error occurred while generating the PDF: {str(e)}", "error")
        return redirect(url_for('timetable.timetable_form'))