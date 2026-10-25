import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';

/// Komponen tombol kustom untuk memicu autentikasi biometrik (Fingerprint / Face ID).
/// Digunakan pada layar login untuk memudahkan teknisi masuk ke sistem tanpa mengetik ulang kata sandi.
class BiometricBtn extends StatefulWidget {
  final Future<void> Function() onSuccess;
  final Function(String message)? onError;

  const BiometricBtn({super.key, required this.onSuccess, this.onError});

  @override
  State<BiometricBtn> createState() => _BiometricBtnState();
}

class _BiometricBtnState extends State<BiometricBtn> {
  final AuthHelper _authHelper = AuthHelper();
  bool _isChecking = false;

  @override
  void dispose() {
    _authHelper.stopAuthentication();
    super.dispose();
  }

  /// Menangani proses interaksi dengan sensor biometrik perangkat
  Future<void> _handleBiometricAuth() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      // 1. Memeriksa ketersediaan sensor biometrik pada perangkat
      final canAuth = await _authHelper.canCheckBiometrics();
      if (!mounted) return;

      if (!canAuth) {
        widget.onError?.call(
          'Sensor biometrik tidak tersedia atau belum didaftarkan pada perangkat ini.',
        );
        return;
      }

      // 2. Menampilkan prompt pemindaian sidik jari / wajah
      final success = await _authHelper.authenticateWithBiometrics(
        reason: 'Scan sidik jari atau wajah Anda untuk masuk ke SmartFix',
      );
      if (!mounted) return;

      if (success) {
        await widget.onSuccess();
      } else {
        widget.onError?.call(
          'Verifikasi biometrik dibatalkan. Silakan masuk menggunakan kata sandi.',
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      // Penanganan berbagai kode error spesifik dari platform OS
      if (e.code == 'auth_in_progress') {
        widget.onError?.call(
          'Autentikasi sedang berlangsung. Silakan coba sesaat lagi.',
        );
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        widget.onError?.call(
          'Biometrik terkunci sementara karena beberapa kali salah. Gunakan kata sandi.',
        );
      } else if (e.code == 'PasscodeNotSet' || e.code == 'NotEnrolled') {
        widget.onError?.call(
          'Kunci layar atau biometrik belum dikonfigurasi di perangkat ini.',
        );
      } else {
        widget.onError?.call(
          'Verifikasi biometrik dibatalkan. Silakan gunakan kata sandi.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call(
        'Terjadi kendala biometrik. Silakan masuk dengan kata sandi.',
      );
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton.icon(
      onPressed: _isChecking ? null : _handleBiometricAuth,
      icon: _isChecking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.fingerprint, color: theme.colorScheme.primary, size: 26),
      label: Text(
        _isChecking ? 'Memverifikasi...' : 'Masuk Cepat dengan Biometrik',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
