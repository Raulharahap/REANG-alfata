import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/screens/layanan/plesir/instruksi_checkout_screen.dart';

class DetailTiketPesananScreen extends StatelessWidget {
  final dynamic data;
  final bool
  isTiketDigital; // True untuk tab Aktif/Selesai, False untuk Pending/Verifikasi/Ditolak
  final String tabType;

  const DetailTiketPesananScreen({
    super.key,
    required this.data,
    required this.isTiketDigital,
    required this.tabType,
  });

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.black87,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(25),
      duration: const Duration(seconds: 2),
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

    // Ekstrak data transaksi utama
    final transaksi = isTiketDigital ? data['transaksi'] : data;
    if (transaksi == null)
      return const Scaffold(body: Center(child: Text('Data tidak valid')));

    final bool isDitolak = tabType == 'ditolak';
    final bool isPending = tabType == 'pending';
    final bool isAktif = tabType == 'aktif';

    // Ambil nama destinasi dan foto
    String namaDestinasi = 'Tiket Plesir';
    String fotoUrl = '';
    if (transaksi['kategori_tiket'] == 'wisata' &&
        transaksi['wisata'] != null) {
      namaDestinasi = transaksi['wisata']['nama_wisata'] ?? '';
      fotoUrl = transaksi['wisata']['foto_utama'] ?? '';
    } else if (transaksi['kategori_tiket'] == 'event' &&
        transaksi['event'] != null) {
      namaDestinasi = transaksi['event']['nama_event'] ?? '';
      fotoUrl = transaksi['event']['foto_utama'] ?? '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan Tiket',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: (isPending || isDitolak)
          ? _buildBottomButton(context, transaksi, isDitolak)
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Jika tiket digital, tampilkan QR Code / Barcode besar di atas
            if (isTiketDigital) _buildQRCodeCard(theme, data, isAktif),
            if (isTiketDigital) const SizedBox(height: 16),

            _buildInfoTransaksiCard(context, theme, transaksi, tabType),
            const SizedBox(height: 16),
            _buildDetailDestinasiCard(theme, transaksi, namaDestinasi, fotoUrl),
            const SizedBox(height: 16),
            _buildRincianPembayaranCard(theme, transaksi),

            // Keterangan Ditolak
            if (isDitolak && transaksi['keterangan_admin'] != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alasan Penolakan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      transaksi['keterangan_admin'],
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- 1. CARD QR CODE (KHUSUS TIKET DIGITAL) ---
  Widget _buildQRCodeCard(ThemeData theme, dynamic tiketData, bool isAktif) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              isAktif
                  ? 'Tunjukkan QR/Kode ini ke Petugas'
                  : 'Tiket Sudah Digunakan',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.qr_code_2,
              size: 120,
              color: isAktif ? const Color(0xFF0F4C81) : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAktif ? Colors.blue.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tiketData['kode_tiket'] ?? '-',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: isAktif
                      ? const Color(0xFF0F4C81)
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. CARD INFO TRANSAKSI ---
  Widget _buildInfoTransaksiCard(
    BuildContext context,
    ThemeData theme,
    dynamic transaksi,
    String tabType,
  ) {
    String statusTeks = 'DIPROSES';
    Color statusWarna = Colors.blue;

    if (tabType == 'pending') {
      statusTeks = 'BELUM BAYAR';
      statusWarna = Colors.orange;
    } else if (tabType == 'verifikasi') {
      statusTeks = 'MENUNGGU VERIFIKASI';
      statusWarna = Colors.blue;
    } else if (tabType == 'ditolak') {
      statusTeks = 'DITOLAK';
      statusWarna = Colors.red;
    } else if (tabType == 'aktif') {
      statusTeks = 'LUNAS (AKTIF)';
      statusWarna = Colors.green;
    } else if (tabType == 'terpakai') {
      statusTeks = 'SELESAI';
      statusWarna = Colors.grey;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Pembayaran',
              style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              statusTeks,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusWarna,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              context,
              'No. Invoice',
              transaksi['kode_invoice'] ?? '-',
              showCopy: true,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Tgl. Pembelian',
              transaksi['created_at'] != null
                  ? transaksi['created_at'].toString().substring(0, 10)
                  : '-',
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. CARD DETAIL DESTINASI ---
  Widget _buildDetailDestinasiCard(
    ThemeData theme,
    dynamic transaksi,
    String namaDestinasi,
    String fotoUrl,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      width: 70,
                      height: 70,
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
                      const SizedBox(height: 4),
                      Text(
                        '${transaksi['jumlah_tiket']} Tiket',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F4C81),
                        ),
                      ),
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

  // --- 4. CARD RINCIAN PEMBAYARAN ---
  Widget _buildRincianPembayaranCard(ThemeData theme, dynamic transaksi) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
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
            _buildInfoRow(
              null,
              'Harga Tiket',
              _formatCurrency(
                (transaksi['total_harga'] ?? 0) ~/
                    (transaksi['jumlah_tiket'] ?? 1),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              null,
              'Jumlah Tiket',
              'x ${transaksi['jumlah_tiket']}',
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _formatCurrency(transaksi['total_harga'] ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0F4C81),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER: INFO ROW ---
  Widget _buildInfoRow(
    BuildContext? context,
    String label,
    String value, {
    bool showCopy = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (showCopy && context != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _showToast(context, '$label disalin');
                },
                child: const Icon(Icons.copy, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // --- TOMBOL BAWAH (UPLOAD BUKTI) ---
  Widget _buildBottomButton(
    BuildContext context,
    dynamic transaksi,
    bool isDitolak,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InstruksiCheckoutScreen(
                transaksiId: transaksi['id'],
                totalHarga: transaksi['total_harga'] ?? 0,
              ),
            ),
          );
        },
        icon: const Icon(Icons.upload_file),
        label: Text(
          isDitolak ? 'Upload Ulang Bukti Transfer' : 'Upload Bukti Pembayaran',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F4C81),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
