import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';

import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/tiket_wisata_model.dart';

class FormInputWisata extends StatefulWidget {
  final TiketWisataModel?
  wisata; // Tambahkan ini agar bisa menerima data untuk Mode Edit

  const FormInputWisata({super.key, this.wisata});

  @override
  State<FormInputWisata> createState() => _FormInputWisataState();
}

class _FormInputWisataState extends State<FormInputWisata> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // --- Controllers ---
  late TextEditingController _namaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _alamatController;
  late TextEditingController _jamController;
  late TextEditingController _hargaController;
  late TextEditingController _kuotaController;
  late TextEditingController _fasilitasController;

  // --- State Variables ---
  String? _kategoriTerpilih;
  final List<String> _daftarKategori = [
    'Alam',
    'Budaya',
    'Edukasi',
    'Wahana Bermain',
  ];

  // State Foto
  XFile? _fotoUtama;
  String? _fotoUtamaLamaUrl;
  bool _fotoError = false;

  List<XFile> _galeriFotoBaru = [];
  List<GaleriFotoModel> _galeriFotoLama = [];
  List<int> _hapusGaleriIds = [];

  bool _isEditMode = false;
  bool _isLoading = false;
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.wisata != null;

    // Isi Controller dengan data lama (Jika Edit) atau kosong (Jika Tambah)
    _namaController = TextEditingController(
      text: widget.wisata?.namaWisata ?? '',
    );
    _deskripsiController = TextEditingController(
      text: widget.wisata?.deskripsi ?? '',
    );
    _alamatController = TextEditingController(
      text: widget.wisata?.alamat ?? '',
    );
    _jamController = TextEditingController(
      text: widget.wisata?.jamOperasional ?? '',
    );

    // Fasilitas dari List<String> diubah jadi string pisah koma
    _fasilitasController = TextEditingController(
      text: widget.wisata?.fasilitas != null
          ? widget.wisata!.fasilitas.join(', ')
          : '',
    );

    _hargaController = TextEditingController(
      text: widget.wisata != null ? widget.wisata!.hargaTiket.toString() : '',
    );
    _kuotaController = TextEditingController(
      text: widget.wisata != null ? widget.wisata!.kuotaPerHari.toString() : '',
    );

    if (_isEditMode) {
      _kategoriTerpilih = widget.wisata!.kategoriWisata;
      _fotoUtamaLamaUrl = widget.wisata!.fotoUtamaUrl;
      _galeriFotoLama = List.from(widget.wisata!.galeri);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _alamatController.dispose();
    _jamController.dispose();
    _hargaController.dispose();
    _kuotaController.dispose();
    _fasilitasController.dispose();
    super.dispose();
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    const String domainHost =
        'https://c4eb-2402-8780-103b-abc-d45e-c0c5-b397-1bce.ngrok-free.app';
    return '$domainHost/storage/$path';
  }

  // --- Fungsi Foto ---
  Future<void> _pickFotoUtama() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _fotoUtama = image;
          _fotoUtamaLamaUrl = null; // Reset foto lama jika pilih baru
          _fotoError = false;
        });
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar: $e", isError: true);
    }
  }

  Future<void> _pickGaleri() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _galeriFotoBaru.addAll(images));
      }
    } catch (e) {
      _showToast("Gagal mengambil gambar galeri: $e", isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(10),
    );
  }

  // --- FUNGSI SUBMIT DATA (CREATE / UPDATE) ---
  Future<void> _submitForm() async {
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
      _fotoError = _fotoUtama == null && _fotoUtamaLamaUrl == null;
    });

    if (!_formKey.currentState!.validate() || _fotoError) {
      _showToast(
        "Harap lengkapi semua data dan foto utama wisata!",
        isError: true,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      _showToast(
        "Sesi Anda telah berakhir, harap login kembali.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tiketData = TiketWisataModel(
        id: widget.wisata?.id,
        namaWisata: _namaController.text,
        kategoriWisata: _kategoriTerpilih!,
        deskripsi: _deskripsiController.text,
        alamat: _alamatController.text,
        jamOperasional: _jamController.text,
        hargaTiket: int.parse(_hargaController.text),
        kuotaPerHari: int.parse(_kuotaController.text),
        fasilitas: _fasilitasController.text.isNotEmpty
            ? _fasilitasController.text.split(',').map((e) => e.trim()).toList()
            : [],
      );

      if (_isEditMode) {
        await _apiService.updateTiketWisata(
          token: auth.token!,
          tiketId: widget.wisata!.id!,
          data: tiketData,
          fotoUtamaBaru: _fotoUtama,
          galeriBaru: _galeriFotoBaru,
          idsFotoGaleriDihapus: _hapusGaleriIds,
        );
        _showToast("Destinasi wisata berhasil diperbarui!");
      } else {
        await _apiService.createTiketWisata(
          token: auth.token!,
          data: tiketData,
          fotoUtamaFile: _fotoUtama!,
          galeriFiles: _galeriFotoBaru,
        );
        _showToast("Destinasi wisata berhasil disimpan!");
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted)
        _showToast(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Destinasi Wisata' : 'Tambah Destinasi Wisata',
        ),
        backgroundColor: const Color(0xFF0D6EFD),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          autovalidateMode: _autoValidateMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- CARD 1: FOTO WISATA ---
              _buildSectionCard(
                theme,
                title: "Foto Destinasi",
                subtitle: "Tambahkan foto utama dan galeri wisata Anda",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Foto Utama (Cover)*"),
                    _buildImagePicker(theme),
                    const SizedBox(height: 20),
                    _buildLabel("Foto Galeri (Opsional)"),
                    _buildGalleryPicker(theme),
                  ],
                ),
              ),

              // --- CARD 2: INFORMASI UTAMA ---
              _buildSectionCard(
                theme,
                title: "Informasi Utama",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Nama Destinasi Wisata*"),
                    TextFormField(
                      controller: _namaController,
                      decoration: _inputDecoration(
                        'Misal: Pantai Karang Song',
                        Icons.landscape,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Kategori Wisata*"),
                    DropdownButtonFormField<String>(
                      value: _kategoriTerpilih,
                      decoration: _inputDecoration(
                        'Pilih Kategori',
                        Icons.category,
                      ),
                      items: _daftarKategori.map((String kategori) {
                        return DropdownMenuItem<String>(
                          value: kategori,
                          child: Text(kategori),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _kategoriTerpilih = value),
                      validator: (value) => value == null
                          ? 'Pilih kategori terlebih dahulu'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Fasilitas (Pisahkan dengan koma)"),
                    TextFormField(
                      controller: _fasilitasController,
                      decoration: _inputDecoration(
                        'Misal: Toilet, Mushola, Parkir Luas',
                        Icons.star_border,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Deskripsi Wisata*"),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                        'Ceritakan keunggulan dan daya tarik tempat ini...',
                        Icons.description,
                      ).copyWith(alignLabelWithHint: true),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),

              // --- CARD 3: LOKASI & OPERASIONAL ---
              _buildSectionCard(
                theme,
                title: "Lokasi & Operasional",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Alamat Lengkap*"),
                    TextFormField(
                      controller: _alamatController,
                      maxLines: 2,
                      decoration: _inputDecoration(
                        'Masukkan alamat lengkap...',
                        Icons.location_on,
                      ).copyWith(alignLabelWithHint: true),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Alamat wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Jam Operasional*"),
                    TextFormField(
                      controller: _jamController,
                      decoration: _inputDecoration(
                        'Misal: 08:00 - 17:00 WIB',
                        Icons.access_time,
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Jam operasional wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),

              // --- CARD 4: TIKET & KAPASITAS ---
              _buildSectionCard(
                theme,
                title: "Tiket & Kapasitas",
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Harga Tiket (Rp)*"),
                          TextFormField(
                            controller: _hargaController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration(
                              'Misal: 15000',
                              Icons.attach_money,
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Kuota Harian*"),
                          TextFormField(
                            controller: _kuotaController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: _inputDecoration(
                              'Misal: 500',
                              Icons.people,
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Wajib diisi'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- TOMBOL SIMPAN ---
              SizedBox(
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading
                      ? const SizedBox()
                      : const Icon(Icons.save, color: Colors.white),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode
                              ? 'Update Data Wisata'
                              : 'Simpan Destinasi Wisata',
                          style: const TextStyle(
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
                    elevation: 2,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // --- WIDGET BUILDER HELPERS ---
  // =========================================================================

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF0D6EFD), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D6EFD),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
            const Divider(height: 24, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _fotoError ? Colors.red : Colors.grey.shade300,
                width: _fotoError ? 2.0 : 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: _fotoUtama != null
                ? Image.file(File(_fotoUtama!.path), fit: BoxFit.cover)
                : (_fotoUtamaLamaUrl != null
                      ? Image.network(
                          _getImageUrl(_fotoUtamaLamaUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.broken_image),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.grey[400],
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Pilih Foto",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Material(
              color: const Color(0xFF0D6EFD),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _pickFotoUtama,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.edit, color: Colors.white, size: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryPicker(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      height: 120,
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickGaleri,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, color: Color(0xFF0D6EFD)),
                  SizedBox(height: 4),
                  Text(
                    "Tambah",
                    style: TextStyle(
                      color: Color(0xFF0D6EFD),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              // Total foto adalah gabungan galeri lama dan baru
              itemCount: _galeriFotoLama.length + _galeriFotoBaru.length,
              itemBuilder: (context, index) {
                bool isFotoLama = index < _galeriFotoLama.length;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isFotoLama
                            ? Image.network(
                                _getImageUrl(_galeriFotoLama[index].fotoUrl),
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(
                                  _galeriFotoBaru[index -
                                          _galeriFotoLama.length]
                                      .path,
                                ),
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: -5,
                        right: -5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFotoLama) {
                                _hapusGaleriIds.add(_galeriFotoLama[index].id!);
                                _galeriFotoLama.removeAt(index);
                              } else {
                                _galeriFotoBaru.removeAt(
                                  index - _galeriFotoLama.length,
                                );
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
