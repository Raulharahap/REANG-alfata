import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class HalamanTambahMetode extends StatefulWidget {
  final Map<String, dynamic>? metodeExisting;

  const HalamanTambahMetode({super.key, this.metodeExisting});

  @override
  State<HalamanTambahMetode> createState() => _HalamanTambahMetodeState();
}

class _HalamanTambahMetodeState extends State<HalamanTambahMetode> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  final TextEditingController _namaMetodeController = TextEditingController();
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _nomorRekeningController =
      TextEditingController();

  File? _qrisImageFile;
  String? _existingQrisUrl;
  bool _isLoading = false;

  String _jenisMetode = 'Transfer Bank';
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.metodeExisting != null) {
      _isEditMode = true;
      _namaMetodeController.text =
          widget.metodeExisting!['nama_metode']?.toString() ?? '';
      _jenisMetode =
          widget.metodeExisting!['jenis_metode']?.toString() ?? 'Transfer Bank';
      _namaPenerimaController.text =
          widget.metodeExisting!['nama_penerima']?.toString() ?? '';
      _nomorRekeningController.text =
          widget.metodeExisting!['nomor_rekening']?.toString() ?? '';

      // 👇 Ambil URL murni dari API Laravel yang sudah diproses oleh Accessor Model
      if (_jenisMetode == 'QRIS') {
        _existingQrisUrl =
            (widget.metodeExisting!['foto_qris'] ??
                    widget.metodeExisting!['foto_qris_url'])
                ?.toString();
      }
    }
  }

  @override
  void dispose() {
    _namaMetodeController.dispose();
    _namaPenerimaController.dispose();
    _nomorRekeningController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> _pickQrisImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _qrisImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Gagal mengambil gambar: $e");
    }
  }

  Future<void> _simpanData() async {
    if (!_formKey.currentState!.validate()) return;

    if (_jenisMetode == 'QRIS' &&
        _qrisImageFile == null &&
        _existingQrisUrl == null) {
      _showToast(
        'Wajib mengunggah foto gambar QRIS terlebih dahulu!',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = context.read<AuthProvider>().token;
      if (token == null) throw Exception('Sesi berakhir, silakan login ulang.');

      final Map<String, dynamic> resultData = {
        'nama_metode': _namaMetodeController.text.trim(),
        'jenis_metode': _jenisMetode,
        'nama_penerima': _jenisMetode == 'Transfer Bank'
            ? _namaPenerimaController.text.trim()
            : '-',
        'nomor_rekening': _jenisMetode == 'Transfer Bank'
            ? _nomorRekeningController.text.trim()
            : '-',
        'file_qris': _jenisMetode == 'QRIS' ? _qrisImageFile : null,
      };

      if (_isEditMode) {
        await _apiService.updateMetodePembayaranPlesir(
          token: token,
          id: widget.metodeExisting!['id'],
          dataMap: resultData,
        );
        _showToast('Metode pembayaran berhasil diubah.');
      } else {
        await _apiService.tambahMetodePembayaranPlesir(
          token: token,
          dataMap: resultData,
        );
        _showToast('Metode pembayaran berhasil ditambahkan.');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0F4C81);
    const Color textColor = Color(0xFF1E293B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Ubah Metode Pembayaran' : 'Tambah Metode Pembayaran',
          style: const TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _namaMetodeController,
                style: const TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  labelText: 'Nama Metode Pembayaran',
                  hintText: 'Contoh: Bank BCA, DANA, QRIS Toko',
                  labelStyle: const TextStyle(color: Colors.black54),
                  floatingLabelStyle: const TextStyle(color: primaryBlue),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: primaryBlue, width: 2),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama metode pembayaran tidak boleh kosong!';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Jenis Kategori Metode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text(
                        'Transfer Bank / E-Wallet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'User transfer manual ke rekening bank atau nomor e-wallet',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: 'Transfer Bank',
                      groupValue: _jenisMetode,
                      activeColor: primaryBlue,
                      onChanged: (value) {
                        setState(() => _jenisMetode = value!);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    RadioListTile<String>(
                      title: const Text(
                        'QRIS (Upload Gambar)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        'User tinggal melakukan scan gambar QRIS yang di-upload admin',
                        style: TextStyle(fontSize: 11),
                      ),
                      value: 'QRIS',
                      groupValue: _jenisMetode,
                      activeColor: primaryBlue,
                      onChanged: (value) {
                        setState(() => _jenisMetode = value!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_jenisMetode == 'Transfer Bank') ...[
                TextFormField(
                  controller: _namaPenerimaController,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nama Pemilik Rekening / Atas Nama',
                    hintText: 'Contoh: PT. Reang Plesir Nusantara',
                    labelStyle: const TextStyle(color: Colors.black54),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: (value) {
                    if (_jenisMetode == 'Transfer Bank' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Nama pemilik rekening wajib diisi!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nomorRekeningController,
                  style: const TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nomor Rekening / Nomor E-Wallet',
                    hintText:
                        'Contoh: 5388288383 (BCA) atau 0812345678 (Gopay)',
                    labelStyle: const TextStyle(color: Colors.black54),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 2,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_jenisMetode == 'Transfer Bank' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Nomor rekening wajib diisi!';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
              ],

              if (_jenisMetode == 'QRIS') ...[
                const Text(
                  'Upload Kode QRIS Toko/Mitra',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickQrisImage,
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _qrisImageFile != null
                            ? primaryBlue
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: _qrisImageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _qrisImageFile!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          )
                        : _existingQrisUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _existingQrisUrl!,
                              fit: BoxFit.contain,
                              headers: const {
                                'ngrok-skip-browser-warning': 'true',
                              }, // Pengaman Ngrok
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: primaryBlue,
                                  size: 36,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Ketuk untuk memilih foto QRIS dari Galeri',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Format: JPG, JPEG, PNG (Maks 2MB)',
                                style: TextStyle(
                                  color: Colors.black38,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],

              ElevatedButton.icon(
                onPressed: _isLoading ? null : _simpanData,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                label: Text(
                  _isLoading
                      ? 'Menyimpan...'
                      : (_isEditMode
                            ? 'Simpan Perubahan'
                            : 'Tambahkan Metode Baru'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
