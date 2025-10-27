from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_session import Session
from config import Config
from timetable.routes import timetable_bp
from hr_calendar.routes import hr_calendar_bp
from utils import get_logistics_db_connection, login_required

app = Flask(__name__)
app.config.from_object(Config)

# Initialize Flask-Session
Session(app)

# Register Blueprints
app.register_blueprint(timetable_bp, url_prefix='/timetable')
app.register_blueprint(hr_calendar_bp, url_prefix='/calendar')

def is_mobile_device(user_agent):
    """Check if the user agent indicates a mobile device."""
    mobile_keywords = ['Mobile', 'Android', 'iPhone', 'iPad', 'Windows Phone', 'BlackBerry']
    return any(keyword in user_agent for keyword in mobile_keywords)

@app.route('/login', methods=['GET', 'POST'])
def login():
    # Check if the user is already logged in
    if 'logged_in' in session:
        return redirect(url_for('index'))  # Redirect to home page if session exists

    if request.method == 'POST':
        staff_code = request.form['staff_code'].upper()
        staff_pass = request.form['staff_pass']
        keep_signed_in = request.form.get('keep_signed_in') == 'on'  # Check if checkbox is selected

        conn = get_logistics_db_connection()
        cursor = conn.cursor()
        cursor.execute("""
            SELECT StaffCode, StaffPass, Name
            FROM tb_Staff
            WHERE UPPER(StaffCode) = ? AND StaffPass = ?
        """, (staff_code, staff_pass))
        user = cursor.fetchone()
        conn.close()

        if user:
            session['logged_in'] = True
            session['staff_code'] = user.StaffCode
            session['staff_name'] = user.Name  # Store name in session
            # Detect if the device is mobile and set the session variable
            user_agent = request.headers.get('User-Agent', '')
            session['is_mobile'] = is_mobile_device(user_agent)

            # Set session permanence and lifetime based on "Keep me signed in"
            if keep_signed_in:
                session.permanent = True  # Make session permanent
                app.permanent_session_lifetime = Config.PERMANENT_SESSION_LIFETIME_LONG  # 30 days
            else:
                session.permanent = False  # Non-permanent session
                app.permanent_session_lifetime = Config.PERMANENT_SESSION_LIFETIME_SHORT  # 10 minutes

            flash('Login successful!', 'success')
            return redirect(url_for('index'))
        else:
            flash('Invalid Staff Code or Password.', 'error')

    return render_template('login.html')

@app.route('/logout')
def logout():
    session.pop('logged_in', None)
    session.pop('staff_code', None)
    session.pop('staff_name', None)  # Clear name from session
    session.pop('is_mobile', None)  # Clear the is_mobile session variable on logout
    flash('You have been logged out.', 'success')
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    staff_name = session.get('staff_name', 'User')  # Default to 'User' if name not found
    return render_template('index.html', staff_name=staff_name)

if __name__ == '__main__':
    app.run(host=Config.HOST, port=Config.PORT)