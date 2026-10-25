// ============================================================================
// FITUR: SMARTFIX ASSISTANT — TEXT LLM MURNI (KONSULTASI OPERASIONAL & SOP)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Text LLM Murni (Full Ketik): Antarmuka obrolan teks terisolasi khusus konsultasi
//    SOP bengkel, estimasi biaya servis, regulasi garansi, dan panduan teknis tanpa
//    fitur unggah foto.
// 2. Terkoneksi ke Backend Laravel (Sanctum): Memanggil POST /api/v1/ai/text-chat
//    melalui AiProxyService sehingga Groq API Key aman tersembunyi di server.
// 3. Multi-turn Conversation Memory: Riwayat percakapan dikirim secara kontekstual
//    ke backend untuk penalaran bersambung.
// 4. Quick Workshop SOP Chips: Menyediakan template pertanyaan cepat terkait alur kerja
//    bengkel reparasi smartphone harian.
// 5. Rich Markdown Rendering: Jawaban terstruktur rapi dengan poin, tabel, dan penekanan
//    istilah teknis.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:smartfix_mobile/features/tools/services/ai_proxy_service.dart';

class SmartFixTextChatScreen extends StatefulWidget {
  const SmartFixTextChatScreen({super.key});

  @override
  State<SmartFixTextChatScreen> createState() => _SmartFixTextChatScreenState();
}

class _SmartFixTextChatScreenState extends State<SmartFixTextChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AiProxyService _aiProxyService = AiProxyService();

  // Status proses generasi respon AI
  bool _isGenerating = false;

  // Daftar bubble percakapan UI
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Halo! Saya **SmartFix Assistant** 💬\n\n'
          'Saya siap membantu konsultasi seputar **SOP bengkel, estimasi biaya servis, '
          'penanganan komplain, klausul garansi, dan operasional harian bengkel SmartFix**.\n\n'
          '*Catatan: Modul ini dikhususkan untuk teks murni (tanpa unggahan foto).*',
    },
  ];

  // Riwayat konteks percakapan untuk dikirim ke API multi-turn
  final List<Map<String, String>> _chatHistory = [];

  // Chip template pertanyaan cepat SOP bengkel
  final List<String> _quickPrompts = [
    'SOP penerimaan HP baru dari pelanggan?',
    'Cara hitung biaya servis LCD dengan markup wajar?',
    'Klausul nota garansi perbaikan yang aman?',
    'Langkah mitigasi saat HP mati total di tangan teknisi?',
    'Tips mengelola antrian servis agar tidak menumpuk?',
    'Standard waktu pengerjaan ganti baterai vs IC?',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  /// Reset sesi percakapan untuk memulai topik konsultasi baru
  void _resetConversation() {
    setState(() {
      _messages.clear();
      _chatHistory.clear();
      _messages.add({
        'role': 'assistant',
        'text':
            'Sesi konsultasi baru telah dimulai. Silakan ajukan pertanyaan seputar '
            'SOP bengkel atau operasional servis smartphone Anda!',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesi obrolan baru berhasil di-reset.'),
        backgroundColor: Color(0xFF0F766E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Mengirim pertanyaan teks ke Backend Laravel (POST /api/v1/ai/text-chat)
  Future<void> _handleSendPrompt(String text) async {
    final query = text.trim();
    if (query.isEmpty || _isGenerating) return;

    _promptController.clear();

    // 1. Tambahkan bubble chat pesan teknisi
    setState(() {
      _messages.add({
        'role': 'user',
        'text': query,
      });
      _isGenerating = true;
    });

    _scrollToBottom();

    // Siapkan history konteks maksimal 10 pertukaran terakhir
    final historyPayload = _chatHistory.length > 10
        ? _chatHistory.sublist(_chatHistory.length - 10)
        : List<Map<String, String>>.from(_chatHistory);

    // 2. Hubungi backend Laravel via AiProxyService
    final result = await _aiProxyService.sendTextMessage(
      message: query,
      history: historyPayload,
    );

    if (!mounted) return;

    if (result.success && result.reply != null) {
      final replyText = result.reply!;
      // Simpan ke riwayat percakapan multi-turn
      _chatHistory.add({'role': 'user', 'content': query});
      _chatHistory.add({'role': 'assistant', 'content': replyText});

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': replyText,
        });
        _isGenerating = false;
      });
    } else {
      final errorMsg = result.errorMessage ?? 'Gagal memproses pesan.';
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text':
              '⚠️ **Gagal Mendapatkan Respons**\n\n$errorMsg\n\n'
              '_Pastikan server Laravel aktif dan endpoint `/api/v1/ai/text-chat` tersedia._',
        });
        _isGenerating = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1E1E1E);
    const surfaceColor = Color(0xFF262626);
    const cardBorderColor = Color(0xFF3B3B3B);
    const teal = Color(0xFF14B8A6);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: teal.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: teal,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SmartFix Assistant',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Text LLM • SOP & Konsultasi Bengkel',
                    style: TextStyle(fontSize: 11, color: Color(0xFFA3A3A3)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Mulai Sesi Baru',
            onPressed: _isGenerating ? null : _resetConversation,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: cardBorderColor, height: 1),
        ),
      ),
      body: Column(
        children: [
          // Banner Info Text LLM Murni
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F766E).withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(color: teal.withValues(alpha: 0.2)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: teal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode Teks Murni: Untuk konsultasi SOP, estimasi biaya & SOP bengkel.',
                    style: TextStyle(fontSize: 11, color: Color(0xFFCCFBF1)),
                  ),
                ),
              ],
            ),
          ),

          // Template Chips (Quick SOP Prompts)
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: _quickPrompts.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = _quickPrompts[index];
                return InkWell(
                  onTap: _isGenerating ? null : () => _handleSendPrompt(prompt),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2B2B2B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: teal.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        prompt,
                        style: const TextStyle(
                          color: Color(0xFFE5E5E5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: cardBorderColor),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildChatBubble(msg['text'] ?? '', isUser);
              },
            ),
          ),

          // Typing Indicator
          if (_isGenerating)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: surfaceColor,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(teal),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SmartFix AI sedang merumuskan jawaban...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input Bar (Hanya Text Field & Send Button - TANPA Opsi Kamera/Galeri)
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 8,
              bottom: MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: const BoxDecoration(
              color: surfaceColor,
              border: Border(top: BorderSide(color: cardBorderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorderColor),
                    ),
                    child: TextField(
                      controller: _promptController,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleSendPrompt,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Ketik pertanyaan SOP atau konsultasi servis...',
                        hintStyle: TextStyle(
                          color: Color(0xFF737373),
                          fontSize: 13,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _isGenerating
                      ? null
                      : () => _handleSendPrompt(_promptController.text),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isGenerating ? Colors.grey.shade800 : teal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (!_isGenerating)
                          BoxShadow(
                            color: teal.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isUser) {
    const teal = Color(0xFF14B8A6);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: teal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: teal.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: teal,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF0F766E) : const Color(0xFF262626),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF14B8A6)
                      : const Color(0xFF3B3B3B),
                ),
              ),
              child: isUser
                  ? Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(
                          color: Color(0xFFEDEDED),
                          fontSize: 13,
                          height: 1.45,
                        ),
                        h1: const TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          color: Color(0xFF5EEAD4),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        strong: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        listBullet: const TextStyle(
                          color: Color(0xFF14B8A6),
                          fontSize: 13,
                        ),
                        code: const TextStyle(
                          color: Color(0xFFFDE047),
                          backgroundColor: Color(0xFF1F1F1F),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF404040)),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F766E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
