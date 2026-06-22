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
// IMPORT HALAMAN TIKET SAYA PLESIR
import 'package:reang_app/screens/layanan/plesir/tiket_saya_screen.dart';

class NotifikasiScreen extends StatefulWidget {
  final VoidCallback? onRefreshBadge;

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
    context.read<AuthProvider>().removeListener(_fetchData);
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();

      if (auth.token == null) {
        throw Exception("User belum login");
      }

      final data = await _apiService.fetchNotifications(auth.token!);

      if (mounted) {
        setState(() {
          _notifikasiList = data;
        });
        widget.onRefreshBadge?.call();
      }
    } catch (e) {
      debugPrint("Error ambil notifikasi: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        widget.onRefreshBadge?.call();
      }
    }
  }

  Future<void> _tandaiSemuaDibaca() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    setState(() {
      _notifikasiList = _notifikasiList
          .map(
            (n) => NotificationModel(
              id: n.id,
              title: n.title,
              body: n.body,
              type: n.type,
              dataId: n.dataId,
              isRead: 1,
              createdAt: n.createdAt,
            ),
          )
          .toList();
    });

    await _apiService.markAllNotificationsRead(auth.token!);
    widget.onRefreshBadge?.call();

    if (mounted) {
      _showToast('Semua notifikasi ditandai sudah dibaca');
    }
  }

  Future<void> _hapusSemuaNotifikasi() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

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

    setState(() => _isLoading = true);
    await _apiService.deleteAllNotifications(auth.token!);

    _fetchData();
    widget.onRefreshBadge?.call();

    if (mounted) {
      _showToast('Semua notifikasi dihapus');
    }
  }

  void _onTapNotification(NotificationModel notif) async {
    final auth = context.read<AuthProvider>();

    // 1. TANDAI DIBACA (API & UI)
    if (!notif.alreadyRead && auth.token != null) {
      // Mengirimkan tipe agar API Service tahu cara menanganinya
      _apiService.markNotificationRead(auth.token!, notif.id, type: notif.type);
      widget.onRefreshBadge?.call();

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
            isRead: 1,
          );
        }
      });
    }

    // 2. NAVIGASI SESUAI TIPE
    if (notif.dataId != null) {
      if (notif.type == 'transaksi') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailOrderScreen(noTransaksi: notif.dataId!),
          ),
        );
      } else if (notif.type == 'dumas') {
        int? idLaporan = int.tryParse(notif.dataId.toString());

        if (idLaporan != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  DetailLaporanScreen(dumasId: idLaporan, isMyReport: true),
            ),
          );
        }
      } else if (notif.type == 'renbang') {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        try {
          int? idUsulan = int.tryParse(notif.dataId.toString());

          if (idUsulan != null && auth.token != null) {
            final usulanData = await _apiService.fetchRenbangDetailById(
              idUsulan,
              auth.token!,
            );

            if (mounted) Navigator.pop(context);

            if (usulanData != null) {
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
            if (mounted) Navigator.pop(context);
          }
        } catch (e) {
          if (mounted) Navigator.pop(context);
          _showToast('Gagal memuat data: $e', isError: true);
        }
      }
      // NAVIGASI KE TIKET PLESIR
      else if (notif.type == 'plesir') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TiketSayaScreen()),
        );
      }
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
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
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'tandai_semua') {
                  _tandaiSemuaDibaca();
                } else if (value == 'hapus_semua') {
                  _hapusSemuaNotifikasi();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'tandai_semua',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 20),
                      SizedBox(width: 12),
                      Text('Tandai dibaca'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'hapus_semua',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
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

class _NotificationCard extends StatelessWidget {
  final NotificationModel notifikasi;
  final VoidCallback onTap;

  const _NotificationCard({required this.notifikasi, required this.onTap});

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
      case 'plesir': // IKON KHUSUS PLESIR
        iconData = Icons.confirmation_number_rounded;
        color = const Color(0xFF1E62DF);
        break;
      default:
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
                      notifikasi.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: notifikasi.alreadyRead
                            ? theme.textTheme.bodyMedium?.color
                            : theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notifikasi.body,
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
