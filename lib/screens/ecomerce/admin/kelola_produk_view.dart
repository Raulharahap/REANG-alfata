// Lokasi: lib/screens/ecomerce/admin/kelola_produk_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:reang_app/models/produk_model.dart';
import 'package:reang_app/models/produk_varian_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';

import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'form_produk_screen.dart';

class KelolaProdukView extends StatefulWidget {
  const KelolaProdukView({super.key});

  @override
  State<KelolaProdukView> createState() => _KelolaProdukViewState();
}

// [PERUBAHAN 1]: Tambahkan 'AutomaticKeepAliveClientMixin'
class _KelolaProdukViewState extends State<KelolaProdukView>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();

  // [PERUBAHAN 2]: Ganti bool _isLoading, _apiError, dan _produkList
  // dengan satu 'Future' yang akan mengelola semua state tersebut.
  late Future<List<ProdukModel>> _produkFuture;

  // [PERUBAHAN 3]: Implementasi 'wantKeepAlive'
  // Ini memberi tahu TabBarView untuk menyimpan state widget ini
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // [PERUBAHAN 4]: Panggil Future saat pertama kali widget dibuat
    // Future ini akan 'hidup' selama widget 'keep alive'
    _produkFuture = _fetchProdukSaya();
  }

  // ===========================================================
  // FETCH DATA (Sekarang mengembalikan Future<List<ProdukModel>>)
  // ===========================================================

  Future<List<ProdukModel>> _fetchProdukSaya() async {
    // [PERUBAHAN 5]: Hapus semua 'setState' dari fungsi fetch data.
    // FutureBuilder akan menangani state loading/error secara otomatis.
    if (!mounted) return [];

    final auth = context.read<AuthProvider>();

    if (auth.token == null || auth.user?.idToko == null) {
      // Lemparkan error agar FutureBuilder bisa menangkapnya
      throw Exception("Tidak dapat memuat produk: ID Toko tidak ditemukan.");
    }

    try {
      final List<ProdukModel> data = await _apiService.fetchProdukByToko(
        token: auth.token!,
        idToko: auth.user!.idToko!,
      );
      // Kembalikan data jika sukses
      return data;
    } catch (e) {
      // Lemparkan kembali error agar FutureBuilder menangkapnya
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // [PERUBAHAN 6]: Buat fungsi _onRefresh
  // Fungsi ini akan dipanggil oleh RefreshIndicator
  Future<void> _onRefresh() async {
    // Panggil setState dan buat Future baru.
    // Ini akan memicu FutureBuilder untuk rebuild dan menampilkan loading spinner.
    setState(() {
      _produkFuture = _fetchProdukSaya();
    });
  }

  // ===========================================================
  // UI HELPERS (Tidak berubah)
  // ===========================================================

  void _showToast(String message, {bool isError = false}) {
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

  // ===========================================================
  // NAVIGASI (Diperbarui untuk memanggil _onRefresh)
  // ===========================================================

  void _goToAddProduk() async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null || auth.user?.idToko == null) return;

    // 1. Tampilkan Loading (Opsional, biar user tau sedang mengecek)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. Panggil API Cek Kelengkapan
      final status = await _apiService.checkTokoKelengkapan(
        token: auth.token!,
        idToko: auth.user!.idToko!,
      );

      // Tutup Loading
      if (mounted) Navigator.pop(context);

      // 3. Cek Hasilnya
      if (status['is_ready'] == true) {
        // --- LULUS: Boleh Masuk Form ---
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const FormProdukScreen(produk: null),
          ),
        ).then((result) {
          if (result == true) _onRefresh();
        });
      } else {
        // --- GAGAL: Tampilkan Pesan Error Spesifik ---
        String message = "Lengkapi pengaturan toko terlebih dahulu!";

        bool noOngkir = status['has_ongkir'] == false;
        bool noMetode = status['has_metode'] == false;

        if (noOngkir && noMetode) {
          message =
              "Wajib isi 'Opsi Pengiriman' & 'Metode Pembayaran' di Pengaturan Toko!";
        } else if (noOngkir) {
          message = "Anda belum mengatur 'Opsi Pengiriman' (Ongkir)!";
        } else if (noMetode) {
          message = "Anda belum mengatur 'Metode Pembayaran'!";
        }

        // Tampilkan Toast Merah
        _showToast(message, isError: true);
      }
    } catch (e) {
      // Tutup loading jika error
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      _showToast("Gagal mengecek status toko. Coba lagi.", isError: true);
    }
  }

  void _editProduk(ProdukModel produk) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormProdukScreen(produk: produk)),
    ).then((result) {
      // [PERUBAHAN 7]: Panggil _onRefresh jika ada perubahan data
      if (result == true) _onRefresh();
    });
  }

  // ===========================================================
  // HAPUS PRODUK (Diperbarui untuk memanggil _onRefresh)
  // ===========================================================

  Future<void> _hapusProduk(int produkId, String namaProduk) async {
    final auth = context.read<AuthProvider>();
    if (auth.token == null) return;

    final bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Hapus Produk?"),
        content: Text(
          "Anda yakin ingin menghapus '$namaProduk'? "
          "Aksi ini tidak dapat dibatalkan.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              "Ya, Hapus",
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      final res = await _apiService.deleteProduk(
        token: auth.token!,
        produkId: produkId,
      );

      _showToast(res['message'] ?? "Produk berhasil dihapus");
      // [PERUBAHAN 7]: Panggil _onRefresh jika ada perubahan data
      _onRefresh();
    } catch (e) {
      _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
    }
  }

  // ===========================================================
  // DATA FORMATTER (Tidak berubah)
  // ===========================================================

  String _formatCurrency(int value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  String _getPriceRange(List<ProdukVarianModel> varians) {
    if (varians.isEmpty) return "Rp 0";

    final list = varians.map((v) => v.harga).toList()..sort();
    final minPrice = _formatCurrency(list.first);
    final maxPrice = _formatCurrency(list.last);

    return minPrice == maxPrice ? minPrice : "$minPrice - $maxPrice";
  }

  String _getTotalStok(List<ProdukVarianModel> varians) {
    if (varians.isEmpty) return "0";
    return varians.fold<int>(0, (sum, v) => sum + v.stok).toString();
  }

  // ===========================================================
  // UI COMPONENTS (Tidak berubah)
  // ===========================================================

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool primary = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: primary
            ? ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              )
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon, size: 16),
                label: Text(text),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    // Hitung tinggi ruang kosong agar RefreshIndicator tetap dapat ditarik
    final double availableHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.top -
        kToolbarHeight;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: availableHeight > 0 ? availableHeight : 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              // ----------------------------------------------------------------
              // Ikon Empty State
              // ----------------------------------------------------------------
              Icon(
                Icons.store_mall_directory_outlined,
                size: 80,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),

              const SizedBox(height: 24),

              // ----------------------------------------------------------------
              // Judul
              // ----------------------------------------------------------------
              Text(
                'Belum Ada Produk Terdaftar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // ----------------------------------------------------------------
              // Subjudul
              // ----------------------------------------------------------------
              Text(
                'Toko Anda belum memiliki produk aktif.\n'
                'Tambahkan produk pertama Anda melalui tombol "Tambah Produk" di bawah.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.hintColor,
                ),
              ),

              const SizedBox(
                height: 100,
              ), // Spacer agar tidak terlalu mepet FAB
            ],
          ),
        ),
      ),
    );
  }

  // Helper baru agar tampilan Rapi, Lurus, dan Mendukung Icon
  Widget _buildUnifiedStat(
    ThemeData theme, {
    required String label,
    required String value,
    IconData? icon,
    Color? iconColor,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
                fontSize: 14, // Ukuran font konsisten
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  // ===========================================================
  // BUILD UI (Dirombak untuk FutureBuilder + RefreshIndicator)
  // ===========================================================

  @override
  Widget build(BuildContext context) {
    // [PERUBAHAN 8]: Panggil super.build()
    super.build(context);

    final theme = Theme.of(context);
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToAddProduk,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),

      body: SafeArea(
        // [PERUBAHAN 9]: Ganti logika if-else dengan FutureBuilder
        child: FutureBuilder<List<ProdukModel>>(
          future: _produkFuture,
          builder: (context, snapshot) {
            // --- 1. Saat Loading ---
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // --- 2. Jika Gagal (Error) ---
            if (snapshot.hasError) {
              // [PERUBAHAN 10]: Bungkus Error state dengan RefreshIndicator
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.5,
                    alignment: Alignment.center,
                    child: Center(
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                ),
              );
            }

            ///alt gambar produk kosong
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState(theme); // <-- Panggil helper baru di sini
            }

            // --- 4. Jika Sukses (Ada Data) ---
            final produkList = snapshot.data!;

            // [PERUBAHAN 10]: Bungkus ListView dengan RefreshIndicator
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + 72 + bottomPad),
                itemCount: produkList.length,
                itemBuilder: (context, i) {
                  final produk = produkList[i];

                  return Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Foto
                        Image.network(
                          produk.foto ?? "",
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            color: theme.colorScheme.surfaceVariant,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 50,
                              color: theme.hintColor,
                            ),
                          ),
                        ),

                        // Nama dan ID
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                produk.nama,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "ID: ${produk.id}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Statistik
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: IntrinsicHeight(
                              // Agar garis pemisah tingginya pas
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // 1. HARGA
                                  _buildUnifiedStat(
                                    theme,
                                    label: "Harga",
                                    value: _getPriceRange(produk.varians),
                                  ),

                                  // Garis Pemisah Tipis
                                  VerticalDivider(
                                    width: 24, // Jarak total (kiri+kanan)
                                    thickness: 1,
                                    color: theme.dividerColor.withOpacity(0.5),
                                    indent: 4,
                                    endIndent: 4,
                                  ),

                                  // 2. STOK
                                  _buildUnifiedStat(
                                    theme,
                                    label: "Stok",
                                    value: _getTotalStok(produk.varians),
                                  ),

                                  VerticalDivider(
                                    width: 24,
                                    thickness: 1,
                                    color: theme.dividerColor.withOpacity(0.5),
                                    indent: 4,
                                    endIndent: 4,
                                  ),

                                  // 3. TERJUAL
                                  _buildUnifiedStat(
                                    theme,
                                    label: "Terjual",
                                    value: produk.terjual.toString(),
                                  ),

                                  VerticalDivider(
                                    width: 24,
                                    thickness: 1,
                                    color: theme.dividerColor.withOpacity(0.5),
                                    indent: 4,
                                    endIndent: 4,
                                  ),

                                  // 4. RATING (Ada Icon Bintang)
                                  _buildUnifiedStat(
                                    theme,
                                    label: "Rating",
                                    value: produk.rating == 0
                                        ? "Baru"
                                        : produk.rating.toStringAsFixed(1),
                                    icon: Icons.star_rounded,
                                    iconColor: Colors.amber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Divider(indent: 16, endIndent: 16),

                        // Aksi
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildActionButton(
                                text: "Edit",
                                icon: Icons.edit_outlined,
                                color: theme.colorScheme.primary,
                                primary: true,
                                onPressed: () => _editProduk(produk),
                              ),
                              _buildActionButton(
                                text: "Hapus",
                                icon: Icons.delete_outline,
                                color: theme.colorScheme.error,
                                onPressed: () =>
                                    _hapusProduk(produk.id, produk.nama),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
