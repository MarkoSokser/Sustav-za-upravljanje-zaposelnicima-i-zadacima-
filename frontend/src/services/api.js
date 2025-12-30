import axios from 'axios';

// Base API URL - promijeni ako backend radi na drugom portu
const API_BASE_URL = 'http://localhost:8000/api';

// Kreiraj axios instancu
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - dodaj token u svaki zahtjev (osim login)
api.interceptors.request.use(
  (config) => {
    // Ne dodavaj token za login request
    if (!config.url?.includes('/auth/login')) {
      const token = localStorage.getItem('token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor - obrada grešaka
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Token je istekao ili nije valjan
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// ==================== AUTH API ====================
export const authAPI = {
  login: (username, password) => 
    api.post('/auth/login', new URLSearchParams({ username, password }), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    }),
  
  getCurrentUser: () => 
    api.get('/auth/me'),
  
  logout: () => 
    api.post('/auth/logout'),
  
  changePassword: (currentPassword, newPassword) =>
    api.post('/auth/change-password', {
      current_password: currentPassword,
      new_password: newPassword
    }),
};

// ==================== USERS API ====================
export const usersAPI = {
  getAll: (isActive = null) => 
    api.get('/users', { params: { is_active: isActive } }),
  
  getById: (userId) => 
    api.get(`/users/${userId}`),
  
  create: (userData) => 
    api.post('/users', userData),
  
  update: (userId, userData) => 
    api.put(`/users/${userId}`, userData),
  
  delete: (userId) => 
    api.delete(`/users/${userId}`),
  
  deactivate: (userId) => 
    api.delete(`/users/${userId}`),
  
  activate: (userId) => 
    api.post(`/users/${userId}/activate`),
  
  getStatistics: (userId) => 
    api.get(`/users/${userId}/statistics`),
  
  getTeam: (userId) => 
    api.get(`/users/${userId}/team`),
  
  getSubordinates: (managerId) => 
    api.get(`/users/${managerId}/subordinates`),
  
  assignManager: (userId, managerId) => 
    api.post(`/users/${userId}/assign-manager`, { manager_id: managerId }),
  
  removeManager: (userId) => 
    api.delete(`/users/${userId}/remove-manager`),
};

// ==================== TASKS API ====================
export const tasksAPI = {
  getAll: (params = {}) => 
    api.get('/tasks', { params }),
  
  getById: (taskId) => 
    api.get(`/tasks/${taskId}`),
  
  create: (taskData) => 
    api.post('/tasks', taskData),
  
  update: (taskId, taskData) => 
    api.put(`/tasks/${taskId}`, taskData),
  
  delete: (taskId) => 
    api.delete(`/tasks/${taskId}`),
  
  updateStatus: (taskId, status) => 
    api.put(`/tasks/${taskId}/status`, { status }),
  
  assignUser: (taskId, userId) => 
    api.post(`/tasks/${taskId}/assign`, { assigned_to: userId }),
  
  unassign: (taskId) => 
    api.delete(`/tasks/${taskId}/unassign`),
  
  getStatistics: () => 
    api.get('/tasks/my/statistics'),
  
  getMyTasks: () => 
    api.get('/tasks/my'),
  
  getOverdue: () => 
    api.get('/tasks/my?overdue=true'),
};

// ==================== ROLES API ====================
export const rolesAPI = {
  getAll: () => 
    api.get('/roles'),
  
  getById: (roleId) => 
    api.get(`/roles/${roleId}`),
  
  create: (roleData) => 
    api.post('/roles', roleData),
  
  update: (roleId, roleData) => 
    api.put(`/roles/${roleId}`, roleData),
  
  delete: (roleId) => 
    api.delete(`/roles/${roleId}`),
  
  assignToUser: (userId, roleName) => 
    api.post('/roles/assign', { user_id: userId, role_name: roleName }),
  
  removeFromUser: (userId, roleName) => 
    api.delete('/roles/revoke', { data: { user_id: userId, role_name: roleName } }),
  
  getPermissions: () => 
    api.get('/roles/permissions'),
  
  getUserRoles: (userId) => 
    api.get(`/roles/user/${userId}`),
  
  // Role Permissions (permisije uloge)
  addPermissionToRole: (roleId, permissionCode) => 
    api.post(`/roles/${roleId}/permissions/${permissionCode}`),
  
  removePermissionFromRole: (roleId, permissionCode) => 
    api.delete(`/roles/${roleId}/permissions/${permissionCode}`),
  
  // User Permissions (direktna dodjela)
  getUserDirectPermissions: (userId) => 
    api.get(`/roles/users/${userId}/permissions`),
  
  getUserEffectivePermissions: (userId) => 
    api.get(`/roles/users/${userId}/effective-permissions`),
  
  assignPermissionToUser: (userId, permissionCode, data = { granted: true }) => 
    api.post(`/roles/users/${userId}/permissions/${permissionCode}`, data),
  
  removePermissionFromUser: (userId, permissionCode) => 
    api.delete(`/roles/users/${userId}/permissions/${permissionCode}`),
};

// ==================== AUDIT API ====================
export const auditAPI = {
  getLogs: (params = {}) => 
    api.get('/audit/logs', { params }),
  
  getLoginEvents: (params = {}) => 
    api.get('/audit/logins', { params }),
  
  getRecentActivity: (limit = 50) => 
    api.get('/audit/recent-activity', { params: { limit } }),
  
  getUserActivity: (userId, limit = 100) => 
    api.get(`/audit/user-activity/${userId}`, { params: { limit } }),
};

export default api;
