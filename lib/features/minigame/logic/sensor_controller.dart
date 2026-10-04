import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

/// Controller to capture and process hardware Accelerometer and Gyroscope sensor streams.
class SensorController {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Smoothed sensor readings
  double xTilt = 0.0;
  double yTilt = 0.0;
  double zTilt = 0.0;

  double gyroX = 0.0;
  double gyroY = 0.0;
  double gyroZ = 0.0;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Start streaming sensor data with a callback on each update
  void startListening({
    required Function(double xTilt, double yTilt) onTiltChanged,
    Function(double gx, double gy, double gz)? onGyroChanged,
  }) {
    if (_isListening) return;
    _isListening = true;

    // Listen to Accelerometer
    _accelSubscription = accelerometerEventStream().listen(
      (AccelerometerEvent event) {
        // Apply low-pass smoothing filter
        xTilt = (xTilt * 0.7) + (event.x * 0.3);
        yTilt = (yTilt * 0.7) + (event.y * 0.3);
        zTilt = (zTilt * 0.7) + (event.z * 0.3);

        onTiltChanged(xTilt, yTilt);
      },
      onError: (err) {
        // Handle gracefully if device lacks sensor (e.g. desktop/emulator)
      },
      cancelOnError: false,
    );

    // Listen to Gyroscope
    _gyroSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        gyroX = event.x;
        gyroY = event.y;
        gyroZ = event.z;

        onGyroChanged?.call(gyroX, gyroY, gyroZ);
      },
      onError: (err) {
        // Sensor fallback
      },
      cancelOnError: false,
    );
  }

  /// Stop sensor subscriptions to preserve device battery
  void stopListening() {
    _accelSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription?.cancel();
    _gyroSubscription = null;
    _isListening = false;
  }
}
