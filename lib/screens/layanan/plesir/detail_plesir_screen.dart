import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/plesir_model.dart';
import 'package:reang_app/models/ulasan_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:reang_app/screens/auth/login_screen.dart'; // PENAMBAHAN: Import LoginScreen

class DetailPlesirScreen extends StatefulWidget {
  final PlesirModel destinationData;
  const DetailPlesirScreen({super.key, required this.destinationData});

  @override
  State<DetailPlesirScreen> createState() => _DetailPlesirScreenState();
}

class _DetailPlesirScreenState extends State<DetailPlesirScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<UlasanModel> _ulasanList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  late double ratingAverage;
  int _reviewCount = 0;
  UlasanModel? _myReview;

  final TextEditingController _reviewCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ratingAverage = widget.destinationData.rating;
    _loadInitialReviews();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialReviews() async {
    setState(() {
      _isLoading = true;
      _ulasanList = [];
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final response = await _apiService.fetchUlasan(
        widget.destinationData.id,
        _currentPage,
      );
      if (mounted) {
        setState(() {
          ratingAverage = response.avgRating;
          _ulasanList = response.ratings;
          _hasMore = response.hasMorePages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast("Gagal memuat ulasan.", context: context);
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      final response = await _apiService.fetchUlasan(
        widget.destinationData.id,
        _currentPage,
      );
      if (mounted) {
        setState(() {
          _ulasanList.addAll(response.ratings);
          _hasMore = response.hasMorePages;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreReviews();
    }
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _launchMapsUrl() async {
    final lat = widget.destinationData.latitude;
    final lng = widget.destinationData.longitude;
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat membuka aplikasi peta';
      }
    } catch (e) {
      showToast(e.toString(), context: context);
    }
  }

  void _showDeleteConfirmationDialog(int ratingId) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

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
                await _apiService.deleteUlasan(
                  ratingId: ratingId,
                  token: authProvider.token!,
                );
                showToast(
                  "Ulasan berhasil dihapus",
                  context: context,
                  backgroundColor: Colors.green,
                );
                _loadInitialReviews();
              } catch (e) {
                showToast(
                  e.toString(),
                  context: context,
                  backgroundColor: Colors.red,
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.destinationData;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _myReview = null;
    if (authProvider.isLoggedIn) {
      try {
        _myReview = _ulasanList.firstWhere(
          (r) => r.userId == authProvider.user!.id,
        );
      } catch (e) {
        _myReview = null;
      }
    }
    final otherReviews = _ulasanList
        .where((r) => r.userId != authProvider.user?.id)
        .toList();
    _reviewCount = _ulasanList.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              stretch: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.3),
                  foregroundColor: Colors.white,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  data.foto,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: theme.colorScheme.surface,
                    child: Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: theme.hintColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  data.judul,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        data.formattedKategori,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.surfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          theme,
                          Icons.location_on,
                          "Lokasi:",
                          data.alamat,
                        ),
                        const Divider(height: 32),
                        _buildDetailRow(
                          theme,
                          Icons.description,
                          "Deskripsi:",
                          "",
                          child: HtmlWidget(data.deskripsi),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: _launchMapsUrl,
                            icon: const Icon(Icons.map_outlined, size: 18),
                            label: const Text('Lihat Lokasi di Peta'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Rating dan Ulasan",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRatingSummary(theme, authProvider),
                const Divider(height: 32),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_ulasanList.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Jadilah yang pertama memberi ulasan!'),
                    ),
                  )
                else
                  Column(
                    children: [
                      if (_myReview != null)
                        _buildUlasan(theme, _myReview!, isMyReview: true),
                      ...otherReviews.map((r) => _buildUlasan(theme, r)),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummary(ThemeData theme, AuthProvider authProvider) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          ratingAverage.toStringAsFixed(1),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(5, (index) {
                  if (ratingAverage >= index + 1) {
                    return const Icon(
                      Icons.star_rounded,
                      color: Colors.amber,
                      size: 22,
                    );
                  }
                  if (ratingAverage > index) {
                    return const Icon(
                      Icons.star_half_rounded,
                      color: Colors.amber,
                      size: 22,
                    );
                  }
                  return const Icon(
                    Icons.star_border_rounded,
                    color: Colors.amber,
                    size: 22,
                  );
                }),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "dari $_reviewCount ulasan",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddReviewSheet(authProvider),
                    icon: Icon(
                      _myReview != null ? Icons.edit_outlined : Icons.add,
                      size: 18,
                    ),
                    label: Text(
                      _myReview != null ? "Edit Ulasan Anda" : "Tambah Ulasan",
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    IconData icon,
    String title,
    String value, {
    Widget? child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              child ??
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                      fontSize: 16,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  // --- PERBAIKAN: Fungsi diubah menjadi async dan menangani navigasi ---
  void _showAddReviewSheet(AuthProvider authProvider) async {
    if (!authProvider.isLoggedIn) {
      // Arahkan ke LoginScreen
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(popOnSuccess: true),
        ),
      );
      // --- PERUBAHAN: Jika login berhasil, muat ulang data ulasan, JANGAN buka sheet ---
      if (result == true && mounted) {
        _loadInitialReviews();
      }
      return;
    }

    _reviewCtrl.text = _myReview?.comment ?? '';
    int tempRating = _myReview?.rating ?? 0;

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
                    _myReview != null ? 'Edit Ulasan Anda' : 'Tambah Ulasan',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rating',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return IconButton(
                        onPressed: () => setSheetState(() => tempRating = idx),
                        icon: Icon(
                          idx <= tempRating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 30,
                          color: Colors.amber,
                        ),
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 36),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reviewCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ulasan (opsional)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSubmit
                          ? () async {
                              final comment = _reviewCtrl.text.trim();
                              final userId = authProvider.user!.id;
                              final token = authProvider.token!;

                              try {
                                final Map<String, dynamic> response;
                                if (_myReview != null) {
                                  response = await _apiService.updateUlasan(
                                    ratingId: _myReview!.id,
                                    rating: tempRating,
                                    comment: comment,
                                    token: token,
                                  );
                                } else {
                                  response = await _apiService.postUlasan(
                                    plesirId: widget.destinationData.id,
                                    userId: userId,
                                    rating: tempRating,
                                    comment: comment,
                                    token: token,
                                  );
                                }

                                final newAvgRating = response['avg_rating'];
                                if (newAvgRating is num) {
                                  setState(
                                    () =>
                                        ratingAverage = newAvgRating.toDouble(),
                                  );
                                }

                                showToast(
                                  "Ulasan berhasil dikirim!",
                                  context: context,
                                  backgroundColor: Colors.green,
                                );
                                Navigator.of(context).pop();
                                _loadInitialReviews();
                              } catch (e) {
                                showToast(
                                  e.toString(),
                                  context: context,
                                  backgroundColor: Colors.red,
                                );
                              }
                            }
                          : null,
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
                      child: const Text('Kirim Ulasan'),
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

  Widget _buildUlasan(
    ThemeData theme,
    UlasanModel ulasan, {
    bool isMyReview = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: isMyReview
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceVariant,
            child: Text(
              ulasan.userName.isNotEmpty
                  ? ulasan.userName[0].toUpperCase()
                  : '?',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyReview ? "Ulasan Anda" : ulasan.userName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < ulasan.rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(ulasan.createdAt, locale: 'id'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ulasan.comment,
                  style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          if (isMyReview)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'hapus') {
                  _showDeleteConfirmationDialog(ulasan.id);
                }
              },
              offset: const Offset(0, 40),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
    );
  }
}
