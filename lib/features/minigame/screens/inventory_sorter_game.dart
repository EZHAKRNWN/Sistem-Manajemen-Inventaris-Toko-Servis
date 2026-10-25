// ============================================================================
// FITUR: MINI-GAME EDUKATIF PENGUJIAN SENSOR SMARTPHONE (INVENTORY SORTER GAME)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Penerapan Nyata Hardware Sensor: Mengontrol pergerakan keranjang suku cadang menggunakan
//    kemiringan fisik smartphone (Tilt Control via Accelerometer).
// 2. Hybrid Control (Fallback Emulator): Jika dijalankan di PC Emulator tanpa sensor fisik,
//    pengguna tetap bisa menggeser keranjang menggunakan drag sentuhan layar (Touch Gesture).
// 3. Game Loop 60 FPS: Menggunakan Periodic Timer 16ms untuk pembaruan posisi part jatuh dan deteksi tabrakan (Collision Detection).
// 4. Manajemen Komponen Servis: Berisi jenis suku cadang nyata seperti Layar OLED, Baterai, IC Chip, Kabel Fleksibel, Kamera, dan Baut.
// 5. Sistem Gamifikasi: Perhitungan skor, combo streak, nyawa (lives), level difficulty scaling, dan High Score.
// ============================================================================

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:smartfix_mobile/features/minigame/logic/sensor_controller.dart';

/// Jenis suku cadang yang jatuh dalam permainan
enum ComponentType { oled, battery, ic, flex, camera, screw }

/// Entitas suku cadang bergerak dengan koordinat x, y, dan kecepatan dinamis
class FallingComponent {
  double x;
  double y;
  final double speed;
  final ComponentType type;
  bool caught = false;
  bool missed = false;

  FallingComponent({
    required this.x,
    required this.y,
    required this.speed,
    required this.type,
  });
}

/// Metadata visual dan skor untuk setiap tipe suku cadang
class _ComponentMeta {
  final String label;
  final IconData icon;
  final Color color;
  final int points;

  const _ComponentMeta({
    required this.label,
    required this.icon,
    required this.color,
    required this.points,
  });
}

class InventorySorterGame extends StatefulWidget {
  const InventorySorterGame({super.key});

  @override
  State<InventorySorterGame> createState() => _InventorySorterGameState();
}

class _InventorySorterGameState extends State<InventorySorterGame>
    with SingleTickerProviderStateMixin {
  static const double _catcherW = 0.22;
  static const double _catcherH = 0.065;
  static const double _catcherY = 0.88;
  static const double _compR = 0.045;
  static const int _maxLives = 3;
  static const int _baseSpawnMs = 900;
  static const int _tickMs = 16;

  final SensorController _sensor = SensorController();
  final Random _rng = Random();

  double _catcherX = 0.5;
  double _rawTiltX = 0.0;
  double _catcherVelocity = 0.0;
  int _score = 0;
  int _highScore = 0;
  int _lives = _maxLives;
  int _level = 1;
  int _combo = 0;
  int _caught = 0;

  bool _isPlaying = false;
  bool _gameOver = false;
  bool _isPaused = false;
  bool _sensorActive = false;

  final List<FallingComponent> _comps = [];
  Timer? _gameLoop;
  Timer? _spawnTimer;

  double? _dragStartX;
  double? _catcherStartX;

  String? _flashText;
  Color _flashColor = Colors.green;
  Timer? _flashTimer;

  static const Map<ComponentType, _ComponentMeta> _meta = {
    ComponentType.oled: _ComponentMeta(
      label: 'OLED',
      icon: Icons.stay_current_portrait,
      color: Color(0xFF6366F1),
      points: 10,
    ),
    ComponentType.battery: _ComponentMeta(
      label: 'Baterai',
      icon: Icons.battery_full,
      color: Color(0xFF22C55E),
      points: 10,
    ),
    ComponentType.ic: _ComponentMeta(
      label: 'IC Chip',
      icon: Icons.memory,
      color: Color(0xFFF59E0B),
      points: 20,
    ),
    ComponentType.flex: _ComponentMeta(
      label: 'Fleksibel',
      icon: Icons.cable,
      color: Color(0xFF14B8A6),
      points: 15,
    ),
    ComponentType.camera: _ComponentMeta(
      label: 'Kamera',
      icon: Icons.camera_alt,
      color: Color(0xFFEC4899),
      points: 15,
    ),
    ComponentType.screw: _ComponentMeta(
      label: 'Baut',
      icon: Icons.settings,
      color: Color(0xFF94A3B8),
      points: 5,
    ),
  };

  @override
  void initState() {
    super.initState();
    // Inisialisasi pembacaan data sensor accelerometer dan gyroscope
    _initSensors();
  }

  /// FITUR: Menghubungkan Sensor Smartphone ke Logika Kemiringan Keranjang
  void _initSensors() {
    _sensor.startListening(
      onTiltChanged: (xTilt, _) {
        if (!_sensorActive && mounted) {
          setState(() => _sensorActive = true);
        }
        _rawTiltX = -xTilt;
      },
      onGyroChanged: (gx, gy, gz) {
        if (!_sensorActive && mounted) {
          setState(() => _sensorActive = true);
        }
        _rawTiltX += (-gy * 0.4);
      },
    );
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _flashTimer?.cancel();
    _sensor.stopListening();
    super.dispose();
  }

  /// FITUR: Memulai Sesi Permainan Baru (Reset Score & Lives)
  void _startGame() {
    _comps.clear();
    setState(() {
      _score = 0;
      _lives = _maxLives;
      _level = 1;
      _combo = 0;
      _caught = 0;
      _catcherX = 0.5;
      _isPlaying = true;
      _gameOver = false;
      _isPaused = false;
      _flashText = null;
    });
    _resetTimers();
  }

  /// Mengatur Timer Loop 60 FPS (16ms) dan Timer Spawn Part Jatuh
  void _resetTimers() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    _gameLoop = Timer.periodic(const Duration(milliseconds: _tickMs), (_) {
      if (_isPlaying && !_isPaused) _tick();
    });
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: max(350, _baseSpawnMs - (_level - 1) * 70)),
      (_) {
        if (_isPlaying && !_isPaused) _spawn();
      },
    );
  }

  void _togglePause() => setState(() => _isPaused = !_isPaused);

  /// FITUR: Game Loop Frame-by-Frame (~60 FPS)
  /// Menghitung pergerakan keranjang via sensor kemiringan, update koordinat Y part, dan deteksi tabrakan (Collision Detection)
  void _tick() {
    if (!mounted) return;
    setState(() {
      // 1. Update posisi horizontal keranjang berdasarkan sensor kemiringan
      if (_sensorActive) {
        final targetVel = (_rawTiltX * 0.0038).clamp(-0.028, 0.028);
        _catcherVelocity = (_catcherVelocity * 0.78) + (targetVel * 0.22);
        _catcherX = (_catcherX + _catcherVelocity).clamp(
          _catcherW / 2,
          1.0 - _catcherW / 2,
        );
      }

      // 2. Turunkan suku cadang yang sedang melayang dan periksa tabrakan
      final speed = 0.006 + (_level - 1) * 0.0012;
      for (final c in _comps) {
        if (c.caught || c.missed) continue;
        c.y += speed * c.speed;
        final inX =
            c.x >= _catcherX - _catcherW / 2 &&
            c.x <= _catcherX + _catcherW / 2;
        final inY = c.y >= _catcherY - _catcherH && c.y <= _catcherY + 0.02;
        if (inX && inY) {
          c.caught = true;
          _onCatch(c.type);
        } else if (c.y > 1.06) {
          c.missed = true;
          _onMiss();
        }
      }
      _comps.removeWhere((c) => c.caught || c.missed);

      // 3. Level scaling setiap kelipatan 50 poin
      final newLv = (_score ~/ 50) + 1;
      if (newLv > _level) {
        _level = newLv;
        _resetTimers();
      }
    });
  }

  void _spawn() {
    if (!mounted) return;
    final types = ComponentType.values;
    setState(() {
      _comps.add(
        FallingComponent(
          x: _compR + _rng.nextDouble() * (1.0 - _compR * 2),
          y: -0.06,
          speed: 0.8 + _rng.nextDouble() * 0.65,
          type: types[_rng.nextInt(types.length)],
        ),
      );
    });
  }

  void _onCatch(ComponentType type) {
    _combo++;
    _caught++;
    final base = _meta[type]!.points;
    final bonus = _combo >= 3 ? (_combo ~/ 3) * 5 : 0;
    final pts = base + bonus;
    _score += pts;
    String txt = '+$pts';
    if (_combo >= 5) {
      txt = '🔥 COMBO x$_combo  +$pts';
    } else if (_combo >= 3) {
      txt = '⚡ x$_combo  +$pts';
    }
    _flash(txt, const Color(0xFF4ADE80));
  }

  void _onMiss() {
    _combo = 0;
    _lives--;
    _flash('💥 TERLEWAT!', Colors.redAccent);
    if (_lives <= 0) {
      _endGame();
    }
  }

  void _endGame() {
    _gameLoop?.cancel();
    _spawnTimer?.cancel();
    if (_score > _highScore) _highScore = _score;
    setState(() {
      _isPlaying = false;
      _gameOver = true;
    });
  }

  void _flash(String text, Color color) {
    _flashTimer?.cancel();
    setState(() {
      _flashText = text;
      _flashColor = color;
    });
    _flashTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _flashText = null);
    });
  }

  void _onPanStart(DragStartDetails d, double w) {
    _dragStartX = d.localPosition.dx;
    _catcherStartX = _catcherX;
    _catcherVelocity = 0.0;
  }

  void _onPanUpdate(DragUpdateDetails d, double w) {
    if (!_isPlaying || _isPaused || _dragStartX == null) return;
    final delta = (d.localPosition.dx - _dragStartX!) / w;
    setState(() {
      _catcherX = (_catcherStartX! + delta).clamp(
        _catcherW / 2,
        1.0 - _catcherW / 2,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Tangkap Sparepart (Gyro) ⚡',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.screen_rotation,
                  size: 14,
                  color: _sensorActive
                      ? const Color(0xFF4ADE80)
                      : Colors.white38,
                ),
                const SizedBox(width: 4),
                Text(
                  _sensorActive ? 'Tilt Aktif' : 'Tilt Sensor',
                  style: TextStyle(
                    fontSize: 10,
                    color: _sensorActive
                        ? const Color(0xFF4ADE80)
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          if (_isPlaying)
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              onPressed: _togglePause,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHud(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (_, c) {
                      final w = c.maxWidth;
                      final h = c.maxHeight;
                      return GestureDetector(
                        onPanStart: (d) => _onPanStart(d, w),
                        onPanUpdate: (d) => _onPanUpdate(d, w),
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: Size(w, h),
                              painter: _GridPainter(),
                            ),
                            CustomPaint(
                              size: Size(w, h),
                              painter: _GamePainter(
                                comps: _comps,
                                catcherX: _catcherX,
                                meta: _meta,
                                catcherW: _catcherW,
                                catcherH: _catcherH,
                                catcherY: _catcherY,
                                compR: _compR,
                              ),
                            ),
                            if (_flashText != null)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _flashColor.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _flashColor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    _flashText!,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _flashColor,
                                    ),
                                  ),
                                ),
                              ),
                            if (!_isPlaying) _buildMainOverlay(w, h),
                            if (_isPaused) _buildPauseOverlay(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildHud() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _maxLives,
              (i) => Icon(
                i < _lives ? Icons.favorite : Icons.favorite_border,
                color: i < _lives ? Colors.redAccent : Colors.white24,
                size: 22,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'TERBAIK: $_highScore',
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1)),
            ),
            child: Text(
              'LEVEL $_level',
              style: const TextStyle(
                color: Color(0xFF818CF8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainOverlay(double w, double h) {
    final isOver = _gameOver;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isOver ? '💥 GAME OVER' : '⚡ TANGKAP SPAREPART HP',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            if (isOver) ...[
              Text(
                'Skor Akhir: $_score poin',
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
              Text(
                '$_caught komponen berhasil ditangkap',
                style: const TextStyle(fontSize: 13, color: Colors.white38),
              ),
              if (_score > 0 && _score >= _highScore)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    '🏆 REKOR SKOR BARU!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 4),
              const Text(
                'Tangkap suku cadang smartphone yang berjatuhan!\nMiringkan ponsel (sensor gyro) ke kiri atau kanan\natau geser layar untuk menggerakkan nampan teknisi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _startGame,
              icon: Icon(isOver ? Icons.replay : Icons.play_arrow),
              label: Text(isOver ? 'Main Lagi' : 'Mulai Game'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            const Text(
              'GAME DIJEDA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _togglePause,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
              ),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: _meta.entries
              .map(
                (e) => Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: e.value.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: e.value.color.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(e.value.icon, color: e.value.color, size: 13),
                      const SizedBox(width: 5),
                      Text(
                        '${e.value.label} +${e.value.points}',
                        style: TextStyle(
                          fontSize: 11,
                          color: e.value.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _GamePainter extends CustomPainter {
  final List<FallingComponent> comps;
  final double catcherX, catcherW, catcherH, catcherY, compR;
  final Map<ComponentType, _ComponentMeta> meta;

  const _GamePainter({
    required this.comps,
    required this.catcherX,
    required this.catcherW,
    required this.catcherH,
    required this.catcherY,
    required this.compR,
    required this.meta,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = catcherX * size.width;
    final cy = catcherY * size.height;
    final cw = catcherW * size.width;
    final ch = catcherH * size.height;
    final rr = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: cw, height: ch),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..color = const Color(0xFF6366F1).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF14B8A6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rr.outerRect),
    );

    for (final c in comps) {
      if (c.caught || c.missed) continue;
      final info = meta[c.type]!;
      final px = c.x * size.width;
      final py = c.y * size.height;
      final r = compR * size.width;
      canvas.drawCircle(
        Offset(px, py),
        r + 5,
        Paint()
          ..color = info.color.withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()..color = info.color.withValues(alpha: 0.92),
      );
      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GamePainter old) => true;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => false;
}
