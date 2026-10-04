import 'package:flutter/material.dart';
import 'package:smartfix_mobile/features/location/screens/map_tracking_screen.dart';
import 'package:smartfix_mobile/features/minigame/screens/inventory_sorter_game.dart';
import 'package:smartfix_mobile/features/tools/screens/ai_assistant_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/blockchain_verify_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/currency_time_converter.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tools = [
      {
        'title': 'Currency & Timezone Converter',
        'subtitle': 'Live converter for IDR, USD, EUR and WIB, WITA, WIT, London',
        'icon': Icons.currency_exchange,
        'color': Colors.blue,
        'screen': const CurrencyTimeConverterScreen(),
      },
      {
        'title': 'AI Repair Assistant',
        'subtitle': 'LLM-powered smartphone diagnostics & pinout assistant',
        'icon': Icons.smart_toy_outlined,
        'color': Colors.purple,
        'screen': const AiAssistantScreen(),
      },
      {
        'title': 'Blockchain Part Verifier',
        'subtitle': 'Verify cryptographic OEM part serial hash on ledger',
        'icon': Icons.verified_user_outlined,
        'color': const Color(0xFF10B981),
        'screen': const BlockchainVerifyScreen(),
      },
      {
        'title': 'GPS Delivery & Tracking',
        'subtitle': 'Geolocator and OpenStreetMap LBS live courier tracking',
        'icon': Icons.map_outlined,
        'color': Colors.teal,
        'screen': const MapTrackingScreen(),
      },
      {
        'title': 'Inventory Sorter Minigame',
        'subtitle': 'Interactive accelerometer and gyroscope sensor game',
        'icon': Icons.sports_esports_outlined,
        'color': Colors.orange,
        'screen': const InventorySorterGame(),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hardware & Utilities'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tools.length,
        itemBuilder: (context, index) {
          final tool = tools[index];
          final color = tool['color'] as Color;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tool['icon'] as IconData, color: color),
              ),
              title: Text(
                tool['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  tool['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => tool['screen'] as Widget,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
