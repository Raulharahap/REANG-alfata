import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/admin/detail_pesanan_admin_screen.dart';

class ManageOrderScreen extends StatefulWidget {
  const ManageOrderScreen({super.key});

  @override
  State<ManageOrderScreen> createState() => _ManageOrderScreenState();
}

class _ManageOrderScreenState extends State<ManageOrderScreen> {
  final ApiService _apiService = ApiService();
  late AuthProvider _authProvider;

  final PageController _pageController = PageController();
  int _activeTabIndex = 0;
  bool _isLoading = true;

  // Penampung data dari API untuk 5 Tab
  Map<String, List<dynamic>> _pesananMap = {
    'pending': [],
    'menunggu_verifikasi': [],
    'ditolak': [],
    'aktif': [],
    'terpakai': [],
  };

  // Daftar kategori status pesanan
  final List<String> _statusTabs = [
    'Belum Bayar',
    'Perlu Verifikasi',
    'Ditolak',
    'Tiket Aktif',
    'Selesai',
  ];

  // Kunci mapping ke data API
  final List<String> _apiKeys = [
    'pending',
    'menunggu_verifikasi',
    'ditolak',
    'aktif',
    'terpakai',
  ];

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _fetchData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --- FUNGSI AMBIL DATA DARI API ---
  Future<void> _fetchData() async {
    if (!_authProvider.isLoggedIn || _authProvider.token == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getAdminPesananMasuk(_authProvider.token!);
      if (mounted) {
        setState(() {
          _pesananMap = {
            'pending': data['pending'] ?? [],
            'menunggu_verifikasi': data['menunggu_verifikasi'] ?? [],
            'ditolak': data['ditolak'] ?? [],
            'aktif': data['aktif'] ?? [],
            'terpakai': data['terpakai'] ?? [],
          };
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat pesanan admin: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER FORMAT UANG & FOTO ---
  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // 👇 PERBAIKAN: Tidak perlu lagi membedah item['transaksi']
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

  // 👇 PERBAIKAN: Tidak perlu lagi membedah item['transaksi']
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          const Padding(
            padding: EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pesanan Masuk',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kelola verifikasi pembayaran & tiket pelanggan di sini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // --- KAPSUL STATUS DENGAN BADGE ---
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: List.generate(_statusTabs.length, (index) {
                final bool isActive = _activeTabIndex == index;
                final String apiKey = _apiKeys[index];
                final int count = _pesananMap[apiKey]?.length ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () {
                      _pageController.jumpToPage(index);
                      setState(() => _activeTabIndex = index);
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF0F4C81)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : Colors.black12.withOpacity(0.06),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _statusTabs[index],
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black54,
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          // Badge Merah jika ada isinya
                          if (count > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.white : Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                count.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF0F4C81)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),

          // --- KONTEN HALAMAN (PAGEVIEW) ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F4C81)),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _apiKeys.length,
                    onPageChanged: (index) {
                      setState(() => _activeTabIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final String currentKey = _apiKeys[index];
                      final List<dynamic> currentList =
                          _pesananMap[currentKey]!;

                      if (currentList.isEmpty) {
                        return _buildEmptyStateContent(
                          "Tidak ada data untuk status '${_statusTabs[index]}' saat ini.",
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _fetchData,
                        color: const Color(0xFF0F4C81),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: currentList.length,
                          itemBuilder: (context, listIndex) {
                            return _buildCardPesananAdmin(
                              currentList[listIndex],
                              currentKey,
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- CARD PESANAN ADMIN ---
  Widget _buildCardPesananAdmin(dynamic item, String tabKey) {
    // Ekstrak Data Langsung dari Item
    final user = item['user'];
    final String namaPelanggan = user != null ? user['name'] : 'Pelanggan';
    final String tanggal = item['created_at'] != null
        ? item['created_at'].toString().substring(0, 16)
        : '-';

    final String fotoUrl = _getFotoDestinasi(item);
    final String namaDestinasi = _getNamaDestinasi(item);

    // Cek apakah tab ini berarti tiket sudah diterbitkan
    final bool isLunas = tabKey == 'aktif' || tabKey == 'terpakai';
    final String kodeInvoiceAtauTiket = isLunas
        ? (item['kode_tiket'] ?? '-')
        : (item['kode_invoice'] ?? '-');

    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // 👇 SEKARANG ADMIN BISA KLIK SEMUA STATUS UNTUK MELIHAT DETAIL!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailPesananAdminScreen(
                transaksi: item,
                onActionSuccess: () {
                  _fetchData(); // Trigger refresh jika admin mengubah status
                },
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Nama User & Tanggal)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xFF0F4C81),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        namaPelanggan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    tanggal,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 24, thickness: 0.5),

              // 2. Body (Foto & Info)
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
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kodeInvoiceAtauTiket,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          namaDestinasi,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item['jumlah_tiket']} Tiket',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Footer (Total Harga & Tombol Aksi)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pembayaran:',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      Text(
                        _formatCurrency(item['total_harga'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F4C81),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  _buildAksiButton(tabKey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- TOMBOL AKSI BERDASARKAN TAB ---
  Widget _buildAksiButton(String tabKey) {
    if (tabKey == 'menunggu_verifikasi') {
      return ElevatedButton.icon(
        onPressed:
            null, // Dinonaktifkan karena klik detail diarahkan lewat Card (InkWell)
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.blue.shade600,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 16),
        label: const Text('Verifikasi'),
      );
    } else if (tabKey == 'aktif') {
      return OutlinedButton.icon(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade700,
          disabledForegroundColor: Colors.green.shade700,
          side: BorderSide(color: Colors.green.shade700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const Icon(Icons.qr_code_scanner, size: 16),
        label: const Text('Tiket Siap Scan'),
      );
    } else {
      return OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: Colors.grey.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('Lihat Detail'),
      );
    }
  }

  // --- WIDGET EMPTY STATE ---
  Widget _buildEmptyStateContent(String subtitle) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Belum Ada Pesanan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
