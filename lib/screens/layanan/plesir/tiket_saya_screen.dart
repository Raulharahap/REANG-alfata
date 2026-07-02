import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart'; // 👇 Import Toast Pembatalan
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

  // =========================================================================
  // 👇 FUNGSI INTERSEPTOR: POP-UP KONFIRMASI DAN PROSES PEMBATALAN KE API
  // =========================================================================
  Future<void> _konfirmasiBatalPesanan(
    BuildContext context,
    int transaksiId,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                "Batalkan Pesanan?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            "Apakah Anda yakin ingin membatalkan pesanan tiket ini? Tindakan ini tidak dapat dikembalikan.",
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Tidak",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Ya, Batalkan",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );

      try {
        final token = context.read<AuthProvider>().token;
        if (token != null) {
          await _apiService.cancelPesananPlesir(token, transaksiId);
          if (mounted) Navigator.pop(context); // Tutup Loading Spinner

          showToast(
            "Pesanan berhasil dibatalkan",
            context: context,
            backgroundColor: Colors.green,
            position: StyledToastPosition.bottom,
            borderRadius: BorderRadius.circular(10),
          );

          _fetchData(); // Tarik ulang data real-time dari database
        }
      } catch (e) {
        if (mounted) Navigator.pop(context); // Tutup Loading Spinner
        showToast(
          e.toString().replaceAll('Exception: ', ''),
          context: context,
          backgroundColor: Colors.red,
          position: StyledToastPosition.bottom,
          borderRadius: BorderRadius.circular(10),
        );
      }
    }
  }

  String _formatRupiah(int number) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
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
  String _getFotoDestinasi(dynamic item) {
    try {
      if (item['kategori_tiket'] == 'wisata' && item['wisata'] != null) {
        return item['wisata']['foto_utama'] ?? '';
      } else if (item['kategori_tiket'] == 'event' && item['event'] != null) {
        return item['event']['foto_utama'] ?? '';
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Mencegah back default melompat ke home
      onPopInvoked: (didPop) {
        if (!didPop) {
          Navigator.pop(
            context,
          ); // Menjamin hanya mundur 1 halaman ke PlesirYuScreen
        }
      },
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () =>
                  Navigator.pop(context), // Mundur ke PlesirYuScreen
            ),
            title: const Text(
              'Tiket Saya',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: const Color(0xFF0F4C81),
              unselectedLabelColor: Colors.black45,
              indicatorColor: const Color(0xFF0F4C81),
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              tabs: [
                _buildTabItem('Belum Bayar', _pending.length),
                _buildTabItem('Verifikasi', _menungguVerifikasi.length),
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
      ),
    );
  }

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
        offset: const Offset(14, -4),
        child: Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: Text(title),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET LIST UNTUK TAB 1, 2, 3 (TRANSAKSI / PEMBAYARAN PENDING)
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
          final String fotoUrl = _getFotoDestinasi(item);
          final bool isDitolak = tabType == 'ditolak';
          final bool isPending = tabType == 'pending';

          // Ambal data tambahan varian & kunjungan
          final String namaKelas = item['varian'] != null
              ? item['varian']['nama_kelas'] ?? ''
              : '';
          final String tglKunjungan = item['tanggal_kunjungan'] != null
              ? item['tanggal_kunjungan'].toString()
              : '-';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetailTiketPesananScreen(data: item, tabType: tabType),
                ),
              ).then((_) => _fetchData());
            },
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_outlined,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item['kode_invoice'] ?? '-',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.bold,
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
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Body Card
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fotoUrl,
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (c, e, s) => Container(
                              width: 75,
                              height: 75,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaDestinasi,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (namaKelas.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Kelas: $namaKelas',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kunjungan: $tglKunjungan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item['jumlah_tiket']} Tiket',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _formatRupiah(item['total_harga'] ?? 0),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F4C81),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Alasan Penolakan
                  if (isDitolak && item['keterangan_admin'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Alasan: ${item['keterangan_admin']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                  // =========================================================================
                  // 👇 RESTRUKTURISASI TOMBOL: MEMBUAT TOMBOL BATAL & BAYAR BERDAMPINGAN
                  // =========================================================================
                  if (isPending || isDitolak)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: isPending
                          ? Row(
                              children: [
                                // --- TOMBOL CANCEL (HANYA DI TAB PENDING) ---
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _konfirmasiBatalPesanan(
                                        context,
                                        item['id'],
                                      ),
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        size: 16,
                                        color: Colors.redAccent,
                                      ),
                                      label: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Colors.redAccent,
                                        ),
                                        foregroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // --- TOMBOL BAYAR SEKARANG ---
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        final metode =
                                            item['metode_pembayaran'] ??
                                            item['metodePembayaran'] ??
                                            {};

                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                InstruksiCheckoutScreen(
                                                  transaksiId: item['id'],
                                                  totalHarga:
                                                      item['total_harga'] ?? 0,
                                                  selectedMetode: metode,
                                                ),
                                          ),
                                        ).then((_) => _fetchData());
                                      },
                                      icon: const Icon(
                                        Icons.upload_file,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Bayar Sekarang',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F4C81,
                                        ),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final metode =
                                      item['metode_pembayaran'] ??
                                      item['metodePembayaran'] ??
                                      {};

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          InstruksiCheckoutScreen(
                                            transaksiId: item['id'],
                                            totalHarga:
                                                item['total_harga'] ?? 0,
                                            selectedMetode: metode,
                                          ),
                                    ),
                                  ).then((_) => _fetchData());
                                },
                                icon: const Icon(Icons.upload_file, size: 16),
                                label: Text(
                                  isDitolak
                                      ? 'Upload Ulang Bukti Bayar'
                                      : 'Bayar Sekarang / Upload Bukti',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F4C81),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
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
  // WIDGET LIST UNTUK TAB 4, 5 (TIKET AKTIF / TERPAKAI)
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
          final String namaDestinasi = _getNamaDestinasi(tiket);
          final String fotoUrl = _getFotoDestinasi(tiket);
          final bool isTerpakai = tabType == 'terpakai';

          final String namaKelas = tiket['varian'] != null
              ? tiket['varian']['nama_kelas'] ?? ''
              : '';
          final String tglKunjungan = tiket['tanggal_kunjungan'] != null
              ? tiket['tanggal_kunjungan'].toString()
              : '-';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetailTiketPesananScreen(data: tiket, tabType: tabType),
                ),
              ).then((_) => _fetchData());
            },
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Header Card
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 14,
                              color: isTerpakai
                                  ? Colors.grey
                                  : Colors.green.shade700,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isTerpakai
                                  ? 'TIKET SELESAI'
                                  : 'TIKET AKTIF / SIAP DIGUNAKAN',
                              style: TextStyle(
                                fontSize: 11,
                                color: isTerpakai
                                    ? Colors.grey.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isTerpakai && tiket['updated_at'] != null)
                          Text(
                            'Scan: ${tiket['updated_at'].toString().substring(0, 10)}',
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
                    thickness: 1,
                    color: Color(0xFFF1F5F9),
                  ),

                  // Body Card
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            fotoUrl,
                            width: 75,
                            height: 75,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (c, e, s) => Container(
                              width: 75,
                              height: 75,
                              color: Colors.grey.shade100,
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaDestinasi,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (namaKelas.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Kelas: $namaKelas',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Kunjungan: $tglKunjungan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isTerpakai
                                      ? Colors.grey.shade100
                                      : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isTerpakai
                                        ? Colors.grey.shade300
                                        : Colors.blue.shade100,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 14,
                                      color: isTerpakai
                                          ? Colors.grey.shade600
                                          : const Color(0xFF0F4C81),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tiket['kode_tiket'] ?? '-',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
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
                size: 70,
                color: Colors.black26,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada tiket di kategori ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
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
