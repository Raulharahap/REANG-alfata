import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

class DetailPesananAdminScreen extends StatefulWidget {
  final dynamic transaksi; // Menerima data transaksi mentah dari list
  final VoidCallback onActionSuccess;

  const DetailPesananAdminScreen({
    super.key,
    required this.transaksi,
    required this.onActionSuccess,
  });

  @override
  State<DetailPesananAdminScreen> createState() =>
      _DetailPesananAdminScreenState();
}

class _DetailPesananAdminScreenState extends State<DetailPesananAdminScreen> {
  final ApiService _apiService = ApiService();
  late String _token;
  late AuthProvider _authProvider;

  bool _isConfirming = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _token = _authProvider.token ?? '';
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
      textStyle: TextStyle(color: theme.colorScheme.onError),
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 3),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _runApiAction(
    Future<dynamic> Function() apiCall,
    String successMessage,
    Function(bool) setLoading,
  ) {
    setLoading(true);
    return apiCall()
        .then((response) {
          _showToast(response['message'] ?? successMessage);
          Navigator.pop(context); // Tutup halaman detail
          widget.onActionSuccess(); // Trigger refresh di list utama
        })
        .catchError((e) {
          _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
        })
        .whenComplete(() {
          if (mounted) setLoading(false);
        });
  }

  void _onConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terima Pembayaran?'),
        content: const Text(
          'Apakah Anda yakin bukti pembayaran valid? Sistem akan otomatis membuat Tiket Digital untuk pembeli ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runApiAction(
                () => _apiService.konfirmasiPembayaranAdmin(
                  token: _token,
                  transaksiId: widget.transaksi['id'],
                  aksi: 'terima',
                ),
                'Pembayaran dikonfirmasi! Tiket diterbitkan.',
                (isLoading) => setState(() => _isConfirming = isLoading),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Terima'),
          ),
        ],
      ),
    );
  }

  void _onReject() {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tolak Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Berikan alasan penolakan agar pembeli dapat memperbaikinya (misal: Bukti transfer buram/kurang).',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: alasanController,
              decoration: const InputDecoration(
                hintText: 'Masukkan alasan...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (alasanController.text.trim().isEmpty) {
                _showToast('Alasan wajib diisi!', isError: true);
                return;
              }
              Navigator.pop(ctx);
              _runApiAction(
                () => _apiService.konfirmasiPembayaranAdmin(
                  token: _token,
                  transaksiId: widget.transaksi['id'],
                  aksi: 'tolak',
                  keteranganAdmin: alasanController.text.trim(),
                ),
                'Pembayaran berhasil ditolak.',
                (isLoading) => setState(() => _isRejecting = isLoading),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tolak Pesanan'),
          ),
        ],
      ),
    );
  }

  void _openImagePreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _ImagePreviewScreen(imageUrl: imageUrl),
      ),
    );
  }

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transaksi = widget.transaksi;
    final bool isActionLoading = _isConfirming || _isRejecting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Verifikasi Pesanan'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: isActionLoading
              ? const LinearProgressIndicator()
              : Container(),
        ),
      ),
      bottomNavigationBar: _buildDynamicActionButtons(
        theme,
        transaksi,
        isActionLoading,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(theme, transaksi),
            const SizedBox(height: 16),

            // Bukti Pembayaran
            if (transaksi['bukti_pembayaran'] != null) ...[
              _buildPaymentProofCard(theme, transaksi['bukti_pembayaran']),
              const SizedBox(height: 16),
            ],

            _buildDetailDestinasiCard(theme, transaksi),
            const SizedBox(height: 16),

            _buildInfoPelangganCard(theme, transaksi),
            const SizedBox(height: 16),

            _buildCostCard(theme, transaksi),
          ],
        ),
      ),
    );
  }

  // --- WIDGET BUILDER ---

  Widget _buildStatusCard(ThemeData theme, dynamic transaksi) {
    String statusUi = 'DIPROSES';
    Color statusColor = Colors.blue;

    switch (transaksi['status_pembayaran']) {
      case 'pending':
        statusUi = 'BELUM BAYAR';
        statusColor = Colors.orange;
        break;
      case 'menunggu_konfirmasi':
        statusUi = 'MENUNGGU VERIFIKASI';
        statusColor = Colors.blue;
        break;
      case 'lunas':
        statusUi = 'LUNAS / TIKET AKTIF';
        statusColor = Colors.green;
        break;
      case 'ditolak':
        statusUi = 'DITOLAK';
        statusColor = Colors.red;
        break;
    }

    return Card(
      elevation: 1,
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
              statusUi,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              theme: theme,
              label: 'No. Invoice',
              value: transaksi['kode_invoice'] ?? '-',
              onCopy: () {
                Clipboard.setData(
                  ClipboardData(text: transaksi['kode_invoice']),
                );
                _showToast('No Invoice disalin');
              },
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              label: 'Tgl. Transaksi',
              value: transaksi['created_at'] != null
                  ? transaksi['created_at'].toString().substring(0, 16)
                  : '-',
            ),

            if (transaksi['status_pembayaran'] == 'ditolak' &&
                transaksi['keterangan_admin'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Alasan Ditolak:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaksi['keterangan_admin'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProofCard(ThemeData theme, String buktiBayarUrl) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bukti Pembayaran Pelanggan",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openImagePreview(context, buktiBayarUrl),
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        buktiBayarUrl,
                        fit: BoxFit.cover,
                        headers: const {'ngrok-skip-browser-warning': 'true'},
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPelangganCard(ThemeData theme, dynamic transaksi) {
    final user = transaksi['user'] ?? {};
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pelanggan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              theme: theme,
              icon: Icons.person_outline,
              label: 'Nama',
              value: user['name'] ?? '-',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              icon: Icons.email_outlined,
              label: 'Email',
              value: user['email'] ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailDestinasiCard(ThemeData theme, dynamic transaksi) {
    String namaDestinasi = 'Tiket';
    String fotoUrl = '';
    if (transaksi['kategori_tiket'] == 'wisata' &&
        transaksi['wisata'] != null) {
      namaDestinasi = transaksi['wisata']['nama_wisata'];
      fotoUrl = transaksi['wisata']['foto_utama'] ?? '';
    } else if (transaksi['kategori_tiket'] == 'event' &&
        transaksi['event'] != null) {
      namaDestinasi = transaksi['event']['nama_event'];
      fotoUrl = transaksi['event']['foto_utama'] ?? '';
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Destinasi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    fotoUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    headers: const {'ngrok-skip-browser-warning': 'true'},
                    errorBuilder: (c, e, s) => Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaDestinasi,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kategori: ${transaksi['kategori_tiket'].toString().toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      if (transaksi['varian'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Kelas: ${transaksi['varian']['nama_kelas']}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(ThemeData theme, dynamic transaksi) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Biaya',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              theme: theme,
              label: 'Harga Tiket',
              value: _formatCurrency(
                (transaksi['total_harga'] ?? 0) ~/
                    (transaksi['jumlah_tiket'] ?? 1),
              ),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              label: 'Jumlah Pembelian',
              value: 'x ${transaksi['jumlah_tiket']} Tiket',
            ),
            const Divider(height: 24, thickness: 1),
            _InfoRow(
              theme: theme,
              label: 'Total Tagihan',
              value: _formatCurrency(transaksi['total_harga']),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildDynamicActionButtons(
    ThemeData theme,
    dynamic transaksi,
    bool isActionLoading,
  ) {
    if (transaksi['status_pembayaran'] != 'menunggu_konfirmasi') return null;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isActionLoading ? null : _onReject,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Tolak",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isActionLoading ? null : _onConfirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Terima Pembayaran",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER INTERNAL ---

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.theme,
    required this.label,
    required this.value,
    this.icon,
    this.isTotal = false,
    this.onCopy,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final IconData? icon;
  final bool isTotal;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Row(
            children: [
              if (icon != null) Icon(icon, size: 16, color: theme.hintColor),
              if (icon != null) const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.end,
                  style: isTotal
                      ? theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        )
                      : theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
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

class _ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  const _ImagePreviewScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                headers: const {'ngrok-skip-browser-warning': 'true'},
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black.withOpacity(0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
