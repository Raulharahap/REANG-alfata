import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:reang_app/models/notification_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/ecomerce/detail_order_screen.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/screens/layanan/dumas/detail_laporan_screen.dart';
import 'package:reang_app/screens/layanan/renbang/detail_usulan_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  // [BARU] Tambahkan variable ini
  final VoidCallback? onRefreshBadge;

  // [UPDATE] Tambahkan di constructor
  const NotifikasiScreen({super.key, this.onRefreshBadge});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<NotificationModel> _notifikasiList = [];

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().addListener(_fetchData);
    _fetchData();
  }

  @override
  void dispose() {
    // 3. Copot Listener saat halaman ditutup
    context.read<AuthProvider>().removeListener(_fetchData);
    super.dispose();
  }

  Future<void> _fetchData() async {
    // 1. Nyalakan loading saat mulai
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();

      // Cek apakah user login
      if (auth.token == null) {
        throw Exception("User belum login");
      }

      // Panggil API
      final data = await _apiService.fetchNotifications(auth.token!);

      if (mounted) {
        setState(() {
          _notifikasiList = data;
        });
        widget.onRefreshBadge?.call();
      }
    } catch (e) {
      debugPrint("Error ambil notifikasi: $e");
      // Jika error, biarkan list kosong atau tampilkan pesan
    } finally {
      // [PENTING] Bagian ini AKAN SELALU DIJALANKAN (Sukses ataupun Error)
      // Jadi loading pasti mati dan tampilan kosong muncul
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onRefreshBadge?.call();
      }
    }
  }

  // Fungsi Tandai Semua Dibaca
  Future<void> _tandaiSemuaDibaca() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    // Optimistic UI Update (Ubah tampilan dulu biar cepat)
    setState(() {
      // Buat list baru dengan status isRead = 1
      _notifikasiList = _notifikasiList
          .map(
            (n) => NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              dataId: n.dataId,
              isRead: 1, // Paksa jadi 1
              createdAt: n.createdAt,
            ),
          )
          .toList();
    });

    // Panggil API di background
    await _apiService.markAllNotificationsRead(auth.token!);
    widget.onRefreshBadge?.call();

    if (mounted) {
      _showToast('Semua notifikasi ditandai sudah dibaca');
    }
  }

  // [FUNGSI BARU] Hapus Semua Notifikasi
  Future<void> _hapusSemuaNotifikasi() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    // Tampilkan Dialog Konfirmasi Dulu
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua?'),
        content: const Text('Semua riwayat notifikasi akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Proses Hapus
    setState(() => _isLoading = true);
    await _apiService.deleteAllNotifications(auth.token!);

    // Refresh Data & Badge
    _fetchData();
    widget.onRefreshBadge?.call(); // Update badge di menu utama jadi 0

    if (mounted) {
      _showToast('Semua notifikasi dihapus');
    }
  }

  // Fungsi Aksi Saat Notif Diklik
  void _onTapNotification(NotificationModel notif) async {
    final auth = context.read<AuthProvider>();

    // 1. TANDAI DIBACA (API & UI)
    if (!notif.alreadyRead && auth.token != null) {
      // Panggil API di background
      _apiService.markNotificationRead(auth.token!, notif.id);
      // Refresh badge di menu utama
      widget.onRefreshBadge?.call();

      // Update tampilan list secara lokal (biar cepat jadi putih)
      setState(() {
        int index = _notifikasiList.indexWhere((n) => n.id == notif.id);
        if (index != -1) {
          _notifikasiList[index] = NotificationModel(
            id: notif.id,
            title: notif.title,
            body: notif.body,
            type: notif.type,
            dataId: notif.dataId,
            createdAt: notif.createdAt,
            isRead: 1, // Paksa jadi 1
          );
        }
      });
    }

    // 2. NAVIGASI SESUAI TIPE
    if (notif.dataId != null) {
      // --- A. TIPE TRANSAKSI ---
      if (notif.type == 'transaksi') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailOrderScreen(noTransaksi: notif.dataId!),
          ),
        );
      }
      // --- B. TIPE DUMAS ---
      else if (notif.type == 'dumas') {
        // Parsing ID ke integer
        int? idLaporan = int.tryParse(notif.dataId.toString());

        if (idLaporan != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailLaporanScreen(
                dumasId: idLaporan,
                isMyReport: true, // Tandai sebagai laporan milik user
              ),
            ),
          );
        }
      }
      // --- C. TIPE RENBANG ---
      else if (notif.type == 'renbang') {
        // 1. Tampilkan Loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        try {
          int? idUsulan = int.tryParse(notif.dataId.toString());

          if (idUsulan != null && auth.token != null) {
            // 2. Ambil Data Lengkap dari API
            final usulanData = await _apiService.fetchRenbangDetailById(
              idUsulan,
              auth.token!,
            );

            // 3. Tutup Loading
            if (mounted) Navigator.pop(context);

            if (usulanData != null) {
              // 4. Buka Layar Detail
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetailUsulanScreen(usulanData: usulanData),
                ),
              );
            } else {
              _showToast('Data usulan tidak ditemukan', isError: true);
            }
          } else {
            if (mounted)
              Navigator.pop(context); // Tutup loading jika ID/Token null
          }
        } catch (e) {
          if (mounted)
            Navigator.pop(context); // Tutup loading jika error koneksi
          _showToast('Gagal memuat data: $e', isError: true);
        }
      }
    }
  }

  // Helper Toast dengan Style Biasa Anda (Hijau/Merah + Animasi)
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      // Warna Hijau Solid (Sukses) atau Merah (Error)
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
      textStyle: const TextStyle(color: Colors.white),

      // Animasi Favorit
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Notifikasi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_notifikasiList.isNotEmpty)
            PopupMenuButton<String>(
              // [FITUR 1] Offset agar menu muncul di BAWAH tombol, tidak menutupinya
              offset: const Offset(0, 50),

              // Style agar sudutnya melengkung
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              onSelected: (value) {
                if (value == 'tandai_semua') {
                  _tandaiSemuaDibaca();
                } else if (value == 'hapus_semua') {
                  _hapusSemuaNotifikasi(); // Panggil fungsi hapus
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                // --- MENU 1: BACA SEMUA ---
                const PopupMenuItem<String>(
                  value: 'tandai_semua',
                  child: Row(
                    children: [
                      Icon(
                        Icons.done_all,
                        color: Colors.blue,
                        size: 20,
                      ), // Ada Ikon
                      SizedBox(width: 12),
                      Text('Tandai dibaca'),
                    ],
                  ),
                ),
                const PopupMenuDivider(), // Garis pemisah
                // --- MENU 2: HAPUS SEMUA ---
                const PopupMenuItem<String>(
                  value: 'hapus_semua',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ), // Ada Ikon
                      SizedBox(width: 12),
                      Text('Hapus semua', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: _notifikasiList.isEmpty
                  ? _buildEmptyView(theme)
                  : ListView.separated(
                      itemCount: _notifikasiList.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        return _NotificationCard(
                          notifikasi: _notifikasiList[index],
                          onTap: () =>
                              _onTapNotification(_notifikasiList[index]),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildEmptyView(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: theme.hintColor,
            ),
            const SizedBox(height: 16),
            Text('Belum ada notifikasi', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Pemberitahuan transaksi dan info lainnya\nakan muncul di sini.',
              style: TextStyle(color: theme.hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Card
class _NotificationCard extends StatelessWidget {
  final NotificationModel notifikasi;
  final VoidCallback onTap;

  const _NotificationCard({required this.notifikasi, required this.onTap});

  // Helper Simpel Waktu
  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 7) {
      return DateFormat('dd MMM yyyy', 'id_ID').format(dateTime);
    } else if (diff.inDays >= 1) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Helper Icon berdasarkan Tipe
  Widget _buildIcon(ThemeData theme) {
    IconData iconData;
    Color color;

    switch (notifikasi.type) {
      case 'transaksi':
        iconData = Icons.shopping_bag;
        color = Colors.orange;
        break;
      case 'dumas':
        iconData = Icons.record_voice_over;
        color = Colors.blue;
        break;
      default: // Info umum
        iconData = Icons.notifications;
        color = theme.colorScheme.primary;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Highlight jika belum dibaca
    final cardColor = notifikasi.alreadyRead
        ? theme.scaffoldBackgroundColor
        : theme.colorScheme.primary.withOpacity(0.05);

    return Material(
      color: cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notifikasi
                          .title, // Judul (Misal: Pembayaran Dikonfirmasi)
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: notifikasi.alreadyRead
                            ? theme.textTheme.bodyMedium?.color
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notifikasi.body, // Isi Pesan
                      style: theme.textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTimeAgo(notifikasi.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Titik merah kecil jika belum dibaca
              if (!notifikasi.alreadyRead)
                Container(
                  margin: const EdgeInsets.only(top: 4, left: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
