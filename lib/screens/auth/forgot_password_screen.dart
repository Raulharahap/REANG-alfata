import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showToast("Harap isi alamat email Anda.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.sendResetLink(email);

      if (mounted) {
        // Sukses
        _showToast(
          response['message'] ?? "Link reset terkirim!",
          isError: false,
        );

        // Tampilkan dialog info sebelum kembali
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Cek Email Anda"),
            content: Text(
              "Kami telah mengirimkan link reset password ke $email.\n\n"
              "Silakan buka email dan klik link tersebut untuk membuat password baru.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.pop(context); // Kembali ke Login
                },
                child: const Text("OK, Mengerti"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      animation: StyledToastAnimation.scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ambil tema saat ini (Light/Dark)
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background ikut tema (Putih di Light, Hitam/Abu di Dark)
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Tombol back ikut warna teks tema
        leading: BackButton(color: theme.iconTheme.color),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ikon Gembok Besar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    // Warna lingkaran menyesuaikan mode
                    color: isDarkMode
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset,
                    size: 80,
                    // Warna ikon ikut primary color
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Lupa Password?',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                    // Warna teks otomatis ikut tema
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Jangan khawatir! Masukkan email yang terdaftar, kami akan mengirimkan link untuk mereset password Anda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme
                        .hintColor, // Warna abu-abu yang aman di kedua mode
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Input Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  // Style teks input (agar terlihat di mode gelap)
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'contoh@email.com',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: theme.iconTheme.color?.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    // Warna isi field menyesuaikan mode
                    fillColor: isDarkMode
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.grey.shade50,
                    // Warna label dan hint
                    labelStyle: TextStyle(color: theme.hintColor),
                    hintStyle: TextStyle(
                      color: theme.hintColor.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Kirim
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirim Link Reset',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
