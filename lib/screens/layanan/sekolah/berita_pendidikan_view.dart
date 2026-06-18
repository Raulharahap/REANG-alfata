import 'package:flutter/material.dart';
import 'package:reang_app/models/berita_pendidikan_model.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/screens/layanan/sekolah/detail_berita_pendidikan_screen.dart';
import 'package:intl/intl.dart';
import 'package:html_unescape/html_unescape.dart';

class BeritaPendidikanView extends StatefulWidget {
  const BeritaPendidikanView({super.key});

  @override
  State<BeritaPendidikanView> createState() => _BeritaPendidikanViewState();
}

class _BeritaPendidikanViewState extends State<BeritaPendidikanView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<BeritaPendidikanModel> _beritaList = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _beritaList = [];
      _currentPage = 1;
      _hasMore = true;
    });
    try {
      final response = await _apiService.fetchBeritaPendidikanPaginated(
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _beritaList = response.data;
          _hasMore = response.hasMorePages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      showToast("Gagal memuat berita pendidikan.", context: context);
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    _currentPage++;
    try {
      final response = await _apiService.fetchBeritaPendidikanPaginated(
        page: _currentPage,
      );
      if (mounted) {
        setState(() {
          _beritaList.addAll(response.data);
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
      _loadMoreData();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _beritaList.isEmpty
          ? const Center(child: Text('Tidak ada berita tersedia.'))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _beritaList.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _beritaList.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final berita = _beritaList[index];
                return _BeritaCard(
                  berita: berita,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // --- PERBAIKAN: Menggunakan parameter 'artikel' ---
                        builder: (context) =>
                            DetailBeritaPendidikanScreen(artikel: berita),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _BeritaCard extends StatelessWidget {
  final BeritaPendidikanModel berita;
  final VoidCallback? onTap;

  const _BeritaCard({required this.berita, this.onTap});

  String get summary {
    final unescape = HtmlUnescape();
    final cleanHtml = unescape.convert(berita.deskripsi);
    final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return cleanHtml.replaceAll(exp, ' ').replaceAll('&nbsp;', ' ').trim();
  }

  String get formattedDate {
    try {
      // --- PERBAIKAN: Menggunakan properti 'tanggal' dari model ---
      return DateFormat('d MMMM y', 'id_ID').format(berita.tanggal);
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              berita.foto,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 180,
                color: theme.colorScheme.surfaceVariant,
                child: const Center(
                  child: Icon(Icons.school_outlined, size: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    berita.judul,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    summary,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: theme.hintColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 13, color: theme.hintColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
