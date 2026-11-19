#ifndef CONFIG_H
#define CONFIG_H

// ============================================================================
// ESP32 IoT Gateway Configuration
// ============================================================================

// Wi-Fi Credentials
#define WIFI_SSID           "SmartRoom_AP"
#define WIFI_PASSWORD       "RoomLighting123"

// Backend Host & Ports (FastAPI server address)
#define BACKEND_HOST        "192.168.1.100" // Change to host machine LAN IP
#define BACKEND_PORT        8000
#define WS_PATH             "/ws/dashboard"
#define REST_TELEMETRY_PATH "/api/devices/telemetry"

// Hardware UART Pin Allocation (UART2 connected to FPGA Pmod JB)
#define FPGA_UART_NUM       2
#define FPGA_UART_BAUD      115200
#define PIN_FPGA_RX         16 // ESP32 GPIO 16 (RX2) <- FPGA TX (JB1 / A14)
#define PIN_FPGA_TX         17 // ESP32 GPIO 17 (TX2) -> FPGA RX (JB2 / A16)

// Gateway Diagnostic LED
#define PIN_STATUS_LED      2  // Onboard blue LED on ESP32 DevKit

// Timing Constants (milliseconds)
#define TELEMETRY_INTERVAL_MS 500
#define HEARTBEAT_INTERVAL_MS 5000
#define RECONNECT_INTERVAL_MS 3000

#endif // CONFIG_H
