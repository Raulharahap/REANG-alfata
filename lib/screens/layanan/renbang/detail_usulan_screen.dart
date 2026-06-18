import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/models/renbang_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/auth/login_screen.dart';

class DetailUsulanScreen extends StatefulWidget {
  final RenbangModel usulanData;
  const DetailUsulanScreen({super.key, required this.usulanData});

  @override
  State<DetailUsulanScreen> createState() => _DetailUsulanScreenState();
}

class _DetailUsulanScreenState extends State<DetailUsulanScreen> {
  final ApiService _apiService = ApiService();
  late int _likesCount;
  late bool _isLiked;
  bool _isLiking = false;
  bool _didStateChange = false;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.usulanData.likesCount;
    _isLiked = widget.usulanData.isLikedByUser;
  }

  Future<void> _toggleLike() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(popOnSuccess: true),
        ),
      );

      if (result == true && mounted) {
        _toggleLike();
      }
      return;
    }

    setState(() => _isLiking = true);

    try {
      final response = await _apiService.likeUsulan(
        usulanId: widget.usulanData.id,
        token: authProvider.token!,
      );
      if (mounted) {
        setState(() {
          _likesCount = response['likes_count'];
          _isLiked = response['status'] == 'liked';
          _didStateChange = true;
        });
      }
    } catch (e) {
      if (mounted) {
        showToast(
          e.toString(),
          context: context,
          position: StyledToastPosition.bottom,
          animation: StyledToastAnimation.scale,
          reverseAnimation: StyledToastAnimation.fade,
          backgroundColor: Colors.red,
          animDuration: const Duration(milliseconds: 150),
          duration: const Duration(seconds: 2),
          borderRadius: BorderRadius.circular(25),
          textStyle: const TextStyle(color: Colors.white),
          curve: Curves.fastOutSlowIn,
        );
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'selesai':
        return const Color(0xFF4CAF50);
      case 'ditolak':
        return const Color(0xFFF44336);
      case 'dalam review':
      case 'diproses':
        return const Color(0xFFFFA500);
      case 'menunggu':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = widget.usulanData.status;
    final statusColor = _getStatusColor(status);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _didStateChange);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detail Usulan'),
          elevation: 1,
          shadowColor: theme.shadowColor.withOpacity(0.3),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryAndStatus(
                  theme,
                  widget.usulanData.kategori,
                  status,
                  statusColor,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.usulanData.judul,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoSection(theme),
                const Divider(height: 32),

                // --- PERUBAHAN: Deskripsi dikembalikan ke sini ---
                Text(
                  'Deskripsi Usulan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.usulanData.deskripsi,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Divider(height: 32),

                // --- Timeline Status ---
                Text(
                  'Riwayat Status Usulan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusTimeline(theme),

                const Divider(height: 32),
                _buildInteractionSection(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTimeline(ThemeData theme) {
    final status = widget.usulanData.status.toLowerCase();
    final tanggapan = widget.usulanData.tanggapan;

    final isMenunggu = true;
    final isDiproses =
        status == 'diproses' || status == 'selesai' || status == 'ditolak';
    final isSelesai = status == 'selesai';
    final isDitolak = status == 'ditolak';

    return Column(
      children: [
        _buildTimelineStep(
          theme: theme,
          icon: Icons.inbox_outlined,
          color: _getStatusColor('menunggu'),
          title: 'Usulan Diterima',
          subtitle: _formatDate(widget.usulanData.createdAt),
          // --- PERUBAHAN: Konten deskripsi dihapus dari sini ---
          isActive: isMenunggu,
        ),
        _buildTimelineStep(
          theme: theme,
          icon: Icons.sync_outlined,
          color: _getStatusColor('diproses'),
          title: 'Sedang Diproses',
          subtitle: isDiproses
              ? 'Usulan Anda sedang ditinjau oleh pihak terkait.'
              : 'Menunggu peninjauan',
          content:
              (isDiproses &&
                  tanggapan != null &&
                  tanggapan.isNotEmpty &&
                  !isSelesai &&
                  !isDitolak)
              ? tanggapan
              : null,
          isActive: isDiproses,
        ),
        if (isDitolak)
          _buildTimelineStep(
            theme: theme,
            icon: Icons.cancel_outlined,
            color: _getStatusColor('ditolak'),
            title: 'Usulan Ditolak',
            subtitle: 'Terima kasih atas partisipasi Anda.',
            content: tanggapan,
            isActive: true,
            isLastStep: true,
          )
        else
          _buildTimelineStep(
            theme: theme,
            icon: Icons.check_circle_outline,
            color: _getStatusColor('selesai'),
            title: 'Selesai',
            subtitle: isSelesai
                ? 'Usulan telah selesai ditindaklanjuti.'
                : 'Menunggu status akhir',
            content: (isSelesai && tanggapan != null && tanggapan.isNotEmpty)
                ? tanggapan
                : null,
            isActive: isSelesai,
            isLastStep: true,
          ),
      ],
    );
  }

  Widget _buildTimelineStep({
    required ThemeData theme,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? content,
    bool isActive = false,
    bool isLastStep = false,
  }) {
    final activeColor = color;
    final inactiveColor = theme.hintColor.withOpacity(0.5);
    final currentStatusColor = isActive ? activeColor : inactiveColor;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: currentStatusColor, size: 28),
              if (!isLastStep)
                Expanded(child: Container(width: 2, color: currentStatusColor)),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? theme.colorScheme.onSurface
                        : inactiveColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isActive ? theme.hintColor : inactiveColor,
                  ),
                ),
                if (content != null && content.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Text(
                      content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAndStatus(
    ThemeData theme,
    String kategori,
    String status,
    Color statusColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            kategori,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(
              theme,
              icon: Icons.person_outline,
              label: 'Di-usulkan oleh',
              value: widget.usulanData.user?.name ?? 'Warga Anonim',
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal usulan',
              value: _formatDate(widget.usulanData.createdAt),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              theme,
              icon: Icons.location_on_outlined,
              label: 'Lokasi',
              value: widget.usulanData.lokasi,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 20, color: theme.hintColor),
            const SizedBox(width: 8),
            Text(
              '$_likesCount Dukungan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: _isLiked
              ? OutlinedButton.icon(
                  onPressed: _isLiking ? null : _toggleLike,
                  icon: _isLiking
                      ? const SizedBox.shrink()
                      : const Icon(Icons.check_circle_outline),
                  label: _isLiking
                      ? const CircularProgressIndicator()
                      : const Text('Batal Dukung'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: _isLiking ? null : _toggleLike,
                  icon: _isLiking
                      ? const SizedBox.shrink()
                      : const Icon(Icons.thumb_up_alt_outlined),
                  label: _isLiking
                      ? const CircularProgressIndicator()
                      : const Text('Beri Dukungan'),
                ),
        ),
      ],
    );
  }
}
