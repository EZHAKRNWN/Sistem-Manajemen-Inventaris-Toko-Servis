// ============================================================================
// FITUR: ASISTEN DIAGNOSTIK PERBAIKAN AI (AI ASSISTANT SCREEN)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Integrasi AI Mutakhir (Groq Cloud LLM): Menggunakan LLM (Llama 3.3 / Qwen) via Groq Inference Engine
//    untuk penalaran cepat pemecahan masalah teknis smartphone (kurang dari 1 detik).
// 2. Multimodal Hardware Vision: Teknisi dapat mengambil foto langsung komponen fisik rusak (Kamera/Galeri)
//    untuk dianalisis secara visual oleh model AI.
// 3. Quick Troubleshooting Chips: Template pertanyaan cepat seputar kerusakan umum (boot loop, short circuit, water damage, dll).
// 4. Rendering Markdown Interaktif: Hasil diagnosa disajikan rapi dengan styling Markdown (tahapan langkah perbaikan, kode pinout, dsb).
// 5. System Prompt Khusus Teknisi: AI diinstruksikan bersikap sebagai ahli mikrosolder & reparasi hardware profesional.
// ============================================================================

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartfix_mobile/features/tools/services/ai_proxy_service.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final AiProxyService _aiProxyService = AiProxyService();

  // Status proses generasi respon AI
  bool _isGenerating = false;

  // File gambar komponen yang dipilih untuk dianalisis AI
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Halo, Rekan Teknisi! 👋 Saya SmartFix AI, asisten diagnostik resmi perbaikan smartphone bengkel SmartFix.\n\n'
          'Saya siap membantu menganalisis kerusakan perangkat keras, panduan mikrosolder, jalur skematik PCB, '
          'penanganan IC, serta estimasi suku cadang. Anda juga dapat melampirkan foto fisik papan PCB atau layar yang rusak untuk dianalisis langsung!',
      'imagePath': null,
    },
  ];

  final List<String> _quickPrompts = [
    'iPhone 13 boot loop, langkah cek apa saja?',
    'Cara aman lepas baterai tanam kembung',
    'Jalur charging Samsung S22 short, pin mana dicek?',
    'HP kemasukan air laut, prosedur awal?',
    'Layar OLED bergaris hijau vertikal, penyebabnya?',
    'Tips solder IC BGA kecil agar tidak over heat',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _selectedImage = picked;
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
  }

  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF262626),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Unggah Foto Komponen / Perangkat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF14B8A6),
                ),
                title: const Text(
                  'Ambil Foto Kamera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: Color(0xFF14B8A6),
                ),
                title: const Text(
                  'Pilih dari Galeri',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// FITUR: Mengirimkan Pertanyaan / Keluhan Servis & Gambar ke Mesin AI Groq
  Future<void> _handleSendPrompt(String text) async {
    final query = text.trim();
    if (query.isEmpty && _selectedImageBytes == null) return;

    final sendingBytes = _selectedImageBytes;
    final sendingPath = _selectedImage?.path;
    _clearSelectedImage();
    _promptController.clear();

    // 1. Tambahkan bubble chat pesan dari sisi teknisi (User)
    setState(() {
      _messages.add({
        'role': 'user',
        'text': query.isNotEmpty
            ? query
            : 'Tolong analisis kondisi fisik perangkat pada foto ini.',
        'imagePath': sendingPath,
        'imageBytes': sendingBytes,
      });
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      String responseText;
      if (sendingPath != null) {
        // Modul 1: AI Visual Diagnostic (Kompresi foto + kirim multipart ke /api/v1/ai/vision-diagnose)
        final result = await _aiProxyService.diagnoseImage(
          imageFile: File(sendingPath),
          prompt: query,
        );
        if (result.success) {
          responseText = result.diagnosis ?? 'Analisis visual perangkat selesai.';
        } else {
          responseText = '⚠️ **Gagal Diagnosa Visual**:\n\n${result.errorMessage}\n\n'
              '_Pastikan server Laravel aktif dan endpoint `/api/v1/ai/vision-diagnose` dapat diakses._';
        }
      } else {
        // Teks diagnostik cepat melalui endpoint proxy
        final result = await _aiProxyService.sendTextMessage(
          message: '[Pertanyaan Diagnostik Hardware]: $query',
        );
        if (result.success) {
          responseText = '${result.reply}\n\n'
              '💡 *Tip: Untuk diagnosa visual hardware yang lebih akurat, lampirkan foto fisik komponen menggunakan ikon kamera/galeri.*';
        } else {
          responseText = '⚠️ **Gagal Terhubung ke Layanan AI**:\n\n${result.errorMessage}\n\n'
              '_Untuk konsultasi SOP atau operasional teks murni, Anda juga dapat menggunakan modul SmartFix Assistant._';
        }
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text': responseText,
            'imagePath': null,
          });
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'text':
                'Maaf Bos, terjadi kendala saat memproses diagnosa visual: $e',
            'imagePath': null,
          });
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('AI Visual Diagnostic'),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Flexible(
                  child: Text(
                    'Multimodal Hardware • Proxy Laravel Sanctum',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Percakapan',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'text': 'Percakapan direset! 🔄 Ada komponen atau kendala servis yang ingin dianalisis, Bos?',
                  'imagePath': null,
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: _quickPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(prompt, style: const TextStyle(fontSize: 12)),
                      avatar: const Icon(Icons.auto_awesome, size: 14),
                      onPressed: () => _handleSendPrompt(prompt),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final String? imagePath = msg['imagePath'] as String?;
                final Uint8List? imageBytes = msg['imageBytes'] as Uint8List?;

                return Align(
                  alignment: isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.84,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? const Color(0xFF0F766E)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(16),
                        bottomLeft: !isUser
                            ? const Radius.circular(0)
                            : const Radius.circular(16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.smart_toy_outlined,
                              size: 14,
                              color: isUser
                                  ? Colors.white70
                                  : const Color(0xFF14B8A6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'Teknisi' : 'SmartFix AI (Groq Vision)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUser
                                    ? Colors.white70
                                    : const Color(0xFF14B8A6),
                              ),
                            ),
                          ],
                        ),

                        if (imageBytes != null ||
                            (imagePath != null && imagePath.isNotEmpty)) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageBytes != null
                                ? Image.memory(
                                    imageBytes,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : (!kIsWeb && File(imagePath!).existsSync())
                                ? Image.file(
                                    File(imagePath),
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],

                        const SizedBox(height: 8),
                        if (isUser)
                          SelectableText(
                            msg['text'] as String? ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          )
                        else
                          MarkdownBody(
                            data: msg['text'] as String? ?? '',
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              p: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 14,
                                height: 1.45,
                              ),
                              strong: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              h1: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                              ),
                              h2: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              h3: TextStyle(
                                color: const Color(0xFF14B8A6),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              listBullet: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 14,
                              ),
                              code: TextStyle(
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                color: theme.colorScheme.primary,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                              codeblockDecoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isGenerating)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF14B8A6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SmartFix AI sedang menganalisis hardware & skematik...',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_selectedImageBytes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _selectedImageBytes!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Foto Perangkat Dilampirkan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Akan dianalisis oleh SmartFix AI',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clearSelectedImage,
                  ),
                ],
              ),
            ),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFF14B8A6),
                  ),
                  tooltip: 'Lampirkan Foto Kondisi Fisik',
                  onPressed: _showImagePickerModal,
                ),
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _handleSendPrompt(val),
                    decoration: InputDecoration(
                      hintText: 'Tanya perbaikan smartphone atau foto...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  onPressed: () => _handleSendPrompt(_promptController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
