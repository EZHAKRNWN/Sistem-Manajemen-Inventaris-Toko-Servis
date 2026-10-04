import 'dart:async';
import 'package:flutter/material.dart';

class CurrencyTimeConverterScreen extends StatefulWidget {
  const CurrencyTimeConverterScreen({super.key});

  @override
  State<CurrencyTimeConverterScreen> createState() =>
      _CurrencyTimeConverterScreenState();
}

class _CurrencyTimeConverterScreenState
    extends State<CurrencyTimeConverterScreen> {
  final TextEditingController _amountController =
      TextEditingController(text: '100');
  String _sourceCurrency = 'USD';

  // Base exchange rates relative to 1 USD
  final Map<String, double> _usdRates = {
    'USD': 1.0,
    'IDR': 15850.0,
    'CNY': 7.24, // Chinese Yuan (Shenzhen/Guangzhou Parts Hub)
    'EUR': 0.92,
    'JPY': 152.4,
    'SGD': 1.34,
  };

  // Currency metadata with symbols and region descriptions
  final Map<String, Map<String, String>> _currencyInfo = {
    'USD': {
      'symbol': '\$',
      'name': 'US Dollar',
      'label': 'Global OEM Benchmark',
    },
    'IDR': {
      'symbol': 'Rp',
      'name': 'Indonesian Rupiah',
      'label': 'Domestic Service Rate',
    },
    'CNY': {
      'symbol': '¥',
      'name': 'Chinese Yuan',
      'label': 'Shenzhen / Guangzhou Spare Parts Hub',
    },
    'EUR': {
      'symbol': '€',
      'name': 'Euro',
      'label': 'European Precision Tools',
    },
    'JPY': {
      'symbol': '¥',
      'name': 'Japanese Yen',
      'label': 'SMD & Micro-soldering Equipment',
    },
    'SGD': {
      'symbol': 'S\$',
      'name': 'Singapore Dollar',
      'label': 'Southeast Asia Distribution',
    },
  };

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now().toUtc();

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
    _amountController.dispose();
    super.dispose();
  }

  double _convert(double amount, String targetCurrency) {
    final baseInUsd = amount / (_usdRates[_sourceCurrency] ?? 1.0);
    return baseInUsd * (_usdRates[targetCurrency] ?? 1.0);
  }

  String _formatCurrency(double value, String currency) {
    if (currency == 'IDR') {
      final formatted = value
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
      return 'Rp $formatted';
    } else if (currency == 'CNY') {
      return '¥ ${value.toStringAsFixed(2)}';
    } else if (currency == 'USD') {
      return '\$ ${value.toStringAsFixed(2)}';
    } else if (currency == 'EUR') {
      return '€ ${value.toStringAsFixed(2)}';
    } else if (currency == 'JPY') {
      final formatted = value
          .toStringAsFixed(0)
          .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
      return '¥ $formatted';
    } else if (currency == 'SGD') {
      return 'S\$ ${value.toStringAsFixed(2)}';
    }
    return '${_currencyInfo[currency]?['symbol'] ?? ''} ${value.toStringAsFixed(2)}';
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
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayName = days[time.weekday - 1];
    final monthName = months[time.month - 1];
    return '$dayName, ${time.day} $monthName';
  }

  bool _isWorkingHours(DateTime localTime, int openHour, int closeHour) {
    // Weekend check: Saturday (6) and Sunday (7)
    if (localTime.weekday == DateTime.sunday) return false;
    return localTime.hour >= openHour && localTime.hour < closeHour;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputAmount = double.tryParse(_amountController.text) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logistics Forex & World Clocks'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section 1: Currency Converter ────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.currency_exchange_rounded,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Spare Parts Currency Converter',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Live exchange rates for China (CNY / ¥), USA (USD), and Indonesia (IDR)',
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
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Input Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            decoration: InputDecoration(
                              labelText: 'Purchase Amount',
                              prefixText: '${_currencyInfo[_sourceCurrency]?['symbol']} ',
                              prefixStyle: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _sourceCurrency,
                            items: _usdRates.keys.map((code) {
                              final info = _currencyInfo[code];
                              return DropdownMenuItem(
                                value: code,
                                child: Text(
                                  '$code (${info?['symbol']})',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _sourceCurrency = val);
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Quick Preset Chips
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip('100', '100'),
                          const SizedBox(width: 6),
                          _buildPresetChip('500', '500'),
                          const SizedBox(width: 6),
                          _buildPresetChip('1,000', '1000'),
                          const SizedBox(width: 6),
                          _buildPresetChip('5,000', '5000'),
                          const SizedBox(width: 6),
                          _buildPresetChip('10,000', '10000'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Converted Results
                    ..._usdRates.keys.where((c) => c != _sourceCurrency).map((target) {
                      final converted = _convert(inputAmount, target);
                      final info = _currencyInfo[target];
                      final isKeyCurrency = target == 'CNY' || target == 'IDR' || target == 'USD';

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isKeyCurrency
                              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: isKeyCurrency
                              ? Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isKeyCurrency
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  info?['symbol'] ?? target,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isKeyCurrency ? Colors.white : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$target - ${info?['name']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    info?['label'] ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatCurrency(converted, target),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isKeyCurrency
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Section 2: Supplier Logistics World Clocks ────────────────────
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
                        'Supplier Logistics World Clocks',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Monitor active manufacturing & cargo dispatch hours across China, USA & Indonesia',
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

            // 1. China Hub (Shenzhen / Guangzhou / Yiwu)
            _buildLogisticsHubCard(
              hubName: 'China Supply & Factory Hub',
              region: 'Shenzhen / Guangzhou / Yiwu',
              timezoneLabel: 'China Standard Time (CST / GMT+8)',
              time: _getTimeForOffset(8),
              openHour: 9,
              closeHour: 18,
              cutoffHour: 17,
              accentColor: const Color(0xFFE11D48), // Rose/Red for China
              icon: Icons.factory_outlined,
              shippingNote: 'Huaqiangbei spare parts & air freight cargo dispatch cutoff: 17:00 CST',
            ),

            // 2. USA Eastern Logistics (Memphis / New York)
            _buildLogisticsHubCard(
              hubName: 'USA Eastern Logistics Hub',
              region: 'Memphis FedEx Hub / New York OEM Depots',
              timezoneLabel: 'Eastern Standard Time (EST / UTC-5)',
              time: _getTimeForOffset(-5),
              openHour: 8,
              closeHour: 17,
              cutoffHour: 16,
              accentColor: const Color(0xFF2563EB), // Blue for USA
              icon: Icons.flight_takeoff_rounded,
              shippingNote: 'FedEx SuperHub parcel intake & express sorting active until 16:30 EST',
            ),

            // 3. USA Pacific Hub (Silicon Valley / LA)
            _buildLogisticsHubCard(
              hubName: 'USA Pacific Tech Hub',
              region: 'California / Silicon Valley Parts Center',
              timezoneLabel: 'Pacific Standard Time (PST / UTC-8)',
              time: _getTimeForOffset(-8),
              openHour: 9,
              closeHour: 17,
              cutoffHour: 16,
              accentColor: const Color(0xFF0284C7), // Sky Blue
              icon: Icons.devices_other_rounded,
              shippingNote: 'West Coast OEM distributor order clearance & freight processing',
            ),

            // 4. Indonesia Domestic Hub (WIB)
            _buildLogisticsHubCard(
              hubName: 'Indonesia Central Service Workshop',
              region: 'Jakarta / Roxy / Surabaya Warehouses',
              timezoneLabel: 'Western Indonesia Time (WIB / UTC+7)',
              time: _getTimeForOffset(7),
              openHour: 8,
              closeHour: 20,
              cutoffHour: 19,
              accentColor: const Color(0xFF0F766E), // Teal
              icon: Icons.storefront_rounded,
              shippingNote: 'Local courier dispatch & technician counter pickup window open until 19:30 WIB',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String value) {
    return InkWell(
      onTap: () {
        _amountController.text = value;
        setState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
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
                // Live Digital Clock Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.3)),
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

            // Status and Operating Hours Row
            Row(
              children: [
                // Active/Closed badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                        isOpen ? 'Dispatch Active (Open)' : 'Off-Hours / Night Queue',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOpen ? Colors.green.shade800 : Colors.amber.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hours: ${openHour.toString().padLeft(2, '0')}:00 - ${closeHour.toString().padLeft(2, '0')}:00',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Logistics / Shipping Note
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
