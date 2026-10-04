import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';

/// Reusable biometric authentication button widget
class BiometricBtn extends StatefulWidget {
  final VoidCallback onSuccess;
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

  Future<void> _handleBiometricAuth() async {
    setState(() => _isChecking = true);
    final canAuth = await _authHelper.canCheckBiometrics();

    if (!canAuth) {
      setState(() => _isChecking = false);
      widget.onError?.call('Biometrics not available or not enrolled on this device.');
      return;
    }

    final success = await _authHelper.authenticateWithBiometrics(
      reason: 'Please scan fingerprint or face to sign into SmartFix',
    );

    setState(() => _isChecking = false);

    if (success) {
      widget.onSuccess();
    } else {
      widget.onError?.call('Biometric verification failed.');
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
      label: const Text(
        'Quick Biometric Sign-In',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
      ),
    );
  }
}
