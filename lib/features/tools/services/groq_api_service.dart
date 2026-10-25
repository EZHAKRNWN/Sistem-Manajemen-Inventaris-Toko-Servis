// ============================================================================
// FITUR: SERVICE KOMUNIKASI AI DIAGNOSTIK GROQ CLOUD (GROQ API SERVICE)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Koneksi ke Groq Cloud Inference Engine: Memanfaatkan model LLM (Qwen 3.8-27B / GPT-OSS 120B)
//    untuk penalaran teknis ultra-cepat (< 1 detik per respons).
// 2. System Prompt Guardrails: AI dibatasi hanya boleh menjawab pertanyaan seputar perbaikan
//    smartphone. Jika pertanyaan di luar konteks servis, AI menolak dengan sopan (Topic Restriction).
// 3. Multimodal Vision (Base64 Image Upload): Mendukung pengiriman foto komponen rusak
//    dalam format Base64 untuk dianalisis secara visual oleh model AI.
// 4. Fallback Model Otomatis: Jika model utama tidak tersedia (404/400), secara otomatis
//    beralih ke model cadangan tanpa mengganggu pengalaman pengguna.
// 5. Singleton Pattern & Chat History: Menggunakan pola Singleton agar sesi percakapan
//    terjaga selama aplikasi aktif (multi-turn conversation memory).
// ============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

class GroqApiService {
  // Endpoint REST API Groq Cloud (OpenAI-compatible format)
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // API Key autentikasi ke layanan Groq Cloud (disimpan secara aman di backend / env)
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'GROQ_API_KEY_SECURED_ON_BACKEND',
  );

  // Model utama: Qwen 3.8-27B (reasoning cepat)
  static const String modelName = 'qwen/qwen3.8-27b';
  // Model cadangan jika model utama tidak tersedia
  static const String fallbackModel = 'openai/gpt-oss-120b';

  /// FITUR: System Prompt Guardrails — Membatasi topik AI hanya seputar perbaikan smartphone
  static const String systemPrompt =
      'Anda adalah SmartFix AI, asisten diagnostik perbaikan smartphone profesional. '
      'Tugas utama Anda HANYA membantu teknisi dalam mendiagnosis kerusakan hardware/software HP, '
      'prosedur servis, pinout IC, estimasi waktu/stok sparepart, dan analisis perbaikan. '
      'Jika diberikan foto/gambar, analisis kondisi fisik komponen secara detail. '
      'ATURAN KETAT: Jika pengguna bertanya di luar konteks perbaikan smartphone atau sistem SmartFix, '
      'tolak secara sopan dan arahkan kembali ke topik servis.';

  static String get baseUrl => _baseUrl;
  static String get apiKey => _apiKey;

  /// FITUR: Singleton Pattern — Menjamin hanya ada satu instance service AI sepanjang siklus aplikasi
  static final GroqApiService _instance = GroqApiService._internal();
  factory GroqApiService({Dio? dio}) {
    if (dio != null) {
      _instance._dio = dio;
    }
    return _instance;
  }

  GroqApiService._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
      ),
    );
    _initHistory();
  }

  late Dio _dio;
  Dio get dio => _dio;

  // Riwayat percakapan multi-turn (memori konteks sesi chat AI)
  final List<Map<String, dynamic>> _messagesHistory = [];
  List<Map<String, dynamic>> get messagesHistory =>
      List.unmodifiable(_messagesHistory);

  /// Menginisialisasi riwayat chat dengan System Prompt
  void _initHistory() {
    _messagesHistory.clear();
    _messagesHistory.add({'role': 'system', 'content': systemPrompt});
  }

  /// FITUR: Membuat atau melanjutkan sesi percakapan AI
  void getChatSession({bool forceNew = false}) {
    if (_messagesHistory.isEmpty || forceNew) {
      _initHistory();
    }
  }

  /// FITUR: Membentuk Pesan Multimodal (Teks + Gambar Base64)
  /// Jika ada gambar, akan dikonversi ke Base64 dan dikirim bersama teks pertanyaan
  static Map<String, dynamic> createUserMessage({
    required String prompt,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) {
    final query = prompt.trim();
    if (imageBytes != null && imageBytes.isNotEmpty) {
      final base64Image = base64Encode(imageBytes);
      final text = query.isNotEmpty
          ? query
          : 'Tolong analisis kondisi fisik komponen atau perangkat smartphone pada foto terlampir ini.';

      return {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': text},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
          },
        ],
      };
    } else {
      return {'role': 'user', 'content': query};
    }
  }

  /// FITUR: Mengirim Pesan ke API Groq Cloud & Menerima Respons Diagnostik AI
  /// Alur: Buat pesan -> Kirim ke model utama -> Jika gagal, fallback ke model cadangan
  Future<String> sendMessage({
    required String prompt,
    Uint8List? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    final hasImage = imageBytes != null && imageBytes.isNotEmpty;
    final userMessage = createUserMessage(
      prompt: prompt,
      imageBytes: imageBytes,
      mimeType: mimeType,
    );

    final historyMessage = hasImage
        ? {
            'role': 'user',
            'content': prompt.trim().isNotEmpty
                ? prompt.trim()
                : 'Analisis foto komponen smartphone.',
          }
        : userMessage;

    _messagesHistory.add(historyMessage);

    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };

    final visionMessages = hasImage
        ? [
            {'role': 'system', 'content': systemPrompt},
            userMessage,
          ]
        : _messagesHistory;

    Future<Response<dynamic>> sendRequest(
      String targetModel,
      List<Map<String, dynamic>> msgs,
    ) {
      return _dio.post(
        _baseUrl,
        options: Options(headers: headers, responseType: ResponseType.json),
        data: {'model': targetModel, 'messages': msgs, 'max_tokens': 1024},
      );
    }

    try {
      Response<dynamic> response;
      try {
        // Percobaan pertama: kirim ke model utama (Qwen)
        response = await sendRequest(modelName, visionMessages);
      } on DioException catch (dioErr) {
        final errCode = dioErr.response?.data?['error']?['code'];
        final statusCode = dioErr.response?.statusCode;

        // Fallback otomatis jika model utama tidak tersedia
        if (statusCode == 404 ||
            errCode == 'model_not_found' ||
            statusCode == 400 ||
            statusCode == 422) {
          final fallbackMsgs = hasImage
              ? [
                  {'role': 'system', 'content': systemPrompt},
                  {
                    'role': 'user',
                    'content':
                        '[Teknisi mengirim foto perangkat] ${prompt.trim().isNotEmpty ? prompt.trim() : "Tolong analisis kerusakan pada perangkat smartphone ini."}',
                  },
                ]
              : _messagesHistory;
          response = await sendRequest(fallbackModel, fallbackMsgs);
        } else {
          rethrow;
        }
      }

      // Parsing respons JSON dari Groq Cloud (format OpenAI-compatible)
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        String? assistantResponse;

        if (data is Map<String, dynamic>) {
          final choices = data['choices'] as List<dynamic>?;
          if (choices != null && choices.isNotEmpty) {
            final firstChoice = choices[0] as Map<String, dynamic>?;
            final message = firstChoice?['message'] as Map<String, dynamic>?;
            assistantResponse = message?['content'] as String?;
          }
        }

        if (assistantResponse != null && assistantResponse.isNotEmpty) {
          _messagesHistory.add({
            'role': 'assistant',
            'content': assistantResponse,
          });
          return assistantResponse;
        }
      }

      return 'Maaf Bos, tidak ada respons yang dapat dihasilkan oleh Groq AI.';
    } on DioException catch (e) {
      if (_messagesHistory.isNotEmpty &&
          _messagesHistory.last == historyMessage) {
        _messagesHistory.removeLast();
      }

      final errorData = e.response?.data;
      String errorMsg;
      if (errorData is Map<String, dynamic> &&
          errorData.containsKey('error') &&
          errorData['error'] is Map<String, dynamic>) {
        errorMsg = errorData['error']['message']?.toString() ?? e.toString();
      } else if (errorData != null) {
        errorMsg = errorData.toString();
      } else {
        errorMsg = e.message ?? 'Koneksi bermasalah';
      }

      return 'Gagal terhubung ke Groq AI: $errorMsg';
    } catch (e) {
      if (_messagesHistory.isNotEmpty &&
          _messagesHistory.last == historyMessage) {
        _messagesHistory.removeLast();
      }
      return 'Terjadi kendala pada layanan AI: $e';
    }
  }

  /// FITUR: Mereset Seluruh Riwayat Percakapan AI (Mulai Sesi Baru)
  void resetChat() {
    _initHistory();
  }
}

/// Alias type agar dapat dipanggil sebagai SmartFixAiService di file lain
typedef SmartFixAiService = GroqApiService;
