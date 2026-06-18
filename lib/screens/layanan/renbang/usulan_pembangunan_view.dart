import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/renbang_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/renbang/detail_usulan_screen.dart';
import 'package:reang_app/screens/layanan/renbang/form_usulan_screen.dart';
import 'package:reang_app/screens/auth/login_screen.dart';

class UsulanPembangunanView extends StatefulWidget {
  const UsulanPembangunanView({super.key});

  @override
  State<UsulanPembangunanView> createState() => _UsulanPembangunanViewState();
}

class _UsulanPembangunanViewState extends State<UsulanPembangunanView> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<RenbangModel> _usulanList = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUsulan();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          _hasNextPage &&
          !_isLoading) {
        _fetchUsulan();
      }
    });
  }

  Future<void> _fetchUsulan({bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _usulanList.clear();
        _currentPage = 1;
        _hasNextPage = true;
        _isInitialLoad = true;
      }
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final response = await _apiService.fetchUsulanPembangunan(
        page: _currentPage,
        token: authProvider.token,
      );

      if (mounted) {
        setState(() {
          _usulanList.addAll(response.data);
          _currentPage++;
          _hasNextPage = response.currentPage < response.lastPage;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialLoad = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Usulan Masyarakat',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                if (auth.isLoggedIn) {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormUsulanScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchUsulan(isRefresh: true);
                  }
                } else {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen(popOnSuccess: true),
                    ),
                  );
                  if (result == true && mounted) {
                    _fetchUsulan(isRefresh: true);
                  }
                }
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah Usulan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Terjadi kesalahan: $_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_usulanList.isEmpty) {
      return const Center(child: Text('Belum ada usulan yang tersedia.'));
    }

    return RefreshIndicator(
      onRefresh: () => _fetchUsulan(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 4),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemCount: _usulanList.length + (_hasNextPage ? 1 : 0),
        itemBuilder: (_, index) {
          if (index == _usulanList.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final usulan = _usulanList[index];
          return _UsulanCard(
            data: usulan,
            onGoBack: () =>
                _fetchUsulan(isRefresh: true), // Kirim fungsi refresh
          );
        },
      ),
    );
  }
}

class _UsulanCard extends StatelessWidget {
  final RenbangModel data;
  final VoidCallback onGoBack; // Callback untuk refresh

  const _UsulanCard({required this.data, required this.onGoBack});

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(data.status);

    return GestureDetector(
      onTap: () async {
        // Tunggu hasil dari detail screen
        final bool? result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => DetailUsulanScreen(usulanData: data),
          ),
        );
        // Jika detail screen mengembalikan true (ada perubahan like), panggil callback
        if (result == true) {
          onGoBack();
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data.judul,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data.kategori,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data.deskripsi,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 14, color: theme.hintColor),
                  const SizedBox(width: 6),
                  Text(
                    data.user?.name ?? 'Warga Anonim',
                    style: TextStyle(fontSize: 13, color: theme.hintColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.thumb_up_alt_outlined,
                    size: 16,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${data.likesCount}',
                    style: TextStyle(fontSize: 13, color: theme.hintColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
