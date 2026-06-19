import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/models/mitra_plesir_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class EditProfileMitraScreen extends StatefulWidget {
  final MitraPlesirModel mitraData;

  const EditProfileMitraScreen({super.key, required this.mitraData});

  @override
  State<EditProfileMitraScreen> createState() => _EditProfileMitraScreenState();
}

class _EditProfileMitraScreenState extends State<EditProfileMitraScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _alamatController;
  late TextEditingController _kontakController;

  bool _isSaving = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Mengisi form dengan data wisata yang sudah ada
    _namaController = TextEditingController(text: widget.mitraData.nama);
    _deskripsiController = TextEditingController(
      text: widget.mitraData.deskripsi,
    );
    _alamatController = TextEditingController(text: widget.mitraData.alamat);
    _kontakController = TextEditingController(text: widget.mitraData.kontak);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _alamatController.dispose();
    _kontakController.dispose();
    super.dispose();
  }

  // Fungsi ambil gambar
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Fungsi simpan data ke API
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception("Sesi berakhir, silakan login ulang");

      await _apiService.updateProfilMitraPlesir(
        token: token,
        nama: _namaController.text,
        alamat: _alamatController.text,
        kontak: _kontakController.text,
        deskripsi: _deskripsiController.text,
        foto: _imageFile != null ? XFile(_imageFile!.path) : null,
      );

      if (mounted) {
        showToast(
          "Profil wisata berhasil diperbarui!",
          context: context,
          backgroundColor: Colors.green,
          position: StyledToastPosition.bottom,
        );
        // Kembali ke halaman sebelumnya dengan membawa nilai true
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        showToast(
          e.toString().replaceAll('Exception: ', ''),
          context: context,
          backgroundColor: Colors.red,
          position: StyledToastPosition.bottom,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Helper URL Gambar
  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    const String domainHost =
        'https://7fed-2402-8780-103b-abc-e96b-4656-8be8-8a62.ngrok-free.app';
    return '$domainHost/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingFoto =
        widget.mitraData.foto != null && widget.mitraData.foto!.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil Wisata',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- FOTO PROFIL WISATA ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.shade100,
                          width: 4,
                        ),
                        // Logika diperbarui: Jika ada file/foto, baru render DecorationImage
                        image: (_imageFile != null || hasExistingFoto)
                            ? DecorationImage(
                                fit: BoxFit.cover,
                                image: _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : NetworkImage(
                                        _getImageUrl(widget.mitraData.foto),
                                      ),
                              )
                            : null,
                      ),
                      // Tampilkan Icon kosongan jika tidak ada foto
                      child: (_imageFile == null && !hasExistingFoto)
                          ? const Icon(
                              Icons.add_a_photo,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    const Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: Color(0xFF1D9BF0),
                        radius: 18,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Ketuk gambar untuk mengganti",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),

              // --- FORM INPUT ---
              _buildTextField(
                controller: _namaController,
                label: 'Nama Objek Wisata',
                icon: Icons.title,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _kontakController,
                label: 'Nomor WhatsApp / Kontak',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _alamatController,
                label: 'Alamat Lengkap',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _deskripsiController,
                label: 'Deskripsi Wisata',
                icon: Icons.description,
                maxLines: 4,
              ),

              const SizedBox(height: 32),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox()
                      : const Icon(Icons.save, color: Colors.white),
                  label: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? '$label wajib diisi' : null,
    );
  }
}
