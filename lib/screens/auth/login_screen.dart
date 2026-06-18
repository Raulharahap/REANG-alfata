import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/user_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/main_screen.dart';
import 'package:reang_app/screens/auth/register_screen.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/screens/auth/admin_login_screen.dart';
import 'package:reang_app/screens/auth/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool popOnSuccess;

  const LoginScreen({super.key, this.popOnSuccess = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isGoogleLoading = false;
  bool _isStandardLoading = false;

  // Getter penggabung (Supaya TextField tetap mati kalau salah satu lagi loading)
  bool get _isLoading => _isGoogleLoading || _isStandardLoading;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- FUNGSI LOGIN GOOGLE (LOGIKA UTAMA) ---
  Future<void> _performGoogleLogin() async {
    if (_isLoading) return;

    setState(() => _isGoogleLoading = true);

    try {
      // 1. Panggil Provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 2. Definisi Variabel 'user' (Ini yang tadi error undefined)
      final UserModel? user = await authProvider.loginWithGoogle();

      if (user == null) {
        setState(() => _isGoogleLoading = true);
        return;
      }

      // 3. Cek Data
      if (user.noKtp.isEmpty || user.phone.isEmpty) {
        if (mounted) {
          _showToast("Silakan lengkapi data diri Anda", Colors.blue);

          // 4. Pindah ke Register & Tunggu Hasilnya (await)
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegisterScreen(
                popOnSuccess: widget.popOnSuccess,
                googleUser: user, // Mengirim data user
              ),
            ),
          );

          // 5. Jika Register Berhasil (result == true)
          if (result == true && mounted) {
            if (widget.popOnSuccess) {
              Navigator.pop(context, true); // Tutup LoginScreen
            } else {
              _handleSuccessLogin(isGoogle: true); // Masuk MainScreen
            }
          }
        }
      } else {
        // User Lama (Data Lengkap) -> Langsung Masuk
        if (mounted) {
          _handleSuccessLogin(isGoogle: true);
        }
      }
    } catch (e) {
      print("Google Login Error: $e");
      if (!e.toString().contains("Null check")) {
        _showToast("Gagal masuk dengan Google.", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // --- FUNGSI LOGIN BIASA (TIDAK BERUBAH) ---
  Future<void> _performLogin() async {
    if (_isLoading) return;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showToast("Email dan password tidak boleh kosong.", Colors.red);
      return;
    }

    setState(() => _isStandardLoading = true);

    try {
      final apiService = ApiService();
      final response = await apiService.loginUser(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final token = response['access_token'];
      final userData = response['user'];

      if (token != null && userData != null) {
        final user = UserModel.fromMap(userData);
        if (mounted) {
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).login(user, token);
        }
        _handleSuccessLogin();
      } else {
        throw Exception("Token atau data pengguna tidak ditemukan.");
      }
    } catch (e) {
      _showToast(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isStandardLoading = false);
    }
  }

  void _handleSuccessLogin({bool isGoogle = false}) {
    _showToast(
      isGoogle ? 'Login Google Berhasil!' : 'Login Berhasil!',
      Colors.green,
    );

    if (widget.popOnSuccess) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showToast(String message, Color color) {
    showToast(
      message,
      context: context,
      backgroundColor: color,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/wongreang.webp', height: 75),
                const SizedBox(height: 2),
                const Text(
                  'selamat datang di Reang',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 24),

                // --- TOMBOL GOOGLE (SUDAH DIAKTIFKAN) ---
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _performGoogleLogin,
                  icon: _isGoogleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : Image.asset('assets/google_icon.webp', height: 24),
                  label: Text(_isLoading ? 'Memproses...' : 'Google'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F2F3),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
                  ),
                ),

                // ----------------------------------------
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('Atau'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // --- NAVIGASI KE FORGOT PASSWORD ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'lupa password?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _performLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isStandardLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Masuk', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RegisterScreen(
                                    popOnSuccess: widget.popOnSuccess,
                                    // googleUser: user, <--- HAPUS BARIS INI (KARENA INI DAFTAR MANUAL)
                                  ),
                                ),
                              );

                              if (result == true && mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                      child: const Text(
                        'Daftar di sini',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DokterLoginScreen(),
                            ),
                          );
                        },
                  child: const Text('Masuk sebagai Admin'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
