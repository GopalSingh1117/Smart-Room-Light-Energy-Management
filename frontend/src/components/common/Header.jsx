import React from 'react';
import { Cpu, Wifi, WifiOff, Bell, User, Sparkles } from 'lucide-react';
import { useWebSocket } from '../../context/WebSocketContext';
import { useAuth } from '../../context/AuthContext';

export const Header = () => {
  const { connected, telemetry } = useWebSocket();
  const { user } = useAuth();

  return (
    <header className="h-16 bg-[#111827] border-b border-[#1E293B] px-6 flex items-center justify-between sticky top-0 z-30">
      {/* Title & Hardware Target Info */}
      <div className="flex items-center space-x-3">
        <div className="bg-indigo-600/20 text-indigo-400 p-2 rounded-lg border border-indigo-500/30">
          <Cpu className="w-5 h-5" />
        </div>
        <div>
          <h1 className="text-sm font-semibold text-white tracking-wide">
            Smart Room Light & Energy Management
          </h1>
          <p className="text-xs text-slate-400">
            FPGA Verilog Core (Artix-7) • ESP32 Gateway • Live Control
          </p>
        </div>
      </div>

      {/* Status Badges & Controls */}
      <div className="flex items-center space-x-4">
        {/* Hardware / Simulation Mode Pill */}
        {telemetry.hardware_connected ? (
          <span className="flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
            <span>FPGA HARDWARE LIVE</span>
          </span>
        ) : (
          <span className="flex items-center space-x-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            <Sparkles className="w-3.5 h-3.5" />
            <span>SIMULATION MODE</span>
          </span>
        )}

        {/* WebSocket Link Status */}
        <div className="flex items-center space-x-2 text-xs">
          {connected ? (
            <span className="flex items-center space-x-1 text-slate-300">
              <Wifi className="w-4 h-4 text-emerald-400" />
              <span className="hidden sm:inline">Telemetry Synced</span>
            </span>
          ) : (
            <span className="flex items-center space-x-1 text-rose-400">
              <WifiOff className="w-4 h-4" />
              <span className="hidden sm:inline">Reconnecting...</span>
            </span>
          )}
        </div>

        {/* User Pill */}
        <div className="flex items-center space-x-2 pl-3 border-l border-slate-800 text-xs text-slate-300">
          <div className="w-7 h-7 rounded-full bg-indigo-500/20 text-indigo-400 flex items-center justify-center font-bold border border-indigo-500/30">
            <User className="w-4 h-4" />
          </div>
          <span className="hidden md:inline font-medium">{user ? user.name : 'Engineering Demo'}</span>
        </div>
      </div>
    </header>
  );
};
