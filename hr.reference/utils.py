import pyodbc
from flask import session, redirect, url_for, flash
from functools import wraps
from config import Config

def get_logistics_db_connection():
    try:
        return pyodbc.connect(Config.LOGISTICS_DB_PATH)
    except pyodbc.Error as e:
        print(f"Database connection error: {e}")
        raise

def get_hr_db_connection():
    try:
        return pyodbc.connect(Config.HR_DB_PATH)
    except pyodbc.Error as e:
        print(f"Database connection error: {e}")
        raise

def login_required(f):
    @wraps(f)
    def wrap(*args, **kwargs):
        if 'logged_in' not in session:
            flash('Please log in to access this page.', 'error')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return wrap