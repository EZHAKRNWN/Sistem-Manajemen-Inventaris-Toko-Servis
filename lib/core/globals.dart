import 'package:flutter/material.dart';

/// GlobalKey untuk mengakses NavigatorState root tanpa membutuhkan BuildContext langsung.
/// Sangat berguna untuk menangani navigasi global dari lapisan service/interceptor,
/// seperti auto-redirect ke halaman Login saat terjadi sesi kedaluwarsa (HTTP 401 Unauthorized).
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();
