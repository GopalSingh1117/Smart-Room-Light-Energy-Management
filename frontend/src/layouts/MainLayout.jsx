import React from 'react';
import { Outlet } from 'react-router-dom';
import { Header } from '../components/common/Header';
import { Sidebar } from '../components/common/Sidebar';
import { VirtualHardwareDock } from '../components/simulation/VirtualHardwareDock';

export const MainLayout = () => {
  return (
    <div className="min-h-screen bg-[#0B1220] flex flex-col">
      <Header />
      <div className="flex flex-1">
        <Sidebar />
        <main className="flex-1 p-6 pb-24 overflow-y-auto max-w-7xl mx-auto w-full">
          <Outlet />
        </main>
      </div>
      <VirtualHardwareDock />
    </div>
  );
};
