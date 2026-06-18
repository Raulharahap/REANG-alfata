import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/detail_transaksi_response.dart';
import 'package:reang_app/models/riwayat_transaksi_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/screens/ecomerce/chat_umkm_screen.dart';

class DetailOrderScreen extends StatefulWidget {
  final String noTransaksi;
  const DetailOrderScreen({super.key, required this.noTransaksi});

  @override
  State<DetailOrderScreen> createState() => _DetailOrderScreenState();
}

class _DetailOrderScreenState extends State<DetailOrderScreen> {
  late Future<DetailTransaksiResponse> _detailFuture;
  final ApiService _apiService = ApiService();
  bool _isCancelling = false; // State untuk loading tombol batal

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      setState(() {
        _detailFuture = _apiService.fetchDetailTransaksi(
          token: auth.token!,
          noTransaksi: widget.noTransaksi,
        );
      });
    } else {
      _detailFuture = Future.error(
        'Gagal memuat detail: Sesi tidak ditemukan.',
      );
    }
  }

  // Helper untuk menampilkan StyledToast
  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      curve: Curves.fastOutSlowIn,
      backgroundColor: isError
          ? theme
                .colorScheme
                .error // Merah untuk error
          : Colors.black.withOpacity(0.8), // Hitam transparan untuk info
    );
  }

  // --- FUNGSI MENUJU CHAT PENJUAL ---
  Future<void> _goToChat(int idToko) async {
    final authProvider = context.read<AuthProvider>();

    // 1. Cek Login
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      _showToast(context, 'Silakan login terlebih dahulu', isError: true);
      // Opsional: Arahkan ke Login Screen
      return;
    }

    // 2. Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 3. Pastikan Firebase Login (Tukar Token jika perlu)
      await authProvider.ensureFirebaseLoggedIn();

      // 4. Ambil Data Toko (untuk dapatkan ID Pemilik)
      final apiService = ApiService();
      final TokoModel tokoTarget = await apiService.fetchDetailToko(
        idToko: idToko,
        token: authProvider.token!,
      );

      if (mounted) {
        Navigator.pop(context); // Tutup Loading

        // 5. Buka Halaman Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatUMKMScreen(toko: tokoTarget),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup Loading
        _showToast(
          context,
          'Gagal membuka chat: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        );
      }
    }
  }

  // Fungsi untuk membatalkan pesanan
  Future<void> _handleCancelOrder(String noTransaksi) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      _showToast(
        context,
        'Sesi Anda berakhir, silakan login ulang.',
        isError: true,
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diurungkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (shouldCancel != true) {
      return; // Pengguna menekan 'Tidak'
    }

    setState(() => _isCancelling = true);
    try {
      final response = await _apiService.batalkanPesanan(
        token: auth.token!,
        noTransaksi: noTransaksi,
      );
      _showToast(context, response['message'] ?? 'Pesanan berhasil dibatalkan');
      // Kirim 'true' kembali ke ProsesOrderScreen untuk memicu refresh
      Navigator.pop(context, true);
    } catch (e) {
      _showToast(
        context,
        e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DetailTransaksiResponse>(
      future: _detailFuture,
      builder: (context, snapshot) {
        // Logika untuk menampilkan Scaffold berdasarkan state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Memuat Detail...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Gagal Memuat Detail',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceAll("Exception: ", ""),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loadDetails,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData) {
          final response = snapshot.data!;
          final transaksi = response.transaksi;
          final items = response.items;
          final theme = Theme.of(context);

          // Tentukan apakah tombol batal boleh tampil
          final bool isForbidden =
              transaksi.status == 'dikirim' ||
              transaksi.status == 'selesai' ||
              transaksi.status == 'dibatalkan';

          final bool canCancel = !isForbidden;

          return Scaffold(
            appBar: AppBar(title: const Text('Detail Pesanan'), elevation: 1),
            // Tampilkan tombol batal HANYA jika status mengizinkan
            bottomNavigationBar: canCancel
                ? _buildCancelButton(context, theme, transaksi.noTransaksi)
                : null,
            body: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInfoTransaksiCard(context, theme, transaksi),
                  const SizedBox(height: 16),
                  _buildAlamatCard(context, theme, transaksi),
                  const SizedBox(height: 16),
                  _buildDaftarProdukCard(context, theme, items),
                  const SizedBox(height: 16),
                  _buildRincianPembayaranCard(context, theme, transaksi),
                  const SizedBox(height: 16),
                  _buildBantuanCard(context, theme, transaksi.idToko),
                ],
              ),
            ),
          );
        }

        return Container(); // Fallback
      },
    );
  }

  // Card 1: Info Status & Transaksi
  Widget _buildInfoTransaksiCard(
    BuildContext context,
    ThemeData theme,
    RiwayatTransaksiModel transaksi,
  ) {
    // Logika warna status dari ProsesOrderScreen
    Color statusColor;
    switch (transaksi.getTabKategori) {
      case 'Selesai':
        statusColor = Colors.green;
        break;
      case 'Dibatalkan':
      case 'Belum Dibayar':
        statusColor = theme.colorScheme.error;
        break;
      default:
        statusColor = theme.colorScheme.primary;
    }

    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Pesanan',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              transaksi.getUiStatus,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Divider(height: 24),

            _InfoRow(
              theme: theme,
              icon: Icons.store_outlined,
              label: 'Nama Toko',
              value: transaksi.namaToko,
            ),
            const SizedBox(height: 12),

            _InfoRow(
              theme: theme,
              icon: Icons.phone_outlined, // Ikon telepon
              label: 'No. HP Toko',
              value: transaksi.noHpToko ?? '-', // Tampilkan nomor
              onCopy: () {
                // Fitur copy agar mudah disalin
                if (transaksi.noHpToko != null) {
                  Clipboard.setData(ClipboardData(text: transaksi.noHpToko!));
                  _showToast(context, 'Nomor HP Toko disalin');
                }
              },
            ),

            // [SELESAI TAMBAHAN]
            const SizedBox(height: 12),

            _InfoRow(
              theme: theme,
              icon: Icons.receipt_long_outlined,
              label: 'No. Transaksi',
              value: transaksi.noTransaksi,
              onCopy: () {
                Clipboard.setData(ClipboardData(text: transaksi.noTransaksi));
                _showToast(context, 'No. Transaksi disalin');
              },
            ),

            // [PERBAIKAN: TAMBAHKAN LOGIKA RESI DI SINI]
            // Tampilkan hanya jika status 'dikirim' atau 'selesai' DAN resi ada
            if ((transaksi.status == 'dikirim' ||
                    transaksi.status == 'selesai') &&
                transaksi.nomorResi != null &&
                transaksi.nomorResi!.isNotEmpty &&
                transaksi.nomorResi != '-') ...[
              const SizedBox(height: 12),
              _InfoRow(
                theme: theme,
                icon: Icons.local_shipping_outlined,
                label: 'Jasa Kirim',
                value: transaksi.jasaPengiriman, // <-- Data dari backend
                valueWeight: FontWeight.bold,
              ),

              // 2. Tampilkan Resi (Jika ada dan bukan '-')
              if (transaksi.nomorResi != null &&
                  transaksi.nomorResi!.isNotEmpty &&
                  transaksi.nomorResi != '-') ...[
                const SizedBox(height: 8),
                _InfoRow(
                  theme: theme,
                  icon: Icons.confirmation_number_outlined, // Ikon Resi
                  label: 'No. Resi',
                  value: transaksi.nomorResi!,
                  valueColor: Colors.blue.shade800,
                  valueWeight: FontWeight.bold,
                  onCopy: () {
                    Clipboard.setData(
                      ClipboardData(text: transaksi.nomorResi!),
                    );
                    _showToast(context, 'No. Resi disalin');
                  },
                ),
              ],
            ],

            // [SELESAI PERBAIKAN]
            const SizedBox(height: 12),

            _InfoRow(
              theme: theme,
              icon: Icons.calendar_today_outlined,
              label: 'Tgl. Pembelian',
              value: DateFormat(
                'dd MMM yyyy, HH:mm',
                'id_ID',
              ).format(transaksi.createdAt.toLocal()),
            ),
          ],
        ),
      ),
    );
  }

  // Card 2: Alamat Pengiriman
  Widget _buildAlamatCard(
    BuildContext context,
    ThemeData theme,
    RiwayatTransaksiModel transaksi,
  ) {
    final auth = context.read<AuthProvider>(); // Untuk ambil nama & no hp
    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alamat Pengiriman',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Text(
              auth.user?.name ?? 'Nama Penerima', // Ambil dari AuthProvider
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.user?.phone ?? '-', // Ambil dari AuthProvider
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              transaksi.alamat,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Card 3: Daftar Produk
  Widget _buildDaftarProdukCard(
    BuildContext context,
    ThemeData theme,
    List<ItemDetailModel> items,
  ) {
    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Produk (${items.length} item)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            // Gunakan Column, bukan ListView, agar tidak konflik scroll
            Column(
              children: items.map((item) {
                return _ProductDetailRow(
                  theme: theme,
                  item: item,
                  // Tampilkan divider untuk semua item KECUALI yang terakhir
                  showDivider: item != items.last,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Card 4: Rincian Pembayaran
  Widget _buildRincianPembayaranCard(
    BuildContext context,
    ThemeData theme,
    RiwayatTransaksiModel transaksi,
  ) {
    // Hitung biaya layanan jika ada
    double biayaLayanan =
        transaksi.total - transaksi.subtotal - transaksi.ongkir;
    // Hindari -0.0
    if (biayaLayanan < 0) biayaLayanan = 0;

    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Pembayaran',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              theme: theme,
              label: 'Metode Pembayaran',
              value: transaksi.metodePembayaran ?? '-',
              valueWeight: FontWeight.w600, // Tampilkan value tebal
            ),
            const Divider(height: 24),
            _InfoRow(
              theme: theme,
              label: 'Subtotal Produk',
              value: _formatCurrency(transaksi.subtotal),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              label: 'Ongkos Kirim',
              value: _formatCurrency(transaksi.ongkir),
            ),
            // Tampilkan biaya layanan hanya jika lebih dari 0
            if (biayaLayanan > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _InfoRow(
                  theme: theme,
                  label: 'Biaya Layanan',
                  value: _formatCurrency(biayaLayanan),
                ),
              ),
            const Divider(height: 24, thickness: 1),
            _InfoRow(
              theme: theme,
              label: 'Total Pembayaran',
              value: _formatCurrency(transaksi.total),
              labelWeight: FontWeight.bold,
              valueWeight: FontWeight.bold,
              valueSize: 18,
              valueColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBantuanCard(BuildContext context, ThemeData theme, int idToko) {
    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Butuh Bantuan?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),

            // --- HANYA TERSISA MENU HUBUNGI PENJUAL ---
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Hubungi Penjual'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => _goToChat(idToko),
            ),
            // ------------------------------------------
          ],
        ),
      ),
    );
  }

  // Tombol Batal
  Widget _buildCancelButton(
    BuildContext context,
    ThemeData theme,
    String noTransaksi,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16 + MediaQuery.of(context).padding.bottom, // Padding aman
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: ElevatedButton(
        onPressed: _isCancelling ? null : () => _handleCancelOrder(noTransaksi),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isCancelling
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Batalkan Pesanan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }
}

// ===============================================
// --- Widget Helper Internal ---
// ===============================================

// Widget untuk baris produk di Card 3
class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow({
    required this.theme,
    required this.item,
    required this.showDivider,
  });

  final ThemeData theme;
  final ItemDetailModel item;
  final bool showDivider;

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.foto ?? "",
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64,
                    height: 64,
                    color: theme.colorScheme.surfaceContainer,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.hintColor.withOpacity(0.7),
                      size: 30,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaProduk,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.jumlah} item x ${_formatCurrency(item.harga)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatCurrency(item.subtotal),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (showDivider) const Divider(height: 24),
      ],
    );
  }
}

// Widget untuk baris info (Label -> Value)
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.theme,
    required this.label,
    required this.value,
    this.icon,
    this.onCopy,
    this.labelWeight,
    this.valueWeight,
    this.valueSize,
    this.valueColor,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final IconData? icon;
  final VoidCallback? onCopy;
  final FontWeight? labelWeight;
  final FontWeight? valueWeight;
  final double? valueSize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2, // Beri label lebih banyak ruang
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: theme.hintColor),
              if (icon != null) const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                    fontWeight: labelWeight,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3, // Beri value lebih banyak ruang
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: valueWeight ?? FontWeight.w500,
                    fontSize: valueSize,
                    color: valueColor,
                  ),
                ),
              ),
              if (onCopy != null) const SizedBox(width: 8),
              if (onCopy != null)
                InkWell(
                  onTap: onCopy,
                  child: Icon(
                    Icons.copy_outlined,
                    size: 16,
                    color: theme.hintColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
