import React from 'react';
import { Play, UserCheck, Sun, Moon, Zap, RefreshCw, Sparkles } from 'lucide-react';
import { useWebSocket } from '../../context/WebSocketContext';
import { lightingApi } from '../../services/api';

export const VirtualHardwareDock = () => {
  const { telemetry, sendWsCommand } = useWebSocket();

  const handleMotionToggle = (active) => {
    sendWsCommand({ command: 'INJECT_MOTION', active });
    lightingApi.injectSimEvent({ motion: active }).catch(console.error);
  };

  const handleLuxChange = (lux) => {
    sendWsCommand({ command: 'SET_LUX', lux: parseInt(lux) });
    lightingApi.injectSimEvent({ ambient_light: parseInt(lux) }).catch(console.error);
  };

  const handleQuickLux = (lux) => {
    handleLuxChange(lux);
  };

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-[#0F172A]/95 backdrop-blur-md border-t border-indigo-500/30 px-6 py-3 z-40 shadow-2xl flex flex-wrap items-center justify-between gap-4">
      {/* Badge & Notice */}
      <div className="flex items-center space-x-3">
        <div className="flex items-center space-x-1.5 px-2.5 py-1 rounded-md bg-amber-500/20 text-amber-400 border border-amber-500/30 text-xs font-bold tracking-wide">
          <Sparkles className="w-3.5 h-3.5" />
          <span>VIRTUAL HARDWARE TEST DOCK</span>
        </div>
        <span className="text-xs text-slate-400 hidden lg:inline">
          Interact with simulated sensor hardware inputs in real time:
        </span>
      </div>

      {/* Interactive Controls */}
      <div className="flex flex-wrap items-center gap-4">
        {/* Motion Trigger */}
        <div className="flex items-center space-x-2 bg-[#172033] px-3 py-1.5 rounded-lg border border-slate-700">
          <span className="text-xs text-slate-300 font-medium">Virtual PIR:</span>
          <button
            onClick={() => handleMotionToggle(!telemetry.motion_detected)}
            className={`px-3 py-1 rounded text-xs font-semibold flex items-center space-x-1 transition-all ${
              telemetry.motion_detected
                ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/30'
                : 'bg-slate-700 hover:bg-slate-600 text-slate-200'
            }`}
          >
            <UserCheck className="w-3.5 h-3.5" />
            <span>{telemetry.motion_detected ? 'Motion ACTIVE' : 'Trigger Motion'}</span>
          </button>
        </div>

        {/* Ambient Lux Slider */}
        <div className="flex items-center space-x-3 bg-[#172033] px-3 py-1.5 rounded-lg border border-slate-700">
          <span className="text-xs text-slate-300 font-medium flex items-center space-x-1">
            {telemetry.ambient_light < 350 ? (
              <Moon className="w-3.5 h-3.5 text-indigo-400" />
            ) : (
              <Sun className="w-3.5 h-3.5 text-amber-400" />
            )}
            <span>Lux:</span>
            <span className="font-mono text-indigo-400 text-xs font-bold">{telemetry.ambient_light}</span>
          </span>
          <input
            type="range"
            min="50"
            max="1000"
            step="10"
            value={telemetry.ambient_light}
            onChange={(e) => handleLuxChange(e.target.value)}
            className="w-28 accent-indigo-500 cursor-pointer h-1.5 bg-slate-700 rounded-lg"
          />
          <div className="flex space-x-1">
            <button
              onClick={() => handleQuickLux(150)}
              className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700 hover:bg-slate-600 text-slate-300"
              title="Set Dark Room"
            >
              Dark
            </button>
            <button
              onClick={() => handleQuickLux(500)}
              className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700 hover:bg-slate-600 text-slate-300"
              title="Set Medium Light"
            >
              Med
            </button>
            <button
              onClick={() => handleQuickLux(850)}
              className="text-[10px] px-1.5 py-0.5 rounded bg-slate-700 hover:bg-slate-600 text-slate-300"
              title="Set Bright Daylight"
            >
              Bright
            </button>
          </div>
        </div>

        {/* Inactivity Stepper */}
        <div className="flex items-center space-x-2 text-xs bg-[#172033] px-3 py-1.5 rounded-lg border border-slate-700">
          <span className="text-slate-400">Timer:</span>
          <span className="font-mono font-bold text-amber-400">{telemetry.timeout_remaining}s</span>
          <button
            onClick={() => lightingApi.injectSimEvent({ tick_countdown: true })}
            className="p-1 rounded bg-slate-700 hover:bg-slate-600 text-slate-200"
            title="Step Countdown"
          >
            <RefreshCw className="w-3 h-3" />
          </button>
        </div>
      </div>
    </div>
  );
};
