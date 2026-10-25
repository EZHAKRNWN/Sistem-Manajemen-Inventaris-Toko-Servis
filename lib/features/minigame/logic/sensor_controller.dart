// ============================================================================
// FITUR: PENGONTROL SENSOR HARDWARE SMARTPHONE (ACCELEROMETER & GYROSCOPE)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Memanfaatkan package 'sensors_plus' untuk membaca sensor fisik smartphone secara real-time.
// 2. Accelerometer: Mendeteksi sudut kemiringan fisik ponsel pada sumbu X (kiri/kanan) dan Y (depan/belakang).
// 3. Gyroscope: Memantau kecepatan sudut rotasi gawai saat digerakkan oleh teknisi.
// 4. Low-Pass Exponential Moving Average (EMA Filter):
//    Menghaluskan pergerakan sinyal sensor agar objek di game bergerak mulus dan tidak bergetar (anti-jitter).
// 5. Dead-Zone Tolerance: Mengabaikan getaran minor mikro dari denyut atau tangan teknisi.
// ============================================================================

import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

class SensorController {
  // Subscription stream sensor akselerometer & giroskop
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Koefisien pemulusan filter Low-Pass EMA (0.0 - 1.0)
  final double accelAlpha;

  // Batas toleransi getaran kecil (dead zone)
  final double deadZone;

  // Nilai kemiringan terevaluasi (derajat/kecepatan)
  double xTilt = 0.0;
  double yTilt = 0.0;
  double zTilt = 0.0;

  // Nilai giroskop
  double gyroX = 0.0;
  double gyroY = 0.0;
  double gyroZ = 0.0;

  bool _isListening = false;
  bool get isListening => _isListening;

  SensorController({this.accelAlpha = 0.22, this.deadZone = 0.08});

  /// FITUR: Mengaktifkan Perekaman Data Sensor Fisik
  /// Mendengarkan perubahan Accelerometer dan Gyroscope dengan sampling interval UI (~60 FPS)
  void startListening({
    required Function(double xTilt, double yTilt) onTiltChanged,
    Function(double gx, double gy, double gz)? onGyroChanged,
  }) {
    if (_isListening) return;
    _isListening = true;

    // Stream pembacaan sensor Accelerometer
    _accelSubscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
            .listen(
              (AccelerometerEvent event) {
                // Terapkan rumus Exponential Moving Average (EMA)
                xTilt = (xTilt * (1.0 - accelAlpha)) + (event.x * accelAlpha);
                yTilt = (yTilt * (1.0 - accelAlpha)) + (event.y * accelAlpha);
                zTilt = (zTilt * (1.0 - accelAlpha)) + (event.z * accelAlpha);

                // Hilangkan micro-jitter dengan deadZone
                final filteredX = xTilt.abs() < deadZone ? 0.0 : xTilt;
                final filteredY = yTilt.abs() < deadZone ? 0.0 : yTilt;

                onTiltChanged(filteredX, filteredY);
              },
              onError: (err) {},
              cancelOnError: false,
            );

    // Stream pembacaan sensor Gyroscope
    _gyroSubscription =
        gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval).listen(
          (GyroscopeEvent event) {
            const gyroAlpha = 0.25;
            gyroX = (gyroX * (1.0 - gyroAlpha)) + (event.x * gyroAlpha);
            gyroY = (gyroY * (1.0 - gyroAlpha)) + (event.y * gyroAlpha);
            gyroZ = (gyroZ * (1.0 - gyroAlpha)) + (event.z * gyroAlpha);

            onGyroChanged?.call(gyroX, gyroY, gyroZ);
          },
          onError: (err) {},
          cancelOnError: false,
        );
  }

  /// FITUR: Mematikan Stream Sensor untuk Menghemat Konsumsi Baterai HP
  void stopListening() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _isListening = false;
  }
}
