import logging
import threading
import time
from typing import Optional, Callable
from app.config import settings

logger = logging.getLogger(__name__)

SOF_1 = 0xAA
SOF_2 = 0x55
EOF_1 = 0x0D
EOF_2 = 0x0A

OPCODE_TELEMETRY   = 0x01
OPCODE_SET_MODE    = 0x02
OPCODE_SET_BRIGHT  = 0x03
OPCODE_SET_TIMEOUT = 0x04
OPCODE_SET_ESAVE   = 0x05
OPCODE_CMD_ACK     = 0x06

class HardwareCommunicationGateway:
    def __init__(self, port: str = settings.SERIAL_PORT, baud: int = settings.BAUD_RATE):
        self.port = port
        self.baud = baud
        self.serial_handle = None
        self.is_connected = False
        self.running = False
        self.telemetry_callback: Optional[Callable[[dict], None]] = None
        self._thread: Optional[threading.Thread] = None

    def connect(self) -> bool:
        if not settings.ENABLE_HARDWARE_SERIAL:
            logger.info("[COMM] Hardware serial disabled in configuration. Using virtual simulator.")
            return False

        try:
            import serial
            self.serial_handle = serial.Serial(self.port, self.baud, timeout=0.1)
            self.is_connected = True
            self.running = True
            self._thread = threading.Thread(target=self._read_loop, daemon=True)
            self._thread.start()
            logger.info(f"[COMM] Connected to physical FPGA/ESP32 on {self.port} at {self.baud} baud.")
            return True
        except Exception as e:
            logger.warning(f"[COMM] Could not open serial port {self.port}: {e}")
            self.is_connected = False
            return False

    def disconnect(self):
        self.running = False
        if self.serial_handle and self.serial_handle.is_open:
            self.serial_handle.close()
        self.is_connected = False
        logger.info("[COMM] Serial port closed.")

    def send_frame(self, opcode: int, payload: bytes) -> bool:
        if not self.is_connected or not self.serial_handle:
            return False

        try:
            length = len(payload)
            crc = length ^ opcode
            for b in payload:
                crc ^= b

            frame = bytes([SOF_1, SOF_2, length, opcode]) + payload + bytes([crc, EOF_1, EOF_2])
            self.serial_handle.write(frame)
            self.serial_handle.flush()
            logger.debug(f"[COMM] Sent frame opcode 0x{opcode:02X}, len {length}")
            return True
        except Exception as e:
            logger.error(f"[COMM] Failed to transmit frame: {e}")
            return False

    def send_mode(self, mode_str: str) -> bool:
        mode_code = 0 if mode_str == "AUTO" else (1 if mode_str == "MANUAL_ON" else 2)
        return self.send_frame(OPCODE_SET_MODE, bytes([mode_code]))

    def send_brightness(self, brightness_pct: int) -> bool:
        val = max(0, min(100, brightness_pct))
        return self.send_frame(OPCODE_SET_BRIGHT, bytes([val]))

    def send_timeout(self, timeout_sec: int) -> bool:
        val = max(5, min(255, timeout_sec))
        return self.send_frame(OPCODE_SET_TIMEOUT, bytes([val]))

    def send_energy_saving(self, enabled: bool) -> bool:
        val = 1 if enabled else 0
        return self.send_frame(OPCODE_SET_ESAVE, bytes([val]))

    def _read_loop(self):
        state = "SOF1"
        length = 0
        opcode = 0
        payload = bytearray()
        calc_crc = 0

        while self.running and self.serial_handle and self.serial_handle.is_open:
            try:
                b_arr = self.serial_handle.read(1)
                if not b_arr:
                    continue
                b = b_arr[0]

                if state == "SOF1":
                    if b == SOF_1:
                        state = "SOF2"
                elif state == "SOF2":
                    state = "LEN" if b == SOF_2 else "SOF1"
                elif state == "LEN":
                    length = b
                    calc_crc = b
                    state = "OPCODE"
                elif state == "OPCODE":
                    opcode = b
                    calc_crc ^= b
                    payload.clear()
                    state = "CRC" if length == 0 else "PAYLOAD"
                elif state == "PAYLOAD":
                    payload.append(b)
                    calc_crc ^= b
                    if len(payload) >= length:
                        state = "CRC"
                elif state == "CRC":
                    state = "EOF1" if b == calc_crc else "SOF1"
                elif state == "EOF1":
                    state = "EOF2" if b == EOF_1 else "SOF1"
                elif state == "EOF2":
                    if b == EOF_2 and opcode == OPCODE_TELEMETRY and len(payload) == 8:
                        data = {
                            "device_id": settings.DEFAULT_DEVICE_ID,
                            "motion_detected": bool(payload[0]),
                            "occupancy": bool(payload[1]),
                            "ambient_light": (payload[2] << 8) | payload[3],
                            "light_status": bool(payload[4]),
                            "brightness": int(payload[5]),
                            "mode": ["AUTO", "MANUAL_ON", "MANUAL_OFF"][min(2, payload[6])],
                            "timeout_remaining": int(payload[7]),
                            "hardware_connected": True
                        }
                        if self.telemetry_callback:
                            self.telemetry_callback(data)
                    state = "SOF1"
            except Exception as e:
                logger.error(f"[COMM] Read error: {e}")
                time.sleep(0.5)

gateway = HardwareCommunicationGateway()
