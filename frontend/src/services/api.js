// Version: 2.0.0
// API Service - HTTP Client Configuration and API Methods

import axios from 'axios'
import router from '../router'

// =============================================================================
// AXIOS INSTANCE CONFIGURATION
// =============================================================================

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// =============================================================================
// REQUEST INTERCEPTOR
// Add JWT token to all requests
// =============================================================================

api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token')
    if (token) {
      config.headers.Authorization = `Bearer ${token}`
    }
    return config
  },
  error => {
    return Promise.reject(error)
  }
)

// =============================================================================
// RESPONSE INTERCEPTOR
// Handle common errors (401, 403, etc.)
// =============================================================================

api.interceptors.response.use(
  response => {
    return response
  },
  error => {
    // Handle 401 Unauthorized (token expired or invalid)
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      router.push('/login')
    }
    
    // Handle 403 Forbidden
    if (error.response?.status === 403) {
      console.error('Access forbidden')
    }
    
    return Promise.reject(error)
  }
)

// =============================================================================
// AUTHENTICATION API
// =============================================================================

export const authAPI = {
  /**
   * User login
   * @param {Object} credentials - { username, password }
   * @returns {Promise} - { token, user }
   */
  login: (credentials) => api.post('/auth/login', credentials),
  
  /**
   * User logout
   * @returns {Promise}
   */
  logout: () => api.post('/auth/logout'),
  
  /**
   * Get current user information
   * @returns {Promise} - User object
   */
  getCurrentUser: () => api.get('/auth/me'),
  
  /**
   * Change password
   * @param {Object} data - { currentPassword, newPassword, confirmPassword }
   * @returns {Promise}
   */
  changePassword: (data) => api.post('/auth/change-password', data)
}

// =============================================================================
// LEAVE MANAGEMENT API
// =============================================================================

export const leaveAPI = {
  /**
   * Get leave balance for current user
   * @param {Number} year - Optional year parameter
   * @returns {Promise} - Array of leave balances
   */
  getBalance: (year = null) => {
    const params = year ? { year } : {}
    return api.get('/leaves/balance', { params })
  },
  
  /**
   * Get all active leave types
   * @returns {Promise} - Array of leave types
   */
  getTypes: () => api.get('/leaves/types'),
  
  /**
   * Submit a new leave request
   * @param {Object} data - { leaveTypeId, startDate, endDate, reason }
   * @returns {Promise} - Created request object
   */
  submitRequest: (data) => api.post('/leaves/request', data),
  
  /**
   * Get leave history for current user
   * @param {Object} params - { status, leaveTypeId, startDate, endDate, limit, offset }
   * @returns {Promise} - { requests, pagination }
   */
  getHistory: (params = {}) => api.get('/leaves/history', { params }),
  
  /**
   * Get specific leave request by ID
   * @param {Number} id - Request ID
   * @returns {Promise} - Request object
   */
  getRequest: (id) => api.get(`/leaves/request/${id}`),
  
  /**
   * Update pending leave request
   * @param {Number} id - Request ID
   * @param {Object} data - { startDate, endDate, reason }
   * @returns {Promise} - Updated request object
   */
  updateRequest: (id, data) => api.put(`/leaves/request/${id}`, data),
  
  /**
   * Cancel leave request
   * @param {Number} id - Request ID
   * @returns {Promise}
   */
  cancelRequest: (id) => api.delete(`/leaves/request/${id}`)
}

// =============================================================================
// PROFILE API
// =============================================================================

export const profileAPI = {
  /**
   * Get user profile
   * @returns {Promise} - User profile object
   */
  getProfile: () => api.get('/profile'),
  
  /**
   * Update user profile
   * @param {Object} data - { fullName, email }
   * @returns {Promise} - Updated profile object
   */
  updateProfile: (data) => api.put('/profile', data)
}

// =============================================================================
// CALENDAR API
// =============================================================================

export const calendarAPI = {
  /**
   * Get team calendar
   * @param {Object} params - { startDate, endDate, month, year }
   * @returns {Promise} - Array of leave events
   */
  getTeamCalendar: (params = {}) => api.get('/calendar', { params }),
  
  /**
   * Get public holidays
   * @param {Number} year - Optional year parameter
   * @returns {Promise} - Array of holidays
   */
  getHolidays: (year = null) => {
    const params = year ? { year } : {}
    return api.get('/calendar/holidays', { params })
  },
  
  /**
   * Get employees on leave today
   * @returns {Promise} - Array of employees
   */
  getOnLeaveToday: () => api.get('/calendar/on-leave-today')
}

// =============================================================================
// ADMIN API
// =============================================================================

export const adminAPI = {
  /**
   * Get dashboard statistics
   * @returns {Promise} - { totalEmployees, pendingApprovals, onLeaveToday, overdueApprovals }
   */
  getDashboardStats: () => api.get('/admin/dashboard/stats'),
  
  /**
   * Get pending leave approvals
   * @param {Object} params - { limit, offset, departmentId, leaveTypeId }
   * @returns {Promise} - { requests, pagination }
   */
  getPendingApprovals: (params = {}) => api.get('/admin/leaves/pending', { params }),
  
  /**
   * Approve leave request
   * @param {Number} id - Request ID
   * @param {Object} data - { comments }
   * @returns {Promise}
   */
  approveRequest: (id, data = {}) => api.put(`/admin/leaves/approve/${id}`, data),
  
  /**
   * Reject leave request
   * @param {Number} id - Request ID
   * @param {Object} data - { comments }
   * @returns {Promise}
   */
  rejectRequest: (id, data) => api.put(`/admin/leaves/reject/${id}`, data),
  
  /**
   * Get all employees
   * @param {Object} params - { search, departmentId, isActive, limit, offset }
   * @returns {Promise} - { employees, pagination }
   */
  getEmployees: (params = {}) => api.get('/admin/employees', { params }),
  
  /**
   * Create new employee
   * @param {Object} data - { username, password, fullName, employeeCode, email, departmentId, position, role, leaveAllocations }
   * @returns {Promise} - Created employee object
   */
  createEmployee: (data) => api.post('/admin/employees', data),
  
  /**
   * Update employee
   * @param {Number} id - Employee ID
   * @param {Object} data - { fullName, email, departmentId, position, role, isActive }
   * @returns {Promise} - Updated employee object
   */
  updateEmployee: (id, data) => api.put(`/admin/employees/${id}`, data),
  
  /**
   * Get all leave types
   * @returns {Promise} - Array of leave types
   */
  getLeaveTypes: () => api.get('/admin/leave-types'),
  
  /**
   * Get all departments
   * @returns {Promise} - Array of departments
   */
  getDepartments: () => api.get('/admin/departments'),
  
  /**
   * Get leave utilization report
   * @param {Object} params - { year, departmentId }
   * @returns {Promise} - Array of utilization data
   */
  getLeaveUtilization: (params = {}) => api.get('/admin/reports/leave-utilization', { params })
}

// =============================================================================
// DEFAULT EXPORT
// =============================================================================

export default api

