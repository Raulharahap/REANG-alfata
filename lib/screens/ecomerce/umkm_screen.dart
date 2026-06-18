import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/produk_model.dart';
import 'package:reang_app/models/riwayat_transaksi_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'cart_screen.dart';
import 'detail_produk_screen.dart';
import 'proses_order_screen.dart';
import 'form_toko_screen.dart';
import 'package:reang_app/screens/auth/login_screen.dart';
import 'package:reang_app/screens/ecomerce/admin/home_admin_umkm_screen.dart';
import 'package:reang_app/screens/ecomerce/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Untuk cek notif
import 'package:reang_app/screens/ecomerce/umkm_chat_list_screen.dart'; // Halaman List Chat

final RouteObserver<ModalRoute<void>> umkmRouteObserver =
    RouteObserver<ModalRoute<void>>();

class UmkmScreen extends StatefulWidget {
  const UmkmScreen({super.key});

  @override
  State<UmkmScreen> createState() => _UmkmScreenState();
}

class _UmkmScreenState extends State<UmkmScreen>
    with WidgetsBindingObserver, RouteAware {
  // --- STATE ---
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  List<ProdukModel> _masterProductList = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  // State untuk notifikasi "Belum Dibayar"
  int _userUnpaidCount = 0; // Khusus user
  int _adminOrderCount = 0; // Untuk Pesanan Masuk
  int _adminChatCount = 0; // Untuk Chat Pelanggan

  StreamSubscription? _adminChatSubscription; // Stream Listener

  // State Paginasi & Error
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _isOpeningChat = false;
  String? _apiError;
  late AuthProvider _authProvider;

  // State Kategori
  final List<Map<String, dynamic>> categories = const [
    {'name': 'Semua', 'icon': Icons.shopping_bag_outlined},
    {'name': 'Fashion', 'icon': Icons.checkroom_outlined},
    {'name': 'Kuliner', 'icon': Icons.lunch_dining_outlined},
    {'name': 'Elektronik', 'icon': Icons.devices_other_outlined},
  ];
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchInitialProducts();
    _scrollController.addListener(_onScroll);

    _authProvider = context.read<AuthProvider>();

    // [PERBAIKAN] Gunakan listener gabungan
    _authProvider.addListener(_onAuthChanged);

    // Panggil pertama kali manual
    _onAuthChanged();
  }

  // --- Lifecycle untuk Auto-Refresh Notifikasi ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      umkmRouteObserver.subscribe(this, route);
      debugPrint("!!! UmkmScreen: Berhasil subscribe ke RouteObserver.");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // [PERBAIKAN] Remove listener yang benar
    _authProvider.removeListener(_onAuthChanged);

    _adminChatSubscription?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    debugPrint("!!! UmkmScreen: didPopNext() terpicu! Refreshing notifikasi.");
    _fetchUnpaidCount();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchUnpaidCount();
    }
  }

  void _listenToAdminChats() {
    // [PENTING] Matikan pendengar lama dulu biar tidak numpuk/salah orang
    _adminChatSubscription?.cancel();
    _adminChatSubscription = null;

    final auth = context.read<AuthProvider>();

    // Kalau belum login, reset chat count jadi 0
    if (!auth.isLoggedIn || auth.user == null) {
      if (mounted) setState(() => _adminChatCount = 0);
      return;
    }

    final myId = auth.user!.id.toString();

    // Mulai dengarkan dengan ID User yang BARU
    _adminChatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myId)
        .where('isUmkmChat', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          int unreadTotal = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();

            // Pastikan konversi tipe data aman
            final chatUserId = data['userId'].toString();

            // Filter: Skip chat punya sendiri
            if (chatUserId == myId) continue;

            final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadMap != null) {
              unreadTotal += (unreadMap[myId] as int? ?? 0);
            }
          }

          if (mounted) {
            setState(() {
              _adminChatCount = unreadTotal;
            });
          }
        });
  }

  // Fungsi ini dipanggil otomatis saat Login / Logout
  void _onAuthChanged() {
    _fetchUnpaidCount(); // Refresh Pesanan API
    _listenToAdminChats(); // Refresh Chat Firebase (INI YANG KEMARIN KURANG)
  }
  // =========================================================================
  // --- FUNGSI DATA & API ---
  // =========================================================================

  Future<void> _fetchUnpaidCount() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || auth.user == null || auth.token == null) {
      if (mounted)
        setState(() {
          _adminOrderCount = 0; // <--- GANTI JADI INI
          _adminChatCount = 0; // <--- TAMBAHKAN INI (Biar chat juga ke-reset)
        });
      return;
    }

    try {
      // 1. User Count
      final List<RiwayatTransaksiModel> allOrders = await _apiService
          .fetchRiwayatTransaksi(token: auth.token!, userId: auth.user!.id);
      final userCount = allOrders
          .where((order) => order.getTabKategori == 'Belum Dibayar')
          .length;

      // 2. Admin Count
      int adminCount = 0;
      if (auth.user!.idToko != null && auth.user!.idToko != 0) {
        try {
          final adminCounts = await _apiService.fetchOrderCounts(
            token: auth.token!,
            idToko: auth.user!.idToko!,
          );
          adminCount =
              (adminCounts['menunggu_konfirmasi'] ?? 0) +
              (adminCounts['diproses'] ?? 0);
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _userUnpaidCount = userCount;
          _adminOrderCount = adminCount;
        });
      }
    } catch (_) {
      // Error handling
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([_fetchInitialProducts(), _fetchUnpaidCount()]);
  }

  Future<void> _fetchInitialProducts() async {
    if (!_isLoadingInitial) {
      setState(() {
        _isLoadingInitial = true;
      });
    }
    _currentPage = 1;
    _hasMorePages = true;
    _apiError = null;

    try {
      final response = await _apiService.fetchProdukPaginated(
        page: _currentPage,
        fitur: categories[_selectedCategoryIndex]['name'],
      );
      _masterProductList = response.data;
      _currentPage = response.currentPage;
      _hasMorePages = response.hasMorePages;
    } catch (e) {
      _apiError = e.toString();
      _masterProductList = [];
    }

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoadingInitial = false;
        _filterProducts();
      });
    }
  }

  Future<void> _fetchMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _apiService.fetchProdukPaginated(
        page: _currentPage + 1,
        fitur: categories[_selectedCategoryIndex]['name'],
      );
      _masterProductList.addAll(response.data);
      _currentPage = response.currentPage;
      _hasMorePages = response.hasMorePages;
    } catch (e) {
      _apiError = e.toString();
      _hasMorePages = false;
    }

    setState(() {
      _isLoadingMore = false;
      _filterProducts();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _fetchMoreProducts();
    }
  }

  // [BARU] Helper format mata uang
  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  // [PERBAIKAN UTAMA 1]: Mapping data ke Card
  Map<String, dynamic> _mapProdukModelToCardData(ProdukModel produk) {
    String baseUrl = "https://zara-gruffiest-silas.ngrok-free.dev"; // Sesuaikan
    String? fotoUrl = produk.foto;

    if (fotoUrl != null && !fotoUrl.startsWith('http')) {
      if (fotoUrl.startsWith('storage/')) {
        fotoUrl = '$baseUrl/$fotoUrl';
      } else {
        fotoUrl = '$baseUrl/storage/$fotoUrl';
      }
    }

    // [PERBAIKAN] Logika Harga dan Stok (Varian)
    String priceDisplay = _formatCurrency(produk.harga);
    int totalStok = produk.stok;

    // [OPSIONAL] Jika Anda ingin rentang harga (bukan hanya terendah)
    if (produk.varians.length > 1) {
      final prices = produk.varians.map((v) => v.harga).toList();
      prices.sort();
      if (prices.first != prices.last) {
        priceDisplay =
            "${_formatCurrency(prices.first)} - ${_formatCurrency(prices.last)}";
      }
    }

    return {
      'id': produk.id,
      'id_toko': produk.idToko,
      'image': fotoUrl,
      'title': produk.nama,
      'subtitle': produk.deskripsi ?? produk.nama,
      'rating': produk.rating == 0 ? 'Baru' : produk.rating.toStringAsFixed(1),
      'sold_text': '$totalStok Stok', // [PERBAIKAN] Tampilkan total stok
      'price_final':
          priceDisplay, // [PERBAIKAN] Tampilkan harga terendah/rentang
      'location': produk.lokasi ?? 'Indramayu',
      'category': produk.fitur ?? 'Lainnya',
      'stock': totalStok,
      'description': produk.deskripsi,
      'specifications': produk.spesifikasi,
      'varians': produk.varians.map((v) => v.toJson()).toList(),
    };
  }

  void _filterProducts() {
    _filteredProducts = _masterProductList
        .map((p) => _mapProdukModelToCardData(p))
        .toList();
    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================================
  // --- FUNGSI EVENT HANDLER ---
  // =========================================================================

  void _onCategorySelected(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    _fetchInitialProducts();
  }

  // GANTI FUNGSI LAMA DENGAN INI
  Future<void> _navigateToOrderProcess() async {
    final auth = context.read<AuthProvider>();

    // SKENARIO 1: SUDAH LOGIN
    // Langsung masuk ke halaman pesanan
    if (auth.isLoggedIn && auth.user != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProsesOrderScreen()),
      );
      // Saat kembali (Back), refresh notifikasi
      _fetchUnpaidCount();
    }
    // SKENARIO 2: BELUM LOGIN
    // Arahkan ke Login dulu
    else {
      final bool? loginSuccess = await Navigator.push(
        context,
        MaterialPageRoute(
          // popOnSuccess: true -> Agar setelah login sukses, dia 'Pop' (balik ke sini) membawa nilai true
          builder: (context) => const LoginScreen(popOnSuccess: true),
        ),
      );

      // Jika user berhasil login (loginSuccess == true)
      if (loginSuccess == true && mounted) {
        // Otomatis lanjutkan buka halaman pesanan
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProsesOrderScreen()),
        );
        _fetchUnpaidCount(); // Refresh notifikasi setelah selesai
      }
    }
  }

  void _showFabMenu() {
    final authProvider = context.read<AuthProvider>();
    final theme = Theme.of(context);
    final myId = authProvider.user?.id.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- OPSI 1: TOKO SAYA (DENGAN LIVE STREAM) ---
              ListTile(
                leading: Icon(
                  Icons.store_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: authProvider.isLoggedIn && authProvider.isUmkm
                    ? StreamBuilder<QuerySnapshot>(
                        // 1. PASANG STREAM LANGSUNG DI SINI
                        stream: FirebaseFirestore.instance
                            .collection('chats')
                            .where('participants', arrayContains: myId)
                            .where('isUmkmChat', isEqualTo: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int unreadChat = 0;

                          // 2. HITUNG CHAT UNREAD SECARA LIVE
                          if (snapshot.hasData) {
                            for (var doc in snapshot.data!.docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final chatUserId = data['userId'].toString();

                              // Filter: Skip chat belanjaan sendiri
                              if (chatUserId == myId) continue;

                              final unreadMap =
                                  data['unreadCount'] as Map<String, dynamic>?;
                              if (unreadMap != null) {
                                unreadChat += (unreadMap[myId] as int? ?? 0);
                              }
                            }
                          }

                          // 3. GABUNGKAN DENGAN ORDER COUNT
                          final totalNotif = _adminOrderCount + unreadChat;

                          return _buildNotificationBadge(
                            totalNotif,
                            const Text(
                              'Toko Saya',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            isDense: true,
                          );
                        },
                      )
                    // Kalau belum login/bukan UMKM, tampilkan teks biasa
                    : const Text(
                        'Toko Saya',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                subtitle: Text(
                  authProvider.isLoggedIn
                      ? (authProvider.isUmkm
                            ? 'Kelola produk dan pesanan toko Anda'
                            : 'Daftar atau buka toko UMKM Anda')
                      : 'Login untuk mengelola toko Anda',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  if (!authProvider.isLoggedIn) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ).then((_) {
                      _fetchUnpaidCount();
                    });
                  } else {
                    if (authProvider.isUmkm) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeAdminUmkmScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FormTokoScreen(),
                        ),
                      );
                    }
                  }
                },
              ),

              // --- OPSI 2: PESANAN SAYA (User Biasa) ---
              ListTile(
                leading: Icon(
                  Icons.receipt_long_outlined,
                  color: theme.hintColor,
                ),
                title: _buildNotificationBadge(
                  _userUnpaidCount,
                  const Text('Pesanan Saya'),
                  isDense: true,
                ),
                subtitle: const Text('Lacak semua pesanan produk UMKM Anda'),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToOrderProcess();
                },
              ),
            ],
          ),
        );
      },
    );

    // Tetap panggil fetch untuk update data order API
    _fetchUnpaidCount();
  }

  // [PERBAIKAN] Widget helper untuk badge (warna hardcoded)
  Widget _buildNotificationBadge(
    int count,
    Widget child, {
    bool isDense = false,
  }) {
    if (count == 0) {
      return child;
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: isDense ? -4 : 0,
          right: isDense ? -4 : 0,
          child: Container(
            padding: EdgeInsets.all(isDense ? 4 : 6),
            decoration: BoxDecoration(
              color: Colors.red, // <-- Warna merah hardcoded
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2,
              ),
            ),
            constraints: BoxConstraints(
              minWidth: isDense ? 18 : 22,
              minHeight: isDense ? 18 : 22,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDense ? 10 : 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatIconButton(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final theme = Theme.of(context);

    if (!auth.isLoggedIn || auth.user == null) {
      return IconButton(
        icon: const Icon(Icons.chat_bubble_outline),
        iconSize: 26.0,
        color: theme.hintColor,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          ).then((_) {
            _fetchUnpaidCount();
          });
        },
      );
    }

    final myId = auth.user!.id.toString();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          // 1. Syarat Keamanan (Participants)
          .where('participants', arrayContains: myId)
          // 2. FILTER BARU: Hanya hitung chat yang dibuat oleh SAYA (sebagai pembeli)
          // Filter ini sama persis dengan yang ada di UmkmChatListScreen
          .where('userId', isEqualTo: int.tryParse(myId) ?? 0)
          // 3. Tipe Chat
          .where('isUmkmChat', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadTotal = 0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final unreadMap = data['unreadCount'] as Map<String, dynamic>?;
            if (unreadMap != null) {
              unreadTotal += (unreadMap[myId] as int? ?? 0);
            }
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: _isOpeningChat
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              iconSize: 26.0,
              color: theme.hintColor,
              onPressed: _isOpeningChat
                  ? null
                  : () async {
                      setState(() => _isOpeningChat = true);
                      try {
                        await auth.ensureFirebaseLoggedIn();
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UmkmChatListScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Gagal membuka chat: ${e.toString()}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isOpeningChat = false);
                        }
                      }
                    },
            ),
            if (unreadTotal > 0 && !_isOpeningChat)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      unreadTotal > 99 ? '99+' : unreadTotal.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // --- FUNGSI BUILD ---
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    const double horizontalPadding = 12.0 * 2;
    const double crossAxisSpacing = 8.0;
    final double itemWidth =
        (screenWidth - horizontalPadding - crossAxisSpacing) / 2;
    // [PERBAIKAN] Sesuaikan rasio untuk mengakomodasi teks harga 2 baris
    const double heightMultiplier = 1.9;
    final double childAspectRatio = itemWidth / (itemWidth * heightMultiplier);

    final bottomInset =
        MediaQuery.of(context).padding.bottom +
        MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65.0),
        child: AppBar(
          automaticallyImplyLeading: false,
          title: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SearchPage(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.ease;
                                  final tween = Tween(
                                    begin: begin,
                                    end: end,
                                  ).chain(CurveTween(curve: curve));
                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(10.0),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.5),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.08),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: theme.hintColor,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Cari produk UMKM...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 4),

                  // 2. TOMBOL CHAT (Panggil fungsi yang kita buat tadi)
                  _buildChatIconButton(context),

                  // 3. TOMBOL KERANJANG (Geser dikit biar ga nempel)
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    iconSize: 26.0, // Sesuaikan ukuran biar sama dengan chat
                    color: theme.hintColor, // Pastikan warna seragam
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
        ),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // --- WIDGET 1: Category Chips (Sticky) ---
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(category['name']),
                        avatar: Icon(
                          category['icon'],
                          size: 18,
                          color: _selectedCategoryIndex == index
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.primary,
                        ),
                        selected: _selectedCategoryIndex == index,
                        showCheckmark: false,
                        onSelected: (bool selected) {
                          if (selected) {
                            _onCategorySelected(index);
                          }
                        },
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: theme.cardColor,
                        labelStyle: TextStyle(
                          color: _selectedCategoryIndex == index
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: _selectedCategoryIndex == index
                                ? Colors.transparent
                                : theme.dividerColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // --- WIDGET 2: Bagian Scrollable (Refresh + Header + Grid) ---
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // --- SLIVER 1: Header "Hasil Produk" (Scrollable) ---
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            10.0,
                            16.0,
                            16.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Hasil Produk (${categories[_selectedCategoryIndex]['name']})',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (!_isLoadingInitial && _apiError == null)
                                Text(
                                  '${_masterProductList.length} produk',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.hintColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // --- SLIVER 2: Grid Produk (Loading/Error/Grid) ---
                      _buildProductGrid(childAspectRatio, bottomInset),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // --- FAB (Floating Action Button) ---
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.only(
                right: 16.0,
                bottom: (bottomInset == 0 ? 16.0 : bottomInset) + 16.0,
              ),
              child: SizedBox(
                width: 55.0,
                height: 55.0,
                child: _buildNotificationBadge(
                  // TOTAL SEMUA NOTIFIKASI:
                  // 1. Pesanan Saya (User)
                  // 2. Pesanan Masuk (Admin)
                  // 3. Chat Pelanggan (Admin)
                  _userUnpaidCount + _adminOrderCount + _adminChatCount,
                  FloatingActionButton(
                    onPressed: _showFabMenu,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 6.0,
                    tooltip: 'Menu Saya',
                    child: const Icon(Icons.apps_outlined, size: 28),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget helper ini di-refactor untuk mengembalikan Sliver
  Widget _buildProductGrid(double childAspectRatio, double bottomInset) {
    if (_isLoadingInitial) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_apiError != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Theme.of(context).hintColor,
                size: 50,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal terhubung',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                'Tarik untuk mencoba lagi.',
                style: TextStyle(color: Theme.of(context).hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_masterProductList.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Text(
            'Belum ada produk yang tersedia.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(12.0, 0, 12.0, bottomInset + 80),
      sliver: SliverGrid.builder(
        itemCount: _filteredProducts.length + (_hasMorePages ? 1 : 0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: childAspectRatio,
        ),
        itemBuilder: (context, index) {
          if (index == _filteredProducts.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final productMap =
              _filteredProducts[index]; // Map → untuk ProductCard
          final produkModel =
              _masterProductList[index]; // Model → untuk DetailScreen

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailProdukScreen(
                    product: produkModel, // kirim Model ke Detail
                  ),
                ),
              );
            },
            child: ProductCard(
              product: productMap, // ProductCard tetap menerima Map
            ),
          );
        },
      ),
    );
  }
}

// =========================================================================
// --- [PERBAIKAN UTAMA 2] ProductCard ---
// =========================================================================
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductCard({required this.product, super.key});

  /// Helper: membangun widget gambar produk (tidak berubah dari aslinya)
  Widget _buildProductImage(String? imageUrl, BuildContext context) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).hintColor.withOpacity(0.7),
            size: 36,
          ),
        ),
      );
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).hintColor.withOpacity(0.7),
              size: 36,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color priceColor = theme.colorScheme.primary;

    // Safe getters with fallback
    final String idTag = product['id']?.toString() ?? UniqueKey().toString();
    final String title = product['title']?.toString() ?? 'Nama Produk';
    final String image = product['image']?.toString() ?? '';
    final String priceFinal = product['price_final']?.toString() ?? '-';
    final String rating = (product['rating'] != null)
        ? product['rating'].toString()
        : '-';
    final String soldText =
        product['sold_text']?.toString() ??
        (product['stock'] != null ? 'Stok: ${product['stock']}' : 'Stok: 0');
    final String location =
        product['location']?.toString() ?? 'Lokasi tidak diketahui';

    return Card(
      elevation: 1.0,
      shadowColor: theme.shadowColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 1. Foto produk
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'produk-$idTag',
              child: _buildProductImage(image, context),
            ),
          ),

          // 2. Area teks
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Judul
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Harga (menampilkan rentang atau value yang sudah ada)
                  Text(
                    priceFinal,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(), // dorong bar bawah ke bawah
                  // Rating & Stok
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber.shade700,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(rating, style: theme.textTheme.bodySmall),
                        ],
                      ),
                      Expanded(
                        child: Text(
                          soldText,
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Lokasi
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: theme.hintColor,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
