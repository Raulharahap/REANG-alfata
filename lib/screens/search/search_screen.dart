import 'package:flutter/material.dart';
import 'package:reang_app/app/data/daftar_layanan.dart';
import 'package:reang_app/models/layanan_model.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LayananModel> _hasilPencarian = [];

  @override
  void initState() {
    super.initState();
    // PERBAIKAN: Awalnya, hasil pencarian kosong.
    _hasilPencarian = [];
    _searchController.addListener(_filterLayanan);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterLayanan);
    _searchController.dispose();
    super.dispose();
  }

  void _filterLayanan() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        // PERBAIKAN: Jika query kosong, kosongkan juga hasilnya.
        _hasilPencarian = [];
      } else {
        _hasilPencarian = semuaLayanan.where((layanan) {
          final namaLayanan = layanan.nama.toLowerCase();
          final deskripsiLayanan = layanan.deskripsi.toLowerCase();
          return namaLayanan.contains(query) ||
              deskripsiLayanan.contains(query);
        }).toList();

        // PERBAIKAN: Urutkan hasil untuk memprioritaskan nama yang diawali dengan query
        _hasilPencarian.sort((a, b) {
          final aStartsWith = a.nama.toLowerCase().startsWith(query);
          final bStartsWith = b.nama.toLowerCase().startsWith(query);

          if (aStartsWith && !bStartsWith) {
            return -1; // a comes first
          } else if (!aStartsWith && bStartsWith) {
            return 1; // b comes first
          } else {
            return a.nama.compareTo(
              b.nama,
            ); // Sort alphabetically as a fallback
          }
        });
      }
    });
  }

  /// Helper widget untuk membangun body berdasarkan state pencarian
  Widget _buildBodyContent() {
    final theme = Theme.of(context);
    // Jika pengguna belum mengetik apa-apa
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Text(
          'Mulai ketik untuk mencari layanan',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    // PERBAIKAN: Tampilan 'tidak ditemukan' diubah menjadi lebih informatif
    if (_hasilPencarian.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Maaf, pencarianmu tidak ada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba cek ulang penulisan atau\ngunakan kata kunci lainnya.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }
    // Jika ada hasil
    return ListView.builder(
      itemCount: _hasilPencarian.length,
      itemBuilder: (context, index) {
        final layanan = _hasilPencarian[index];
        return Column(
          children: [
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 229, 236, 251),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(layanan.iconAsset),
              ),
              title: Text(layanan.nama),
              subtitle: Text(
                layanan.deskripsi,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => layanan.tujuanScreen),
                );
              },
            ),
            const Divider(height: 1, indent: 80),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // PERBAIKAN: AppBar diubah total untuk styling search bar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Menghilangkan bayangan default AppBar
        elevation: 0,
        // Menggunakan warna background dari tema
        backgroundColor: theme.appBarTheme.backgroundColor,
        // PERBAIKAN: titleSpacing diatur untuk kontrol posisi yang lebih baik
        titleSpacing: 0,
        // Title diisi dengan container search bar kustom
        title: Container(
          // PERBAIKAN: Margin ditambahkan untuk memberi jarak dari tepi
          margin: const EdgeInsets.only(right: 16.0),
          height: 48,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true, // Langsung fokus ke text field saat halaman dibuka
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
            decoration: InputDecoration(
              // Ikon search di kiri dalam box
              prefixIcon: Icon(Icons.search, color: theme.hintColor),
              // Tombol silang di kanan dalam box (hanya muncul jika ada teks)
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      color: theme.hintColor,
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              hintText: 'Cari layanan...',
              hintStyle: TextStyle(color: theme.hintColor),
              border: InputBorder.none,
              // Padding konten di dalam textfield
              contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
            ),
          ),
        ),
      ),
      body: _buildBodyContent(),
    );
  }
}
