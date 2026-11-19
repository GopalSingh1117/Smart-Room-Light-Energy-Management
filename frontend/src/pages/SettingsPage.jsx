import React, { useState, useEffect } from 'react';
import { Settings, Save, CheckCircle2, AlertCircle, Sun, Moon, Clock, Zap, ShieldCheck } from 'lucide-react';
import { settingsApi } from '../services/api';

export const SettingsPage = () => {
  const [formData, setFormData] = useState({
    room_name: 'Smart Engineering Lab',
    light_threshold_dark: 350,
    light_threshold_bright: 700,
    default_brightness: 100,
    shutdown_timeout: 30,
    energy_saving_enabled: true,
    led_rated_power_watts: 10.0,
  });

  const [saving, setSaving] = useState(false);
  const [toast, setToast] = useState(null);

  useEffect(() => {
    settingsApi.getSettings()
      .then((res) => setFormData(res.data))
      .catch(console.error);
  }, []);

  const handleChange = (field, val) => {
    setFormData((prev) => ({ ...prev, [field]: val }));
  };

  const handleSave = async (e) => {
    e.preventDefault();
    setSaving(true);
    setToast(null);

    // Validation
    if (formData.light_threshold_dark >= formData.light_threshold_bright) {
      setToast({ type: 'error', msg: 'Validation Error: Dark threshold must be strictly less than Bright threshold.' });
      setSaving(false);
      return;
    }

    try {
      await settingsApi.updateSettings(formData);
      setToast({ type: 'success', msg: 'System settings successfully updated and synchronized with FPGA controller.' });
    } catch (err) {
      setToast({ type: 'error', msg: 'Failed to update settings on the server.' });
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 max-w-3xl">
      <div>
        <h2 className="text-xl font-bold text-white tracking-tight flex items-center space-x-2">
          <Settings className="w-5 h-5 text-indigo-400" />
          <span>System Parameters & Threshold Calibration</span>
        </h2>
        <p className="text-xs text-slate-400 mt-1">
          Configure sensor sensitivity, ADC thresholds, shutdown timers, and electrical load ratings.
        </p>
      </div>

      {toast && (
        <div className={`p-4 rounded-xl border flex items-center justify-between text-xs font-medium ${
          toast.type === 'success'
            ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
            : 'bg-rose-500/10 border-rose-500/30 text-rose-300'
        }`}>
          <div className="flex items-center space-x-2">
            {toast.type === 'success' ? <CheckCircle2 className="w-4 h-4 shrink-0" /> : <AlertCircle className="w-4 h-4 shrink-0" />}
            <span>{toast.msg}</span>
          </div>
          <button onClick={() => setToast(null)} className="text-slate-400 hover:text-white">✕</button>
        </div>
      )}

      <form onSubmit={handleSave} className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-6">
        {/* Section 1: Room Identification */}
        <div className="space-y-4">
          <h3 className="text-xs font-bold text-white uppercase tracking-wider">
            1. Room Location & Identification
          </h3>
          <div>
            <label className="block text-xs font-medium text-slate-300 mb-1">Room / Lab Area Name</label>
            <input
              type="text"
              value={formData.room_name}
              onChange={(e) => handleChange('room_name', e.target.value)}
              className="w-full bg-[#0B1220] border border-slate-700 rounded-xl px-4 py-2.5 text-xs text-white focus:outline-none focus:border-indigo-500"
              required
            />
          </div>
        </div>

        {/* Section 2: Sensor Thresholds */}
        <div className="space-y-4 pt-4 border-t border-slate-800">
          <h3 className="text-xs font-bold text-white uppercase tracking-wider">
            2. Ambient Light Threshold Calibration (10-bit ADC: 0 to 1023)
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1 flex items-center space-x-1.5">
                <Moon className="w-3.5 h-3.5 text-indigo-400" />
                <span>Dark Environment Threshold</span>
              </label>
              <input
                type="number"
                min="50"
                max="600"
                value={formData.light_threshold_dark}
                onChange={(e) => handleChange('light_threshold_dark', parseInt(e.target.value))}
                className="w-full bg-[#0B1220] border border-slate-700 rounded-xl px-4 py-2 text-xs font-mono text-white focus:outline-none focus:border-indigo-500"
                required
              />
              <span className="text-[10px] text-slate-500 mt-1 block">Readings below this trigger 100% full illumination.</span>
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1 flex items-center space-x-1.5">
                <Sun className="w-3.5 h-3.5 text-amber-400" />
                <span>Bright Daylight Threshold</span>
              </label>
              <input
                type="number"
                min="500"
                max="1023"
                value={formData.light_threshold_bright}
                onChange={(e) => handleChange('light_threshold_bright', parseInt(e.target.value))}
                className="w-full bg-[#0B1220] border border-slate-700 rounded-xl px-4 py-2 text-xs font-mono text-white focus:outline-none focus:border-indigo-500"
                required
              />
              <span className="text-[10px] text-slate-500 mt-1 block">Readings above this suppress lighting to 0% (Daylight Mode).</span>
            </div>
          </div>
        </div>

        {/* Section 3: Inactivity & Electrical Ratings */}
        <div className="space-y-4 pt-4 border-t border-slate-800">
          <h3 className="text-xs font-bold text-white uppercase tracking-wider">
            3. Timing & Fixture Power Rating
          </h3>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1 flex items-center space-x-1.5">
                <Clock className="w-3.5 h-3.5 text-amber-400" />
                <span>Default Inactivity Timeout (Seconds)</span>
              </label>
              <input
                type="number"
                min="5"
                max="1800"
                value={formData.shutdown_timeout}
                onChange={(e) => handleChange('shutdown_timeout', parseInt(e.target.value))}
                className="w-full bg-[#0B1220] border border-slate-700 rounded-xl px-4 py-2 text-xs font-mono text-white focus:outline-none focus:border-indigo-500"
                required
              />
              <span className="text-[10px] text-slate-500 mt-1 block">Duration of inactivity before lights turn off.</span>
            </div>

            <div>
              <label className="block text-xs font-medium text-slate-300 mb-1 flex items-center space-x-1.5">
                <Zap className="w-3.5 h-3.5 text-emerald-400" />
                <span>LED Fixture Rated Power (Watts)</span>
              </label>
              <input
                type="number"
                step="0.5"
                min="1"
                max="500"
                value={formData.led_rated_power_watts}
                onChange={(e) => handleChange('led_rated_power_watts', parseFloat(e.target.value))}
                className="w-full bg-[#0B1220] border border-slate-700 rounded-xl px-4 py-2 text-xs font-mono text-white focus:outline-none focus:border-indigo-500"
                required
              />
              <span className="text-[10px] text-slate-500 mt-1 block">Used for accurate numerical energy integration.</span>
            </div>
          </div>
        </div>

        {/* Save Button */}
        <div className="pt-4 border-t border-slate-800 flex justify-end">
          <button
            type="submit"
            disabled={saving}
            className="px-6 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold transition-all shadow-lg shadow-indigo-600/30 flex items-center space-x-2"
          >
            <Save className="w-4 h-4" />
            <span>{saving ? 'Saving...' : 'Save Parameters'}</span>
          </button>
        </div>
      </form>
    </div>
  );
};
