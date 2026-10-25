import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartfix_mobile/features/tools/services/groq_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GroqApiService (Groq Console Llama 3.3) Unit Tests', () {
    test(
      'GroqApiService has correct Groq API configurations and is singleton',
      () {
        final service1 = GroqApiService();
        final service2 = GroqApiService();

        expect(identical(service1, service2), isTrue);
        expect(
          GroqApiService.apiKey.isNotEmpty,
          isTrue,
        );
        expect(
          GroqApiService.baseUrl,
          'https://api.groq.com/openai/v1/chat/completions',
        );
        expect(GroqApiService.modelName, 'qwen/qwen3.8-27b');
      },
    );

    test('Guardrails system prompt is strictly configured', () {
      expect(
        GroqApiService.systemPrompt,
        contains(
          'SmartFix AI, asisten diagnostik perbaikan smartphone profesional',
        ),
      );
      expect(
        GroqApiService.systemPrompt,
        contains(
          'ATURAN KETAT: Jika pengguna bertanya di luar konteks perbaikan smartphone',
        ),
      );
    });

    test('createUserMessage returns text content when image bytes is null', () {
      final message = GroqApiService.createUserMessage(
        prompt: 'iPhone bootloop solusinya apa?',
      );

      expect(message['role'], 'user');
      expect(message['content'], 'iPhone bootloop solusinya apa?');
    });

    test('createUserMessage returns multimodal structure with base64 when image bytes provided', () {
      final fakeBytes = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final message = GroqApiService.createUserMessage(
        prompt: 'Cek jalur short ini',
        imageBytes: fakeBytes,
        mimeType: 'image/jpeg',
      );

      expect(message['role'], 'user');
      final contents = message['content'] as List<dynamic>;
      expect(contents.length, 2);
      expect(contents[0]['type'], 'text');
      expect(contents[0]['text'], 'Cek jalur short ini');
      expect(contents[1]['type'], 'image_url');
      expect(
        contents[1]['image_url']['url'],
        'data:image/jpeg;base64,${base64Encode(fakeBytes)}',
      );
    });

    test(
      'Session initializes with system prompt and resetChat clears history',
      () {
        final service = GroqApiService();
        service.getChatSession(forceNew: true);

        expect(service.messagesHistory.isNotEmpty, isTrue);
        expect(service.messagesHistory.first['role'], 'system');
        expect(
          service.messagesHistory.first['content'],
          GroqApiService.systemPrompt,
        );

        service.resetChat();
        expect(service.messagesHistory.length, 1);
        expect(service.messagesHistory.first['role'], 'system');
      },
    );

    test('SmartFixAiService typedef points to GroqApiService', () {
      final service = SmartFixAiService();
      expect(service, isA<GroqApiService>());
    });
  });
}
