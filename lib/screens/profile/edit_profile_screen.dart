import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/providers/theme_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _apiService = ApiService();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _alamatController;
  late TextEditingController _emailController;

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _alamatFocus = FocusNode();
  final _emailFocus = FocusNode();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _alamatController = TextEditingController(text: user?.alamat ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _alamatController.dispose();
    _emailController.dispose();
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _alamatFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  /// Menutup keyboard
  void _unfocus() {
    FocusScope.of(context).unfocus();
  }

  /// Menangani tombol Simpan
  Future<void> _onSave() async {
    _unfocus();
    if (_isLoading) return;

    setState(() => _isLoading = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) {
      _showToast("Sesi tidak valid, silakan login ulang", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    // Data yang akan dikirim ke API
    final Map<String, dynamic> dataToUpdate = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'email': _emailController.text.trim(),
    };

    try {
      // Menggunakan metode PUT seperti yang dibahas
      final updatedUser = await _apiService.updateUserProfile(
        auth.token!,
        dataToUpdate,
      );

      // Perbarui data di AuthProvider secara lokal
      await auth.updateLocalUser(updatedUser);

      _showToast("Profil berhasil diperbarui", isError: false);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // --- PERBAIKAN PENANGANAN ERROR ---
      String errorMessage = "Terjadi kesalahan.";
      if (e is DioException) {
        // Jika error adalah DioException (masalah jaringan atau server)
        errorMessage = "Gagal menyimpan. Periksa koneksi internet Anda.";
      } else {
        // Error lain (misal: validasi dari server)
        errorMessage = e.toString().replaceFirst("Exception: ", "");
      }
      _showToast(errorMessage, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      backgroundColor: isError ? Colors.red : Colors.green,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
    );
  }

  // --- FUNGSI BARU: Untuk mendapatkan inisial ---
  String _getInitials(String name) {
    // Bersihkan nama dari spasi berlebih di awal/akhir
    String trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'G';

    // Pisahkan nama berdasarkan spasi
    List<String> names = trimmedName.split(' ');

    // Penting: Hapus item kosong jika ada spasi ganda (misal: "Alfa  Rizi")
    names.removeWhere((item) => item.isEmpty);

    // KASUS 1: Jika ada 2 KATA ATAU LEBIH (misal: "Alfa Rizi" atau "Alfa Rizi Nugroho")
    if (names.length > 1) {
      return names[0][0].toUpperCase() +
          names[1][0].toUpperCase(); // Hasil: "AR"
    }
    // KASUS 2: Jika HANYA ADA 1 KATA (misal: "Alfarizi")
    else if (names.isNotEmpty) {
      return names[0][0].toUpperCase(); // Hasil: "A"
    }
    // KASUS 3: Jika nama hanya berisi spasi (sudah difilter, tapi untuk keamanan)
    else {
      return 'G';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    // Kita gunakan 'watch' agar inisial nama ikut update jika nama diganti
    final user = Provider.of<AuthProvider>(context).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Data pengguna tidak ditemukan.")),
      );
    }

    return GestureDetector(
      onTap: _unfocus,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: themeProvider.isDarkMode
              ? const Color(0xFF1F1F1F)
              : theme.appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _unfocus();
              Navigator.of(context).pop();
            },
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: false,
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else
              TextButton(
                onPressed: _onSave,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            // --- PERUBAHAN: Avatar dengan Inisial ---
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  _getInitials(_nameController.text),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            // Tombol Change Photo dihapus
            const SizedBox(height: 32),
            Text(
              'Personal Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // --- Field yang Bisa Diedit ---
            _buildEditableField(
              theme: theme,
              label: 'Full Name',
              controller: _nameController,
              focusNode: _nameFocus,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 24),
            _buildEditableField(
              theme: theme,
              label: 'Phone Number',
              controller: _phoneController,
              focusNode: _phoneFocus,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            _buildEditableField(
              theme: theme,
              label: 'Alamat',
              controller: _alamatController,
              focusNode: _alamatFocus,
              icon: Icons.home_outlined,
            ),
            const SizedBox(height: 24),
            _buildLockedField(theme: theme, label: 'E-mail', value: user.email),
            const SizedBox(height: 24),

            // --- Field yang Terkunci ---
            _buildLockedField(
              theme: theme,
              label: 'Nomor KTP',
              value: user.noKtp.isNotEmpty ? user.noKtp : 'Belum diisi',
            ),
          ],
        ),
      ),
    );
  }

  /// Widget untuk field yang bisa diedit
  Widget _buildEditableField({
    required ThemeData theme,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            suffixIcon: Icon(
              icon,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Widget untuk field yang tidak bisa diedit
  Widget _buildLockedField({
    required ThemeData theme,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ),
            Icon(
              Icons.lock_outline,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ],
        ),
      ],
    );
  }
}
