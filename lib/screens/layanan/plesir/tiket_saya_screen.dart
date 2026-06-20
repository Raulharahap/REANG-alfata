import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/instruksi_checkout_screen.dart';
import 'package:reang_app/screens/layanan/plesir/detail_tiket_pesanan_screen.dart';

class TiketSayaScreen extends StatefulWidget {
  const TiketSayaScreen({super.key});

  @override
  State<TiketSayaScreen> createState() => _TiketSayaScreenState();
}

class _TiketSayaScreenState extends State<TiketSayaScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  // --- STATE PENAMPUNG DATA 5 TAB ---
  List<dynamic> _pending = [];
  List<dynamic> _menungguVerifikasi = [];
  List<dynamic> _ditolak = [];
  List<dynamic> _aktif = [];
  List<dynamic> _terpakai = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final data = await _apiService.getSemuaTiketSaya(token);

        setState(() {
          _pending = data['pending'] ?? [];
          _menungguVerifikasi = data['menunggu_verifikasi'] ?? [];
          _ditolak = data['ditolak'] ?? [];
          _aktif = data['aktif'] ?? [];
          _terpakai = data['terpakai'] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat tiket saya: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatRupiah(int number) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(number);
  }

  // --- HELPER MENGAMBIL NAMA DESTINASI ---
  String _getNamaDestinasi(dynamic item) {
    try {
      if (item['kategori_tiket'] == 'wisata' && item['wisata'] != null) {
        return item['wisata']['nama_wisata'] ?? 'Destinasi Wisata';
      } else if (item['kategori_tiket'] == 'event' && item['event'] != null) {
        return item['event']['nama_event'] ?? 'Event Acara';
      }
    } catch (e) {
      return 'Tiket Plesir';
    }
    return 'Tiket Plesir';
  }

  // --- HELPER MENGAMBIL FOTO UTAMA DESTINASI ---
  String _getFotoDestinasi(dynamic item, {bool isTiketDigital = false}) {
    try {
      // Jika tab tiket digital, datanya ada di dalam objek 'transaksi'
      final target = isTiketDigital ? item['transaksi'] : item;
      if (target == null) return '';

      if (target['kategori_tiket'] == 'wisata' && target['wisata'] != null) {
        return target['wisata']['foto_utama'] ?? '';
      } else if (target['kategori_tiket'] == 'event' &&
          target['event'] != null) {
        return target['event']['foto_utama'] ?? '';
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Tiket Saya',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0F4C81),
            unselectedLabelColor: Colors.black45,
            indicatorColor: const Color(0xFF0F4C81),
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 14,
            ),
            // Menggunakan widget Tab() dengan custom child agar bisa dipasang Badge
            tabs: [
              _buildTabItem('Belum Bayar', _pending.length),
              _buildTabItem('Menunggu Verifikasi', _menungguVerifikasi.length),
              _buildTabItem('Ditolak', _ditolak.length, isError: true),
              _buildTabItem('Tiket Aktif', _aktif.length, isSuccess: true),
              _buildTabItem('Selesai', _terpakai.length),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF0F4C81)),
              )
            : TabBarView(
                children: [
                  _buildListTransaksi(_pending, 'pending'),
                  _buildListTransaksi(_menungguVerifikasi, 'verifikasi'),
                  _buildListTransaksi(_ditolak, 'ditolak'),
                  _buildListTiketDigital(_aktif, 'aktif'),
                  _buildListTiketDigital(_terpakai, 'terpakai'),
                ],
              ),
      ),
    );
  }

  // --- WIDGET TAB DENGAN BADGE NOTIFIKASI ---
  Tab _buildTabItem(
    String title,
    int count, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    Color badgeColor = Colors.red;
    if (isSuccess) badgeColor = Colors.green;
    if (count == 0) badgeColor = Colors.transparent;

    return Tab(
      child: Badge(
        isLabelVisible: count > 0,
        label: Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: badgeColor,
        offset: const Offset(
          12,
          -4,
        ), // Mengatur posisi badge agak ke kanan atas
        child: Padding(
          padding: const EdgeInsets.only(right: 8.0), // Jarak teks dengan badge
          child: Text(title),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET LIST UNTUK TAB 1, 2, 3 (TRANSAKSI / PEMBAYARAN)
  // ===========================================================================
  Widget _buildListTransaksi(List<dynamic> items, String tabType) {
    if (items.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF0F4C81),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final String namaDestinasi = _getNamaDestinasi(item);
          final String fotoUrl = _getFotoDestinasi(item, isTiketDigital: false);
          final bool isDitolak = tabType == 'ditolak';
          final bool isPending = tabType == 'pending';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailTiketPesananScreen(
                    data: item,
                    isTiketDigital: false, // Karena ini List Transaksi
                    tabType: tabType,
                  ),
                ),
              ).then((_) => _fetchData()); // Refresh kalau kembali dari detail
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header (Invoice & Status)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['kode_invoice'] ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDitolak
                                ? Colors.red.shade50
                                : (isPending
                                      ? Colors.orange.shade50
                                      : Colors.blue.shade50),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isDitolak
                                ? 'DITOLAK'
                                : (isPending
                                      ? 'BELUM BAYAR'
                                      : 'MENUNGGU VERIFIKASI'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDitolak
                                  ? Colors.red.shade700
                                  : (isPending
                                        ? Colors.orange.shade800
                                        : Colors.blue.shade700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                    thickness: 1.5,
                  ),

                  // Body Card (Gambar & Info)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Gambar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              headers: const {
                                'ngrok-skip-browser-warning': 'true',
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Detail Pesanan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaDestinasi,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${item['jumlah_tiket']}x Tiket ${item['kategori_tiket'].toString().toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatRupiah(item['total_harga'] ?? 0),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F4C81),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Keterangan Penolakan (Khusus Tab Ditolak)
                  if (isDitolak && item['keterangan_admin'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Container(
                        width: double.infinity,
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
                                  'Alasan Penolakan:',
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
                              item['keterangan_admin'],
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tombol Aksi Bawah (Upload Bukti)
                  // Mencegah propagasi gesture ke card dengan memberikan event onPressed sendiri
                  if (isPending || isDitolak)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InstruksiCheckoutScreen(
                                  transaksiId: item['id'],
                                  totalHarga: item['total_harga'] ?? 0,
                                ),
                              ),
                            ).then((_) => _fetchData());
                          },
                          icon: const Icon(Icons.upload_file, size: 18),
                          label: Text(
                            isDitolak
                                ? 'Upload Ulang Bukti Transfer'
                                : 'Upload Bukti Pembayaran',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C81),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET LIST UNTUK TAB 4, 5 (TIKET DIGITAL FISIK)
  // ===========================================================================
  Widget _buildListTiketDigital(List<dynamic> items, String tabType) {
    if (items.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF0F4C81),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final tiket = items[index];
          final transaksi = tiket['transaksi'] ?? {};
          final String namaDestinasi = _getNamaDestinasi(transaksi);
          final String fotoUrl = _getFotoDestinasi(tiket, isTiketDigital: true);
          final bool isTerpakai = tabType == 'terpakai';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailTiketPesananScreen(
                    data: tiket,
                    isTiketDigital: true, // Karena ini List Tiket Digital
                    tabType: tabType,
                  ),
                ),
              ).then((_) => _fetchData());
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header (Status Tiket)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 16,
                              color: isTerpakai
                                  ? Colors.grey.shade600
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isTerpakai
                                  ? 'TIKET SELESAI'
                                  : 'TIKET SIAP DIGUNAKAN',
                              style: TextStyle(
                                fontSize: 12,
                                color: isTerpakai
                                    ? Colors.grey.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isTerpakai && tiket['waktu_scan'] != null)
                          Text(
                            'Dipakai: ${tiket['waktu_scan'].toString().substring(0, 10)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFF1F5F9),
                    thickness: 1.5,
                  ),

                  // Body (Foto & Barcode/QR Text)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail Gambar
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              headers: const {
                                'ngrok-skip-browser-warning': 'true',
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Detail Tiket Digital
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaDestinasi,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isTerpakai
                                      ? Colors.grey.shade100
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isTerpakai
                                        ? Colors.grey.shade300
                                        : Colors.blue.shade100,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 16,
                                      color: isTerpakai
                                          ? Colors.grey.shade600
                                          : const Color(0xFF0F4C81),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tiket['kode_tiket'] ?? '-',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        color: isTerpakai
                                            ? Colors.grey.shade600
                                            : const Color(0xFF0F4C81),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // WIDGET EMPTY STATE KETIKA LIST KOSONG
  // ===========================================================================
  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 80,
                color: Colors.black26,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum ada tiket di kategori ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
