import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class FormUsulanScreen extends StatefulWidget {
  const FormUsulanScreen({Key? key}) : super(key: key);

  @override
  State<FormUsulanScreen> createState() => _FormUsulanScreenState();
}

class _FormUsulanScreenState extends State<FormUsulanScreen> {
  // --- State and Controllers ---
  final _apiService = ApiService();
  final _judulController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _deskripsiController = TextEditingController();
  bool _isLoading = false;

  // --- Data ---
  final List<String> _kategoriList = [
    'Infrastruktur',
    'Pendidikan',
    'Kesehatan',
    'Ekonomi',
    'Sosial',
    'Lainnya',
  ];
  String? _selectedKategori;

  @override
  void dispose() {
    _judulController.dispose();
    _lokasiController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  /// Helper untuk menampilkan toast dengan gaya yang konsisten
  void _showStyledToast(String message, {bool isError = false}) {
    // Pastikan keyboard tertutup sebelum menampilkan toast
    FocusScope.of(context).unfocus();
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      backgroundColor: isError ? Colors.red : Colors.green,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
    );
  }

  /// Menampilkan dialog konfirmasi sebelum mengirim
  void _showConfirmationDialog() {
    // Tutup keyboard sebelum menampilkan dialog
    FocusScope.of(context).unfocus();

    if (_judulController.text.trim().isEmpty ||
        _selectedKategori == null ||
        _lokasiController.text.trim().isEmpty ||
        _deskripsiController.text.trim().isEmpty) {
      _showStyledToast(
        "Harap lengkapi semua kolom yang wajib diisi.",
        isError: true,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Usulan'),
          content: const Text(
            'Pastikan data yang Anda masukkan sudah benar. Kirim usulan ini?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kirim'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
                _performSubmit(); // Lanjutkan proses pengiriman
              },
            ),
          ],
        );
      },
    );
  }

  /// Logika untuk mengirim data ke API setelah dikonfirmasi
  void _performSubmit() async {
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception("Sesi Anda telah berakhir. Harap login kembali.");
      }

      final response = await _apiService.postUsulanPembangunan(
        judul: _judulController.text.trim(),
        kategori: _selectedKategori!,
        lokasi: _lokasiController.text.trim(),
        deskripsi: _deskripsiController.text.trim(),
        token: token,
      );

      _showStyledToast(response['message'] ?? "Usulan berhasil dikirim!");

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _showStyledToast(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final boxDecoration = BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );

    final inputDecoration = InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      filled: true,
      fillColor: Colors.transparent,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // --- PERUBAHAN 2: Menambahkan leading IconButton di AppBar ---
      appBar: AppBar(
        title: const Text('Form Tambah Usulan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Tutup keyboard terlebih dahulu, baru kembali ke halaman sebelumnya
            FocusScope.of(context).unfocus();
            Navigator.of(context).pop();
          },
        ),
      ),
      // --- PERUBAHAN 1: Membungkus body dengan GestureDetector ---
      body: GestureDetector(
        onTap: () {
          // Menutup keyboard saat area kosong di-tap
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Sampaikan ide dan usulan Anda untuk pembangunan Indramayu yang lebih baik.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Text('Judul Usulan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: boxDecoration,
              child: TextField(
                controller: _judulController,
                decoration: inputDecoration.copyWith(
                  hintText: 'Contoh: Perbaikan Jembatan Desa Sukra',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Kategori Pembangunan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: boxDecoration,
              child: DropdownMenu<String>(
                initialSelection: _selectedKategori,
                onSelected: (String? value) =>
                    setState(() => _selectedKategori = value),
                expandedInsets: EdgeInsets.zero,
                hintText: 'Pilih kategori usulan',
                inputDecorationTheme: InputDecorationTheme(
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.5)),
                ),
                dropdownMenuEntries: _kategoriList
                    .map<DropdownMenuEntry<String>>(
                      (String value) =>
                          DropdownMenuEntry<String>(value: value, label: value),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Text('Lokasi Usulan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: boxDecoration,
              child: TextField(
                controller: _lokasiController,
                maxLines: 2,
                decoration: inputDecoration.copyWith(
                  hintText: 'Contoh: Jalan Raya Pantura, Desa Sukra',
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Deskripsi Lengkap', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              decoration: boxDecoration,
              child: TextField(
                controller: _deskripsiController,
                maxLines: 5,
                decoration: inputDecoration.copyWith(
                  hintText: 'Jelaskan secara rinci mengenai usulan Anda...',
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _showConfirmationDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Kirim Usulan',
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
    );
  }
}
