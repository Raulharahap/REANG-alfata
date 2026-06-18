// Lokasi: lib/screens/ecomerce/admin/form_metode_pembayaran_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/payment_method_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class FormMetodePembayaranScreen extends StatefulWidget {
  // Jika 'metode' null, ini adalah mode Tambah
  // Jika 'metode' diisi, ini adalah mode Edit
  final PaymentMethodModel? metode;

  const FormMetodePembayaranScreen({super.key, this.metode});

  bool get isEditMode => metode != null;

  @override
  State<FormMetodePembayaranScreen> createState() =>
      _FormMetodePembayaranScreenState();
}

class _FormMetodePembayaranScreenState
    extends State<FormMetodePembayaranScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late AuthProvider _authProvider;

  // Controllers
  final _namaMetodeC = TextEditingController();
  final _namaPenerimaC = TextEditingController();
  final _nomorTujuanC = TextEditingController();

  // State untuk jenis (Bank/QRIS)
  String _jenis = 'bank'; // Default

  // State untuk gambar
  XFile? _pickedQrisImage;
  String? _existingQrisUrl;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();

    // Jika mode Edit, isi formulir dengan data yang ada
    if (widget.isEditMode) {
      final m = widget.metode!;
      _namaMetodeC.text = m.namaMetode;
      _namaPenerimaC.text = m.namaPenerima;
      _nomorTujuanC.text = m.nomorTujuan;
      _jenis = m.jenis;
      _existingQrisUrl = m.fotoQris;
    }
  }

  @override
  void dispose() {
    _namaMetodeC.dispose();
    _namaPenerimaC.dispose();
    _nomorTujuanC.dispose();
    super.dispose();
  }

  /// Menampilkan toast
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      backgroundColor: isError
          ? theme.colorScheme.error
          : Colors.black.withOpacity(0.8),
    );
  }

  /// Logika Pilih Gambar
  Future<void> _pilihGambar() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedQrisImage = image;
        });
      }
    } catch (e) {
      _showToast('Gagal mengambil gambar: $e', isError: true);
    }
  }

  /// Logika Submit Form
  Future<void> _submitForm() async {
    // 1. Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Cek dependensi
    if (!_authProvider.isLoggedIn || _authProvider.user?.idToko == null) {
      _showToast('Anda harus login / ID Toko tidak ditemukan', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 3. Panggil API (Create atau Update)
      if (widget.isEditMode) {
        // --- Mode UPDATE ---
        await _apiService.updateMetodePembayaran(
          token: _authProvider.token!,
          idToko: _authProvider.user!.idToko!,
          metodeId: widget.metode!.id,
          namaMetode: _namaMetodeC.text,
          jenis: _jenis,
          namaPenerima: _namaPenerimaC.text,
          nomorTujuan: _nomorTujuanC.text,
          fotoQrisBaru: _pickedQrisImage,
        );
        _showToast('Metode berhasil diperbarui');
      } else {
        // --- Mode CREATE ---
        await _apiService.createMetodePembayaran(
          token: _authProvider.token!,
          idToko: _authProvider.user!.idToko!,
          namaMetode: _namaMetodeC.text,
          jenis: _jenis,
          namaPenerima: _namaPenerimaC.text,
          nomorTujuan: _nomorTujuanC.text,
          fotoQris: _pickedQrisImage,
        );
        _showToast('Metode berhasil ditambahkan');
      }

      // 4. Kembali ke halaman sebelumnya
      if (mounted) {
        Navigator.pop(context, true); // Kirim 'true' untuk trigger refresh
      }
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Metode' : 'Tambah Metode'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Field Nama Metode ---
              TextFormField(
                controller: _namaMetodeC,
                decoration: const InputDecoration(
                  labelText: 'Nama Metode',
                  hintText: 'Cth: Bank BCA, QRIS Toko',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama metode tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // --- Pilihan Jenis (Bank / QRIS) ---
              Text('Jenis Metode', style: theme.textTheme.titleMedium),
              RadioListTile<String>(
                title: const Text('Transfer Bank'),
                value: 'bank',
                groupValue: _jenis,
                onChanged: (value) {
                  if (value != null) setState(() => _jenis = value);
                },
              ),
              RadioListTile<String>(
                title: const Text('QRIS'),
                value: 'qris',
                groupValue: _jenis,
                onChanged: (value) {
                  if (value != null) setState(() => _jenis = value);
                },
              ),

              // [TAMBAHKAN KODE INI]
              RadioListTile<String>(
                title: const Text('COD (Bayar di Tempat)'),
                value: 'cod',
                groupValue: _jenis,
                onChanged: (value) {
                  if (value != null) setState(() => _jenis = value);
                },
              ),
              // [SELESAI PENAMBAHAN]
              const SizedBox(height: 20),

              // --- Field Dinamis (Bank) ---
              if (_jenis == 'bank') ...[
                TextFormField(
                  controller: _namaPenerimaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penerima',
                    hintText: 'Cth: Budi Santoso',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_jenis == 'bank' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Nama penerima tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nomorTujuanC,
                  decoration: const InputDecoration(
                    labelText: 'Nomor Rekening',
                    hintText: 'Cth: 1234567890',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_jenis == 'bank' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Nomor rekening tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ],

              // --- Field Dinamis (QRIS) ---
              if (_jenis == 'qris') ...[
                Text('Gambar QRIS', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                _buildImagePreview(theme),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pilihGambar,
                  icon: const Icon(Icons.upload_file),
                  label: Text(
                    _pickedQrisImage != null || _existingQrisUrl != null
                        ? 'Ganti Gambar'
                        : 'Pilih Gambar QRIS',
                  ),
                ),
                TextFormField(
                  controller: _nomorTujuanC,
                  decoration: const InputDecoration(
                    labelText: 'NMID (Opsional)',
                    hintText: 'Cth: ID1234567890',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => null, // Opsional
                ),
              ],

              const SizedBox(height: 32),

              // --- Tombol Simpan ---
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget untuk menampilkan preview gambar
  Widget _buildImagePreview(ThemeData theme) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Prioritas 1: Tampilkan gambar baru yang dipilih
            if (_pickedQrisImage != null)
              Expanded(
                child: Image.file(
                  File(_pickedQrisImage!.path),
                  fit: BoxFit.contain,
                ),
              )
            // Prioritas 2: Tampilkan gambar lama (mode edit)
            else if (_existingQrisUrl != null && _existingQrisUrl!.isNotEmpty)
              Expanded(
                child: Image.network(
                  _existingQrisUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, err, stack) =>
                      const Center(child: Text('Gagal memuat gambar')),
                ),
              )
            // Prioritas 3: Tampilkan placeholder
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 50,
                      color: theme.hintColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada gambar QRIS',
                      style: TextStyle(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
