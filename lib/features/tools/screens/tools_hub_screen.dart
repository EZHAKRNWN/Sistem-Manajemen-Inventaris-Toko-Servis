import 'package:flutter/material.dart';
import 'package:smartfix_mobile/features/location/screens/map_tracking_screen.dart';
import 'package:smartfix_mobile/features/minigame/screens/inventory_sorter_game.dart';
import 'package:smartfix_mobile/features/tools/screens/ai_assistant_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/blockchain_verify_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/currency_time_converter.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  // Industrial-Tech Color System
  static const Color _bgColor = Color(0xFF1E1E1E);
  static const Color _surfaceColor = Color(0xFF262626);
  static const Color _cardColor = Color(0xFF2B2B2B);
  static const Color _cardBorderColor = Color(0xFF3B3B3B);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFA3A3A3);

  @override
  Widget build(BuildContext context) {
    final toolGroups = [
      {
        'category': 'Cryptographic Provenance & Security',
        'items': [
          {
            'title': 'Blockchain Part Verifier',
            'subtitle': 'Verify cryptographic SHA-256 hashes and audit supply chain ledger blocks',
            'badge': 'SHA-256',
            'badgeColor': _teal,
            'icon': Icons.security_rounded,
            'accentColor': _teal,
            'screen': const BlockchainVerifyScreen(),
          },
        ],
      },
      {
        'category': 'Intelligence & Diagnostics',
        'items': [
          {
            'title': 'AI Repair Assistant',
            'subtitle': 'Motherboard diagnostics, pinout guidance, and repair troubleshooting',
            'badge': 'AI Diagnostics',
            'badgeColor': Colors.purpleAccent,
            'icon': Icons.smart_toy_outlined,
            'accentColor': Colors.purpleAccent,
            'screen': const AiAssistantScreen(),
          },
          {
            'title': 'Currency & Timezone Converter',
            'subtitle': 'Live exchange rates for IDR, USD, EUR and multi-region service times',
            'badge': 'Forex & Time',
            'badgeColor': Colors.lightBlueAccent,
            'icon': Icons.currency_exchange_rounded,
            'accentColor': Colors.lightBlueAccent,
            'screen': const CurrencyTimeConverterScreen(),
          },
        ],
      },
      {
        'category': 'Logistics & Hardware Sensors',
        'items': [
          {
            'title': 'GPS Courier Tracking',
            'subtitle': 'Live field location tracking via OpenStreetMap & Geolocator',
            'badge': 'LBS GPS',
            'badgeColor': Colors.tealAccent,
            'icon': Icons.map_outlined,
            'accentColor': Colors.tealAccent,
            'screen': const MapTrackingScreen(),
          },
          {
            'title': 'Sensor Inventory Sorter',
            'subtitle': 'Calibrate & test device gyroscope and accelerometer sensors',
            'badge': 'Sensors',
            'badgeColor': Colors.amber,
            'icon': Icons.sports_esports_outlined,
            'accentColor': Colors.amber,
            'screen': const InventorySorterGame(),
          },
        ],
      },
    ];

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _surfaceColor,
        elevation: 0,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Technical Utilities',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Engineering tools, diagnostics & cryptography',
              style: TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          // Banner Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.handyman_rounded, color: _teal, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Workshop Operations Toolkit',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'All diagnostic, logistics, and verification modules are operational.',
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grouped Sections
          ...toolGroups.map((group) {
            final category = group['category'] as String;
            final items = group['items'] as List<Map<String, dynamic>>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                ...items.map((tool) {
                  final accentColor = tool['accentColor'] as Color;
                  final badgeColor = tool['badgeColor'] as Color;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _cardBorderColor),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => tool['screen'] as Widget,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Icon Capsule
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Icon(
                                  tool['icon'] as IconData,
                                  color: accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Title & Subtitle
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            tool['title'] as String,
                                            style: const TextStyle(
                                              color: _textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: badgeColor.withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Text(
                                            tool['badge'] as String,
                                            style: TextStyle(
                                              color: badgeColor,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tool['subtitle'] as String,
                                      style: const TextStyle(
                                        color: _textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: _textSecondary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}
