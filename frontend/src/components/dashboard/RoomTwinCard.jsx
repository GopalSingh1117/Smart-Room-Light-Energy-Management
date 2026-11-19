import React from 'react';
import { Lightbulb, Power, Sparkles, Moon, Sun, UserCheck, UserX } from 'lucide-react';
import { useWebSocket } from '../../context/WebSocketContext';
import { lightingApi } from '../../services/api';

export const RoomTwinCard = () => {
  const { telemetry, sendWsCommand } = useWebSocket();

  const handleTogglePower = () => {
    const nextPower = !telemetry.light_status;
    sendWsCommand({
      command: 'SET_MODE',
      mode: nextPower ? 'MANUAL_ON' : 'MANUAL_OFF'
    });
    lightingApi.setPower(nextPower).catch(console.error);
  };

  const getBulbColor = () => {
    if (!telemetry.light_status || telemetry.brightness === 0) return '#475569';
    if (telemetry.brightness < 40) return '#FCD34D'; // Soft warm dim
    if (telemetry.brightness < 80) return '#F59E0B'; // Amber warm
    return '#60A5FA'; // Bright daylight white/cool
  };

  const glowStyle = telemetry.light_status && telemetry.brightness > 0 ? {
    filter: `drop-shadow(0 0 ${Math.max(10, telemetry.brightness * 0.4)}px ${getBulbColor()})`
  } : {};

  return (
    <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 relative overflow-hidden shadow-xl">
      {/* Decorative ambient background gradient */}
      <div
        className="absolute top-0 right-0 w-80 h-80 rounded-full blur-3xl pointer-events-none transition-all duration-700 opacity-20"
        style={{
          backgroundColor: telemetry.light_status ? getBulbColor() : 'transparent',
          transform: 'translate(30%, -30%)'
        }}
      />

      <div className="flex flex-col md:flex-row items-center justify-between gap-6 relative z-10">
        {/* Left Info Column */}
        <div className="space-y-4 text-center md:text-left">
          <div className="inline-flex items-center space-x-2 px-3 py-1 rounded-full text-xs font-semibold bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
            <Sparkles className="w-3.5 h-3.5" />
            <span>ROOM DIGITAL TWIN • REAL-TIME HARDWARE STATE</span>
          </div>

          <div>
            <h2 className="text-2xl font-bold text-white tracking-tight">Smart Lab Lighting</h2>
            <p className="text-sm text-slate-400 mt-1">
              Autonomous Verilog FSM State:{' '}
              <span className="font-mono font-bold text-indigo-400 uppercase bg-indigo-950/60 px-2 py-0.5 rounded border border-indigo-500/30">
                {telemetry.fsm_state || (telemetry.light_status ? 'LIGHT_ON' : 'IDLE')}
              </span>
            </p>
          </div>

          {/* Quick Metrics Pills */}
          <div className="flex flex-wrap items-center justify-center md:justify-start gap-3 pt-2">
            <span className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-[#0B1220] border border-slate-800 text-xs text-slate-300">
              {telemetry.occupancy ? (
                <UserCheck className="w-4 h-4 text-emerald-400" />
              ) : (
                <UserX className="w-4 h-4 text-slate-500" />
              )}
              <span>{telemetry.occupancy ? 'Room Occupied' : 'Vacant'}</span>
            </span>

            <span className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-[#0B1220] border border-slate-800 text-xs text-slate-300">
              {telemetry.ambient_light < 350 ? (
                <Moon className="w-4 h-4 text-indigo-400" />
              ) : (
                <Sun className="w-4 h-4 text-amber-400" />
              )}
              <span>Lux: <strong className="text-white font-mono">{telemetry.ambient_light}</strong></span>
            </span>

            <span className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-[#0B1220] border border-slate-800 text-xs text-slate-300">
              <span>Power: <strong className="text-emerald-400 font-mono">{telemetry.estimated_power_watts} W</strong></span>
            </span>
          </div>
        </div>

        {/* Center: Interactive Graphic Light Bulb */}
        <div className="flex flex-col items-center justify-center p-6 bg-[#0B1220]/60 rounded-2xl border border-slate-800/80 min-w-[220px]">
          <div className="relative cursor-pointer group" onClick={handleTogglePower} title="Click to toggle power">
            <svg
              className="w-28 h-28 transition-all duration-500 transform group-hover:scale-105"
              viewBox="0 0 24 24"
              fill={telemetry.light_status ? getBulbColor() : 'none'}
              stroke={telemetry.light_status ? getBulbColor() : '#64748B'}
              strokeWidth="1.5"
              strokeLinecap="round"
              strokeLinejoin="round"
              style={glowStyle}
            >
              <path d="M12 2a7 7 0 0 0-7 7c0 2.38 1.19 4.47 3 5.74V17a2 2 0 0 0 2 2h4a2 2 0 0 0 2-2v-2.26c1.81-1.27 3-3.36 3-5.74a7 7 0 0 0-7-7z" />
              <line x1="9" y1="21" x2="15" y2="21" />
            </svg>
          </div>

          <div className="mt-3 text-center">
            <span className="text-lg font-bold font-mono text-white tracking-wider">
              {telemetry.light_status ? `${telemetry.brightness}%` : 'OFF'}
            </span>
            <div className="text-[11px] text-slate-400 font-medium">
              PWM Brightness
            </div>
          </div>
        </div>

        {/* Right: Master Interactive Toggle Switch */}
        <div className="flex flex-col items-center justify-center space-y-3">
          <button
            onClick={handleTogglePower}
            className={`w-16 h-16 rounded-2xl flex items-center justify-center transition-all duration-300 shadow-xl ${
              telemetry.light_status
                ? 'bg-emerald-600 text-white shadow-emerald-600/40 hover:bg-emerald-500 scale-105'
                : 'bg-slate-800 text-slate-400 hover:bg-slate-700 hover:text-slate-200'
            }`}
            title="Master Light Switch"
          >
            <Power className="w-8 h-8" />
          </button>
          <span className="text-xs font-semibold uppercase tracking-wider text-slate-300">
            {telemetry.light_status ? 'Switch OFF' : 'Switch ON'}
          </span>
        </div>
      </div>
    </div>
  );
};
