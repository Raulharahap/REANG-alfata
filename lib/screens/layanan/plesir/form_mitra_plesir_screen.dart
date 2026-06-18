import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/admin/home_admin_plesir_screen.dart';

class FormMitraPlesirScreen extends StatefulWidget {
  const FormMitraPlesirScreen({super.key});

  @override
  State<FormMitraPlesirScreen> createState() => _FormMitraPlesirScreenState();
}

class _FormMitraPlesirScreenState extends State<FormMitraPlesirScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _namaWisataController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  final TextEditingController _kontakController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Efek kosmetik UX loading profesional
    await Future.delayed(const Duration(milliseconds: 800));

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;

    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesi habis, silakan login kembali')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Memanggil ApiService yang sudah mengarah ke endpoint mitra_wisata
      final response = await _apiService.registerMitraWisata(
        token: token,
        nama: _namaWisataController.text,
        alamat: _alamatController.text,
        kontak: _kontakController
            .text, // Sesuai dengan request backend ($request->kontak)
        deskripsi: _deskripsiController.text,
      );

      // JIKA API BERHASIL, PINDAH KE DASHBOARD DI SINI
      if (mounted) {
        // [PERUBAHAN LOGIKA DI SINI]:
        // Update status pendaftaran mitra di AuthProvider / Local Storage Anda agar aplikasi ingat
        // Contoh jika di AuthProvider Anda ada fungsi setMitraStatus:
        // authProvider.setMitraStatus(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pendaftaran Berhasil! Role Anda diperbarui menjadi Admin Mitra.',
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeAdminPlesirScreen(),
          ),
        );
      }
    } catch (e) {
      // JIKA API GAGAL, AKAN TERTANGKAP DI SINI DAN HALAMAN TIDAK AKAN PINDAH
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Lengkapi Data Wisata Anda",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildTextField(
                      controller: _namaWisataController,
                      label: "Nama Objek Wisata",
                      hint: "Contoh: Pantai Karang Song",
                      icon: Icons.landscape,
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _alamatController,
                      label: "Alamat Lengkap",
                      hint: "Jl. Raya Indramayu...",
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _kontakController,
                      label: "Nomor WhatsApp/Kontak",
                      hint: "08123456xxxx",
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),

                    _buildTextField(
                      controller: _deskripsiController,
                      label: "Deskripsi Singkat",
                      hint: "Jelaskan keunggulan wisata Anda...",
                      icon: Icons.description,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          "Daftar Sekarang",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
      validator: (value) =>
          value == null || value.isEmpty ? "$label wajib diisi" : null,
    );
  }
}
