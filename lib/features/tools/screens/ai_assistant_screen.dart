import 'package:flutter/material.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isGenerating = false;

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'text':
          'Hello! I am your SmartFix AI Diagnostics Assistant. Ask me anything about smartphone repair procedures, IC component pinouts, or inventory supply estimations.',
    },
  ];

  final List<String> _quickPrompts = [
    'Diagnose iPhone 13 boot loop issue',
    'Samsung S22 charging IC pinout',
    'How to safely remove swollen Li-ion battery',
    'Recommend torque specs for Apple pentalobe screws',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSendPrompt(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    _promptController.clear();
    setState(() {
      _messages.add({'role': 'user', 'text': query});
      _isGenerating = true;
    });

    _scrollToBottom();

    // Simulate AI response delay
    await Future.delayed(const Duration(milliseconds: 1200));

    String aiReply = _generateSimulatedResponse(query);

    if (mounted) {
      setState(() {
        _messages.add({'role': 'assistant', 'text': aiReply});
        _isGenerating = false;
      });
      _scrollToBottom();
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

  String _generateSimulatedResponse(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('boot loop') || lower.contains('bootloop')) {
      return 'For iPhone 13 boot loop:\n1. Check battery terminal VDD_MAIN voltage (~3.8V-4.2V).\n2. Inspect proximity sensor flex for corrosion from moisture.\n3. Try disconnecting ear speaker flex cable before boot.\n4. If Apple logo flashes, test NAND via 3uTools/DFU error code.';
    } else if (lower.contains('battery')) {
      return 'Li-ion Battery Safety Protocol:\n1. Disconnect battery flex cable first before touching any motherboard component.\n2. Apply 99% isopropyl alcohol around adhesive strips.\n3. Never use metallic or sharp pry tools on the pouch.\n4. Store swollen cells in a fire-safe LiPo container.';
    } else {
      return 'SmartFix AI Analysis for "$prompt":\n- Recommended Procedure: Inspect under 40x microscope for SMD solder cracks.\n- Check inventory: Verify availability of replacement flex ribbons in stock.\n- Estimated repair turnaround: 45 - 60 minutes.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Repair Diagnostics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'assistant',
                  'text': 'Chat reset. How can I assist your repair work today?',
                });
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Prompts Horizontal Bar
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
                              isUser ? 'Technician' : 'SmartFix AI',
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
                    'SmartFix AI is analyzing hardware schematic...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Prompt Input Field
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
                      hintText: 'Ask repair question or diagnostic prompt...',
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
