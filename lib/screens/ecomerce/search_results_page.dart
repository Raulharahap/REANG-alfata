import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reang_app/models/produk_model.dart';
import 'package:reang_app/models/produk_varian_model.dart'; // <-- [BARU] Impor Varian
import 'package:reang_app/services/api_service.dart';
import 'cart_screen.dart';
import 'detail_produk_screen.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  // --- STATE ---
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // State untuk hasil pencarian utama
  List<ProdukModel> _masterProductList = [];
  List<Map<String, dynamic>> _filteredProducts = [];

  // State Paginasi & Error
  int _currentPage = 1;
  bool _hasMorePages = true;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  String? _apiError;

  // State untuk rekomendasi jika hasil pencarian kosong
  List<ProdukModel> _recommendations = [];
  List<Map<String, dynamic>> _mappedRecommendations = [];
  bool _isLoadingRecs = false;

  // Base URL fallback (sesuaikan bila ApiService menyediakan lokasi baseUrl)
  final String _baseUrl = "https://zara-gruffiest-silas.ngrok-free.dev";

  @override
  void initState() {
    super.initState();
    _fetchInitialProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================================
  // --- FUNGSI DATA & API ---
  // =========================================================================

  Future<void> _fetchInitialProducts() async {
    if (!_isLoadingInitial) {
      setState(() => _isLoadingInitial = true);
    }
    _currentPage = 1;
    _hasMorePages = true;
    _apiError = null;
    _recommendations = [];
    _mappedRecommendations = [];

    try {
      final response = await _apiService.fetchProdukPaginated(
        page: _currentPage,
        query: widget.query,
      );

      _masterProductList = response.data;
      _currentPage = response.currentPage;
      _hasMorePages = response.hasMorePages;

      if (_masterProductList.isEmpty && _apiError == null) {
        _fetchRecommendations();
      }
    } catch (e) {
      _apiError = e.toString();
      _masterProductList = [];
    }

    // Animasi kecil supaya UI tidak langsung "kejepret"
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() {
        _isLoadingInitial = false;
        _filterProducts();
      });
    }
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoadingRecs = true);
    try {
      final recResponse = await _apiService.fetchProdukPaginated(
        page: 1,
        fitur: 'Semua',
      );
      _recommendations = recResponse.data;
      _mappedRecommendations = _recommendations
          .map((p) => _mapProdukModelToCardData(p))
          .toList();
    } catch (e) {
      _recommendations = [];
      _mappedRecommendations = [];
    }
    if (mounted) setState(() => _isLoadingRecs = false);
  }

  Future<void> _fetchMoreProducts() async {
    if (_isLoadingMore || !_hasMorePages) return;
    setState(() => _isLoadingMore = true);

    try {
      final response = await _apiService.fetchProdukPaginated(
        page: _currentPage + 1,
        query: widget.query,
      );
      _masterProductList.addAll(response.data);
      _currentPage = response.currentPage;
      _hasMorePages = response.hasMorePages;
    } catch (e) {
      _apiError = e.toString();
      _hasMorePages = false;
    }

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        _filterProducts();
      });
    }
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

  // [PERBAIKAN UTAMA 1]: Mapping data ke Card (disamakan dengan UmkmScreen)
  Map<String, dynamic> _mapProdukModelToCardData(ProdukModel produk) {
    String? fotoUrl = produk.foto;

    if (fotoUrl != null && fotoUrl.isNotEmpty && !fotoUrl.startsWith('http')) {
      if (fotoUrl.startsWith('storage/')) {
        fotoUrl = '$_baseUrl/$fotoUrl';
      } else {
        fotoUrl = '$_baseUrl/storage/$fotoUrl';
      }
    }

    // [PERBAIKAN] Logika Harga dan Stok (Varian)
    String priceDisplay;
    int totalStok = 0;

    final List<ProdukVarianModel> varianList = produk.varians;
    if (varianList.isEmpty) {
      priceDisplay = _formatCurrency(0);
      totalStok = 0;
    } else {
      final prices = varianList.map((v) => v.harga).whereType<int>().toList();
      prices.sort();
      totalStok = varianList.fold(0, (sum, v) => sum + (v.stok));

      if (prices.isEmpty) {
        priceDisplay = _formatCurrency(0);
      } else if (prices.first == prices.last) {
        priceDisplay = _formatCurrency(prices.first);
      } else {
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
      'sold_text': '$totalStok Stok',
      'price_final': priceDisplay,
      'location': produk.lokasi ?? 'Indramayu',
      'category': produk.fitur ?? 'Lainnya',
      'stock': totalStok,
      'description': produk.deskripsi,
      'specifications': produk.spesifikasi,
      'varians': varianList.map((v) => v.toJson()).toList(),
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
    // [PERBAIKAN] Rasio disamakan dengan UmkmScreen
    const double heightMultiplier = 1.9;
    final double childAspectRatio = itemWidth / (itemWidth * heightMultiplier);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65.0),
        child: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          titleSpacing: 0.0,
          title: SafeArea(
            child: Container(
              padding: const EdgeInsets.only(top: 8.0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
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
                      Icon(Icons.search, color: theme.hintColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.query,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            SafeArea(
              child: Container(
                padding: const EdgeInsets.only(top: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  iconSize: 28.0,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CartScreen(),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          foregroundColor: theme.colorScheme.onSurface,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInitialProducts,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
                child: Text(
                  'Hasil untuk "${widget.query}"',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            _buildProductGrid(childAspectRatio),
          ],
        ),
      ),
    );
  }

  /// Widget helper ini di-refactor untuk mengembalikan Sliver
  Widget _buildProductGrid(double childAspectRatio) {
    final theme = Theme.of(context);

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
              Icon(Icons.wifi_off_rounded, color: theme.hintColor, size: 50),
              const SizedBox(height: 16),
              Text(
                'Gagal terhubung',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              Text(
                'Tarik untuk mencoba lagi.',
                style: TextStyle(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_masterProductList.isEmpty) {
      // [PERBAIKAN] Tampilkan "Not Found" + Rekomendasi
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search_off_outlined,
                  color: theme.hintColor.withOpacity(0.7),
                  size: 80,
                ),
                const SizedBox(height: 20),
                Text(
                  'Maaf, pencarian tidak ditemukan',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Kata kunci "${widget.query}" tidak cocok dengan produk manapun.\nCoba periksa ejaan atau gunakan kata kunci lain.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Divider(color: theme.dividerColor.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Rekomendasi untuk Anda',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Grid Rekomendasi
          _isLoadingRecs
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _mappedRecommendations.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, index) {
                    // Ambil Map dan Model
                    final productMap =
                        _mappedRecommendations[index]; // Map (untuk Card)
                    final produkModel =
                        _recommendations[index]; // Model (untuk Detail)

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailProdukScreen(
                              product: produkModel, // kirim Model
                            ),
                          ),
                        );
                      },
                      child: ProductCard(
                        product: productMap, // Card tetap pakai Map
                      ),
                    );
                  },
                ),
          const SizedBox(height: 24), // Padding bawah
        ]),
      );
    }

    // [PERBAIKAN 5] Kembalikan SliverPadding + SliverGrid (State Sukses)
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 80),
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

          // Ambil Map dan Model
          final productMap = _filteredProducts[index]; // Map untuk Card
          final produkModel = _masterProductList[index]; // Model untuk Detail

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      DetailProdukScreen(product: produkModel),
                ),
              );
            },
            child: ProductCard(product: productMap),
          );
        },
      ),
    );
  }
}

// =========================================================================
// --- ProductCard (Anti-Overflow) ---
// =========================================================================
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const ProductCard({required this.product, super.key});

  /// (Helper _buildProductImage)
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

    final title = (product['title'] ?? 'Nama Produk').toString();
    final priceFinal = (product['price_final'] ?? 'Rp 0').toString();
    final rating = product['rating']?.toString() ?? '0';
    final soldText = product['sold_text'] ?? 'Stok: 0';
    final location = product['location'] ?? 'Lokasi tidak diketahui';

    return Card(
      elevation: 1.0,
      shadowColor: theme.shadowColor.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: Hero(
              tag: 'produk-${product['id']}',
              child: _buildProductImage(product['image'] as String?, context),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0), // <-- Padding Rapat
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    priceFinal,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: priceColor,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
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
                          const SizedBox(width: 2),
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
                  const SizedBox(height: 4),
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
                          softWrap: false,
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
