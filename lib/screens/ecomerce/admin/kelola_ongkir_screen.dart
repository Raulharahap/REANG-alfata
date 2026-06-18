// Lokasi: lib/screens/ecomerce/admin/kelola_ongkir_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/ongkir_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

// Import halaman form yang baru dibuat
import 'form_ongkir_screen.dart';

class KelolaOngkirScreen extends StatefulWidget {
  const KelolaOngkirScreen({super.key});

  @override
  State<KelolaOngkirScreen> createState() => _KelolaOngkirScreenState();
}

class _KelolaOngkirScreenState extends State<KelolaOngkirScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<OngkirModel>> _ongkirFuture;
  late AuthProvider _authProvider;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _ongkirFuture = _fetchOngkir();
  }

  /// Mengambil data dari API
  Future<List<OngkirModel>> _fetchOngkir() async {
    if (!_authProvider.isLoggedIn || _authProvider.user?.idToko == null) {
      throw Exception('ID Toko tidak ditemukan. Silakan login ulang.');
    }

    // Fungsi ini sudah ada di ApiService Anda
    return _apiService.getOngkirOptions(
      token: _authProvider.token!,
      idToko: _authProvider.user!.idToko!,
    );
  }

  /// Memuat ulang data
  Future<void> _refreshData() async {
    setState(() {
      _ongkirFuture = _fetchOngkir();
    });
  }

  /// Menampilkan toast
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      // ... (style toast lainnya)
      backgroundColor: isError
          ? theme.colorScheme.error
          : Colors.black.withOpacity(0.8),
    );
  }

  /// Logika Hapus Data
  Future<void> _hapusOngkir(OngkirModel ongkir) async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Ongkir?"),
        content: Text(
          "Anda yakin ingin menghapus ongkir untuk daerah '${ongkir.daerah}'?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Ya, Hapus",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final response = await _apiService.deleteOngkir(
        token: _authProvider.token!,
        idToko: _authProvider.user!.idToko!,
        ongkirId: ongkir.id,
      );
      _showToast(response['message'] ?? 'Berhasil dihapus');
      _refreshData(); // Muat ulang data
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    }
  }

  /// Navigasi ke halaman Tambah/Edit
  void _goToForm({OngkirModel? ongkir}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormOngkirScreen(ongkir: ongkir)),
    ).then((result) {
      // Jika form mengembalikan 'true' (artinya ada perubahan), refresh data
      if (result == true) {
        _refreshData();
      }
    });
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Opsi Pengiriman')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(ongkir: null), // Panggil form tambah
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<OngkirModel>>(
        future: _ongkirFuture,
        builder: (context, snapshot) {
          // --- 1. Saat Loading ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- 2. Jika Gagal (Error) ---
          if (snapshot.hasError) {
            return _buildErrorState(theme, snapshot.error.toString());
          }

          // --- 3. Jika Sukses tapi Kosong ---
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(theme);
          }

          // --- 4. Jika Sukses dan Ada Data ---
          final listOngkir = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: listOngkir.length,
              itemBuilder: (context, index) {
                final option = listOngkir[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Icon(
                      Icons.local_shipping_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      option.daerah,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _formatCurrency(option.harga),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary.withOpacity(0.8),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Edit
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _goToForm(ongkir: option),
                        ),
                        // Tombol Hapus
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _hapusOngkir(option),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Helper untuk State Kosong
  Widget _buildEmptyState(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_shipping_outlined,
                size: 80,
                color: theme.hintColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Opsi Ongkir',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Tambahkan jangkauan daerah dan harga ongkir agar pelanggan dapat memesan.',
                style: TextStyle(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk State Error
  Widget _buildErrorState(ThemeData theme, String error) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Data',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                error.replaceAll("Exception: ", ""),
                style: TextStyle(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
