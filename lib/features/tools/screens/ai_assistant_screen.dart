import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;
  String _apiKey = '';

  GenerativeModel? _model;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('gemini_api_key') ?? '';
      _apiKeyController.text = _apiKey;
    });
    if (_apiKey.isNotEmpty) {
      _initModel();
    }
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    setState(() {
      _apiKey = key;
    });
    _initModel();
  }

  void _initModel() {
    if (_apiKey.isEmpty) return;
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(
          'Kamu adalah asisten teknisi perbaikan smartphone yang ahli, bernama SmartFix AI. '
          'Kamu selalu berbicara dengan Bahasa Indonesia yang natural, ramah, dan membantu, layaknya teman teknisi (menggunakan kata sapaan "Bos"). '
          'Berikan jawaban yang akurat, terstruktur, dan praktis terkait perbaikan hardware, software, '
          'solder, mikroskop, skematik, dan inventaris toko servis HP. '
          'Gunakan emoji jika sesuai untuk memperjelas pesan.'),
    );
    _chatSession = _model!.startChat(history: [
      Content.model([
        TextPart('Halo, Bos! 👋 Saya asisten diagnostik SmartFix kamu. '
            'Tanya aja soal kerusakan HP, prosedur servis, pinout IC, '
            'atau estimasi stok sparepart — saya bantu sebisa mungkin! 😊')
      ])
    ]);
  }

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Halo, Bos! 👋 Saya asisten diagnostik SmartFix kamu. '
          'Tanya aja soal kerusakan HP, prosedur servis, pinout IC, '
          'atau estimasi stok sparepart — saya bantu sebisa mungkin! 😊',
    },
  ];

  final List<String> _quickPrompts = [
    'iPhone 13 boot loop, kenapa ya?',
    'Cara aman lepas baterai bengkak',
    'Pinout IC charging Samsung S22',
    'HP kena air, langkah pertama apa?',
    'Layar OLED bergaris, penyebabnya?',
    'Tips solder IC kecil tanpa hot air',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendPrompt(String text) async {
    if (_apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan API Key Gemini terlebih dahulu di pengaturan (ikon kunci).')),
      );
      return;
    }

    final query = text.trim();
    if (query.isEmpty) return;

    _promptController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      if (_chatSession == null) _initModel();
      final response = await _chatSession!.sendMessage(Content.text(query));
      
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': response.text ?? 'Maaf Bos, saya tidak bisa memproses permintaan tersebut.'});
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'role': 'assistant', 'text': 'Maaf Bos, terjadi kesalahan: $e'});
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

  // Simulated response logic removed. Gemini API integrated above.

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Diagnostik Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Atur API Key',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pengaturan API Key'),
                  content: TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'Masukkan API Key Anda',
                    ),
                    obscureText: true,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _saveApiKey(_apiKeyController.text.trim());
                        Navigator.pop(context);
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'text': 'Chat direset! 🔄 Ada yang bisa saya bantu hari ini, Bos?',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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

          // Message Bubbles
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                        bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
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
                              color: isUser ? Colors.white70 : theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isUser ? 'Teknisi' : 'SmartFix AI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isUser ? Colors.white70 : theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SelectableText(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.white : theme.colorScheme.onSurface,
                            fontSize: 14,
                            height: 1.4,
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
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SmartFix AI sedang menganalisis skematik...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Prompt Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) => _handleSendPrompt(val),
                    decoration: InputDecoration(
                      hintText: 'Tanya soal servis HP atau diagnostik...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send_rounded),
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
