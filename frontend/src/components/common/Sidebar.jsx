import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  Activity,
  Sliders,
  BarChart3,
  HardDrive,
  Settings,
  Lightbulb
} from 'lucide-react';

const navItems = [
  { name: 'Dashboard', path: '/', icon: LayoutDashboard },
  { name: 'Live Monitoring', path: '/monitoring', icon: Activity },
  { name: 'Lighting Control', path: '/control', icon: Sliders },
  { name: 'Energy Analytics', path: '/analytics', icon: BarChart3 },
  { name: 'Device Management', path: '/devices', icon: HardDrive },
  { name: 'Settings', path: '/settings', icon: Settings },
];

export const Sidebar = () => {
  return (
    <aside className="w-64 bg-[#111827] border-r border-[#1E293B] flex flex-col justify-between h-[calc(100vh-4rem)] sticky top-16">
      <div className="p-4 space-y-6">
        {/* Brand Badge */}
        <div className="flex items-center space-x-3 px-3 py-2 bg-[#172033] rounded-xl border border-indigo-500/20">
          <div className="p-2 rounded-lg bg-indigo-600 text-white shadow-lg shadow-indigo-600/30">
            <Lightbulb className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs font-bold text-white tracking-wider uppercase">Smart Light OS</div>
            <div className="text-[10px] text-slate-400 font-mono">v2.4.0 • FPGA Real-Time</div>
          </div>
        </div>

        {/* Navigation Items */}
        <nav className="space-y-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) =>
                  `flex items-center space-x-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-200 ${
                    isActive
                      ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/25 font-semibold'
                      : 'text-slate-400 hover:text-slate-100 hover:bg-[#172033]'
                  }`
                }
              >
                <Icon className="w-4 h-4" />
                <span>{item.name}</span>
              </NavLink>
            );
          })}
        </nav>
      </div>

      {/* System Status Footer Card */}
      <div className="p-4 border-t border-[#1E293B]">
        <div className="bg-[#172033]/60 rounded-xl p-3 border border-slate-800 text-xs text-slate-400 space-y-1.5">
          <div className="flex justify-between items-center text-slate-300 font-medium">
            <span>Hardware FSM</span>
            <span className="text-emerald-400 font-mono text-[11px]">8 States Synced</span>
          </div>
          <div className="flex justify-between text-[11px]">
            <span>PWM Clock</span>
            <span className="font-mono text-slate-200">5 kHz (8-bit)</span>
          </div>
          <div className="flex justify-between text-[11px]">
            <span>UART Baud</span>
            <span className="font-mono text-slate-200">115,200 bps</span>
          </div>
        </div>
      </div>
    </aside>
  );
};
