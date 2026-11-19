import React, { useState, useEffect } from 'react';
import {
  Lightbulb,
  UserCheck,
  Sun,
  Gauge,
  Zap,
  Wifi,
  Sliders,
  Clock,
  CheckCircle2,
  TrendingDown,
  Activity
} from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';
import { RoomTwinCard } from '../components/dashboard/RoomTwinCard';
import { lightingApi, analyticsApi } from '../services/api';

export const DashboardPage = () => {
  const { telemetry, sendWsCommand, recentEvents } = useWebSocket();
  const [sliderVal, setSliderVal] = useState(telemetry.brightness || 100);
  const [energySummary, setEnergySummary] = useState({
    today_energy_wh: 52.4,
    weekly_energy_wh: 348.6,
    monthly_energy_wh: 1420.0,
    estimated_savings_pct: 78.4,
  });

  useEffect(() => {
    setSliderVal(telemetry.brightness);
  }, [telemetry.brightness]);

  useEffect(() => {
    analyticsApi.getEnergy()
      .then((res) => setEnergySummary(res.data))
      .catch(console.error);
  }, []);

  const handleModeChange = (targetMode) => {
    sendWsCommand({ command: 'SET_MODE', mode: targetMode });
    lightingApi.setMode(targetMode).catch(console.error);
  };

  const handleBrightnessChange = (e) => {
    const val = parseInt(e.target.value);
    setSliderVal(val);
    sendWsCommand({ command: 'SET_BRIGHTNESS', brightness: val });
    lightingApi.setBrightness(val).catch(console.error);
  };

  return (
    <div className="space-y-6">
      {/* Top 6 Summary Cards */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {/* Card 1: Light Status */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Light Status</span>
            <Lightbulb className={`w-4 h-4 ${telemetry.light_status ? 'text-amber-400' : 'text-slate-500'}`} />
          </div>
          <div className="mt-2">
            <span className="text-xl font-bold text-white">
              {telemetry.light_status ? 'ACTIVE' : 'OFF'}
            </span>
            <span className="block text-[11px] text-slate-400 font-mono mt-0.5">
              {telemetry.light_status ? `${telemetry.brightness}% PWM` : '0 W'}
            </span>
          </div>
        </div>

        {/* Card 2: Occupancy */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Occupancy</span>
            <UserCheck className={`w-4 h-4 ${telemetry.occupancy ? 'text-emerald-400' : 'text-slate-500'}`} />
          </div>
          <div className="mt-2">
            <span className="text-xl font-bold text-white">
              {telemetry.occupancy ? 'OCCUPIED' : 'VACANT'}
            </span>
            <span className="block text-[11px] text-slate-400 mt-0.5">
              PIR: {telemetry.motion_detected ? 'Motion' : 'Static'}
            </span>
          </div>
        </div>

        {/* Card 3: Ambient Light */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Ambient Light</span>
            <Sun className="w-4 h-4 text-amber-400" />
          </div>
          <div className="mt-2">
            <span className="text-xl font-bold font-mono text-white">
              {telemetry.ambient_light}
            </span>
            <span className="block text-[11px] text-slate-400 mt-0.5">
              Zone: <strong className="text-indigo-400">{telemetry.ambient_light < 350 ? 'DARK' : (telemetry.ambient_light > 700 ? 'BRIGHT' : 'MEDIUM')}</strong>
            </span>
          </div>
        </div>

        {/* Card 4: Brightness */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Brightness</span>
            <Gauge className="w-4 h-4 text-indigo-400" />
          </div>
          <div className="mt-2">
            <span className="text-xl font-bold font-mono text-white">
              {telemetry.brightness}%
            </span>
            <span className="block text-[11px] text-slate-400 mt-0.5">
              Mode: <strong className="text-white">{telemetry.mode}</strong>
            </span>
          </div>
        </div>

        {/* Card 5: Power & Energy */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Power Load</span>
            <Zap className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2">
            <span className="text-xl font-bold font-mono text-white">
              {telemetry.estimated_power_watts} W
            </span>
            <span className="block text-[11px] text-emerald-400 mt-0.5">
              {energySummary.estimated_savings_pct}% Saved
            </span>
          </div>
        </div>

        {/* Card 6: Device Link */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-4 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-xs font-medium">Hardware</span>
            <Wifi className={`w-4 h-4 ${telemetry.hardware_connected ? 'text-emerald-400' : 'text-amber-400'}`} />
          </div>
          <div className="mt-2">
            <span className="text-sm font-bold text-white">
              {telemetry.hardware_connected ? 'FPGA LINK' : 'SIMULATOR'}
            </span>
            <span className="block text-[11px] text-slate-400 mt-0.5 font-mono">
              Timer: {telemetry.timeout_remaining}s
            </span>
          </div>
        </div>
      </div>

      {/* Main Interactive Room Visualizer Card */}
      <RoomTwinCard />

      {/* Interactive Controls & Analytics Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Lighting Mode Selection & Brightness Controls */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-6">
          <div>
            <h3 className="text-base font-bold text-white flex items-center space-x-2">
              <Sliders className="w-4 h-4 text-indigo-400" />
              <span>Operating Mode Selection</span>
            </h3>
            <p className="text-xs text-slate-400 mt-1">
              Select FPGA lighting arbitration rule. Local hardware button takes priority.
            </p>
          </div>

          {/* 3-Way Mode Buttons */}
          <div className="grid grid-cols-3 gap-2">
            {[
              { id: 'AUTO', label: 'AUTO', desc: 'Sensors decide' },
              { id: 'MANUAL_ON', label: 'FORCE ON', desc: 'Override ON' },
              { id: 'MANUAL_OFF', label: 'FORCE OFF', desc: 'Override OFF' },
            ].map((m) => (
              <button
                key={m.id}
                onClick={() => handleModeChange(m.id)}
                className={`p-3 rounded-xl border text-center transition-all ${
                  telemetry.mode === m.id
                    ? 'bg-indigo-600 border-indigo-500 text-white shadow-lg shadow-indigo-600/30'
                    : 'bg-[#0B1220] border-slate-800 text-slate-400 hover:text-slate-200 hover:border-slate-700'
                }`}
              >
                <div className="text-xs font-bold">{m.label}</div>
                <div className="text-[10px] mt-0.5 opacity-80">{m.desc}</div>
              </button>
            ))}
          </div>

          {/* Brightness Slider */}
          <div className="space-y-3 pt-2 border-t border-slate-800">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-300 font-medium">Manual Brightness Setpoint</span>
              <span className="font-mono font-bold text-indigo-400 text-sm">{sliderVal}%</span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              step="5"
              value={sliderVal}
              onChange={handleBrightnessChange}
              className="w-full h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>0% (OFF)</span>
              <span>30% (LOW)</span>
              <span>60% (MED)</span>
              <span>100% (HIGH)</span>
            </div>
          </div>
        </div>

        {/* Middle Column: Energy Overview Card */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-5">
          <div className="flex justify-between items-center">
            <h3 className="text-base font-bold text-white flex items-center space-x-2">
              <Zap className="w-4 h-4 text-emerald-400" />
              <span>Energy Overview</span>
            </h3>
            <span className="text-xs px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-400 font-semibold border border-emerald-500/20">
              {energySummary.estimated_savings_pct}% Net Savings
            </span>
          </div>

          <div className="grid grid-cols-3 gap-3 text-center">
            <div className="bg-[#0B1220] p-3 rounded-xl border border-slate-800">
              <span className="text-[10px] text-slate-400 uppercase font-semibold">Today</span>
              <div className="text-lg font-bold font-mono text-white mt-1">
                {energySummary.today_energy_wh} <span className="text-xs text-slate-400">Wh</span>
              </div>
            </div>
            <div className="bg-[#0B1220] p-3 rounded-xl border border-slate-800">
              <span className="text-[10px] text-slate-400 uppercase font-semibold">This Week</span>
              <div className="text-lg font-bold font-mono text-white mt-1">
                {energySummary.weekly_energy_wh} <span className="text-xs text-slate-400">Wh</span>
              </div>
            </div>
            <div className="bg-[#0B1220] p-3 rounded-xl border border-slate-800">
              <span className="text-[10px] text-slate-400 uppercase font-semibold">This Month</span>
              <div className="text-lg font-bold font-mono text-white mt-1">
                {energySummary.monthly_energy_wh} <span className="text-xs text-slate-400">Wh</span>
              </div>
            </div>
          </div>

          <div className="bg-indigo-950/40 border border-indigo-500/30 rounded-xl p-3 text-xs text-slate-300 space-y-1">
            <div className="flex items-center space-x-1.5 text-indigo-400 font-semibold">
              <TrendingDown className="w-4 h-4" />
              <span>Smart Conservation vs Traditional Baseline</span>
            </div>
            <p className="text-[11px] text-slate-400">
              Calculated against standard 60W continuous lighting. Automatic shut-off and PWM dimming reduces active power draw by over 75%.
            </p>
          </div>
        </div>

        {/* Right Column: Recent Activity Feed */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 flex flex-col justify-between">
          <div className="space-y-4">
            <h3 className="text-base font-bold text-white flex items-center space-x-2">
              <Activity className="w-4 h-4 text-indigo-400" />
              <span>Recent Activity Feed</span>
            </h3>

            <div className="space-y-2.5 max-h-56 overflow-y-auto pr-1">
              {recentEvents.length === 0 ? (
                <div className="text-xs text-slate-500 py-6 text-center">
                  Waiting for telemetry events...
                </div>
              ) : (
                recentEvents.slice(0, 5).map((evt) => (
                  <div key={evt.id} className="flex items-start space-x-2.5 text-xs p-2 rounded-lg bg-[#0B1220]/70 border border-slate-800/80">
                    <span className="font-mono text-[10px] text-slate-500 shrink-0 mt-0.5">
                      {evt.time}
                    </span>
                    <span className="text-slate-300 flex-1">{evt.text}</span>
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="pt-3 border-t border-slate-800 text-[11px] text-slate-500 flex justify-between">
            <span>Inactivity Auto-Shutdown</span>
            <span className="font-mono text-slate-300">{telemetry.timeout_remaining}s remaining</span>
          </div>
        </div>
      </div>
    </div>
  );
};
