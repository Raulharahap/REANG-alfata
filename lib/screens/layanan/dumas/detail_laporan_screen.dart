import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/dumas_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:reang_app/screens/layanan/dumas/dumas_image_preview_screen.dart';

class DetailLaporanScreen extends StatefulWidget {
  final int dumasId;
  final bool isMyReport; // Flag untuk menandai ini laporan milik user

  const DetailLaporanScreen({
    super.key,
    required this.dumasId,
    this.isMyReport = false, // Defaultnya false
  });

  @override
  State<DetailLaporanScreen> createState() => _DetailLaporanScreenState();
}

class _DetailLaporanScreenState extends State<DetailLaporanScreen> {
  final ApiService _api_service = ApiService();
  late Future<DumasModel> _dumasFuture;

  @override
  void initState() {
    super.initState();
    _loadDumasDetail();
  }

  // Fungsi untuk memuat data, akan dipanggil ulang setelah rating dikirim
  void _loadDumasDetail() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _dumasFuture = _api_service.fetchDumasDetail(
        widget.dumasId,
        token: auth.isLoggedIn ? auth.token : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: FutureBuilder<DumasModel>(
        future: _dumasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal memuat detail laporan.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadDumasDetail,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!;
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(context, theme, data),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(theme, data),
                      const SizedBox(height: 18),
                      _buildDetailInfo(theme, data),
                      const SizedBox(height: 18),
                      Text(
                        'Status Laporan',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDynamicTimeline(theme, data),
                      if (data.status.toLowerCase() == 'selesai')
                        _buildFeedbackSection(context, theme, data),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FEEDBACK SECTION (UI DIPERBAIK) ---
  Widget _buildFeedbackSection(
    BuildContext context,
    ThemeData theme,
    DumasModel data,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ulasan Laporan',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (data.userRating != null)
            _buildAlreadyRatedView(context, theme, data)
          else if (widget.isMyReport)
            _buildGiveRatingPrompt(context, theme, data)
          else
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Center(
                  child: Text(
                    'Belum ada ulasan untuk laporan ini.',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Tampilan prompt untuk memberi ulasan — tombol dibuat besar & jelas
  Widget _buildGiveRatingPrompt(
    BuildContext context,
    ThemeData theme,
    DumasModel data,
  ) {
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Laporan Selesai Ditangani',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Bantu kami meningkatkan kualitas layanan dengan memberikan penilaian Anda.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            // Tombol jelas dengan ikon + teks (full width)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showRatingBottomSheet(context, data),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.star_border),
                    SizedBox(width: 10),
                    Text('Beri Ulasan', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RATING VIEW (saat sudah ada rating) diperbagus & bintang dikecilkan ---
  Widget _buildAlreadyRatedView(
    BuildContext context,
    ThemeData theme,
    DumasModel data,
  ) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // kecilkan bintang tampilan agar tidak terlalu besar
    const double starSize = 25.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating header: compact stars + numeric value + menu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // Compact stars with subtle spacing
                    Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: Icon(
                            index < (data.userRating ?? 0)
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: starSize,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${(data.userRating ?? 0).toStringAsFixed(0)}/5',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (widget.isMyReport && auth.isLoggedIn)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showRatingBottomSheet(context, data);
                      } else if (value == 'hapus') {
                        _showDeleteConfirmationDialog(context);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'hapus',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 20),
                                SizedBox(width: 8),
                                Text('Hapus'),
                              ],
                            ),
                          ),
                        ],
                    icon: Icon(Icons.more_vert, color: theme.hintColor),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Ulasan teks
            if (data.userComment != null && data.userComment!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Text(
                  data.userComment!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ] else
              Text(
                'Pengguna tidak menambahkan komentar.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ulasan?'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus ulasan ini? Tindakan ini tidak dapat diurungkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await _api_service.deleteDumasRating(
                  dumasId: widget.dumasId,
                  token: authProvider.token!,
                );
                showToast(
                  "Ulasan berhasil dihapus",
                  context: context,
                  backgroundColor: Colors.green,
                  position: StyledToastPosition.bottom,
                  animation: StyledToastAnimation.scale,
                  reverseAnimation: StyledToastAnimation.fade,
                  animDuration: const Duration(milliseconds: 150),
                  duration: const Duration(seconds: 2),
                  borderRadius: BorderRadius.circular(25),
                  textStyle: const TextStyle(color: Colors.white),
                  curve: Curves.fastOutSlowIn,
                );
                _loadDumasDetail();
              } catch (e) {
                showToast(
                  e.toString(),
                  context: context,
                  backgroundColor: Colors.red,
                  position: StyledToastPosition.bottom,
                  animation: StyledToastAnimation.scale,
                  reverseAnimation: StyledToastAnimation.fade,
                  animDuration: const Duration(milliseconds: 150),
                  duration: const Duration(seconds: 2),
                  borderRadius: BorderRadius.circular(25),
                  textStyle: const TextStyle(color: Colors.white),
                  curve: Curves.fastOutSlowIn,
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showRatingBottomSheet(BuildContext context, DumasModel data) {
    int tempRating = data.userRating ?? 0;
    final commentController = TextEditingController(
      text: data.userComment ?? '',
    );
    bool isSubmitting = false;
    final auth = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (contextSheet, setSheetState) {
              final bool canSubmit = tempRating > 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    data.userRating != null
                        ? 'Edit Ulasan Anda'
                        : 'Beri Ulasan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                        onPressed: () {
                          setSheetState(() => tempRating = i + 1);
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: InputDecoration(
                      labelText: 'Ulasan (Opsional)',
                      hintText: 'Tuliskan ulasan Anda...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                              (states) =>
                                  states.contains(MaterialState.disabled)
                                  ? Colors.grey.shade300
                                  : Colors.blue.shade800,
                            ),
                        foregroundColor:
                            MaterialStateProperty.resolveWith<Color?>(
                              (states) =>
                                  states.contains(MaterialState.disabled)
                                  ? Colors.black38
                                  : Colors.white,
                            ),
                      ),
                      onPressed: canSubmit && !isSubmitting
                          ? () async {
                              setSheetState(() => isSubmitting = true);
                              try {
                                await _api_service_postRating_wrapper(
                                  dumasId: widget.dumasId,
                                  rating: tempRating.toDouble(),
                                  comment: commentController.text,
                                  token: auth.token!,
                                );
                                showToast(
                                  "Ulasan Anda berhasil disimpan!",
                                  context: context,
                                  backgroundColor: Colors.green,
                                  position: StyledToastPosition.bottom,
                                  animation: StyledToastAnimation.scale,
                                  reverseAnimation: StyledToastAnimation.fade,
                                  animDuration: const Duration(
                                    milliseconds: 150,
                                  ),
                                  duration: const Duration(seconds: 2),
                                  borderRadius: BorderRadius.circular(25),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  curve: Curves.fastOutSlowIn,
                                );
                                Navigator.of(ctx).pop(); // Close the modal
                                _loadDumasDetail(); // Refresh the detail page
                              } catch (e) {
                                showToast(
                                  "Gagal mengirim ulasan: ${e.toString()}",
                                  context: context,
                                  position: StyledToastPosition.bottom,
                                  animation: StyledToastAnimation.scale,
                                  reverseAnimation: StyledToastAnimation.fade,
                                  animDuration: const Duration(
                                    milliseconds: 150,
                                  ),
                                  duration: const Duration(seconds: 2),
                                  borderRadius: BorderRadius.circular(25),
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  curve: Curves.fastOutSlowIn,
                                );
                              } finally {
                                if (mounted) {
                                  setSheetState(() => isSubmitting = false);
                                }
                              }
                            }
                          : null,
                      child: isSubmitting
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text('Kirim Ulasan'),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // wrapper supaya statemen await _api_service.postDumasRating tetap sama struktur panggilannya
  Future<void> _api_service_postRating_wrapper({
    required int dumasId,
    required double rating,
    required String comment,
    required String token,
  }) {
    return _api_service.postDumasRating(
      dumasId: dumasId,
      rating: rating,
      comment: comment,
      token: token,
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    DumasModel data,
  ) {
    // Foto murni, tanpa judul dan tanpa gradient (sesuai permintaan)
    return SliverAppBar(
      expandedHeight: 260.0,
      pinned: true,
      stretch: true,
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withOpacity(0.5),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Kembali',
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (data.buktiLaporan != null && data.buktiLaporan!.isNotEmpty)
              Image.network(
                data.buktiLaporan!,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => _buildImageError(theme),
              )
            else
              _buildImageError(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 56,
          color: theme.hintColor,
        ),
      ),
    );
  }

  // Header card: KEMBALI ke pill lonjong (tanpa waktu) — sesuai permintaanmu
  Widget _buildHeaderCard(ThemeData theme, DumasModel data) {
    final statusKey = data.status.toLowerCase();
    final statusColor = _statusColorFor(statusKey);
    final statusIcon = _getStatusIcon(statusKey);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Icon box (lebih besar, visual kuat)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.95),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(statusIcon, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID Laporan',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text('#${data.id}', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: theme.hintColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        data.lokasiLaporan,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // === INI BAGIAN YANG KAMU MAU TETAPKAN: lonjong tanpa waktu ===
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Status',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.85)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 20, color: statusColor),
                    const SizedBox(width: 10),
                    Text(
                      data.status[0].toUpperCase() + data.status.substring(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailInfo(ThemeData theme, DumasModel data) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            theme,
            Icons.report_gmailerrorred_outlined,
            'Judul Laporan',
            data.jenisLaporan,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            Icons.category_outlined,
            'Kategori',
            data.kategoriLaporan,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            Icons.place_outlined,
            'Alamat',
            data.lokasiLaporan,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            theme,
            Icons.description_outlined,
            'Deskripsi',
            data.deskripsi,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String title,
    String value, {
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  /// TAMPILAN TIMELINE (VERTIKAL) YANG DIPERBAIKI — TIDAK ADA DUPLIKASI STATUS
  Widget _buildDynamicTimeline(ThemeData theme, DumasModel data) {
    final statusOrder = ['menunggu', 'diproses', 'selesai'];
    final currentStatus = data.status.toLowerCase();
    int currentStatusIndex = statusOrder.indexOf(currentStatus);

    // Konfigurasi langkah (label, warna, ikon)
    final List<Map<String, dynamic>> timelineConfig = [
      {
        'status': 'Menunggu',
        'key': 'menunggu',
        'subtitle': 'Laporan diterima oleh sistem',
        'color': Colors.orange,
        'icon': Icons.watch_later_outlined,
      },
      {
        'status': 'Diproses',
        'key': 'diproses',
        'subtitle': 'Laporan sedang ditindaklanjuti oleh instansi terkait',
        'color': Colors.blue,
        'icon': Icons.settings_suggest_outlined,
      },
      {
        'status': 'Selesai',
        'key': 'selesai',
        'subtitle': 'Laporan telah selesai ditindaklanjuti',
        'color': Colors.green,
        'icon': Icons.check_circle_outline,
      },
    ];

    // --- BAGIAN 1: STATUS DITOLAK (Manual) ---
    if (currentStatus == 'ditolak') {
      return Column(
        children: [
          // Kartu Menunggu (Pasti tidak ada foto/komen)
          _buildTimelineCard(
            theme,
            title: 'Menunggu',
            subtitle: 'Laporan diterima oleh sistem',
            color: Colors.orange,
            icon: Icons.watch_later_outlined,
            active: true,
            time: timeago.format(data.createdAt, locale: 'id'),
          ),
          const SizedBox(height: 12),
          // Kartu Ditolak (Pasti AKTIF, langsung pasang datanya)
          _buildTimelineCard(
            theme,
            title: 'Ditolak',
            subtitle: 'Laporan ditolak oleh instansi terkait.',
            color: Colors.red,
            icon: Icons.block,
            active: true,
            time: timeago.format(data.createdAt, locale: 'id'),
            comment: data.tanggapan, // Langsung ambil data (hapus isActive)
            foto: data.fotoTanggapan, // Langsung ambil data (hapus isActive)
          ),
        ],
      );
    }

    if (currentStatusIndex == -1) {
      // unknown status: tampilkan single entry
      return _TimelineEntry(
        dotColor: data.statusColor,
        title: data.status,
        subtitle: 'Status laporan saat ini.',
        timestamp: timeago.format(data.createdAt, locale: 'id'),
        isLast: true,
      );
    }

    // --- BAGIAN 2: STATUS NORMAL (Looping) ---
    final List<Widget> list = [];
    for (int i = 0; i <= currentStatusIndex; i++) {
      final step = timelineConfig[i];
      // Definisi isActive ada di sini
      final bool isActive = i == currentStatusIndex;

      list.add(
        _buildTimelineCard(
          theme,
          title: step['status'] as String,
          subtitle: step['subtitle'] as String,
          color: step['color'] as Color,
          icon: step['icon'] as IconData,
          active: isActive,
          time: timeago.format(data.createdAt, locale: 'id'),
          // Di sini BARU pakai isActive
          comment: isActive ? data.tanggapan : null,
          foto: isActive ? data.fotoTanggapan : null,
        ),
      );
      if (i < currentStatusIndex) list.add(const SizedBox(height: 12));
    }

    return Column(children: list);
  }

  // single card for timeline step (visual only)
  Widget _buildTimelineCard(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required bool active,
    required String time,
    String? comment,
    String? foto,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.06) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color.withOpacity(0.9) : theme.dividerColor,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // big icon circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: active ? color : color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                size: active ? 26 : 22,
                color: active ? Colors.white : color,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: active ? color : null,
                        ),
                      ),
                    ),
                    if (active)
                      Text(
                        time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                if (comment != null && comment.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(comment, style: theme.textTheme.bodyMedium),
                  ),
                ],

                // --- 2. BLOK FOTO (Cek Foto Saja - TERPISAH) ---
                // Ditaruh sejajar dengan blok komentar, bukan di dalamnya
                if (foto != null && foto.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    // <--- 1. BUNGKUS DENGAN GESTURE DETECTOR
                    onTap: () {
                      // <--- 2. LOGIKA PINDAH HALAMAN
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DumasImagePreviewScreen(
                            imageUrl: foto,
                            caption:
                                comment, // Kirim teks tanggapan juga biar muncul dibawah
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.network(
                          foto,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(Icons.broken_image),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helpers: mapping status to color/icon (visual only)
  Color _statusColorFor(String status) {
    switch (status.toLowerCase()) {
      case 'diproses':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'diproses':
        return Icons.build_circle_outlined;
      case 'selesai':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel_outlined;
      default:
        return Icons.pending_outlined;
    }
  }
}

// --- Widget Timeline Entry (tampilan sedikit disesuaikan) ---
class _TimelineEntry extends StatelessWidget {
  final Color dotColor;
  final String title;
  final String subtitle;
  final String timestamp;
  final bool isLast;

  const _TimelineEntry({
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            // Dot with icon slightly larger but balanced
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 110, color: theme.dividerColor),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: dotColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  timestamp,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
                if (!isLast) const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
