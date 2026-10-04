import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';

/// Reusable biometric authentication button widget
class BiometricBtn extends StatefulWidget {
  final Future<void> Function() onSuccess;
  final Function(String message)? onError;

  const BiometricBtn({
    super.key,
    required this.onSuccess,
    this.onError,
  });

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

  Future<void> _handleBiometricAuth() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final canAuth = await _authHelper.canCheckBiometrics();
      if (!mounted) return;

      if (!canAuth) {
        widget.onError?.call(
          'Biometrics not available or not enrolled. Please use your email and password to sign in.',
        );
        return;
      }

      final success = await _authHelper.authenticateWithBiometrics(
        reason: 'Scan your fingerprint/face or use device PIN to sign into SmartFix',
      );
      if (!mounted) return;

      if (success) {
        await widget.onSuccess();
      } else {
        widget.onError?.call(
          'Biometric verification was cancelled. You can sign in using your password above.',
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'auth_in_progress') {
        widget.onError?.call('Authentication already in progress. Please try again.');
      } else if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
        widget.onError?.call('Biometrics temporarily locked due to failed attempts. Please use your password.');
      } else if (e.code == 'PasscodeNotSet' || e.code == 'NotEnrolled') {
        widget.onError?.call('No screen lock or biometrics configured. Please sign in with password.');
      } else {
        widget.onError?.call('Biometric verification cancelled. Please use password to sign in.');
      }
    } catch (e) {
      if (!mounted) return;
      widget.onError?.call('Biometric authentication error. Please sign in with password.');
    } finally {
      // Guarantee that the loading spinner is stopped in all scenarios
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
        _isChecking ? 'Verifying...' : 'Quick Biometric Sign-In',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      ),
    );
  }
}
