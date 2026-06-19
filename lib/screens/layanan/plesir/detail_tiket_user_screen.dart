import 'package:flutter/material.dart';
import 'package:reang_app/models/tiket_wisata_model.dart';
import 'package:reang_app/models/tiket_event_model.dart';
import 'checkout_detail_screen.dart';

class DetailTiketUserScreen extends StatefulWidget {
  final dynamic item; // Bisa berupa TiketWisataModel atau TiketEventModel

  const DetailTiketUserScreen({super.key, required this.item});

  @override
  State<DetailTiketUserScreen> createState() => _DetailTiketUserScreenState();
}

class _DetailTiketUserScreenState extends State<DetailTiketUserScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  List<String> _allImages = [];

  @override
  void initState() {
    super.initState();
    _setupImageList();
  }

  // Gabungkan foto utama dan galeri ke dalam satu list string url
  void _setupImageList() {
    final item = widget.item;
    if (item.fotoUtamaUrl != null && item.fotoUtamaUrl.isNotEmpty) {
      _allImages.add(item.fotoUtamaUrl);
    }

    // Gabungkan list galeri foto jika ada
    if (item.galeri != null && item.galeri.isNotEmpty) {
      for (var img in item.galeri) {
        _allImages.add(img.fotoUrl);
      }
    }

    // Fallback jika tidak ada foto sama sekali
    if (_allImages.isEmpty) {
      _allImages.add('');
    }
  }

  String _getImageUrl(String path) {
    if (path.isEmpty) return '';
    const String domainHost =
        'https://c4eb-2402-8780-103b-abc-d45e-c0c5-b397-1bce.ngrok-free.app';
    return '$domainHost/storage/$path';
  }

  // ===========================================================================
  // BOTTOM SHEET: POP-UP PEMILIHAN VARIAN TIKET KHUSUS EVENT (GAYA SHOPEE)
  // ===========================================================================
  void _showVariantSelectionBottomSheet(
    BuildContext context,
    String title,
    String location,
    String imageUrl,
  ) {
    final item = widget.item;

    // Variabel untuk menyimpan varian yang sedang dipilih di dalam pop-up
    VarianTiketEventModel? selectedVariant;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Dibuat transparan agar border radius putih terlihat
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Garis abu-abu di atas (Pull indicator)
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header Pop-up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Pilih Kelas Tiket",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 10),
                  const SizedBox(height: 10),

                  // List Varian Tiket
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: item.varians.length,
                    itemBuilder: (context, index) {
                      final v = item.varians[index];
                      final bool isSelected = selectedVariant == v;

                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedVariant = v;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF0D6EFD).withOpacity(0.05)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0D6EFD)
                                  : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.namaKelas,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isSelected
                                          ? const Color(0xFF0D6EFD)
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sisa Kuota: ${v.kuota} Kursi',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Rp ${v.harga}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected
                                      ? const Color(0xFF0D6EFD)
                                      : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tombol Lanjutkan Pembayaran
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: selectedVariant == null
                          ? null // Disable tombol kalau belum pilih
                          : () {
                              Navigator.pop(context); // Tutup pop-up
                              // Lanjut ke Checkout dengan membawa varian yang dipilih
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutDetailScreen(
                                    title:
                                        "$title - ${selectedVariant!.namaKelas}", // Tambah info varian
                                    location: location,
                                    price:
                                        "Rp ${selectedVariant!.harga}", // Harga sesuai varian
                                    imageUrl: imageUrl,
                                  ),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedVariant == null
                            ? Colors.grey.shade300
                            : const Color(0xFF0D6EFD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: selectedVariant == null ? 0 : 2,
                      ),
                      child: Text(
                        selectedVariant == null
                            ? "Pilih Tiket Dulu"
                            : "Lanjutkan Pembayaran",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: selectedVariant == null
                              ? Colors.grey.shade600
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final bool isWisata = item is TiketWisataModel;

    final String title = isWisata ? item.namaWisata : item.namaEvent;
    final String location = isWisata ? item.alamat : item.lokasi;
    final String category = isWisata ? item.kategoriWisata : item.kategoriEvent;
    final String description = item.deskripsi;

    // Menghitung info harga final untuk display awal
    String finalPrice = "";
    if (isWisata) {
      finalPrice = "Rp ${item.hargaTiket}";
    } else {
      if (item.varians.isNotEmpty) {
        int minPrice = item.varians
            .map((v) => v.harga)
            .reduce((a, b) => a < b ? a : b);
        finalPrice = "Rp $minPrice";
      } else {
        finalPrice = "TBA";
      }
    }

    // Cek kedaluwarsa & keaktifan
    bool isExpired = false;
    if (!isWisata) {
      try {
        DateTime eventDate = DateTime.parse(item.tanggalEvent);
        if (eventDate.add(const Duration(days: 1)).isBefore(DateTime.now())) {
          isExpired = true;
        }
      } catch (e) {
        // Abaikan
      }
    }
    bool isUnavailable = !item.isActive || isExpired;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. BACKGROUND GAMBAR SLIDER (Di Posisi Paling Belakang)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320, // Tinggi gambar diperbesar sedikit
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentImageIndex = index);
                  },
                  itemCount: _allImages.length,
                  itemBuilder: (context, index) {
                    return Image.network(
                      _allImages[index], // Panggil langsung tanpa fungsi tambahan!
                      fit: BoxFit.cover,
                      headers: const {
                        'ngrok-skip-browser-warning': 'true',
                      }, // Wajib ada untuk ngrok
                      errorBuilder: (c, e, s) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.broken_image,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
                // Efek Gradient Hitam di Atas agar Tombol Back Selalu Terlihat
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                        Colors.black.withOpacity(
                          0.2,
                        ), // Sedikit gelap di bawah untuk dot indicator
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- KONTEN SCROLL DETAIL UTAMA ---
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Ruang kosong agar gambar background terlihat
                SizedBox(height: 250),

                // KONTEN OVERLAPPING CARD (Putih melengkung ke atas)
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dot Indicator Penunjuk Gambar Geser (Hanya muncul jika foto > 1)
                        if (_allImages.length > 1)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_allImages.length, (
                                  index,
                                ) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    width: _currentImageIndex == index ? 24 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentImageIndex == index
                                          ? const Color(0xFF0D6EFD)
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ),

                        // Badge Jenis Layanan
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isWisata
                                ? Colors.teal.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isWisata
                                ? "Pariwisata • $category"
                                : "Event Acara • $category",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isWisata
                                  ? Colors.teal.shade700
                                  : Colors.orange.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama Utama Tiket
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lokasi / Alamat Lengkap
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Jika Event, Munculkan Baris Detail Tanggal & Jam
                        if (!isWisata) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.calendar_month,
                                  color: Color(0xFF0D6EFD),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  "${item.tanggalEvent}  •  ${item.jamEvent}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],

                        const Divider(
                          height: 40,
                          thickness: 1,
                          color: Colors.black12,
                        ),

                        // Logistik Info Khusus Wisata
                        if (isWisata) ...[
                          _buildInfoRow(
                            Icons.access_time,
                            "Jam Operasional",
                            item.jamOperasional,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.people_outline,
                            "Kuota Maksimal",
                            "${item.kuotaPerHari} Pengunjung / Hari",
                          ),
                          const Divider(
                            height: 40,
                            thickness: 1,
                            color: Colors.black12,
                          ),
                        ],

                        // Deskripsi Singkat/Lengkap
                        const Text(
                          'Tentang Tempat Ini',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            height: 1.7, // Line height agar lebih enak dibaca
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 28),

                        // Menampilkan Fasilitas Khusus Wisata
                        if (isWisata && item.fasilitas.isNotEmpty) ...[
                          const Text(
                            'Fasilitas Tersedia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: item.fasilitas
                                .map<Widget>(
                                  (f) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      f.toString(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Spacing ganjal ekstra di bawah
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. STICKY BACK BUTTON (Pojok Kiri Atas)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(
                0.2,
              ), // Lebih nge-blend dengan background
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                ), // Ikon putih karena backgroud ada overlay hitam
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 4. STICKY BOTTOM ACTIONS BAR (UNTUK BELI TIKET)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWisata ? "Harga Tiket Masuk" : "Harga Mulai Dari",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          finalPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20, // Diperbesar
                            color: isUnavailable
                                ? Colors.grey
                                : const Color(0xFF0D6EFD),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 150,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isUnavailable
                            ? null
                            : () {
                                if (isWisata) {
                                  // JIKA WISATA, LANGSUNG KE CHECKOUT KARENA TIDAK ADA VARIAN
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CheckoutDetailScreen(
                                            title: title,
                                            location: location,
                                            price: finalPrice,
                                            imageUrl: _allImages.isNotEmpty
                                                ? _allImages.first
                                                : '',
                                          ),
                                    ),
                                  );
                                } else {
                                  // JIKA EVENT, MUNCULKAN POP-UP PEMILIHAN VARIAN TIKET!
                                  _showVariantSelectionBottomSheet(
                                    context,
                                    title,
                                    location,
                                    _allImages.isNotEmpty
                                        ? _allImages.first
                                        : '',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isUnavailable
                              ? Colors.grey.shade300
                              : const Color(0xFF0D6EFD),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              14,
                            ), // Sedikit lebih bulat
                          ),
                        ),
                        child: Text(
                          isUnavailable ? "Tidak Tersedia" : "Beli Tiket",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF0D6EFD), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
