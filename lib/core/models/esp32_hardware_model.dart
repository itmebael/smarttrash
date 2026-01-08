class Esp32HardwareMapping {
  final int ultrasonicTrigGpio;
  final int ultrasonicEchoGpio;
  final int gpsTxToRx2Gpio; // GPS TX -> ESP32 RX2 (GPIO 16)
  final int gpsRxToTx2Gpio; // GPS RX -> ESP32 TX2 (GPIO 17)
  final int sim800lTxdToRxGpio; // SIM800L TXD -> ESP32 RX (GPIO 26)
  final int sim800lRxdToTxGpio; // SIM800L RXD -> ESP32 TX (GPIO 27)
  final int redLedGpio; // FULL
  final int yellowLedGpio; // HALF
  final int greenLedGpio; // EMPTY

  const Esp32HardwareMapping({
    required this.ultrasonicTrigGpio,
    required this.ultrasonicEchoGpio,
    required this.gpsTxToRx2Gpio,
    required this.gpsRxToTx2Gpio,
    required this.sim800lTxdToRxGpio,
    required this.sim800lRxdToTxGpio,
    required this.redLedGpio,
    required this.yellowLedGpio,
    required this.greenLedGpio,
  });

  factory Esp32HardwareMapping.fromDefaults() {
    return const Esp32HardwareMapping(
      ultrasonicTrigGpio: 5,
      ultrasonicEchoGpio: 18,
      gpsTxToRx2Gpio: 16,
      gpsRxToTx2Gpio: 17,
      sim800lTxdToRxGpio: 26,
      sim800lRxdToTxGpio: 27,
      redLedGpio: 12,
      yellowLedGpio: 13,
      greenLedGpio: 14,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ultrasonicTrigGpio': ultrasonicTrigGpio,
      'ultrasonicEchoGpio': ultrasonicEchoGpio,
      'gpsTxToRx2Gpio': gpsTxToRx2Gpio,
      'gpsRxToTx2Gpio': gpsRxToTx2Gpio,
      'sim800lTxdToRxGpio': sim800lTxdToRxGpio,
      'sim800lRxdToTxGpio': sim800lRxdToTxGpio,
      'redLedGpio': redLedGpio,
      'yellowLedGpio': yellowLedGpio,
      'greenLedGpio': greenLedGpio,
    };
  }

  factory Esp32HardwareMapping.fromMap(Map<String, dynamic> map) {
    return Esp32HardwareMapping(
      ultrasonicTrigGpio: map['ultrasonicTrigGpio'] as int,
      ultrasonicEchoGpio: map['ultrasonicEchoGpio'] as int,
      gpsTxToRx2Gpio: map['gpsTxToRx2Gpio'] as int,
      gpsRxToTx2Gpio: map['gpsRxToTx2Gpio'] as int,
      sim800lTxdToRxGpio: map['sim800lTxdToRxGpio'] as int,
      sim800lRxdToTxGpio: map['sim800lRxdToTxGpio'] as int,
      redLedGpio: map['redLedGpio'] as int,
      yellowLedGpio: map['yellowLedGpio'] as int,
      greenLedGpio: map['greenLedGpio'] as int,
    );
  }
}


