// ============================================================================
// FITUR: PUSAT UTILITAS TEKNIS & INTEGRASI FITUR LANJUTAN (TOOLS HUB SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Hub Navigasi Utilitas Lengkap: Menjadi pusat akses untuk 5 fitur unggulan aplikasi SmartFix.
// 2. Kategori Keamanan Kriptografi: Menyediakan akses ke modul Verifikasi Blockchain Ledger (SHA-256).
// 3. Kategori AI & Kecerdasan Buatan: Mengarahkan teknisi ke Asisten AI Diagnostik Servis (Groq Cloud).
// 4. Kategori Konversi Kurs & Waktu: Membantu kalkulasi impor suku cadang global (IDR, USD, EUR, CNY, JPY)
//    serta sinkronisasi zona waktu (WIB, WITA, WIT, London, CST, JST, EST).
// 5. Kategori Hardware & Sensor: Mengintegrasikan Peta Navigasi Lokasi Gudang (LBS) dan Mini-game Gyroscope.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:smartfix_mobile/features/location/screens/map_tracking_screen.dart';
import 'package:smartfix_mobile/features/minigame/screens/inventory_sorter_game.dart';
import 'package:smartfix_mobile/features/tools/screens/ai_assistant_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/blockchain_verify_screen.dart';
import 'package:smartfix_mobile/features/tools/screens/currency_time_converter.dart';
import 'package:smartfix_mobile/features/tools/screens/smartfix_text_chat_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

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
        'category': 'Keamanan & Asal Kriptografi',
        'items': [
          {
            'title': 'Pemverifikasi Part Blockchain',
            'subtitle': 'Verifikasi hash SHA-256 kriptografi dan audit blok ledger rantai pasokan',
            'badge': 'SHA-256',
            'badgeColor': _teal,
            'icon': Icons.security_rounded,
            'accentColor': _teal,
            'screen': const BlockchainVerifyScreen(),
          },
        ],
      },
      {
        'category': 'Kecerdasan & Diagnostik AI',
        'items': [
          {
            'title': 'AI Visual Diagnostic',
            'subtitle': 'Diagnostik visual kerusakan fisik smartphone & motherboard via foto kamera/galeri',
            'badge': 'AI Vision',
            'badgeColor': Colors.purpleAccent,
            'icon': Icons.document_scanner_outlined,
            'accentColor': Colors.purpleAccent,
            'screen': const AiAssistantScreen(),
          },
          {
            'title': 'SmartFix Assistant',
            'subtitle': 'Konsultasi SOP bengkel, estimasi biaya servis, garansi & alur kerja teknisi (Teks Murni)',
            'badge': 'Text LLM',
            'badgeColor': _teal,
            'icon': Icons.chat_bubble_outline_rounded,
            'accentColor': _teal,
            'screen': const SmartFixTextChatScreen(),
          },
          {
            'title': 'Zona Waktu & Jam Kerja Suplier',
            'subtitle':
                'Pantau jam operasional suplier internasional (London, Shenzhen, Tokyo, NY) & zona waktu WIB, WITA, WIT',
            'badge': 'Jam Dunia',
            'badgeColor': Colors.amber,
            'icon': Icons.schedule_rounded,
            'accentColor': Colors.amber,
            'screen': const CurrencyTimeConverterScreen(),
          },
        ],
      },
      {
        'category': 'Logistik & Sensor Perangkat Keras',
        'items': [
          {
            'title': 'Lokasi Gudang Sparepart',
            'subtitle': 'Temukan gudang suku cadang di Yogyakarta & buka rute via Google Maps',
            'badge': 'Gudang DIY',
            'badgeColor': Colors.tealAccent,
            'icon': Icons.warehouse_outlined,
            'accentColor': Colors.tealAccent,
            'screen': const MapTrackingScreen(),
          },
          {
            'title': 'Tangkap Sparepart (Sensor Gyro) ⚡',
            'subtitle': 'Tangkap komponen smartphone yang berjatuhan dengan memiringkan ponsel — uji refleks teknisi!',
            'badge': 'Mini Game Gyro',
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
              'Utilitas Teknis',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Alat rekayasa, diagnostik & kriptografi',
              style: TextStyle(color: _textSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
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
                  child: const Icon(
                    Icons.handyman_rounded,
                    color: _teal,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toolkit Operasi Bengkel',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Semua modul diagnostik, logistik, dan verifikasi beroperasi.',
                        style: TextStyle(color: _textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

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
                                            color: badgeColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color: badgeColor.withValues(
                                                alpha: 0.4,
                                              ),
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
