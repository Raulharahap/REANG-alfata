import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/main_screen.dart';
import 'package:reang_app/screens/dokter/konsultasi_pasien_screen.dart';
// Import LoginScreen tidak lagi dibutuhkan di sini
// import 'package:reang_app/screens/auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthStatus();
    });
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await Future.wait([
      authProvider.tryAutoLogin(),
      Future.delayed(const Duration(seconds: 2)),
    ]);

    if (mounted) {
      // --- PERUBAHAN UTAMA DI SINI ---
      if (authProvider.isLoggedIn && authProvider.role == 'puskesmas') {
        // HANYA jika login sebagai Dokter, arahkan ke halaman khusus dokter
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const KonsultasiPasienScreen(),
          ),
          (route) => false,
        );
      } else {
        // UNTUK SEMUA KONDISI LAIN (login sebagai user biasa ATAU belum login/tamu),
        // arahkan ke halaman utama.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/wongreang.webp', // Pastikan path ini benar
          width: 300,
        ),
      ),
    );
  }
}
