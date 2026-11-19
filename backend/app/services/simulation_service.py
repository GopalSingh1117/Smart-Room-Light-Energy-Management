import asyncio
import logging
import random
from datetime import datetime, timezone
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

class HardwareSimulator:
    """
    Virtual Hardware Simulation Engine for FPGA & ESP32.
    Executes the exact same 8-state FSM as the Verilog RTL core.
    Allows complete testing of web dashboards, controls, and analytics
    without requiring physical hardware connected to the computer.
    """
    def __init__(self, device_id: str = "ROOM_001"):
        self.device_id = device_id
        self.is_running = False

        # Virtual Sensors & Environment
        self.motion_detected = False
        self.occupancy = False
        self.ambient_light = 240 # 0-1023 (Dark room default)
        
        # Virtual Controller State
        self.mode = "AUTO" # AUTO, MANUAL_ON, MANUAL_OFF
        self.manual_brightness_setpoint = 100
        self.current_brightness = 0
        self.light_status = False
        self.timeout_remaining = 30
        self.configured_timeout = 30
        self.energy_saving = True

        # Thresholds
        self.thresh_dark = 350
        self.thresh_bright = 700

        # FSM State tracker (mirrors Verilog)
        # IDLE(0), DAYLIGHT(1), OCCUPIED(2), LIGHT_ON(3), DIMMED(4), TIMEOUT(5), MANUAL_ON(6), MANUAL_OFF(7)
        self.fsm_state = "IDLE"

    def inject_motion(self, active: bool = True):
        self.motion_detected = active
        if active:
            self.occupancy = True
            self.timeout_remaining = self.configured_timeout

    def set_ambient_light(self, lux: int):
        self.ambient_light = max(0, min(1023, lux))

    def set_mode(self, mode: str):
        if mode in ["AUTO", "MANUAL_ON", "MANUAL_OFF"]:
            self.mode = mode
            if mode == "MANUAL_ON":
                self.occupancy = True

    def set_brightness(self, brightness: int):
        self.manual_brightness_setpoint = max(0, min(100, brightness))

    def set_timeout(self, seconds: int):
        self.configured_timeout = max(5, min(1800, seconds))
        if self.timeout_remaining > self.configured_timeout:
            self.timeout_remaining = self.configured_timeout

    def set_energy_saving(self, enabled: bool):
        self.energy_saving = enabled

    def step_fsm(self):
        """Advances the state machine by 1 second tick"""
        # 1. Manual Overrides take precedence
        if self.mode == "MANUAL_ON":
            self.fsm_state = "MANUAL_ON"
            self.current_brightness = self.manual_brightness_setpoint
            self.light_status = True
            return

        if self.mode == "MANUAL_OFF":
            self.fsm_state = "MANUAL_OFF"
            self.current_brightness = 0
            self.light_status = False
            return

        # 2. Automatic Mode Logic
        is_bright = self.ambient_light >= self.thresh_bright
        is_medium = self.thresh_dark <= self.ambient_light < self.thresh_bright
        is_dark   = self.ambient_light < self.thresh_dark

        if self.fsm_state == "IDLE":
            self.current_brightness = 0
            self.light_status = False
            if self.motion_detected or self.occupancy:
                if is_bright:
                    self.fsm_state = "DAYLIGHT"
                else:
                    self.fsm_state = "OCCUPIED"

        elif self.fsm_state == "DAYLIGHT":
            self.current_brightness = 0
            self.light_status = False
            if is_bright:
                if self.timeout_remaining > 0 and not self.motion_detected:
                    self.timeout_remaining -= 1
                elif self.timeout_remaining <= 0:
                    self.occupancy = False
                    self.fsm_state = "IDLE"
            else:
                # Sunlight dropped while occupied
                if self.occupancy:
                    self.fsm_state = "OCCUPIED"

        elif self.fsm_state == "OCCUPIED":
            if is_bright:
                self.fsm_state = "DAYLIGHT"
            elif is_dark:
                self.fsm_state = "LIGHT_ON"
                self.current_brightness = 100
                self.light_status = True
            else:
                self.fsm_state = "DIMMED"
                self.current_brightness = 30 if self.energy_saving else 60
                self.light_status = True

        elif self.fsm_state in ["LIGHT_ON", "DIMMED"]:
            self.light_status = True
            if is_bright and self.energy_saving:
                self.fsm_state = "DAYLIGHT"
                self.current_brightness = 0
                self.light_status = False
            elif is_dark:
                self.current_brightness = 100
            elif is_medium:
                self.current_brightness = 30 if self.energy_saving else 60

            # Countdown logic
            if not self.motion_detected:
                if self.timeout_remaining > 1:
                    self.timeout_remaining -= 1
                    # Inactivity warning: pre-dim light
                    if self.timeout_remaining <= 5:
                        self.fsm_state = "DIMMED"
                        self.current_brightness = 30
                else:
                    self.timeout_remaining = 0
                    self.occupancy = False
                    self.fsm_state = "TIMEOUT"
            else:
                # Continuous motion maintains timeout
                self.timeout_remaining = self.configured_timeout

        elif self.fsm_state == "TIMEOUT":
            self.current_brightness = 0
            self.light_status = False
            self.occupancy = False
            self.fsm_state = "IDLE"

    def get_telemetry(self) -> Dict[str, Any]:
        rated_power = 10.0 # Watts
        duty_fraction = (self.current_brightness / 100.0) if self.light_status else 0.0
        watts = round(duty_fraction * rated_power, 2)

        return {
            "device_id": self.device_id,
            "timestamp": datetime.now(timezone.utc).timestamp(),
            "motion_detected": self.motion_detected,
            "occupancy": self.occupancy,
            "ambient_light": self.ambient_light,
            "light_status": self.light_status,
            "brightness": self.current_brightness,
            "mode": self.mode,
            "timeout_remaining": self.timeout_remaining,
            "estimated_power_watts": watts,
            "fsm_state": self.fsm_state,
            "hardware_connected": False # Explicitly marks simulated data
        }

simulator = HardwareSimulator()
