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

  // Base rates relative to 1 USD
  final Map<String, double> _usdRates = {
    'USD': 1.0,
    'IDR': 15850.0,
    'EUR': 0.92,
    'JPY': 152.4,
    'SGD': 1.34,
  };

  late Timer _clockTimer;
  DateTime _currentTime = DateTime.now().toUtc();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
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

  String _formatTime(DateTime utcTime, int offsetHours, [int offsetMinutes = 0]) {
    final target = utcTime.add(Duration(hours: offsetHours, minutes: offsetMinutes));
    final h = target.hour.toString().padLeft(2, '0');
    final m = target.minute.toString().padLeft(2, '0');
    final s = target.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inputAmount = double.tryParse(_amountController.text) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency & Time Converter'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CURRENCY SECTION
            Text(
              'Global Spare Parts Currency Converter',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: _sourceCurrency,
                            items: _usdRates.keys
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _sourceCurrency = val);
                            },
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // Converted rows
                    ..._usdRates.keys.where((c) => c != _sourceCurrency).map((target) {
                      final converted = _convert(inputAmount, target);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              target,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              target == 'IDR'
                                  ? 'Rp ${converted.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
                                  : converted.toStringAsFixed(2),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
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

            const SizedBox(height: 24),

            // TIMEZONE SECTION
            Text(
              'Supplier Logistics World Clocks',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Coordinate with regional parts distribution hubs in real-time.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            _buildTimezoneCard(
              zone: 'WIB (Western Indonesia Time)',
              city: 'Jakarta / Surabaya (UTC+7)',
              time: _formatTime(_currentTime, 7),
              icon: Icons.access_time_filled,
              color: Colors.teal,
            ),
            _buildTimezoneCard(
              zone: 'WITA (Central Indonesia Time)',
              city: 'Makassar / Bali (UTC+8)',
              time: _formatTime(_currentTime, 8),
              icon: Icons.access_time,
              color: Colors.indigo,
            ),
            _buildTimezoneCard(
              zone: 'WIT (Eastern Indonesia Time)',
              city: 'Jayapura / Ambon (UTC+9)',
              time: _formatTime(_currentTime, 9),
              icon: Icons.schedule,
              color: Colors.deepPurple,
            ),
            _buildTimezoneCard(
              zone: 'London (GMT / BST)',
              city: 'London UK Supply Hub (UTC+0)',
              time: _formatTime(_currentTime, 0),
              icon: Icons.public,
              color: Colors.blueGrey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneCard({
    required String zone,
    required String city,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(zone, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(city),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
