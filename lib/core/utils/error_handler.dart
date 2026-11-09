import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorHandler {
  /// Menerjemahkan pesan error teknis menjadi pesan yang ramah pengguna
  static String parse(dynamic error) {
    if (error == null) return 'Terjadi kendala pada sistem. Silakan coba lagi.';
    final str = error.toString();
    final lower = str.toLowerCase();

    // Autentikasi
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials') ||
        lower.contains('invalid grant')) {
      return 'Email atau password tidak valid (Invalid credentials). Silakan periksa kembali akun Anda.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email Anda belum dikonfirmasi. Periksa kotak masuk email Anda.';
    }
    if (lower.contains('user not found')) {
      return 'Akun dengan email tersebut tidak ditemukan.';
    }
    if (lower.contains('user already registered')) {
      return 'Email tersebut sudah terdaftar di sistem. Gunakan email lain.';
    }

    // Jaringan / Internet
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network') ||
        lower.contains('clientexception') ||
        lower.contains('connection refused') ||
        lower.contains('timed out')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda lalu coba lagi.';
    }

    // Database / Foreign Key / Unique Constraint
    if (lower.contains('foreign key') || lower.contains('23503')) {
      return 'Data ini tidak dapat dihapus karena masih terkait dengan data lainnya.';
    }
    if (lower.contains('duplicate key') || lower.contains('23505')) {
      return 'Data ini sudah ada sebelumnya. Gunakan data yang berbeda.';
    }

    // Limit permintaan
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Terlalu banyak permintaan dalam waktu singkat. Mohon tunggu beberapa saat.';
    }

    // Fallback: hapus prefix exception bawaan
    final clean = str
        .replaceFirst('Exception: ', '')
        .replaceFirst('AuthException: ', '')
        .replaceFirst('PostgrestException(message: ', '')
        .replaceFirst('PostgrestException: ', '')
        .trim();

    return clean.isNotEmpty ? clean : 'Terjadi kendala pada sistem. Silakan coba lagi.';
  }

  /// Menampilkan SnackBar Error yang modern, floating, dan ber-icon
  static void showError(BuildContext context, dynamic error, {String? prefix}) {
    final parsed = parse(error);
    final message = prefix != null ? '$prefix: $parsed' : parsed;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.destructive,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Menampilkan SnackBar Sukses yang modern, floating, dan ber-icon
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Menampilkan SnackBar Peringatan (Warning)
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

