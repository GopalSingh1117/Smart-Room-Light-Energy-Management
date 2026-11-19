import React, { createContext, useContext, useState, useEffect, useRef } from 'react';

const WebSocketContext = createContext(null);

export const WebSocketProvider = ({ children }) => {
  const [telemetry, setTelemetry] = useState({
    device_id: 'ROOM_001',
    motion_detected: false,
    occupancy: false,
    ambient_light: 350,
    light_status: false,
    brightness: 0,
    mode: 'AUTO',
    timeout_remaining: 30,
    estimated_power_watts: 0.0,
    fsm_state: 'IDLE',
    hardware_connected: false,
  });

  const [connected, setConnected] = useState(false);
  const [recentEvents, setRecentEvents] = useState([]);
  const wsRef = useRef(null);

  const addEvent = (desc, type = 'info') => {
    setRecentEvents((prev) => [
      { id: Date.now(), time: new Date().toLocaleTimeString(), text: desc, type },
      ...prev.slice(0, 24),
    ]);
  };

  useEffect(() => {
    let reconnectTimeout = null;

    const connectWebSocket = () => {
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      // In dev mode on port 5173, connect directly to FastAPI port 8000 to avoid proxy drops
      const wsHost = window.location.port === '5173'
        ? `${window.location.hostname}:8000`
        : window.location.host;
      const wsUrl = `${protocol}//${wsHost}/ws/dashboard`;

      const ws = new WebSocket(wsUrl);
      wsRef.current = ws;

      ws.onopen = () => {
        setConnected(true);
        addEvent('Connected to real-time telemetry stream', 'success');
      };

      ws.onmessage = (event) => {
        try {
          const payload = JSON.parse(event.data);
          if (payload.data) {
            setTelemetry((prev) => {
              const next = { ...prev, ...payload.data };
              // Detect state transitions to add activity logs
              if (prev.light_status !== next.light_status) {
                addEvent(`Lights switched ${next.light_status ? 'ON' : 'OFF'} (${next.brightness}%)`, next.light_status ? 'success' : 'warning');
              }
              if (prev.mode !== next.mode) {
                addEvent(`Operating mode changed to ${next.mode}`, 'info');
              }
              if (!prev.motion_detected && next.motion_detected) {
                addEvent('Motion detected in room (PIR Trigger)', 'info');
              }
              return next;
            });
          }
        } catch (err) {
          console.error('WS parse error:', err);
        }
      };

      ws.onclose = () => {
        setConnected(false);
        reconnectTimeout = setTimeout(connectWebSocket, 2500);
      };

      ws.onerror = (err) => {
        console.warn('WS error:', err);
        ws.close();
      };
    };

    connectWebSocket();

    return () => {
      if (reconnectTimeout) clearTimeout(reconnectTimeout);
      if (wsRef.current) wsRef.current.close();
    };
  }, []);

  const sendWsCommand = (cmdObj) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      wsRef.current.send(JSON.stringify(cmdObj));
    }
  };

  return (
    <WebSocketContext.Provider value={{ telemetry, setTelemetry, connected, sendWsCommand, recentEvents, addEvent }}>
      {children}
    </WebSocketContext.Provider>
  );
};

export const useWebSocket = () => useContext(WebSocketContext);
