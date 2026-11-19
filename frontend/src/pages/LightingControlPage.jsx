import React, { useState } from 'react';
import { Sliders, Power, Clock, Leaf, CheckCircle2, AlertCircle, ShieldAlert } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';
import { lightingApi } from '../services/api';

export const LightingControlPage = () => {
  const { telemetry, sendWsCommand, addEvent } = useWebSocket();
  const [targetBrightness, setTargetBrightness] = useState(telemetry.brightness || 100);
  const [targetTimeout, setTargetTimeout] = useState(telemetry.timeout_remaining || 30);
  const [energySaving, setEnergySaving] = useState(true);
  const [ackStatus, setAckStatus] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleModeSelect = async (mode) => {
    setLoading(true);
    try {
      sendWsCommand({ command: 'SET_MODE', mode });
      await lightingApi.setMode(mode);
      setAckStatus({ type: 'success', msg: `Command ACK: Mode switched to ${mode}. FPGA arbitrated.` });
      addEvent(`User switched operating mode to ${mode}`, 'info');
    } catch (err) {
      setAckStatus({ type: 'error', msg: 'Failed to transmit mode command to gateway.' });
    } finally {
      setLoading(false);
    }
  };

  const handleApplyControl = async () => {
    setLoading(true);
    try {
      sendWsCommand({ command: 'SET_BRIGHTNESS', brightness: targetBrightness });
      await lightingApi.setBrightness(targetBrightness);

      sendWsCommand({ command: 'SET_TIMEOUT', timeout_seconds: targetTimeout });
      await lightingApi.setTimeoutSec(targetTimeout);

      await lightingApi.setEnergySaving(energySaving);

      setAckStatus({ type: 'success', msg: 'Command ACK: Brightness, Timeout, and Energy settings synchronized with FPGA.' });
      addEvent(`Applied settings: Brightness=${targetBrightness}%, Timeout=${targetTimeout}s`, 'success');
    } catch (err) {
      setAckStatus({ type: 'error', msg: 'Gateway transmission failed.' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      <div>
        <h2 className="text-xl font-bold text-white tracking-tight flex items-center space-x-2">
          <Sliders className="w-5 h-5 text-indigo-400" />
          <span>Dedicated Lighting Control Console</span>
        </h2>
        <p className="text-xs text-slate-400 mt-1">
          Direct hardware arbitration overrides. Commands are framed with CRC and forwarded directly to the FPGA UART controller.
        </p>
      </div>

      {/* Acknowledgement Toast Banner */}
      {ackStatus && (
        <div className={`p-4 rounded-xl border flex items-center justify-between text-xs font-medium ${
          ackStatus.type === 'success'
            ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
            : 'bg-rose-500/10 border-rose-500/30 text-rose-300'
        }`}>
          <div className="flex items-center space-x-2">
            {ackStatus.type === 'success' ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <AlertCircle className="w-4 h-4 shrink-0" />}
            <span>{ackStatus.msg}</span>
          </div>
          <button onClick={() => setAckStatus(null)} className="text-slate-400 hover:text-white">✕</button>
        </div>
      )}

      {/* Mode Selector Section */}
      <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-4">
        <h3 className="text-sm font-bold text-white uppercase tracking-wider">
          1. System Operating Mode
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* AUTO Mode */}
          <div
            onClick={() => handleModeSelect('AUTO')}
            className={`cursor-pointer p-4 rounded-xl border transition-all ${
              telemetry.mode === 'AUTO'
                ? 'bg-indigo-600/20 border-indigo-500 ring-2 ring-indigo-500/30'
                : 'bg-[#0B1220] border-slate-800 hover:border-slate-700'
            }`}
          >
            <div className="flex justify-between items-center">
              <span className="font-bold text-sm text-white">AUTO MODE</span>
              {telemetry.mode === 'AUTO' && <CheckCircle2 className="w-4 h-4 text-indigo-400" />}
            </div>
            <p className="text-xs text-slate-400 mt-2">
              Autonomous FPGA sensor control. PIR motion and LDR ambient lux determine lighting.
            </p>
          </div>

          {/* MANUAL ON */}
          <div
            onClick={() => handleModeSelect('MANUAL_ON')}
            className={`cursor-pointer p-4 rounded-xl border transition-all ${
              telemetry.mode === 'MANUAL_ON'
                ? 'bg-emerald-600/20 border-emerald-500 ring-2 ring-emerald-500/30'
                : 'bg-[#0B1220] border-slate-800 hover:border-slate-700'
            }`}
          >
            <div className="flex justify-between items-center">
              <span className="font-bold text-sm text-white">MANUAL ON</span>
              {telemetry.mode === 'MANUAL_ON' && <CheckCircle2 className="w-4 h-4 text-emerald-400" />}
            </div>
            <p className="text-xs text-slate-400 mt-2">
              Forces lighting ON at selected setpoint. Sensor darkness and motion rules bypassed.
            </p>
          </div>

          {/* MANUAL OFF */}
          <div
            onClick={() => handleModeSelect('MANUAL_OFF')}
            className={`cursor-pointer p-4 rounded-xl border transition-all ${
              telemetry.mode === 'MANUAL_OFF'
                ? 'bg-rose-600/20 border-rose-500 ring-2 ring-rose-500/30'
                : 'bg-[#0B1220] border-slate-800 hover:border-slate-700'
            }`}
          >
            <div className="flex justify-between items-center">
              <span className="font-bold text-sm text-white">MANUAL OFF</span>
              {telemetry.mode === 'MANUAL_OFF' && <CheckCircle2 className="w-4 h-4 text-rose-400" />}
            </div>
            <p className="text-xs text-slate-400 mt-2">
              Forces lighting OFF (0% duty). All automatic triggers suppressed.
            </p>
          </div>
        </div>
      </div>

      {/* Manual Brightness & Inactivity Configuration */}
      <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-6">
        <h3 className="text-sm font-bold text-white uppercase tracking-wider">
          2. Hardware Setpoints & Timers
        </h3>

        {/* Brightness */}
        <div className="space-y-3">
          <div className="flex justify-between items-center text-xs">
            <span className="text-slate-300 font-semibold">Target Brightness Level</span>
            <span className="font-mono font-bold text-indigo-400 text-sm">{targetBrightness}%</span>
          </div>
          <input
            type="range"
            min="0"
            max="100"
            step="5"
            value={targetBrightness}
            onChange={(e) => setTargetBrightness(parseInt(e.target.value))}
            className="w-full h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-indigo-500"
          />
          <div className="flex justify-between text-[11px] text-slate-500">
            <span>0% (OFF)</span>
            <span>30% (Low Dim)</span>
            <span>60% (Medium)</span>
            <span>100% (High Output)</span>
          </div>
        </div>

        {/* Inactivity Timeout */}
        <div className="space-y-3 pt-4 border-t border-slate-800">
          <div className="flex justify-between items-center text-xs">
            <span className="text-slate-300 font-semibold flex items-center space-x-1.5">
              <Clock className="w-4 h-4 text-amber-400" />
              <span>Inactivity Shutdown Timeout (Seconds)</span>
            </span>
            <span className="font-mono font-bold text-amber-400 text-sm">{targetTimeout}s</span>
          </div>
          <input
            type="range"
            min="5"
            max="300"
            step="5"
            value={targetTimeout}
            onChange={(e) => setTargetTimeout(parseInt(e.target.value))}
            className="w-full h-2 bg-slate-800 rounded-lg appearance-none cursor-pointer accent-amber-500"
          />
          <div className="flex justify-between text-[11px] text-slate-500">
            <span>5s (Test Fast)</span>
            <span>30s (Default Lab)</span>
            <span>120s (2 Mins)</span>
            <span>300s (5 Mins)</span>
          </div>
        </div>

        {/* Energy Saving Strategy Toggle */}
        <div className="pt-4 border-t border-slate-800 flex items-center justify-between">
          <div className="space-y-0.5">
            <div className="text-xs font-semibold text-white flex items-center space-x-1.5">
              <Leaf className="w-4 h-4 text-emerald-400" />
              <span>Aggressive Energy-Saving Mode</span>
            </div>
            <p className="text-[11px] text-slate-400">
              Dims medium light condition to 30% instead of 60%, and turns lights off immediately upon bright daylight emergence.
            </p>
          </div>
          <button
            onClick={() => setEnergySaving(!energySaving)}
            className={`w-12 h-6 rounded-full transition-colors p-1 flex items-center ${
              energySaving ? 'bg-emerald-600 justify-end' : 'bg-slate-700 justify-start'
            }`}
          >
            <span className="w-4 h-4 rounded-full bg-white shadow-md" />
          </button>
        </div>

        {/* Apply Settings Button */}
        <div className="pt-4 border-t border-slate-800 flex justify-end">
          <button
            onClick={handleApplyControl}
            disabled={loading}
            className="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold transition-all shadow-lg shadow-indigo-600/30 flex items-center space-x-2"
          >
            {loading ? <span>Transmitting...</span> : <span>Apply & Synchronize Hardware</span>}
          </button>
        </div>
      </div>
    </div>
  );
};
