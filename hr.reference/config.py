class Config:
    # Timetable PDF Configuration
    HEADER_FONT_SIZE = 12
    SUBHEADER_FONT_SIZE = 12
    DEFAULT_FONT_SIZE = 10
    DAY_FONT_SIZE = 12
    TIME_FONT_SIZE = 10
    SUNDAY_COLOR = 'red'
    LEAVE_NAME_COLOR = 'red'
    TIME_COLOR_SENSOR1 = 'blue'
    MARGIN_SIZE = 36

    # Database Paths
    ACCESS_DB_PATH = r"C:\github\py01\Etak\Timecard\att2000.mdb"
    LOGISTICS_DB_PATH = 'DRIVER={SQL Server};SERVER=.;DATABASE=Logistics;Trusted_Connection=yes;'
    HR_DB_PATH = 'DRIVER={SQL Server};SERVER=.;DATABASE=HR;Trusted_Connection=yes;'

    # Common Settings
    HOST = '0.0.0.0'
    PORT = 1088

    # Session Configuration
    SECRET_KEY = '88888888'  # Replace with a secure random key
    SESSION_TYPE = 'filesystem'
    SESSION_PERMANENT = True
    PERMANENT_SESSION_LIFETIME_SHORT = 600  # 10 minutes in seconds
    PERMANENT_SESSION_LIFETIME_LONG = 2592000  # 30 days in seconds