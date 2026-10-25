// ============================================================================
// SERVICE: AI PROXY — Komunikasi AI via Backend Laravel (Server-Side Proxy)
// ----------------------------------------------------------------------------
// Kegunaan untuk Presentasi:
// 1. Keamanan API Key Zero-Exposure: Groq API Key TIDAK pernah disimpan di Flutter / APK.
//    Semua interaksi ke Groq API dilakukan secara terisolasi di server Laravel.
// 2. Kompresi Gambar Otomatis: Menggunakan flutter_image_compress untuk meminimalisir
//    ukuran payload foto hardware sebelum dikirim ke server.
// 3. Dua Endpoint Terpisah Sesuai Arsitektur:
//    - Vision: POST /api/v1/ai/vision-diagnose (multipart/form-data)
//    - Text Chat: POST /api/v1/ai/text-chat (JSON text murni)
// 4. Sanctum Authentication: Token Bearer otomatis disematkan oleh ApiService Interceptor.
// 5. Error Handling Komprehensif: Menangani timeout jaringan bengkel, server down,
//    hingga sesi kedaluwarsa secara ramah teknisi.
// ============================================================================

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:smartfix_mobile/core/api_service.dart';

class AiProxyService {
  final ApiService _api = ApiService();

  // ── Modul 1: AI Visual Diagnostic (Multimodal Hardware) ───────────────────

  /// Mengirimkan foto kerusakan hardware ke backend Laravel
  /// Endpoint: POST /api/v1/ai/vision-diagnose (multipart/form-data)
  Future<AiVisionResult> diagnoseImage({
    required File imageFile,
    String? prompt,
  }) async {
    try {
      // 1. Kompresi foto kerusakan menggunakan flutter_image_compress
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 1024,
        minHeight: 1024,
        quality: 75,
        format: CompressFormat.jpeg,
      );

      if (compressedBytes == null || compressedBytes.isEmpty) {
        throw Exception('Gagal melakukan kompresi foto perangkat.');
      }

      // 2. Bungkus ke MultipartFile
      final multipartImage = MultipartFile.fromBytes(
        compressedBytes,
        filename: 'hardware_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final formData = FormData.fromMap({
        'image': multipartImage,
        if (prompt != null && prompt.trim().isNotEmpty)
          'prompt': prompt.trim(),
      });

      // 3. Kirim request ke backend Laravel melalui Dio instance ApiService
      // Base URL ApiService sudah mengarah ke /api/, jadi endpoint: v1/ai/vision-diagnose
      final response = await _api.dio.post(
        'v1/ai/vision-diagnose',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 60),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return AiVisionResult.success(
            diagnosis: data['diagnosis']?.toString() ?? '',
            modelUsed: data['model_used']?.toString() ?? 'Groq Vision',
            analyzedAt: data['analyzed_at']?.toString(),
          );
        }
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Respons diagnosis tidak valid dari server.';
        return AiVisionResult.failure(message);
      }

      return AiVisionResult.failure('Server tidak mengembalikan respons yang valid.');
    } on DioException catch (e) {
      return AiVisionResult.failure(_formatDioError(e, isVision: true));
    } catch (e) {
      return AiVisionResult.failure('Terjadi kesalahan saat memproses foto: $e');
    }
  }

  // ── Modul 2: SmartFix Assistant (Text LLM Murni Tanpa Foto) ───────────────

  /// Mengirim pertanyaan teks seputar SOP, estimasi biaya, atau manajemen servis
  /// Endpoint: POST /api/v1/ai/text-chat (application/json)
  Future<AiTextResult> sendTextMessage({
    required String message,
    List<Map<String, String>>? history,
  }) async {
    try {
      final payload = <String, dynamic>{
        'message': message.trim(),
        if (history != null && history.isNotEmpty) 'history': history,
      };

      final response = await _api.dio.post(
        'v1/ai/text-chat',
        data: payload,
        options: Options(
          receiveTimeout: const Duration(seconds: 45),
          sendTimeout: const Duration(seconds: 20),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data['success'] == true) {
          return AiTextResult.success(
            reply: data['reply']?.toString() ?? '',
            modelUsed: data['model_used']?.toString() ?? 'Groq Text LLM',
          );
        }
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Gagal mendapatkan balasan dari AI.';
        return AiTextResult.failure(message);
      }

      return AiTextResult.failure('Server tidak mengembalikan respons yang valid.');
    } on DioException catch (e) {
      return AiTextResult.failure(_formatDioError(e, isVision: false));
    } catch (e) {
      return AiTextResult.failure('Terjadi kendala percakapan teks: $e');
    }
  }

  // ── Error Formatter Jaringan Bengkel Fluktuatif ────────────────────────────

  String _formatDioError(DioException e, {required bool isVision}) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Koneksi ke server timeout (waktu koneksi habis). Periksa sinyal Wi-Fi bengkel.';
      case DioExceptionType.sendTimeout:
        return isVision
            ? 'Pengiriman file gambar timeout. Ukuran foto terlalu besar atau jaringan lambat.'
            : 'Pengiriman pesan timeout. Coba periksa koneksi internet Anda.';
      case DioExceptionType.receiveTimeout:
        return isVision
            ? 'AI Vision membutuhkan waktu pemrosesan lebih lama. Silakan ulangi beberapa saat lagi.'
            : 'AI Server membutuhkan waktu lebih lama untuk merespon. Silakan coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server Laravel (${ApiService.baseUrl}). Pastikan service Laravel dan jaringan aktif.';
      default:
        final res = e.response;
        if (res?.data != null && res!.data is Map) {
          final data = res.data as Map;
          if (data['message'] != null) {
            return data['message'].toString();
          }
        }
        if (res?.statusCode == 401) {
          return 'Sesi autentikasi telah berakhir. Silakan login kembali ke akun teknisi Anda.';
        } else if (res?.statusCode == 422) {
          return 'Validasi server gagal. Pastikan format input dan tipe file sesuai.';
        } else if (res?.statusCode == 503) {
          return 'Layanan Groq AI sedang dalam pemeliharaan atau kapasitas penuh. Coba lagi sebentar.';
        } else if (res?.statusCode == 500) {
          return 'Terjadi gangguan internal pada server SmartFix.';
        }
        return e.message ?? 'Terjadi kesalahan komunikasi jaringan.';
    }
  }
}

// ── Model Hasil Diagnostik & Teks ───────────────────────────────────────────

class AiVisionResult {
  final bool success;
  final String? diagnosis;
  final String? errorMessage;
  final String? modelUsed;
  final String? analyzedAt;

  const AiVisionResult._({
    required this.success,
    this.diagnosis,
    this.errorMessage,
    this.modelUsed,
    this.analyzedAt,
  });

  factory AiVisionResult.success({
    required String diagnosis,
    String? modelUsed,
    String? analyzedAt,
  }) {
    return AiVisionResult._(
      success: true,
      diagnosis: diagnosis,
      modelUsed: modelUsed,
      analyzedAt: analyzedAt,
    );
  }

  factory AiVisionResult.failure(String error) {
    return AiVisionResult._(
      success: false,
      errorMessage: error,
    );
  }
}

class AiTextResult {
  final bool success;
  final String? reply;
  final String? errorMessage;
  final String? modelUsed;

  const AiTextResult._({
    required this.success,
    this.reply,
    this.errorMessage,
    this.modelUsed,
  });

  factory AiTextResult.success({
    required String reply,
    String? modelUsed,
  }) {
    return AiTextResult._(
      success: true,
      reply: reply,
      modelUsed: modelUsed,
    );
  }

  factory AiTextResult.failure(String error) {
    return AiTextResult._(
      success: false,
      errorMessage: error,
    );
  }
}
