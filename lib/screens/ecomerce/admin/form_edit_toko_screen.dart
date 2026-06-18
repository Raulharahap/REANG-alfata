import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class FormEditTokoScreen extends StatefulWidget {
  final TokoModel toko;
  const FormEditTokoScreen({super.key, required this.toko});

  @override
  State<FormEditTokoScreen> createState() => _FormEditTokoScreenState();
}

class _FormEditTokoScreenState extends State<FormEditTokoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _namaController;
  late TextEditingController _pemilikController;
  late TextEditingController _emailController;
  late TextEditingController _tahunController;
  late TextEditingController _alamatController;
  late TextEditingController _deskripsiController;

  File? _fotoBaru;
  bool _isLoading = false;

  // [PENTING] Ganti ini sesuai alamat server Laravel Anda (ngrok/ip)
  final String baseUrl = "https://zara-gruffiest-silas.ngrok-free.dev";

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.toko.nama);
    _pemilikController = TextEditingController(text: widget.toko.namaPemilik);
    _emailController = TextEditingController(text: widget.toko.emailToko);
    _tahunController = TextEditingController(text: widget.toko.tahunBerdiri);
    _alamatController = TextEditingController(text: widget.toko.alamat);
    _deskripsiController = TextEditingController(text: widget.toko.deskripsi);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _fotoBaru = File(picked.path));
    }
  }

  // [FUNGSI BARU] Helper untuk memperbaiki URL gambar yang rusak
  String _getValidImageUrl(String path) {
    if (path.startsWith('http')) {
      return path; // Sudah lengkap
    }

    // Jika path-nya lokal (cth: toko_profile/abc.jpg), tambahkan domain + storage
    // Hapus slash di depan jika ada agar tidak double slash
    String cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return "$baseUrl/storage/$cleanPath";
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      await _apiService.updateToko(
        token: auth.token!,
        nama: _namaController.text,
        namaPemilik: _pemilikController.text,
        emailToko: _emailController.text,
        tahunBerdiri: _tahunController.text,
        alamat: _alamatController.text,
        deskripsi: _deskripsiController.text,
        foto: _fotoBaru,
      );

      if (mounted) {
        _showToast("Profil berhasil diperbarui!");
        Navigator.pop(context, true); // Kembali & Refresh
      }
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
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
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(25),
      animation: StyledToastAnimation.scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic Foto: Prioritas Foto Baru -> Foto Lama -> Null
    ImageProvider? bgImage;

    if (_fotoBaru != null) {
      bgImage = FileImage(_fotoBaru!);
    } else if (widget.toko.foto != null && widget.toko.foto!.isNotEmpty) {
      // Gunakan helper URL di sini
      bgImage = NetworkImage(_getValidImageUrl(widget.toko.foto!));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil Toko")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Foto Picker
              GestureDetector(
                onTap: _pickImage,
                child: HeroMode(
                  // [FIX ERROR HERO] Matikan animasi hero di sini
                  enabled: false,
                  child: CircleAvatar(
                    radius: 60, // Sedikit lebih besar
                    backgroundColor: Colors.grey[200],
                    backgroundImage: bgImage,
                    child: bgImage == null
                        ? const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey,
                          )
                        : null,
                    onBackgroundImageError: (_, __) {
                      // Silent fail jika gambar rusak
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ketuk foto untuk mengubah",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 24),

              TextFormField(
                controller: _namaController,
                decoration: _inputDecoration('Nama Toko'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pemilikController,
                decoration: _inputDecoration('Nama Pemilik'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: _inputDecoration('Email Toko'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tahunController,
                decoration: _inputDecoration('Tahun Berdiri (Contoh: 2020)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: _inputDecoration('Alamat Lengkap'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: _inputDecoration('Deskripsi Singkat'),
                maxLines: 4,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _simpan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Simpan Perubahan",
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
    );
  }

  // Helper Dekorasi Input
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
