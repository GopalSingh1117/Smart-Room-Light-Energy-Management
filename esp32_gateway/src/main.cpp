// ============================================================================
// File: main.cpp
// Project: ESP32 IoT Gateway for FPGA Smart Room Lighting System
// Framework: Arduino / PlatformIO
// ============================================================================

#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>

#include "config.h"
#include "uart_bridge.h"

// Hardware Serial 2 for FPGA connection
HardwareSerial FpgaSerial(FPGA_UART_NUM);
FpgaUartBridge fpgaBridge(&FpgaSerial);

// WebSocket client
WebSocketsClient webSocket;

unsigned long lastTelemetryMillis = 0;
unsigned long lastHeartbeatMillis = 0;
bool wsConnected = false;

// -----------------------------------------------------------------------------
// WebSocket Event Handler
// -----------------------------------------------------------------------------
void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_DISCONNECTED:
            Serial.println("[WS] Disconnected from FastAPI Backend!");
            wsConnected = false;
            digitalWrite(PIN_STATUS_LED, LOW);
            break;

        case WStype_CONNECTED:
            Serial.printf("[WS] Connected to: %s%s\n", BACKEND_HOST, WS_PATH);
            wsConnected = true;
            digitalWrite(PIN_STATUS_LED, HIGH);
            // Send initial registration packet
            webSocket.sendTXT("{\"type\":\"gateway_register\",\"device_id\":\"ROOM_001\"}");
            break;

        case WStype_TEXT: {
            Serial.printf("[WS] Received Control Command: %s\n", payload);
            StaticJsonDocument<256> doc;
            DeserializationError err = deserializeJson(doc, payload);
            if (err) {
                Serial.printf("[WS] JSON parse failed: %s\n", err.c_str());
                return;
            }

            const char* cmd = doc["command"];
            if (!cmd) return;

            if (strcmp(cmd, "SET_MODE") == 0) {
                const char* mode = doc["mode"];
                if (strcmp(mode, "AUTO") == 0) fpgaBridge.setMode(0);
                else if (strcmp(mode, "MANUAL_ON") == 0) fpgaBridge.setMode(1);
                else if (strcmp(mode, "MANUAL_OFF") == 0) fpgaBridge.setMode(2);
                Serial.printf("[GW] Forwarded SET_MODE (%s) to FPGA.\n", mode);
            }
            else if (strcmp(cmd, "SET_BRIGHTNESS") == 0) {
                uint8_t brightness = doc["brightness"];
                fpgaBridge.setBrightness(brightness);
                Serial.printf("[GW] Forwarded SET_BRIGHTNESS (%d%%) to FPGA.\n", brightness);
            }
            else if (strcmp(cmd, "SET_TIMEOUT") == 0) {
                uint8_t timeoutSec = doc["timeout_seconds"];
                fpgaBridge.setTimeout(timeoutSec);
                Serial.printf("[GW] Forwarded SET_TIMEOUT (%ds) to FPGA.\n", timeoutSec);
            }
            else if (strcmp(cmd, "SET_ENERGY_SAVING") == 0) {
                bool esave = doc["enabled"];
                fpgaBridge.setEnergySaving(esave);
                Serial.printf("[GW] Forwarded SET_ENERGY_SAVING (%d) to FPGA.\n", esave);
            }
            break;
        }

        default:
            break;
    }
}

// -----------------------------------------------------------------------------
// Wi-Fi Setup and Watchdog
// -----------------------------------------------------------------------------
void setupWiFi() {
    Serial.printf("\n[WiFi] Connecting to %s ...\n", WIFI_SSID);
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 20) {
        delay(500);
        Serial.print(".");
        attempts++;
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("\n[WiFi] Connected! IP Address: %s\n", WiFi.localIP().toString().c_str());
    } else {
        Serial.println("\n[WiFi] Warning: Could not connect to AP. Running offline gateway mode.");
    }
}

// -----------------------------------------------------------------------------
// Setup
// -----------------------------------------------------------------------------
void setup() {
    // USB Debug Console
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n=======================================================");
    Serial.println("  ESP32 IoT Gateway for FPGA Room Light System Initialized");
    Serial.println("=======================================================");

    pinMode(PIN_STATUS_LED, OUTPUT);
    digitalWrite(PIN_STATUS_LED, LOW);

    // Initialize FPGA Hardware UART
    fpgaBridge.begin(FPGA_UART_BAUD, PIN_FPGA_RX, PIN_FPGA_TX);
    Serial.printf("[UART] FPGA Bridge listening on RX2: GPIO%d, TX2: GPIO%d at %d bps\n",
                  PIN_FPGA_RX, PIN_FPGA_TX, FPGA_UART_BAUD);

    setupWiFi();

    // Initialize WebSocket
    if (WiFi.status() == WL_CONNECTED) {
        webSocket.begin(BACKEND_HOST, BACKEND_PORT, WS_PATH);
        webSocket.onEvent(webSocketEvent);
        webSocket.setReconnectInterval(RECONNECT_INTERVAL_MS);
    }
}

// -----------------------------------------------------------------------------
// Main Loop
// -----------------------------------------------------------------------------
void loop() {
    if (WiFi.status() == WL_CONNECTED) {
        webSocket.loop();
    }

    // Process incoming FPGA packets
    bool newTelemetry = fpgaBridge.update();

    if (newTelemetry) {
        String jsonPayload = fpgaBridge.getTelemetryJson("ROOM_001");
        Serial.printf("[FPGA -> GW] Telemetry: %s\n", jsonPayload.c_str());

        // Forward to WebSocket if connected
        if (wsConnected) {
            webSocket.sendTXT(jsonPayload);
        }
    }

    // Periodic Heartbeat & Wi-Fi Reconnect check
    unsigned long now = millis();
    if (now - lastHeartbeatMillis >= HEARTBEAT_INTERVAL_MS) {
        lastHeartbeatMillis = now;
        if (WiFi.status() != WL_CONNECTED) {
            Serial.println("[WiFi] Lost connection, attempting reconnect...");
            WiFi.reconnect();
        }
    }
}
