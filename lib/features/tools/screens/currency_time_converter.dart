// ============================================================================
// FITUR: ZONA WAKTU & JAM KERJA SUPLIER GLOBAL (WORLD CLOCK & LOGISTICS TIME ZONES)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Jam Dunia Real-Time: Sinkronisasi waktu detik-per-detik untuk zona waktu domestik (WIB, WITA, WIT).
// 2. Sinkronisasi Jam Kerja Suplier Internasional:
//    Menampilkan jam operasional suplier di London UK (dengan kalkulasi BST/Daylight Saving Time),
//    China (CST UTC+8), Tokyo Jepang (JST UTC+9), dan New York (EST UTC-5).
// 3. Konverter Waktu Interaktif (TimePicker): Memungkinkan simulasi jam untuk memastikan teknisi
//    menghubungi distributor luar negeri pada jam kerja aktif mereka.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

class CurrencyTimeConverterScreen extends StatefulWidget {
  const CurrencyTimeConverterScreen({super.key});

  @override
  State<CurrencyTimeConverterScreen> createState() =>
      _CurrencyTimeConverterScreenState();
}

typedef WorldClockScreen = CurrencyTimeConverterScreen;

class _CurrencyTimeConverterScreenState
    extends State<CurrencyTimeConverterScreen> {
  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now().toUtc();

  TimeOfDay _interactiveSourceTime = const TimeOfDay(hour: 10, minute: 0);
  String _interactiveSourceZone = 'WIB';

  int get _londonOffset {
    final now = DateTime.now().toUtc();
    final year = now.year;
    DateTime lastSunday(int month) {
      var d = DateTime.utc(
        year,
        month + 1,
        1,
      ).subtract(const Duration(days: 1));
      while (d.weekday != DateTime.sunday) {
        d = d.subtract(const Duration(days: 1));
      }
      return d;
    }

    final bstStart = DateTime.utc(year, 3, lastSunday(3).day, 1);
    final bstEnd = DateTime.utc(year, 10, lastSunday(10).day, 1);
    return (now.isAfter(bstStart) && now.isBefore(bstEnd)) ? 1 : 0;
  }

  Map<String, int> get _allZoneOffsets => {
    'WIB': 7,
    'WITA': 8,
    'WIT': 9,
    'London': _londonOffset,
    'Tiongkok (CST)': 8,
    'Jepang (JST)': 9,
    'AS Timur (EST)': -5,
  };

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now().toUtc();
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  DateTime _getTimeForOffset(int offsetHours) {
    return _currentTime.add(Duration(hours: offsetHours));
  }

  String _formatDigitalClock(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final s = time.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDateShort(DateTime time) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final dayName = days[time.weekday - 1];
    final monthName = months[time.month - 1];
    return '$dayName, ${time.day} $monthName';
  }

  bool _isWorkingHours(DateTime localTime, int openHour, int closeHour) {
    if (localTime.weekday == DateTime.sunday) return false;
    return localTime.hour >= openHour && localTime.hour < closeHour;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zona Waktu & Jam Suplier Global'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Informasi Jam Kerja Suplier',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.public_rounded, color: Color(0xFF14B8A6)),
                      SizedBox(width: 8),
                      Text('Zona Waktu Suplier', style: TextStyle(fontSize: 18)),
                    ],
                  ),
                  content: const Text(
                    'Fitur ini membantu teknisi dan staf bengkel memantau jam operasional suplier suku cadang internasional di London, Shenzhen, Tokyo, dan New York, serta koordinasi antar cabang di WIB, WITA, dan WIT secara real-time.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Konversi Waktu & Jam Logistik Global',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sinkronisasi waktu servis & logistik (WIB, WITA, WIT, London, Tiongkok, Jepang, AS)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Colors.amber.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: Colors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Kalkulator Konversi Waktu Antar-Zona',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: _interactiveSourceTime,
                                builder: (ctx, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(ctx)
                                        .copyWith(alwaysUse24HourFormat: true),
                                    child: child ?? const SizedBox(),
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _interactiveSourceTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Waktu Acuan',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_interactiveSourceTime.hour.toString().padLeft(2, '0')}:${_interactiveSourceTime.minute.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: _interactiveSourceZone,
                            isExpanded: true,
                            items: _allZoneOffsets.keys.map((zone) {
                              return DropdownMenuItem(
                                value: zone,
                                child: Text(
                                  zone,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _interactiveSourceZone = val);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Zona Asal',
                              labelStyle: const TextStyle(fontSize: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTimePresetChip(
                            '08:00 (Buka)',
                            const TimeOfDay(hour: 8, minute: 0),
                          ),
                          const SizedBox(width: 6),
                          _buildTimePresetChip(
                            '12:00 (Siang)',
                            const TimeOfDay(hour: 12, minute: 0),
                          ),
                          const SizedBox(width: 6),
                          _buildTimePresetChip(
                            '17:00 (Cut-Off)',
                            const TimeOfDay(hour: 17, minute: 0),
                          ),
                          const SizedBox(width: 6),
                          _buildTimePresetChip(
                            '20:00 (Tutup)',
                            const TimeOfDay(hour: 20, minute: 0),
                          ),
                          const SizedBox(width: 6),
                          _buildTimePresetChip('Jam Sekarang', TimeOfDay.now()),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    Text(
                      'Hasil Konversi di Zona Lain:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allZoneOffsets.keys.map((targetZone) {
                        final isSelected = targetZone == _interactiveSourceZone;
                        final convertedTime = _computeZoneTime(
                          _interactiveSourceTime,
                          _interactiveSourceZone,
                          targetZone,
                        );
                        final dayNote = _computeDayNote(
                          _interactiveSourceTime,
                          _interactiveSourceZone,
                          targetZone,
                        );
                        final isMandatory =
                            targetZone == 'WIB' ||
                            targetZone == 'WITA' ||
                            targetZone == 'WIT' ||
                            targetZone == 'London';

                        return Container(
                          width: (MediaQuery.of(context).size.width - 70) / 2,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : isMandatory
                                ? Colors.amber.withValues(alpha: 0.1)
                                : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : isMandatory
                                  ? Colors.amber.withValues(alpha: 0.4)
                                  : theme.colorScheme.outlineVariant.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    targetZone,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : isMandatory
                                          ? Colors.amber
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (isSelected)
                                    const Text(
                                      'ACUAN',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF14B8A6),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                convertedTime,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                dayNote,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(
                  Icons.podcasts_rounded,
                  size: 16,
                  color: Color(0xFF14B8A6),
                ),
                const SizedBox(width: 6),
                Text(
                  'Jam Digital Real-Time & Operasional Logistik',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            _buildLogisticsHubCard(
              hubName: 'Bengkel Servis Pusat SmartFix Indonesia (WIB)',
              region: 'Gudang Roxy Square / Mangga Dua Jakarta (WIB / UTC+7)',
              timezoneLabel: 'Waktu Indonesia Barat (WIB / UTC+7)',
              time: _getTimeForOffset(7),
              openHour: 8,
              closeHour: 20,
              cutoffHour: 19,
              accentColor: const Color(0xFF0F766E),
              icon: Icons.storefront_rounded,
              shippingNote: 'Loket pengambilan teknisi & pengiriman kurir lokal buka hingga 19:30 WIB',
            ),

            _buildLogisticsHubCard(
              hubName: 'Hub Logistik & Servis Regional Bali-Sulawesi (WITA)',
              region: 'Denpasar Bali / Makassar Regional Service Center (WITA / UTC+8)',
              timezoneLabel: 'Waktu Indonesia Tengah (WITA / UTC+8)',
              time: _getTimeForOffset(8),
              openHour: 8,
              closeHour: 20,
              cutoffHour: 19,
              accentColor: const Color(0xFF0284C7),
              icon: Icons.location_city_rounded,
              shippingNote: 'Distribusi suku cadang regional & pengiriman cepat buka hingga 19:30 WITA',
            ),

            _buildLogisticsHubCard(
              hubName: 'Hub Logistik & Servis Regional Maluku-Papua (WIT)',
              region: 'Pusat Layanan Jayapura / Ambon Depo (WIT / UTC+9)',
              timezoneLabel: 'Waktu Indonesia Timur (WIT / UTC+9)',
              time: _getTimeForOffset(9),
              openHour: 8,
              closeHour: 20,
              cutoffHour: 19,
              accentColor: const Color(0xFF10B981),
              icon: Icons.explore_outlined,
              shippingNote: 'Penyortiran pengiriman kargo udara suku cadang timur aktif hingga 19:00 WIT',
            ),

            _buildLogisticsHubCard(
              hubName: 'Pusat Suku Cadang & Lisensi Diagnostik London UK',
              region: 'London Tech City / Heathrow Logistics Cargo Depot UK',
              timezoneLabel:
                  'Waktu London Inggris (${_londonOffset == 1 ? 'BST / UTC+1' : 'GMT / UTC+0'})',
              time: _getTimeForOffset(_londonOffset),
              openHour: 8,
              closeHour: 17,
              cutoffHour: 16,
              accentColor: const Color(0xFF8B5CF6),
              icon: Icons.language_rounded,
              shippingNote: 'Pemrosesan pesanan kargo suku cadang Eropa & lisensi software aktif hingga 16:30 London',
            ),

            _buildLogisticsHubCard(
              hubName: 'Pusat Pabrik & Suku Cadang Tiongkok',
              region: 'Shenzhen / Guangzhou / Yiwu (Pasar Huaqiangbei)',
              timezoneLabel: 'Waktu Standar Tiongkok (CST / GMT+8)',
              time: _getTimeForOffset(8),
              openHour: 9,
              closeHour: 18,
              cutoffHour: 17,
              accentColor: const Color(0xFFE11D48),
              icon: Icons.factory_outlined,
              shippingNote: 'Batas pemrosesan kargo udara suku cadang Huaqiangbei: 17:00 CST',
            ),

            _buildLogisticsHubCard(
              hubName: 'Pusat Komponen Presisi & SMD Jepang',
              region: 'Tokyo Akihabara / Osaka Precision Hub',
              timezoneLabel: 'Waktu Standar Jepang (JST / GMT+9)',
              time: _getTimeForOffset(9),
              openHour: 9,
              closeHour: 18,
              cutoffHour: 17,
              accentColor: const Color(0xFFF59E0B),
              icon: Icons.precision_manufacturing_rounded,
              shippingNote: 'Pengiriman alat mikrosolder & IC solder SMD presisi: 17:30 JST',
            ),

            _buildLogisticsHubCard(
              hubName: 'Pusat Logistik Pantai Timur AS',
              region: 'Depo OEM New York & SuperHub FedEx Memphis',
              timezoneLabel: 'Waktu Standar Timur AS (EST / UTC-5)',
              time: _getTimeForOffset(-5),
              openHour: 8,
              closeHour: 17,
              cutoffHour: 16,
              accentColor: const Color(0xFF2563EB),
              icon: Icons.flight_takeoff_rounded,
              shippingNote: 'Penyortiran paket ekspres & penerimaan kargo aktif hingga 16:30 EST',
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTimePresetChip(String label, TimeOfDay time) {
    final isSelected =
        _interactiveSourceTime.hour == time.hour &&
        _interactiveSourceTime.minute == time.minute;
    return InkWell(
      onTap: () {
        setState(() => _interactiveSourceTime = time);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.25)
              : Theme.of(context).colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Colors.amber
                : Theme.of(context).colorScheme.outlineVariant
                      .withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.amber : null,
          ),
        ),
      ),
    );
  }

  String _computeZoneTime(TimeOfDay baseTime, String fromZone, String toZone) {
    final fromOffset = _allZoneOffsets[fromZone] ?? 7;
    final toOffset = _allZoneOffsets[toZone] ?? 7;
    final diffHours = toOffset - fromOffset;

    int totalMinutes =
        (baseTime.hour * 60 + baseTime.minute) + (diffHours * 60);
    while (totalMinutes < 0) {
      totalMinutes += 1440;
    }
    totalMinutes = totalMinutes % 1440;

    final h = (totalMinutes ~/ 60).toString().padLeft(2, '0');
    final m = (totalMinutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _computeDayNote(TimeOfDay baseTime, String fromZone, String toZone) {
    final fromOffset = _allZoneOffsets[fromZone] ?? 7;
    final toOffset = _allZoneOffsets[toZone] ?? 7;
    final diffHours = toOffset - fromOffset;
    final totalHours = baseTime.hour + diffHours;
    if (totalHours >= 24) return '+1 hr (Besok)';
    if (totalHours < 0) return '-1 hr (Kemarin)';
    return 'Hari sama';
  }

  Widget _buildLogisticsHubCard({
    required String hubName,
    required String region,
    required String timezoneLabel,
    required DateTime time,
    required int openHour,
    required int closeHour,
    required int cutoffHour,
    required Color accentColor,
    required IconData icon,
    required String shippingNote,
  }) {
    final isOpen = _isWorkingHours(time, openHour, closeHour);
    final digitalTime = _formatDigitalClock(time);
    final dateStr = _formatDateShort(time);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isOpen
              ? accentColor.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.25),
          width: isOpen ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accentColor.withValues(alpha: 0.15),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hubName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        region,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        digitalTime,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: accentColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen ? Colors.green : Colors.amber.shade700,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isOpen
                            ? 'Pengiriman Aktif (Buka)'
                            : 'Di Luar Jam Kerja (Malam)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOpen
                              ? Colors.green.shade400
                              : Colors.amber.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Jam Kerja: ${openHour.toString().padLeft(2, '0')}:00 - ${closeHour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    shippingNote,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
