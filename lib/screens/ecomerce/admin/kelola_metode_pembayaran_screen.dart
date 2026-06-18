import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/payment_method_model.dart'; // <-- Pastikan model ini ada
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'form_metode_pembayaran_screen.dart';

class KelolaMetodePembayaranScreen extends StatefulWidget {
  const KelolaMetodePembayaranScreen({super.key});

  @override
  State<KelolaMetodePembayaranScreen> createState() =>
      _KelolaMetodePembayaranScreenState();
}

class _KelolaMetodePembayaranScreenState
    extends State<KelolaMetodePembayaranScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<PaymentMethodModel>> _metodeFuture;
  late AuthProvider _authProvider; // Untuk token & idToko

  @override
  void initState() {
    super.initState();
    // Kita tidak bisa 'await' di initState, jadi panggil fungsi
    // yang akan menginisialisasi datanya
    // context.read() aman di initState
    _authProvider = context.read<AuthProvider>();
    _metodeFuture = _fetchMetodePembayaran();
  }

  /// Mengambil data dari API
  Future<List<PaymentMethodModel>> _fetchMetodePembayaran() async {
    if (!_authProvider.isLoggedIn || _authProvider.user?.idToko == null) {
      throw Exception('ID Toko tidak ditemukan. Silakan login ulang.');
    }

    return _apiService.getPaymentMethodsForToko(
      token: _authProvider.token!,
      idToko: _authProvider.user!.idToko!,
    );
  }

  /// Memuat ulang data
  Future<void> _refreshData() async {
    setState(() {
      _metodeFuture = _fetchMetodePembayaran();
    });
  }

  /// Menampilkan toast
  void _showToast(String message, {bool isError = false}) {
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

  /// Logika Hapus Data
  Future<void> _hapusMetode(PaymentMethodModel metode) async {
    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Metode?"),
        content: Text(
          "Anda yakin ingin menghapus '${metode.namaMetode}'?\n"
          "(${metode.nomorTujuan})",
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
      final response = await _apiService.deleteMetodePembayaran(
        token: _authProvider.token!,
        idToko: _authProvider.user!.idToko!,
        metodeId: metode.id,
      );
      _showToast(response['message'] ?? 'Berhasil dihapus');
      _refreshData(); // Muat ulang data setelah berhasil
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    }
  }

  /// Navigasi ke halaman Tambah/Edit
  void _goToForm({PaymentMethodModel? metode}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Arahkan ke form yang baru kita buat
        builder: (context) => FormMetodePembayaranScreen(metode: metode),
      ),
    ).then((result) {
      // Jika form mengembalikan 'true' (artinya ada perubahan), refresh data
      if (result == true) {
        _refreshData(); // Panggil fungsi refresh
      }
    });

    // Hapus baris _showToast di bawah ini
    // _showToast('TODO: Buka halaman tambah/edit metode bayar');
  }

  IconData _getIconForType(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'bank':
        return Icons.account_balance_outlined;
      case 'qris':
        return Icons.qr_code_2_outlined;
      case 'ewallet': // (Anda mungkin akan menambah ini nanti)
        return Icons.wallet_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Metode Pembayaran')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(metode: null), // Panggil form tambah
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<PaymentMethodModel>>(
        future: _metodeFuture,
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
          final listMetode = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: listMetode.length,
              itemBuilder: (context, index) {
                final metode = listMetode[index];

                // Tentukan subtitle berdasarkan jenis
                String subtitle =
                    "${metode.namaPenerima}\n${metode.nomorTujuan}";
                if (metode.jenis.toLowerCase() == 'qris') {
                  subtitle = metode.keterangan ?? 'QRIS Toko';
                }

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
                      _getIconForType(metode.jenis),
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      metode.namaMetode,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(subtitle),
                    isThreeLine: metode.jenis.toLowerCase() == 'bank',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tombol Edit
                        IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () => _goToForm(metode: metode),
                        ),
                        // Tombol Hapus
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () => _hapusMetode(metode),
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
      child: ListView(
        // Gunakan ListView agar bisa di-scroll/refresh
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Ikon Besar & Tidak Seram
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_card_outlined, // Ikon kartu +
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              // 2. Teks Judul
              Text(
                'Belum Ada Metode Pembayaran',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // 3. Teks Penjelasan
              Text(
                'Toko Anda belum bisa menerima pembayaran.\nTambahkan rekening atau QRIS sekarang.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // 4. Tombol Aksi di Tengah (Opsional, tapi bagus untuk UX)
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => _goToForm(metode: null),
                  icon: const Icon(Icons.add),
                  label: const Text("Tambah Metode"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
