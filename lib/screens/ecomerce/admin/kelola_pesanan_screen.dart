import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/admin_pesanan_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'detail_pesanan_admin_screen.dart';

// =============================================================================
// PARENT WIDGET
// =============================================================================
class KelolaPesananScreen extends StatefulWidget {
  const KelolaPesananScreen({super.key});

  @override
  State<KelolaPesananScreen> createState() => _KelolaPesananScreenState();
}

class _KelolaPesananScreenState extends State<KelolaPesananScreen> {
  final ApiService _apiService = ApiService();
  late AuthProvider _authProvider;

  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  // Badge State
  Map<String, int> _counts = {};

  final List<String> _statusFilters = [
    'Perlu Dikonfirmasi',
    'Siap Dikemas',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  final List<String> _apiStatusKeys = [
    'menunggu_konfirmasi',
    'diproses',
    'dikirim',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _fetchBadgeCounts();
  }

  Future<void> _fetchBadgeCounts() async {
    if (!_authProvider.isLoggedIn || _authProvider.user?.idToko == null) return;

    try {
      final data = await _apiService.fetchOrderCounts(
        token: _authProvider.token!,
        idToko: _authProvider.user!.idToko!,
      );
      if (mounted) setState(() => _counts = data);
    } catch (e) {
      debugPrint("Gagal load badge: $e");
    }
  }

  void _globalRefresh() {
    _fetchBadgeCounts();
    setState(() {});
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Perlu Dikonfirmasi':
        return Icons.hourglass_top_outlined;
      case 'Siap Dikemas':
        return Icons.inventory_2_outlined;
      case 'Dikirim':
        return Icons.local_shipping_outlined;
      case 'Selesai':
        return Icons.check_circle_outline;
      case 'Dibatalkan':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            'Kelola Pesanan Masuk',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        SizedBox(
          height: 50, // Tinggi Chip
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _statusFilters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final status = _statusFilters[index];
              final apiStatus = _apiStatusKeys[index];
              final bool isSelected = _selectedIndex == index;
              final int count = _counts[apiStatus] ?? 0;

              final bool showBadge =
                  count > 0 &&
                  (apiStatus == 'menunggu_konfirmasi' ||
                      apiStatus == 'diproses' ||
                      apiStatus == 'dikirim');

              return ChoiceChip(
                showCheckmark: false,
                label: Row(
                  children: [
                    Icon(
                      _getIconForStatus(status),
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(status),
                    if (showBadge) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                onSelected: (val) {
                  _pageController.jumpToPage(index);
                  setState(() => _selectedIndex = index);
                },
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                selectedColor: theme.colorScheme.primary,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _statusFilters.length,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            itemBuilder: (context, index) {
              return OrderListTab(
                apiStatus: _apiStatusKeys[index],
                onUpdate: _globalRefresh,
              );
            },
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// CHILD WIDGET: List Pesanan Per Tab (INFINITE SCROLL)
// =============================================================================
class OrderListTab extends StatefulWidget {
  final String apiStatus;
  final VoidCallback onUpdate;

  const OrderListTab({
    super.key,
    required this.apiStatus,
    required this.onUpdate,
  });

  @override
  State<OrderListTab> createState() => _OrderListTabState();
}

class _OrderListTabState extends State<OrderListTab>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // State Data List
  List<AdminPesananModel> _items = [];
  bool _isFirstLoading = true; // Loading awal
  bool _isLoadMoreRunning = false; // Loading bawah (pagination)
  bool _hasNextPage = true; // Masih ada data lagi?
  int _page = 1; // Halaman saat ini
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadFirstData();

    // Listener Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Reset dan Load Awal
  Future<void> _loadFirstData() async {
    if (!mounted) return;
    setState(() {
      _isFirstLoading = true;
      _errorMessage = null;
      _page = 1;
      _hasNextPage = true;
      _items = [];
    });

    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn) throw Exception("Belum login");

      final data = await _apiService.fetchAdminPesanan(
        token: auth.token!,
        idToko: auth.user!.idToko!,
        status: widget.apiStatus,
        page: _page,
      );

      if (mounted) {
        setState(() {
          _items = data;
          _isFirstLoading = false;
          // Jika data kurang dari 10, berarti ini halaman terakhir
          if (data.length < 10) {
            _hasNextPage = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFirstLoading = false;
          _errorMessage = e.toString().replaceAll("Exception: ", "");
        });
      }
    }
  }

  // Load Page Berikutnya
  Future<void> _loadMoreData() async {
    if (_hasNextPage && !_isFirstLoading && !_isLoadMoreRunning) {
      setState(() => _isLoadMoreRunning = true);

      try {
        final auth = context.read<AuthProvider>();
        _page += 1; // Naikkan halaman

        final data = await _apiService.fetchAdminPesanan(
          token: auth.token!,
          idToko: auth.user!.idToko!,
          status: widget.apiStatus,
          page: _page,
        );

        if (mounted) {
          setState(() {
            if (data.isNotEmpty) {
              _items.addAll(data); // Tambahkan ke list
            }

            // Cek jika data habis
            if (data.length < 10) {
              _hasNextPage = false;
            }
            _isLoadMoreRunning = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadMoreRunning = false);
      }
    }
  }

  // Fungsi Refresh Tarik Turun
  Future<void> _handleRefresh() async {
    widget.onUpdate(); // Refresh badge parent
    await _loadFirstData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    // 1. Loading Awal
    if (_isFirstLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error Awal
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text("Gagal Memuat Data", style: theme.textTheme.titleMedium),
            Text(_errorMessage!, style: TextStyle(color: theme.hintColor)),
            TextButton(
              onPressed: _loadFirstData,
              child: const Text("Coba Lagi"),
            ),
          ],
        ),
      );
    }

    // 3. Kosong
    if (_items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh, // Gunakan _handleRefresh
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 80,
                    color: theme.hintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada pesanan di status ini.",
                    style: TextStyle(color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4. List Data (Infinite Scroll)
    return RefreshIndicator(
      onRefresh: _handleRefresh, // Gunakan _handleRefresh
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),

        // [PERBAIKAN: Hapus padding ganda]
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

        // Tambah 1 item di bawah untuk indikator loading bawah
        itemCount: _items.length + 1,

        itemBuilder: (ctx, index) {
          // Jika di paling bawah
          if (index == _items.length) {
            if (_isLoadMoreRunning) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (!_hasNextPage && _items.length > 5) {
              // Tanda sudah mentok (opsional)
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text("Semua data telah dimuat")),
              );
            } else {
              return const SizedBox.shrink();
            }
          }

          return _PesananAdminCard(
            pesanan: _items[index], // Gunakan _items
            onActionSuccess: _handleRefresh, // Refresh list setelah aksi
          );
        },
      ),
    );
  }
}

// =============================================================================
// KARTU PESANAN (SAMA SEPERTI SEBELUMNYA - TIDAK BERUBAH)
// =============================================================================
class _PesananAdminCard extends StatelessWidget {
  final AdminPesananModel pesanan;
  final VoidCallback onActionSuccess;

  const _PesananAdminCard({
    required this.pesanan,
    required this.onActionSuccess,
  });

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final theme = Theme.of(context);
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? theme.colorScheme.error : Colors.green,
      textStyle: TextStyle(color: theme.colorScheme.onError),
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      curve: Curves.fastOutSlowIn,
    );
  }

  void _goToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPesananAdminScreen(
          noTransaksi: pesanan.noTransaksi,
          onActionSuccess: onActionSuccess, // Teruskan callback ke detail
        ),
      ),
    ).then((_) {
      // [PENTING] Panggil refresh saat kembali, siapa tahu data berubah di detail
      onActionSuccess();
    });
  }

  void _showSelesaiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.orange,
          size: 50,
        ),
        title: const Text(
          'Hati-hati!',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Apakah Anda yakin barang SUDAH SAMPAI di tangan pembeli?",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tindakan ini akan menyelesaikan pesanan secara otomatis dan tidak dapat dibatalkan lagi.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup Dialog

              try {
                final api = ApiService();
                final token = context.read<AuthProvider>().token!;

                final response = await api.adminTandaiSelesai(
                  token: token,
                  noTransaksi: pesanan.noTransaksi,
                );

                if (!context.mounted) return;

                _showToast(context, response['message'] ?? 'Pesanan selesai!');
                onActionSuccess();
              } catch (e) {
                if (!context.mounted) return;
                _showToast(
                  context,
                  e.toString().replaceAll("Exception: ", ""),
                  isError: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, Saya Yakin'),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiButton(BuildContext context, String status) {
    final theme = Theme.of(context);

    switch (status) {
      case 'menunggu_konfirmasi':
        return ElevatedButton.icon(
          onPressed: () => _goToDetail(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Cek Pembayaran'),
        );
      case 'diproses':
        return ElevatedButton.icon(
          onPressed: () => _goToDetail(context),
          icon: const Icon(Icons.local_shipping_outlined, size: 18),
          label: const Text('Proses Kirim'),
        );
      case 'dikirim':
        return OutlinedButton(
          onPressed: () => _showSelesaiDialog(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade700,
            side: BorderSide(color: Colors.green.shade700),
          ),
          child: const Text('Tandai Selesai'),
        );
      default:
        return OutGarisButton(
          onPressed: () => _goToDetail(context),
          child: const Text('Lihat Detail'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _goToDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pesanan.namaPemesan,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat(
                      'dd MMM, HH:mm',
                      'id_ID',
                    ).format(pesanan.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 20, thickness: 0.5),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      pesanan.fotoProduk ?? "",
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 70,
                        height: 70,
                        color: theme.colorScheme.surfaceContainer,
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: theme.hintColor,
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
                          pesanan.noTransaksi,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pesanan.namaProdukUtama,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pesanan.jumlah} Item',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Pesanan:', style: theme.textTheme.bodySmall),
                      Text(
                        _formatCurrency(pesanan.total),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  _buildAksiButton(context, pesanan.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OutGarisButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  const OutGarisButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: child);
  }
}
