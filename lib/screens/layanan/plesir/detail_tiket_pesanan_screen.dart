import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Jangan lupa package QR-nya

import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/instruksi_checkout_screen.dart';

class DetailTiketPesananScreen extends StatefulWidget {
  final dynamic data;
  final String tabType;

  const DetailTiketPesananScreen({
    super.key,
    required this.data,
    required this.tabType,
  });

  @override
  State<DetailTiketPesananScreen> createState() =>
      _DetailTiketPesananScreenState();
}

class _DetailTiketPesananScreenState extends State<DetailTiketPesananScreen> {
  final ApiService _apiService = ApiService();
  late dynamic _transaksi;

  @override
  void initState() {
    super.initState();
    // 👇 Sangat simpel: Langsung pakai data mentah, tidak perlu if/else lagi
    _transaksi = widget.data;
  }

  void _showToast(String message, {bool isError = false}) {
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

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: NetworkImage(
                imageUrl,
                headers: const {'ngrok-skip-browser-warning': 'true'},
              ),
              minScale: PhotoViewComputedScale.contained,
            ),
            Positioned(
              top: 40,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGantiMetodeBottomSheet() {
    final String kategori = _transaksi['kategori_tiket'] ?? 'wisata';
    final int targetId = kategori == 'wisata'
        ? _transaksi['wisata_id']
        : _transaksi['event_id'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return FutureBuilder(
          future: _apiService.getMetodeCheckoutPlesir(
            kategori: kategori,
            targetId: targetId,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF0F4C81)),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                (snapshot.data as List).isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(
                  child: Text("Gagal memuat atau tidak ada metode tersedia."),
                ),
              );
            }

            final metodeList = snapshot.data as List;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Pilih Metode Pembayaran Baru",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(height: 24),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: metodeList.length,
                      itemBuilder: (context, index) {
                        final metode = metodeList[index];
                        final bool isQris = metode['jenis_metode'] == 'QRIS';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 4,
                          ),
                          leading: Icon(
                            isQris
                                ? Icons.qr_code_scanner
                                : Icons.account_balance,
                            color: const Color(0xFF0F4C81),
                            size: 28,
                          ),
                          title: Text(
                            metode['nama_metode'] ?? '-',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            isQris
                                ? 'Bayar pakai E-Wallet/M-Banking'
                                : 'Transfer Manual',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Colors.grey,
                          ),
                          onTap: () async {
                            Navigator.pop(ctx);

                            setState(() {
                              _transaksi['metode_pembayaran'] = metode;
                            });

                            final token = context.read<AuthProvider>().token;
                            if (token != null) {
                              try {
                                await _apiService
                                    .updateMetodePembayaranTransaksiPlesir(
                                      token,
                                      _transaksi['id'],
                                      metode['id'],
                                    );
                                _showToast('Metode pembayaran berhasil diubah');
                              } catch (e) {
                                _showToast(
                                  'Gagal merubah metode di server',
                                  isError: true,
                                );
                              }
                            }

                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => InstruksiCheckoutScreen(
                                    transaksiId: _transaksi['id'],
                                    totalHarga: _transaksi['total_harga'] ?? 0,
                                    selectedMetode: metode,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_transaksi == null) {
      return const Scaffold(body: Center(child: Text('Data tidak valid')));
    }

    final bool isDitolak = widget.tabType == 'ditolak';
    final bool isPending = widget.tabType == 'pending';
    final bool isAktif = widget.tabType == 'aktif';
    final bool isTerpakai = widget.tabType == 'terpakai';
    final bool tampilkanQR =
        isAktif || isTerpakai; // QR tampil jika Lunas atau Selesai

    String namaDestinasi = 'Tiket Plesir';
    String fotoUrl = '';
    if (_transaksi['kategori_tiket'] == 'wisata' &&
        _transaksi['wisata'] != null) {
      namaDestinasi = _transaksi['wisata']['nama_wisata'] ?? '';
      fotoUrl = _transaksi['wisata']['foto_utama'] ?? '';
    } else if (_transaksi['kategori_tiket'] == 'event' &&
        _transaksi['event'] != null) {
      namaDestinasi = _transaksi['event']['nama_event'] ?? '';
      fotoUrl = _transaksi['event']['foto_utama'] ?? '';
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
          ? _buildBottomButton(_transaksi, isDitolak)
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (tampilkanQR) _buildQRCodeCard(theme, _transaksi, isAktif),
            if (tampilkanQR) const SizedBox(height: 16),

            _buildInfoTransaksiCard(theme, _transaksi, widget.tabType),
            const SizedBox(height: 16),

            if (isDitolak && _transaksi['keterangan_admin'] != null) ...[
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
                      _transaksi['keterangan_admin'],
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _buildDetailDestinasiCard(
              theme,
              _transaksi,
              namaDestinasi,
              fotoUrl,
            ),
            const SizedBox(height: 16),

            _buildMetodePembayaranCard(theme, _transaksi),
            const SizedBox(height: 16),

            _buildRincianPembayaranCard(theme, _transaksi),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- CARD GENERATOR QR CODE ---
  Widget _buildQRCodeCard(ThemeData theme, dynamic tiketData, bool isAktif) {
    final String kodeTiket = tiketData['kode_tiket']?.toString() ?? '';

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
            const SizedBox(height: 20),

            if (kodeTiket.isNotEmpty && kodeTiket != 'null')
              QrImageView(
                data: kodeTiket,
                version: QrVersions.auto,
                size: 160.0,
                gapless: false,
                // Jika statusnya sudah terpakai/selesai, QR code berubah jadi abu-abu buram
                foregroundColor: isAktif
                    ? const Color(0xFF0F4C81)
                    : Colors.grey.shade400,
              )
            else
              Container(
                width: 160,
                height: 160,
                color: Colors.grey.shade100,
                child: const Center(
                  child: Text(
                    'Menyiapkan Tiket...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isAktif ? Colors.blue.shade50 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                kodeTiket.isNotEmpty ? kodeTiket : '-',
                style: TextStyle(
                  fontSize: 18,
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

  Widget _buildInfoTransaksiCard(
    ThemeData theme,
    dynamic transaksi,
    String tabType,
  ) {
    String statusTeks = 'DIPROSES';
    Color statusWarna = Colors.blue;

    if (tabType == 'pending') {
      statusTeks = 'BELUM BAYAR';
      statusWarna = Colors.orange.shade800;
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
      statusTeks = 'SELESAI / TERPAKAI';
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
              'No. Invoice',
              transaksi['kode_invoice'] ?? '-',
              showCopy: true,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
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
                    headers: const {'ngrok-skip-browser-warning': 'true'},
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

  Widget _buildMetodePembayaranCard(ThemeData theme, dynamic transaksi) {
    final metode = transaksi['metode_pembayaran'];

    if (metode == null) {
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
                'Metode Pembayaran',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
              Text(
                'Belum ada metode pembayaran yang dipilih.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final String jenisMetode = (metode['jenis_metode'] ?? '')
        .toString()
        .toUpperCase();
    final bool isQris = jenisMetode == 'QRIS';

    final String? fotoQrisUrl = metode['foto_qris']?.toString();

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
              'Metode Pembayaran Terpilih',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Jenis', metode['jenis_metode'] ?? '-'),
            const SizedBox(height: 12),
            _buildInfoRow('Nama Layanan', metode['nama_metode'] ?? '-'),
            const SizedBox(height: 12),

            if (isQris && fotoQrisUrl != null) ...[
              const Text('Kode QRIS:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _showImagePreview(fotoQrisUrl),
                icon: const Icon(
                  Icons.qr_code_scanner,
                  color: Color(0xFF0F4C81),
                ),
                label: const Text(
                  'Lihat Kode QRIS',
                  style: TextStyle(color: Color(0xFF0F4C81)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0F4C81)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ] else if (isQris && fotoQrisUrl == null) ...[
              const Text('Kode QRIS:', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              const Text(
                'Gambar QRIS tidak tersedia.',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              _buildInfoRow(
                'No. Rekening/Tujuan',
                metode['nomor_rekening'] ?? '-',
                showCopy: true,
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Atas Nama', metode['nama_penerima'] ?? '-'),
            ],
          ],
        ),
      ),
    );
  }

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
              'Harga Tiket',
              _formatCurrency(
                (transaksi['total_harga'] ?? 0) ~/
                    (transaksi['jumlah_tiket'] ?? 1),
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Jumlah Tiket', 'x ${transaksi['jumlah_tiket']}'),
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

  Widget _buildInfoRow(String label, String value, {bool showCopy = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (showCopy) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  _showToast('$label disalin');
                },
                child: const Icon(Icons.copy, size: 16, color: Colors.grey),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildBottomButton(dynamic transaksi, bool isDitolak) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                final metode = transaksi['metode_pembayaran'];

                if (metode == null || metode.isEmpty) {
                  _showToast(
                    'Silakan pilih Ganti Metode Pembayaran terlebih dahulu.',
                    isError: true,
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstruksiCheckoutScreen(
                      transaksiId: transaksi['id'],
                      totalHarga: transaksi['total_harga'] ?? 0,
                      selectedMetode: metode,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: Text(
                isDitolak
                    ? 'Upload Ulang Bukti Transfer'
                    : 'Bayar Sekarang & Upload Bukti',
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
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showGantiMetodeBottomSheet,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Ganti Metode Pembayaran'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F4C81),
                side: const BorderSide(color: Color(0xFF0F4C81)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
