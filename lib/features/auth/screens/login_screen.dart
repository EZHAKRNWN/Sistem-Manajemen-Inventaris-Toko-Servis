import 'package:flutter/material.dart';
import 'package:smartfix_mobile/core/api_service.dart';
import 'package:smartfix_mobile/core/auth_helper.dart';
import 'package:smartfix_mobile/core/notification_helper.dart';
import 'package:smartfix_mobile/features/auth/widgets/biometric_btn.dart';
import 'package:smartfix_mobile/main_layout.dart';

/// Halaman Login utama aplikasi SmartFix Mobile.
/// Fitur ini memenuhi kriteria projek PAM:
/// 1. Autentikasi pengguna berbasis REST API & Laravel Sanctum Bearer Token
/// 2. Integrasi Login Biometrik (Fingerprint / Face ID) menggunakan hardware sensor
/// 3. Validasi formulir (format email regex, panjang minimal password)
/// 4. Notifikasi lokal selamat datang saat autentikasi berhasil
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controller form & text field
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final AuthHelper _authHelper = AuthHelper();
  final ApiService _apiService = ApiService();

  // Animasi fade-in saat pertama kali layar dimuat
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  // Warna tema Industrial-Tech
  static const Color _bgColor = Color(0xFF1E1E1E);
  static const Color _surfaceColor = Color(0xFF2A2A2A);
  static const Color _teal = Color(0xFF14B8A6);
  static const Color _tealDark = Color(0xFF0F766E);
  static const Color _textPrimary = Color(0xFFF5F5F5);
  static const Color _textSecondary = Color(0xFFB0B0B0);

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller animasi fade-in
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // Mengisi otomatis email jika sebelumnya pernah login dengan biometrik
    _loadSavedAccount();
  }

  /// Membaca email yang tersimpan aman untuk memudahkan proses login berikutnya
  Future<void> _loadSavedAccount() async {
    final creds = await _authHelper.getBiometricCredentials();
    if (creds != null && creds['email'] != null && mounted) {
      if (_emailController.text.isEmpty) {
        setState(() {
          _emailController.text = creds['email']!;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  /// Menangani alur setelah login berhasil (simpan sesi, picu notifikasi, dan buka MainLayout)
  Future<void> _onLoginSuccess(String token, String username) async {
    await _authHelper.setSession(token: token, username: username);

    // Memicu notifikasi lokal selamat datang
    NotificationHelper().showNotification(
      id: 101,
      title: 'Selamat Datang, $username!',
      body: 'Anda berhasil masuk dengan aman ke SmartFix Mobile.',
    );

    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const MainLayout()));
  }

  /// Menangani login manual menggunakan email dan kata sandi via API REST
  Future<void> _handlePasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Request autentikasi ke backend Laravel Sanctum
      final response = await _apiService.login(email, password);

      final String username =
          (response['user'] is Map
              ? (response['user']['name'] as String?)
              : null) ??
          email.split('@').first;

      final String token =
          (response['token'] ??
                  response['access_token'] ??
                  (response['data'] is Map
                      ? response['data']['token']
                      : null) ??
                  '')
              as String;

      // Simpan kredensial terenkripsi agar dapat digunakan untuk login cepat biometrik berikutnya
      await _authHelper.saveBiometricCredentials(
        email: email,
        password: password,
        username: username,
      );

      if (!mounted) return;
      await _onLoginSuccess(token, username);
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } catch (e) {
      if (!mounted) return;
      _showError(
        'Login gagal. Silakan periksa kredensial atau koneksi jaringan Anda.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menangani login cepat menggunakan sensor biometrik (Fingerprint / Face ID)
  Future<void> _handleBiometricSuccess() async {
    // Ambil kredensial akun yang tersimpan secara terenkripsi di Secure Storage
    final savedCreds = await _authHelper.getBiometricCredentials();
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : savedCreds?['email'];
    final password = _passwordController.text.isNotEmpty
        ? _passwordController.text
        : savedCreds?['password'];

    // Validasi apakah pengguna sudah pernah login sebelumnya
    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      _showError(
        'Belum ada akun tersimpan untuk biometrik. Silakan masuk menggunakan Email dan Password terlebih dahulu minimal 1 kali.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Login langsung ke backend Sanctum dengan kredensial terverifikasi sensor biometrik
      final response = await _apiService.login(email, password);

      final String username =
          (response['user'] is Map
              ? (response['user']['name'] as String?)
              : null) ??
          savedCreds?['username'] ??
          email.split('@').first;

      final String token =
          (response['token'] ??
                  response['access_token'] ??
                  (response['data'] is Map
                      ? response['data']['token']
                      : null) ??
                  '')
              as String;

      // Perbarui kredensial tersimpan
      await _authHelper.saveBiometricCredentials(
        email: email,
        password: password,
        username: username,
      );

      if (!mounted) return;
      await _onLoginSuccess(token, username);
    } on Exception catch (e) {
      if (!mounted) return;
      _showError(
        'Autentikasi biometrik gagal: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Login biometrik gagal menghubungi server backend.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Menampilkan floating SnackBar merah untuk pesan error
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28.0,
              vertical: 20.0,
            ),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo & Branding SmartFix
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [_teal, _tealDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _teal.withValues(alpha: 0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.build_circle,
                          size: 46,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Judul Aplikasi
                    const Text(
                      'SmartFix Mobile',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sistem Inventaris & Perbaikan Smartphone',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: _textSecondary),
                    ),
                    const SizedBox(height: 40),

                    // Input Field: Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: _textPrimary),
                      decoration: _inputDecoration(
                        label: 'Email',
                        hint: 'anda@contoh.com',
                        icon: Icons.email_outlined,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Silakan masukkan email Anda';
                        }
                        final emailRegex = RegExp(
                          r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(val.trim())) {
                          return 'Silakan masukkan alamat email yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Input Field: Kata Sandi
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: _textPrimary),
                      decoration:
                          _inputDecoration(
                            label: 'Kata Sandi',
                            hint: '••••••••',
                            icon: Icons.lock_outline,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _textSecondary,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Silakan masukkan kata sandi Anda';
                        }
                        if (val.length < 4) {
                          return 'Kata sandi minimal 4 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Tombol Submit Login Manual
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_teal, _tealDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _teal.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handlePasswordLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Garis Pemisah (Divider) ATAU
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: _textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'ATAU',
                            style: TextStyle(
                              color: _textSecondary.withValues(alpha: 0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: _textSecondary.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Opsi Login Biometrik (Fingerprint / Face ID)
                    BiometricBtn(
                      onSuccess: _handleBiometricSuccess,
                      onError: (msg) => _showError(msg),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Helper styling dekorasi text field input form
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: _teal, size: 22),
      filled: true,
      fillColor: _surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _textSecondary.withValues(alpha: 0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _teal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
