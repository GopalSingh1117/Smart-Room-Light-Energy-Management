import axios from 'axios';

const api = axios.create({
  baseURL: typeof window !== 'undefined' && window.location.port === '5173'
    ? `http://${window.location.hostname}:8000/api`
    : '/api',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Attach JWT token to requests if present in localStorage
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

export const lightingApi = {
  getStatus: () => api.get('/lighting/status'),
  setMode: (mode) => api.post('/lighting/mode', { mode }),
  setPower: (power) => api.post('/lighting/power', { power }),
  setBrightness: (brightness) => api.post('/lighting/brightness', { brightness }),
  setTimeoutSec: (timeout_seconds) => api.post('/lighting/timeout', { timeout_seconds }),
  setEnergySaving: (enabled) => api.post('/lighting/energy-saving', { enabled }),
  injectSimEvent: (event) => api.post('/lighting/simulate', event),
};

export const sensorsApi = {
  getLatest: () => api.get('/sensors/latest'),
  getHistory: (limit = 30) => api.get(`/sensors/history?limit=${limit}`),
  getOccupancy: () => api.get('/sensors/occupancy'),
  getAmbientLight: () => api.get('/sensors/ambient-light'),
};

export const analyticsApi = {
  getEnergy: () => api.get('/analytics/energy'),
  getDaily: () => api.get('/analytics/daily'),
  getWeekly: () => api.get('/analytics/weekly'),
  getMonthly: () => api.get('/analytics/monthly'),
};

export const settingsApi = {
  getSettings: () => api.get('/settings'),
  updateSettings: (data) => api.put('/settings', data),
};

export const devicesApi = {
  getDevices: () => api.get('/devices'),
};

export const authApi = {
  login: (email, password) => api.post('/auth/login', { email, password }),
  register: (name, email, password) => api.post('/auth/register', { name, email, password }),
  getMe: () => api.get('/auth/me'),
};

export default api;
