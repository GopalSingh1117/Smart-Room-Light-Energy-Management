import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './context/AuthContext';
import { WebSocketProvider } from './context/WebSocketContext';
import { MainLayout } from './layouts/MainLayout';

import { DashboardPage } from './pages/DashboardPage';
import { LiveMonitoringPage } from './pages/LiveMonitoringPage';
import { LightingControlPage } from './pages/LightingControlPage';
import { EnergyAnalyticsPage } from './pages/EnergyAnalyticsPage';
import { DeviceManagementPage } from './pages/DeviceManagementPage';
import { SettingsPage } from './pages/SettingsPage';

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <WebSocketProvider>
          <Routes>
            <Route path="/" element={<MainLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="monitoring" element={<LiveMonitoringPage />} />
              <Route path="control" element={<LightingControlPage />} />
              <Route path="analytics" element={<EnergyAnalyticsPage />} />
              <Route path="devices" element={<DeviceManagementPage />} />
              <Route path="settings" element={<SettingsPage />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Route>
          </Routes>
        </WebSocketProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}

export default App;
