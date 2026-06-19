import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/layanan/plesir/admin/home_admin_plesir_screen.dart';

class FormMitraPlesirScreen extends StatefulWidget {
  const FormMitraPlesirScreen({super.key});

  @override
  State<FormMitraPlesirScreen> createState() => _FormMitraPlesirScreenState();
}

class _FormMitraPlesirScreenState extends State<FormMitraPlesirScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaWisataController = TextEditingController();
  final _alamatController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _kontakController = TextEditingController();

  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Pengecekan role saat halaman pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfAlreadyMitra();
    });
  }

  void _checkIfAlreadyMitra() {
    final authProvider = context.read<AuthProvider>();

    // Asumsi: Kamu memiliki getter isAdminPlesir di AuthProvider
    // (Sama seperti authProvider.isUmkm)
    if (authProvider.isAdminPlesir) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeAdminPlesirScreen()),
      );
    }
  }

  @override
  void dispose() {
    _namaWisataController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    // 1. Validasi form
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final navigator = Navigator.of(context);

    try {
      final token = authProvider.token;
      if (token == null) {
        throw Exception("Sesi Anda telah berakhir. Silakan login kembali.");
      }

      // =========================================================================
      // 2. DAFTARKAN MITRA PLESIR BARU
      // =========================================================================
      await _apiService.registerMitraPlesir(
        token: token,
        nama: _namaWisataController.text,
        alamat: _alamatController.text,
        deskripsi: _deskripsiController.text,
        kontak: _kontakController.text,
      );

      // =========================================================================
      // 3. SINKRONISASI ULANG DATA USER
      // =========================================================================

      // 3a. Update role lokal (jika belum jadi Admin Plesir)
      // Asumsi: Kamu perlu membuat fungsi upgradeToAdminPlesir() di AuthProvider
      if (!authProvider.isAdminPlesir) {
        await authProvider.upgradeToAdminPlesir();
      }

      // 3b. Ambil ulang profil user dari backend (agar status role terbaru masuk)
      await authProvider.fetchUserProfile();

      // =========================================================================
      // 4. TAMPILKAN NOTIFIKASI BERHASIL
      // =========================================================================
      if (!mounted) return;

      showToast(
        "Pendaftaran Berhasil! Role Anda diperbarui.",
        context: context,
        backgroundColor: Colors.green,
        position: StyledToastPosition.bottom,
      );

      // =========================================================================
      // 5. ARAHKAN USER KE DASHBOARD ADMIN PLESIR
      // =========================================================================
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeAdminPlesirScreen()),
      );
    } catch (e) {
      // =========================================================================
      // 6. ERROR HANDLING
      // =========================================================================
      if (!mounted) return;

      showToast(
        e.toString().replaceAll('Exception: ', ''),
        context: context,
        backgroundColor: Colors.red,
        position: StyledToastPosition.bottom,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Daftar Mitra Plesir-Yu',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Lengkapi Data Wisata Anda",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField(
                      controller: _namaWisataController,
                      label: "Nama Objek Wisata",
                      hint: "Contoh: Pantai Karang Song",
                      icon: Icons.landscape,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _deskripsiController,
                      label: "Deskripsi Singkat",
                      hint: "Jelaskan keunggulan wisata Anda...",
                      icon: Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _alamatController,
                      label: "Alamat Lengkap",
                      hint: "Jl. Raya Indramayu...",
                      icon: Icons.location_on,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _kontakController,
                      label: "Nomor WhatsApp/Kontak",
                      hint: "08123456xxxx",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Daftar Sekarang',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _submitForm,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }
}
