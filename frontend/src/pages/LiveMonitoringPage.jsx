import React, { useState, useEffect } from 'react';
import { Activity, Sun, Gauge, UserCheck, Radio, ArrowUpRight } from 'lucide-react';
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid } from 'recharts';
import { useWebSocket } from '../context/WebSocketContext';
import { sensorsApi } from '../services/api';

export const LiveMonitoringPage = () => {
  const { telemetry } = useWebSocket();
  const [chartData, setChartData] = useState([]);

  useEffect(() => {
    // Initial history fetch
    sensorsApi.getHistory(20)
      .then((res) => {
        const formatted = res.data.map((d) => ({
          time: new Date(d.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }),
          lux: d.ambient_light,
          brightness: d.ambient_light < 350 ? 100 : (d.ambient_light > 700 ? 0 : 60),
        }));
        setChartData(formatted);
      })
      .catch(console.error);
  }, []);

  // Append live telemetry point into strip chart
  useEffect(() => {
    const nowTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    setChartData((prev) => [
      ...prev.slice(-19),
      {
        time: nowTime,
        lux: telemetry.ambient_light,
        brightness: telemetry.light_status ? telemetry.brightness : 0,
      },
    ]);
  }, [telemetry]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center space-x-2">
            <Activity className="w-5 h-5 text-indigo-400" />
            <span>Live Sensor & Oscilloscope Telemetry</span>
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            Real-time telemetry stream synchronized at 2 Hz directly from FPGA UART / ESP32 Gateway.
          </p>
        </div>

        <div className="flex items-center space-x-2 px-3 py-1.5 rounded-lg bg-[#172033] border border-slate-700 text-xs">
          <Radio className="w-4 h-4 text-emerald-400 animate-pulse" />
          <span className="text-slate-300 font-medium">Sampling Rate:</span>
          <span className="font-mono text-emerald-400 font-bold">50 Hz Hardware • 2 Hz Stream</span>
        </div>
      </div>

      {/* Sensor Gauge Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {/* Gauge 1: PIR Motion */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="text-xs text-slate-400 font-medium">Motion Presence</div>
          <div className="mt-3 flex items-center justify-between">
            <span className={`text-2xl font-bold ${telemetry.motion_detected ? 'text-emerald-400' : 'text-slate-500'}`}>
              {telemetry.motion_detected ? 'DETECTED' : 'CLEAR'}
            </span>
            <div className={`p-3 rounded-xl ${telemetry.motion_detected ? 'bg-emerald-500/20 text-emerald-400' : 'bg-slate-800 text-slate-600'}`}>
              <UserCheck className="w-6 h-6" />
            </div>
          </div>
          <div className="text-[11px] text-slate-400 mt-3 border-t border-slate-800/80 pt-2">
            HC-SR501 Digital Output: {telemetry.motion_detected ? '3.3V Logic HIGH' : '0.0V Logic LOW'}
          </div>
        </div>

        {/* Gauge 2: Ambient Lux */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="text-xs text-slate-400 font-medium">Ambient Light (ADC)</div>
          <div className="mt-3 flex items-center justify-between">
            <div>
              <span className="text-2xl font-bold font-mono text-white">
                {telemetry.ambient_light}
              </span>
              <span className="text-xs text-slate-400 ml-1">/ 1023</span>
            </div>
            <div className="p-3 rounded-xl bg-amber-500/20 text-amber-400">
              <Sun className="w-6 h-6" />
            </div>
          </div>
          <div className="text-[11px] text-slate-400 mt-3 border-t border-slate-800/80 pt-2">
            Classification Zone: <strong className="text-amber-400 font-semibold">{telemetry.ambient_light < 350 ? 'DARK' : (telemetry.ambient_light > 700 ? 'BRIGHT' : 'MEDIUM')}</strong>
          </div>
        </div>

        {/* Gauge 3: PWM Brightness */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="text-xs text-slate-400 font-medium">PWM Dimming Level</div>
          <div className="mt-3 flex items-center justify-between">
            <div>
              <span className="text-2xl font-bold font-mono text-white">
                {telemetry.light_status ? telemetry.brightness : 0}%
              </span>
              <span className="text-xs text-slate-400 ml-1">Duty</span>
            </div>
            <div className="p-3 rounded-xl bg-indigo-500/20 text-indigo-400">
              <Gauge className="w-6 h-6" />
            </div>
          </div>
          <div className="text-[11px] text-slate-400 mt-3 border-t border-slate-800/80 pt-2">
            PWM Frequency: 5,000 Hz (Flicker-Free Slew)
          </div>
        </div>

        {/* Gauge 4: Shutdown Countdown */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="text-xs text-slate-400 font-medium">Inactivity Countdown</div>
          <div className="mt-3 flex items-center justify-between">
            <div>
              <span className="text-2xl font-bold font-mono text-amber-400">
                {telemetry.timeout_remaining}s
              </span>
              <span className="text-xs text-slate-400 ml-1">remaining</span>
            </div>
            <div className="p-3 rounded-xl bg-amber-500/20 text-amber-400">
              <Activity className="w-6 h-6" />
            </div>
          </div>
          <div className="text-[11px] text-slate-400 mt-3 border-t border-slate-800/80 pt-2">
            Timer resets instantly upon new motion pulse
          </div>
        </div>
      </div>

      {/* Real-Time Dual Oscilloscope Strip Chart */}
      <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-4">
        <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2">
          <div>
            <h3 className="text-base font-bold text-white flex items-center space-x-2">
              <span>Synchronized Sensor vs PWM Strip Chart</span>
              <ArrowUpRight className="w-4 h-4 text-slate-400" />
            </h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Visualizes how ambient darkness triggers automatic PWM LED brightness adaptation.
            </p>
          </div>

          <div className="flex items-center space-x-4 text-xs">
            <span className="flex items-center space-x-1.5 text-amber-400 font-medium">
              <span className="w-3 h-0.5 bg-amber-400 inline-block" />
              <span>Ambient Lux (0-1023)</span>
            </span>
            <span className="flex items-center space-x-1.5 text-indigo-400 font-medium">
              <span className="w-3 h-0.5 bg-indigo-400 inline-block" />
              <span>PWM Duty (0-100%)</span>
            </span>
          </div>
        </div>

        <div className="h-80 w-full pt-4">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={chartData} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1E293B" vertical={false} />
              <XAxis dataKey="time" stroke="#64748B" fontSize={11} tickLine={false} />
              <YAxis yAxisId="left" stroke="#F59E0B" fontSize={11} domain={[0, 1024]} tickLine={false} />
              <YAxis yAxisId="right" orientation="right" stroke="#6366F1" fontSize={11} domain={[0, 100]} tickLine={false} />
              <Tooltip
                contentStyle={{ backgroundColor: '#0B1220', borderColor: '#334155', borderRadius: '0.75rem', fontSize: '12px' }}
                labelStyle={{ color: '#F8FAFC', fontWeight: 'bold' }}
              />
              <Line yAxisId="left" type="monotone" dataKey="lux" stroke="#F59E0B" strokeWidth={2.5} dot={false} isAnimationActive={false} />
              <Line yAxisId="right" type="stepAfter" dataKey="brightness" stroke="#6366F1" strokeWidth={2.5} dot={false} isAnimationActive={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};
