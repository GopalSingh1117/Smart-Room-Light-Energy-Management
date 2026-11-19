import React, { useState, useEffect } from 'react';
import { HardDrive, Cpu, Wifi, CheckCircle2, AlertTriangle, RefreshCw, Terminal, Activity } from 'lucide-react';
import { useWebSocket } from '../context/WebSocketContext';
import { devicesApi } from '../services/api';

export const DeviceManagementPage = () => {
  const { telemetry, connected } = useWebSocket();
  const [devices, setDevices] = useState([]);
  const [loading, setLoading] = useState(false);

  const fetchDevices = () => {
    setLoading(true);
    devicesApi.getDevices()
      .then((res) => setDevices(res.data))
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchDevices();
  }, []);

  return (
    <div className="space-y-6 max-w-5xl">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center space-x-2">
            <HardDrive className="w-5 h-5 text-indigo-400" />
            <span>Hardware Device & Gateway Topology</span>
          </h2>
          <p className="text-xs text-slate-400 mt-1">
            Real-time diagnostics for the physical FPGA core, ESP32 Wi-Fi bridge, and UART bus communications.
          </p>
        </div>

        <button
          onClick={fetchDevices}
          disabled={loading}
          className="px-3.5 py-1.5 rounded-lg bg-[#172033] hover:bg-slate-700 text-xs font-semibold text-slate-200 border border-slate-700 flex items-center space-x-1.5 transition-all"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin' : ''}`} />
          <span>Refresh Hardware Status</span>
        </button>
      </div>

      {/* Hardware Architecture Status Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Unit 1: Real-Time FPGA Controller */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-4">
          <div className="flex justify-between items-start">
            <div className="flex items-center space-x-3">
              <div className="p-2.5 rounded-xl bg-indigo-600/20 text-indigo-400 border border-indigo-500/30">
                <Cpu className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white">FPGA Deterministic Core</h3>
                <span className="text-[11px] text-slate-400">Xilinx Artix-7 (Digilent Basys 3)</span>
              </div>
            </div>
            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
              SYNTHESIZED
            </span>
          </div>

          <div className="bg-[#0B1220] rounded-xl p-3.5 border border-slate-800 space-y-2 text-xs">
            <div className="flex justify-between">
              <span className="text-slate-400">Master Clock:</span>
              <span className="font-mono text-slate-200">100.00 MHz Oscillator</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">FSM State Engine:</span>
              <span className="font-mono text-indigo-400 uppercase font-semibold">{telemetry.fsm_state || 'ACTIVE'}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">PWM Switching:</span>
              <span className="font-mono text-slate-200">5.0 kHz (8-bit resolution)</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Sensor Interfaces:</span>
              <span className="font-mono text-slate-200">PIR (GPIO) + MCP3008 (SPI 1MHz)</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Display Bus:</span>
              <span className="font-mono text-slate-200">4-Digit 7-Segment (1 kHz Mux)</span>
            </div>
          </div>
        </div>

        {/* Unit 2: ESP32 IoT Communications Gateway */}
        <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-4">
          <div className="flex justify-between items-start">
            <div className="flex items-center space-x-3">
              <div className="p-2.5 rounded-xl bg-emerald-600/20 text-emerald-400 border border-emerald-500/30">
                <Wifi className="w-6 h-6" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white">ESP32 IoT Gateway</h3>
                <span className="text-[11px] text-slate-400">ESP32-WROOM-32D (802.11 b/g/n)</span>
              </div>
            </div>
            <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold ${
              connected ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30' : 'bg-rose-500/20 text-rose-400 border border-rose-500/30'
            }`}>
              {connected ? 'ONLINE' : 'OFFLINE'}
            </span>
          </div>

          <div className="bg-[#0B1220] rounded-xl p-3.5 border border-slate-800 space-y-2 text-xs">
            <div className="flex justify-between">
              <span className="text-slate-400">UART Serial Port:</span>
              <span className="font-mono text-slate-200">UART2 (GPIO 16/17 @ 115,200 baud)</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Protocol Framing:</span>
              <span className="font-mono text-slate-200">SOF 0xAA 0x55 • XOR Checksum</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">WebSocket Endpoint:</span>
              <span className="font-mono text-slate-200">/ws/dashboard</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">REST Ingestion:</span>
              <span className="font-mono text-slate-200">/api/devices/telemetry</span>
            </div>
            <div className="flex justify-between">
              <span className="text-slate-400">Hardware Link Mode:</span>
              <span className="font-mono text-amber-400">
                {telemetry.hardware_connected ? 'Physical COM Port Live' : 'High-Fidelity Virtual Simulator'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Raw Framed Packet Inspector */}
      <div className="bg-[#172033] border border-[#1E293B] rounded-2xl p-6 space-y-3">
        <div className="flex items-center space-x-2 text-white font-bold text-sm">
          <Terminal className="w-4 h-4 text-emerald-400" />
          <span>Raw UART Frame Inspector (FPGA &lt;--&gt; ESP32 Wire Protocol)</span>
        </div>
        <p className="text-xs text-slate-400">
          Sample 14-byte framed telemetry payload currently generated by the hardware state machine:
        </p>

        <div className="bg-[#0B1220] p-4 rounded-xl border border-slate-800 font-mono text-xs text-slate-300 overflow-x-auto space-y-2">
          <div className="text-indigo-400 font-semibold">
            [0xAA, 0x55, 0x08, 0x01, {telemetry.motion_detected ? '0x01' : '0x00'}, {telemetry.occupancy ? '0x01' : '0x00'}, 0x{(telemetry.ambient_light >> 8).toString(16).padStart(2,'0')}, 0x{(telemetry.ambient_light & 0xFF).toString(16).padStart(2,'0')}, {telemetry.light_status ? '0x01' : '0x00'}, 0x{telemetry.brightness.toString(16).padStart(2,'0')}, 0x{telemetry.mode === 'AUTO' ? '00' : (telemetry.mode === 'MANUAL_ON' ? '01' : '02')}, 0x{telemetry.timeout_remaining.toString(16).padStart(2,'0')}, CRC, 0x0D, 0x0A]
          </div>
          <div className="text-[11px] text-slate-500">
            Byte Layout: [SOF1, SOF2, LEN=8, OPCODE=0x01, MOTION, OCCUPANCY, LUX_MSB, LUX_LSB, LIGHT_ST, BRIGHTNESS, MODE, REMAINING_SEC, LRC_CHECKSUM, \r, \n]
          </div>
        </div>
      </div>
    </div>
  );
};
