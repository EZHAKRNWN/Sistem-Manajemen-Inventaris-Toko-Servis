import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smartfix_mobile/features/minigame/logic/sensor_controller.dart';

class InventorySorterGame extends StatefulWidget {
  const InventorySorterGame({super.key});

  @override
  State<InventorySorterGame> createState() => _InventorySorterGameState();
}

class _InventorySorterGameState extends State<InventorySorterGame> {
  final SensorController _sensorController = SensorController();

  int _score = 0;
  bool _isPlaying = false;
  double _itemX = 0.0; // -1.0 (Left: Bin A) to +1.0 (Right: Bin B)
  double _rawTiltX = 0.0;

  String _currentItem = 'OLED Screen';
  String _targetBin = 'Left'; // 'Left' (Screens) or 'Right' (Batteries)

  Timer? _gameLoopTimer;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    _sensorController.startListening(
      onTiltChanged: (xTilt, yTilt) {
        if (!_isPlaying) return;
        setState(() {
          _rawTiltX = xTilt;
          // Invert or adjust x-tilt for intuitive steering
          _itemX = (_itemX - (xTilt * 0.04)).clamp(-1.0, 1.0);
        });
      },
    );
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _itemX = 0.0;
      _isPlaying = true;
      _spawnNewItem();
    });

    _gameLoopTimer?.cancel();
    _gameLoopTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_isPlaying) return;

      // Check if item reached left bin or right bin
      if (_itemX <= -0.85) {
        _evaluateSort('Left');
      } else if (_itemX >= 0.85) {
        _evaluateSort('Right');
      }
    });
  }

  void _spawnNewItem() {
    final isScreen = DateTime.now().millisecond % 2 == 0;
    _currentItem = isScreen ? 'OLED Screen' : 'Li-Ion Battery';
    _targetBin = isScreen ? 'Left' : 'Right';
    _itemX = 0.0;
  }

  void _evaluateSort(String chosenBin) {
    if (chosenBin == _targetBin) {
      _score += 10;
    } else {
      _score = (_score - 5).clamp(0, 9999);
    }
    _spawnNewItem();
    setState(() {});
  }

  void _stopGame() {
    _gameLoopTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _gameLoopTimer?.cancel();
    _sensorController.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Sorter Minigame'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Score & Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Score',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$_score pts',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: _isPlaying ? _stopGame : _startGame,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Stop' : 'Start Sorting'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isPlaying ? Colors.red : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Sensor Telemetry indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.screen_rotation, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Tilt: ${_rawTiltX.toStringAsFixed(2)} | Sorter: ${_itemX.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Game Arena
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Stack(
                    children: [
                      // Target Bins Header
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.smartphone, color: Colors.blue),
                                  SizedBox(height: 4),
                                  Text(
                                    'BIN A: SCREENS',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  Text('(Tilt Left)', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade800),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.battery_charging_full, color: Colors.amber.shade800),
                                  const SizedBox(height: 4),
                                  Text(
                                    'BIN B: BATTERIES',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                  const Text('(Tilt Right)', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Movable Repair Item
                      Align(
                        alignment: Alignment(_itemX, 0.2),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 50),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentItem.contains('Screen')
                                    ? Icons.stay_current_portrait
                                    : Icons.bolt,
                                color: theme.colorScheme.primary,
                                size: 36,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentItem,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Manual control buttons for emulators without gyro/accelerometer
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPlaying
                          ? () {
                              setState(() {
                                _itemX = (_itemX - 0.2).clamp(-1.0, 1.0);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Nudge Left'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isPlaying
                          ? () {
                              setState(() {
                                _itemX = (_itemX + 0.2).clamp(-1.0, 1.0);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Nudge Right'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
