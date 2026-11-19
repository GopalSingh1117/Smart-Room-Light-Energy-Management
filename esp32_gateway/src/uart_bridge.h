#ifndef UART_BRIDGE_H
#define UART_BRIDGE_H

#include <Arduino.h>
#include <ArduinoJson.h>

// Binary Protocol Constants
#define SOF_BYTE_1   0xAA
#define SOF_BYTE_2   0x55
#define EOF_BYTE_1   0x0D // '\r'
#define EOF_BYTE_2   0x0A // '\n'

#define OPCODE_TELEMETRY   0x01
#define OPCODE_SET_MODE    0x02
#define OPCODE_SET_BRIGHT  0x03
#define OPCODE_SET_TIMEOUT 0x04
#define OPCODE_SET_ESAVE   0x05
#define OPCODE_CMD_ACK     0x06

struct HardwareTelemetry {
    bool motion_detected;
    bool occupancy;
    uint16_t ambient_light;
    bool light_status;
    uint8_t brightness;
    String mode;
    uint8_t timeout_remaining;
    bool valid;
};

class FpgaUartBridge {
private:
    HardwareSerial* serialPort;
    enum ParserState {
        STATE_WAIT_SOF1,
        STATE_WAIT_SOF2,
        STATE_READ_LEN,
        STATE_READ_OPCODE,
        STATE_READ_PAYLOAD,
        STATE_READ_CRC,
        STATE_WAIT_EOF1,
        STATE_WAIT_EOF2
    };

    ParserState state;
    uint8_t expectedLen;
    uint8_t opcode;
    uint8_t payload[16];
    uint8_t payloadIdx;
    uint8_t calculatedCrc;

public:
    HardwareTelemetry latestTelemetry;

    FpgaUartBridge(HardwareSerial* port) : serialPort(port), state(STATE_WAIT_SOF1), payloadIdx(0) {
        latestTelemetry.valid = false;
    }

    void begin(unsigned long baud, int rxPin, int txPin) {
        serialPort->begin(baud, SERIAL_8N1, rxPin, txPin);
    }

    // Process incoming serial bytes from FPGA
    bool update() {
        bool newPacketReceived = false;

        while (serialPort->available() > 0) {
            uint8_t b = serialPort->read();

            switch (state) {
                case STATE_WAIT_SOF1:
                    if (b == SOF_BYTE_1) state = STATE_WAIT_SOF2;
                    break;

                case STATE_WAIT_SOF2:
                    if (b == SOF_BYTE_2) state = STATE_READ_LEN;
                    else state = STATE_WAIT_SOF1;
                    break;

                case STATE_READ_LEN:
                    expectedLen = b;
                    calculatedCrc = b;
                    state = STATE_READ_OPCODE;
                    break;

                case STATE_READ_OPCODE:
                    opcode = b;
                    calculatedCrc ^= b;
                    payloadIdx = 0;
                    if (expectedLen == 0) state = STATE_READ_CRC;
                    else state = STATE_READ_PAYLOAD;
                    break;

                case STATE_READ_PAYLOAD:
                    payload[payloadIdx++] = b;
                    calculatedCrc ^= b;
                    if (payloadIdx >= expectedLen) {
                        state = STATE_READ_CRC;
                    }
                    break;

                case STATE_READ_CRC:
                    if (b == calculatedCrc) {
                        state = STATE_WAIT_EOF1;
                    } else {
                        state = STATE_WAIT_SOF1; // Checksum error, discard
                    }
                    break;

                case STATE_WAIT_EOF1:
                    if (b == EOF_BYTE_1) state = STATE_WAIT_EOF2;
                    else state = STATE_WAIT_SOF1;
                    break;

                case STATE_WAIT_EOF2:
                    if (b == EOF_BYTE_2) {
                        // Frame complete!
                        if (opcode == OPCODE_TELEMETRY && expectedLen == 8) {
                            latestTelemetry.motion_detected = (payload[0] != 0);
                            latestTelemetry.occupancy       = (payload[1] != 0);
                            latestTelemetry.ambient_light   = ((uint16_t)payload[2] << 8) | payload[3];
                            latestTelemetry.light_status    = (payload[4] != 0);
                            latestTelemetry.brightness      = payload[5];

                            switch (payload[6]) {
                                case 0: latestTelemetry.mode = "AUTO"; break;
                                case 1: latestTelemetry.mode = "MANUAL_ON"; break;
                                case 2: latestTelemetry.mode = "MANUAL_OFF"; break;
                                default: latestTelemetry.mode = "AUTO"; break;
                            }

                            latestTelemetry.timeout_remaining = payload[7];
                            latestTelemetry.valid = true;
                            newPacketReceived = true;
                        }
                    }
                    state = STATE_WAIT_SOF1;
                    break;
            }
        }
        return newPacketReceived;
    }

    // Transmit binary command frame to FPGA
    void sendCommand(uint8_t cmdOpcode, const uint8_t* cmdPayload, uint8_t len) {
        serialPort->write(SOF_BYTE_1);
        serialPort->write(SOF_BYTE_2);
        serialPort->write(len);
        serialPort->write(cmdOpcode);

        uint8_t crc = len ^ cmdOpcode;
        for (uint8_t i = 0; i < len; i++) {
            serialPort->write(cmdPayload[i]);
            crc ^= cmdPayload[i];
        }

        serialPort->write(crc);
        serialPort->write(EOF_BYTE_1);
        serialPort->write(EOF_BYTE_2);
    }

    void setMode(uint8_t modeCode) {
        sendCommand(OPCODE_SET_MODE, &modeCode, 1);
    }

    void setBrightness(uint8_t dutyPct) {
        sendCommand(OPCODE_SET_BRIGHT, &dutyPct, 1);
    }

    void setTimeout(uint8_t timeoutSec) {
        sendCommand(OPCODE_SET_TIMEOUT, &timeoutSec, 1);
    }

    void setEnergySaving(bool enable) {
        uint8_t val = enable ? 1 : 0;
        sendCommand(OPCODE_SET_ESAVE, &val, 1);
    }

    String getTelemetryJson(const char* deviceId) {
        StaticJsonDocument<256> doc;
        doc["device_id"] = deviceId;
        doc["motion_detected"] = latestTelemetry.motion_detected;
        doc["occupancy"] = latestTelemetry.occupancy;
        doc["ambient_light"] = latestTelemetry.ambient_light;
        doc["light_status"] = latestTelemetry.light_status;
        doc["brightness"] = latestTelemetry.brightness;
        doc["mode"] = latestTelemetry.mode;
        doc["timeout_remaining"] = latestTelemetry.timeout_remaining;
        doc["hardware_connected"] = true;

        String output;
        serializeJson(doc, output);
        return output;
    }
};

#endif // UART_BRIDGE_H
