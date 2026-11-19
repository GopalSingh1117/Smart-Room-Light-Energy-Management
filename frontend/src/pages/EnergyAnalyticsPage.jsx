import React, { useState, useEffect } from 'react';
import { BarChart3, Zap, TrendingDown, DollarSign, Clock, ShieldAlert } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, Tooltip, ResponsiveContainer, CartesianGrid, Legend } from 'recharts';
import { analyticsApi } from '../services/api';

export const EnergyAnalyticsPage = () => {
  const [analytics, setAnalytics] = useState({
    today_energy_wh: 52.4,
    weekly_energy_wh: 348.6,
    monthly_energy_wh: 1420.0,
    estimated_savings_pct: 78.4,
    daily_history: [],
  });

  useEffect(() => {
    analyticsApi.getEnergy()
      .then((res) => setAnalytics(res.data))
      .catch(console.error);
  }, []);

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-xl font-bold text-white tracking-tight flex items-center space-x-2">
          <BarChart3 className="w-5 h-5 text-indigo-400" />
          <span>Energy Consumption & Cost Savings Analytics</span>
        </h2>
        <p className="text-xs text-slate-400 mt-1">
          Numerical integration of PWM duty cycle and active operating hours calculated at 10W rated fixture load.
        </p>
      </div>

      {/* Engineering Disclaimers Banner */}
      <div className="p-3.5 rounded-xl bg-amber-500/10 border border-amber-500/30 text-xs text-amber-300 flex items-start space-x-2.5">
        <ShieldAlert className="w-4 h-4 shrink-0 mt-0.5" />
        <div>
          <span className="font-bold">Academic Engineering Measurement Note:</span> Values represent integrated electrical energy estimated from recorded PWM duty cycles and the LED fixture power rating (P = P_rated * Duty / 100). Without dedicated shunt/hall-effect power transducer ICs, values are mathematically estimated.
        </div>
      </div>

      {/* Analytics KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* KPI 1 */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="flex justify-between items-center text-slate-400 text-xs font-medium">
            <span>Today's Energy</span>
            <Zap className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-2xl font-bold font-mono text-white mt-2">
            {analytics.today_energy_wh} <span className="text-xs font-normal text-slate-400">Wh</span>
          </div>
          <div className="text-[11px] text-slate-400 mt-2">
            Baseline (Always-On): 480 Wh
          </div>
        </div>

        {/* KPI 2 */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="flex justify-between items-center text-slate-400 text-xs font-medium">
            <span>Weekly Cumulative</span>
            <Clock className="w-4 h-4 text-indigo-400" />
          </div>
          <div className="text-2xl font-bold font-mono text-white mt-2">
            {analytics.weekly_energy_wh} <span className="text-xs font-normal text-slate-400">Wh</span>
          </div>
          <div className="text-[11px] text-slate-400 mt-2">
            ~{(analytics.weekly_energy_wh / 1000).toFixed(2)} kWh Consumed
          </div>
        </div>

        {/* KPI 3 */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="flex justify-between items-center text-slate-400 text-xs font-medium">
            <span>Energy Saved vs Incandescent</span>
            <TrendingDown className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-2xl font-bold font-mono text-emerald-400 mt-2">
            {analytics.estimated_savings_pct}%
          </div>
          <div className="text-[11px] text-slate-400 mt-2">
            Occupancy shut-off & dimming
          </div>
        </div>

        {/* KPI 4 */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-xl p-5">
          <div className="flex justify-between items-center text-slate-400 text-xs font-medium">
            <span>Estimated Monthly Cost Saved</span>
            <DollarSign className="w-4 h-4 text-amber-400" />
          </div>
          <div className="text-2xl font-bold font-mono text-white mt-2">
            ₹{((480 * 30 - analytics.monthly_energy_wh) / 1000 * 8.5).toFixed(1)}
          </div>
          <div className="text-[11px] text-slate-400 mt-2">
            @ ₹8.5 / kWh commercial rate
          </div>
        </div>
      </div>

      {/* 7-Day Comparison Bar Chart */}
      <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-4">
        <div className="flex flex-col sm:flex-row justify-between sm:items-center gap-2">
          <div>
            <h3 className="text-base font-bold text-white">Daily Energy Consumption vs Energy Saved (Wh)</h3>
            <p className="text-xs text-slate-400 mt-0.5">
              Comparison between actual energy consumed by the FPGA smart system and energy saved relative to legacy lighting.
            </p>
          </div>
        </div>

        <div className="h-80 w-full pt-4">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={analytics.daily_history} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#1E293B" vertical={false} />
              <XAxis dataKey="label" stroke="#64748B" fontSize={11} tickLine={false} />
              <YAxis stroke="#64748B" fontSize={11} tickLine={false} />
              <Tooltip
                contentStyle={{ backgroundColor: '#0B1220', borderColor: '#334155', borderRadius: '0.75rem', fontSize: '12px' }}
                labelStyle={{ color: '#F8FAFC', fontWeight: 'bold' }}
              />
              <Legend wrapperStyle={{ fontSize: '12px', paddingTop: '10px' }} />
              <Bar dataKey="energy_wh" name="Actual Consumed (Wh)" fill="#6366F1" radius={[4, 4, 0, 0]} />
              <Bar dataKey="energy_saved_wh" name="Energy Saved (Wh)" fill="#22C55E" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};
