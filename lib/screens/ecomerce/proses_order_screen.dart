import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/riwayat_transaksi_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/ecomerce/payment_instruction_screen.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/screens/ecomerce/detail_order_screen.dart';
import 'package:reang_app/screens/ecomerce/chat_umkm_screen.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/screens/ecomerce/add_review_screen.dart';

// =============================================================================
// PARENT WIDGET (Hanya mengurus Tab, Badge, dan PageView)
// =============================================================================
class ProsesOrderScreen extends StatefulWidget {
  const ProsesOrderScreen({super.key});

  @override
  State<ProsesOrderScreen> createState() => _ProsesOrderScreenState();
}

class _ProsesOrderScreenState extends State<ProsesOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  // Badge Counts State
  Map<String, int> _counts = {};

  final List<String> _tabs = const [
    'Belum Dibayar',
    'Dikemas',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  // Mapping API Status Keys
  final List<String> _apiStatusKeys = const [
    'belum_dibayar',
    'dikemas',
    'dikirim',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _fetchBadgeCounts();
  }

  // [FITUR BARU] Ambil Badge Cepat (Ringan)
  Future<void> _fetchBadgeCounts() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.user == null) return;

    try {
      final data = await _apiService.fetchUserOrderCounts(
        token: auth.token!,
        userId: auth.user!.id,
      );
      if (mounted) {
        setState(() => _counts = data);
      }
    } catch (e) {
      debugPrint("Gagal load badge user: $e");
    }
  }

  // Refresh Global (Hanya update Badge)
  void _globalRefresh() {
    _fetchBadgeCounts();
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        actions: const [],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            controller: _tabController,
            tabAlignment: TabAlignment.start,
            isScrollable: true,
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant
                .withOpacity(0.7),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
            ),
            tabs: List.generate(_tabs.length, (index) {
              final tabLabel = _tabs[index];
              final apiStatus = _apiStatusKeys[index];
              final count = _counts[apiStatus] ?? 0;

              final bool showBadge =
                  (apiStatus == 'belum_dibayar' ||
                      apiStatus == 'dikemas' ||
                      apiStatus == 'dikirim') &&
                  count > 0;

              return Tab(
                child: Row(
                  children: [
                    Text(tabLabel),
                    if (showBadge)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onError,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
      // [PERUBAHAN] Body sekarang menggunakan TabBarView + Widget Anak Lazy Load
      body: TabBarView(
        controller: _tabController,
        children: List.generate(_tabs.length, (index) {
          return UserOrderListTab(
            apiStatus: _apiStatusKeys[index],
            onUpdate: _globalRefresh,
          );
        }),
      ),
    );
  }
}

// =============================================================================
// CHILD WIDGET: List Pesanan Per Tab (Lazy Load + Infinite Scroll)
// =============================================================================
class UserOrderListTab extends StatefulWidget {
  final String apiStatus;
  final VoidCallback onUpdate;

  const UserOrderListTab({
    super.key,
    required this.apiStatus,
    required this.onUpdate,
  });

  @override
  State<UserOrderListTab> createState() => _UserOrderListTabState();
}

class _UserOrderListTabState extends State<UserOrderListTab>
    with AutomaticKeepAliveClientMixin {
  // [1] Keep Alive
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<RiwayatTransaksiModel> _items = [];
  bool _isFirstLoading = true;
  bool _isLoadMoreRunning = false;
  bool _hasNextPage = true;
  int _page = 1;
  String? _errorMessage;

  @override
  bool get wantKeepAlive => true; // [2] Data tidak hilang saat geser tab

  @override
  void initState() {
    super.initState();
    _loadFirstData(); // [3] Lazy Load (Hanya dipanggil saat tab dibuka)

    // [4] Infinite Scroll Listener
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

      // Panggil API dengan Status Spesifik
      final data = await _apiService.fetchRiwayatTransaksi(
        token: auth.token!,
        userId: auth.user!.id,
        status: widget.apiStatus,
        page: _page,
      );

      if (mounted) {
        setState(() {
          _items = data;
          _isFirstLoading = false;
          if (data.length < 10) _hasNextPage = false;
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

  Future<void> _loadMoreData() async {
    if (_hasNextPage && !_isFirstLoading && !_isLoadMoreRunning) {
      setState(() => _isLoadMoreRunning = true);
      try {
        final auth = context.read<AuthProvider>();
        _page += 1;
        final data = await _apiService.fetchRiwayatTransaksi(
          token: auth.token!,
          userId: auth.user!.id,
          status: widget.apiStatus,
          page: _page,
        );

        if (mounted) {
          setState(() {
            if (data.isNotEmpty) {
              _items.addAll(data);
            }
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

  Future<void> _handleRefresh() async {
    widget.onUpdate(); // Refresh Badge di Parent
    await _loadFirstData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Wajib panggil super.build
    final theme = Theme.of(context);

    // 1. Loading
    if (_isFirstLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2. Error
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text("Gagal Memuat Pesanan", style: theme.textTheme.titleMedium),
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
        onRefresh: _handleRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: theme.hintColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Tidak ada pesanan di sini.",
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
      onRefresh: _handleRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _items.length + 1, // +1 untuk loading bawah
        itemBuilder: (context, index) {
          if (index == _items.length) {
            if (_isLoadMoreRunning) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox.shrink();
          }

          return OrderCard(
            order: _items[index],
            onPaymentSuccess: _handleRefresh,
          );
        },
      ),
    );
  }
}

// ===============================================
// --- KARTU PESANAN (DESAIN 100% SAMA) ---
// ===============================================
class OrderCard extends StatelessWidget {
  final RiwayatTransaksiModel order;
  final VoidCallback onPaymentSuccess;

  const OrderCard({
    required this.order,
    required this.onPaymentSuccess,
    super.key,
  });

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
      animation: StyledToastAnimation.scale,
      reverseAnimation: StyledToastAnimation.fade,
      animDuration: const Duration(milliseconds: 150),
      duration: const Duration(seconds: 2),
      borderRadius: BorderRadius.circular(25),
      textStyle: const TextStyle(color: Colors.white),
      backgroundColor: isError
          ? theme.colorScheme.error
          : Colors.black.withOpacity(0.8),
    );
  }

  void _goToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailOrderScreen(noTransaksi: order.noTransaksi),
      ),
    ).then((result) {
      if (result == true) {
        onPaymentSuccess();
      }
    });
  }

  void _goToPayment(BuildContext context) async {
    final apiService = ApiService();
    final auth = context.read<AuthProvider>();

    if (auth.token == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await apiService.fetchDetailTransaksi(
        token: auth.token!,
        noTransaksi: order.noTransaksi,
      );

      final Map<String, dynamic> paymentMap = response.transaksi.toJson();
      final List<Map<String, dynamic>> paymentData = [paymentMap];

      if (context.mounted) {
        Navigator.pop(context); // Tutup loading
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentInstructionScreen(
              paymentData: paymentData,
              onCustomClose: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
        onPaymentSuccess();
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup loading
        _showToast(
          context,
          'Gagal memuat: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        );
      }
    }
  }

  void _konfirmasiSelesai(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pesanan Diterima?"),
        content: const Text(
          "Pastikan produk sudah sesuai dan tidak rusak. Dana akan diteruskan ke penjual.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog
              try {
                final auth = context.read<AuthProvider>();
                final api = ApiService();

                await api.userSelesaikanPesanan(
                  token: auth.token!,
                  noTransaksi: order.noTransaksi,
                );

                if (context.mounted) {
                  _showToast(context, "Pesanan Selesai. Terima kasih!");
                  onPaymentSuccess(); // Refresh halaman
                }
              } catch (e) {
                if (context.mounted) {
                  _showToast(
                    context,
                    e.toString().replaceAll("Exception: ", ""),
                    isError: true,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text("Ya, Diterima"),
          ),
        ],
      ),
    );
  }

  void _goToReview(BuildContext context) async {
    final api = ApiService();
    final auth = context.read<AuthProvider>();

    try {
      showDialog(
        context: context,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Ambil Detail Transaksi (untuk tau produknya apa)
      final detail = await api.fetchDetailTransaksi(
        token: auth.token!,
        noTransaksi: order.noTransaksi,
      );

      // 2. [BARU] Cek apakah sudah ada ulasan sebelumnya?
      Map<String, dynamic>? ulasanLama;
      if (order.isReviewed) {
        ulasanLama = await api.fetchUlasanSaya(
          token: auth.token!,
          noTransaksi: order.noTransaksi,
        );
      }

      if (!context.mounted) return;
      Navigator.pop(context); // Tutup loading

      final itemToReview = detail.items.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddReviewScreen(
            idProduk: itemToReview.idProduk,
            namaProduk: itemToReview.namaProduk,
            fotoProduk: itemToReview.foto,
            noTransaksi: order.noTransaksi,

            // [BARU] Kirim data lama (jika ada)
            initialRating: ulasanLama?['rating'],
            initialComment: ulasanLama?['komentar'],
            initialPhotoUrl: ulasanLama?['foto'],
          ),
        ),
      ).then((result) {
        if (result == true) {
          onPaymentSuccess();
        }
      });
    } catch (e) {
      Navigator.pop(context);
      _showToast(context, "Gagal memuat data", isError: true);
    }
  }

  void _goToChat(BuildContext context) async {
    // 1. Ambil Auth Provider untuk dapatkan Token
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Cek Token dulu
    if (authProvider.token == null) {
      _showToast(context, 'Anda belum login', isError: true);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final apiService = ApiService();

      // 2. Panggil API dengan Token (UPDATE DISINI)
      final TokoModel tokoTarget = await apiService.fetchDetailToko(
        idToko: order.idToko,
        token: authProvider.token!, // <--- Masukkan Token disini
      );

      if (context.mounted) {
        Navigator.pop(context); // Tutup Loading

        // 3. Masuk Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatUMKMScreen(toko: tokoTarget),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showToast(
          context,
          'Gagal: ${e.toString().replaceAll("Exception: ", "")}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // --- [DEFINISI WARNA] ---
    final primaryColor = theme.colorScheme.primary;
    final onPrimaryColor = theme.colorScheme.onPrimary;
    // -----------------------

    final uiStatus = order.getUiStatus;
    final tabKategori = order.getTabKategori;
    final isUnpaid = tabKategori == 'Belum Dibayar';

    Color statusColor;
    switch (tabKategori) {
      case 'Selesai':
        statusColor = Colors.green;
        break;
      case 'Dibatalkan':
      case 'Belum Dibayar':
        statusColor = theme.colorScheme.error;
        break;
      default:
        statusColor = primaryColor;
    }

    VoidCallback? secondaryAction;
    String secondaryText = 'Hubungi Penjual';
    Color? secondaryColor;
    Color? secondaryTextColor;

    if (tabKategori == 'Selesai') {
      // [PERBAIKAN] Cek apakah sudah diulas?
      if (order.isReviewed) {
        secondaryText = 'Edit Ulasan';
        // Nanti di _goToReview kita perlu kirim tanda kalau ini edit
        secondaryAction = () => _goToReview(context);
      } else {
        secondaryText = 'Beri Ulasan';
        secondaryAction = () => _goToReview(context);
      }
    } else if (tabKategori == 'Dikirim') {
      secondaryAction = () => _konfirmasiSelesai(context);
      secondaryText = 'Pesanan Diterima';
      secondaryColor = Colors.green;
      secondaryTextColor = Colors.white;
    } else {
      secondaryAction = () => _goToChat(context);
      secondaryText = 'Hubungi Penjual';
    }

    return Card(
      elevation: 1,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Header Toko & Status
            Row(
              children: [
                Icon(
                  Icons.store_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.namaToko,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  uiStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),

            // Produk Info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order.fotoProduk ?? "",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: theme.colorScheme.surfaceContainer,
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        color: theme.hintColor.withOpacity(0.7),
                        size: 36,
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
                        order.namaProdukUtama ?? 'Produk',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(order.total),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${order.jumlah} Item',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer: Tanggal
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: theme.hintColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tanggal Pesanan:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat(
                      'dd MMM yyyy, HH:mm',
                      'id_ID',
                    ).format(order.createdAt.toLocal()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tombol Aksi
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goToDetail(context),
                    icon: Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: const Text(
                      'Lihat Detail',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      side: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: isUnpaid
                      ? ElevatedButton(
                          onPressed: () => _goToPayment(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.error,
                            foregroundColor: theme.colorScheme.onError,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 1,
                          ),
                          child: const Text('Bayar Sekarang'),
                        )
                      : ElevatedButton(
                          onPressed: secondaryAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: secondaryColor ?? primaryColor,
                            foregroundColor:
                                secondaryTextColor ?? onPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 1,
                          ),
                          child: Text(secondaryText),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
