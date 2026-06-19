import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/tiket_wisata_model.dart';
import 'package:reang_app/models/tiket_event_model.dart';
import 'detail_tiket_user_screen.dart'; // Import halaman detail
import 'checkout_detail_screen.dart';

class PesanTiketScreen extends StatefulWidget {
  const PesanTiketScreen({super.key});

  @override
  State<PesanTiketScreen> createState() => _PesanTiketScreenState();
}

class _PesanTiketScreenState extends State<PesanTiketScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  bool _isLoading = true;
  List<TiketWisataModel> _listWisata = [];
  List<TiketEventModel> _listEvent = [];

  // 0 = Semua, 1 = Wisata, 2 = Event
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Wisata', 'Event'];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    showToast(
      message,
      context: context,
      position: StyledToastPosition.bottom,
      backgroundColor: isError ? Colors.red : Colors.green,
      textStyle: const TextStyle(color: Colors.white),
      borderRadius: BorderRadius.circular(10),
    );
  }

  // --- Fungsi Hit API Explore ---
  Future<void> _fetchData({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.explorePlesir(query: query);
      if (mounted) {
        setState(() {
          _listWisata = data['wisata'] ?? [];
          _listEvent = data['event'] ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        _showToast(
          "Error API: ${e.toString().replaceAll('Exception: ', '')}",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _fetchData(query: query);
    });
  }

  List<dynamic> get _filteredItems {
    List<dynamic> combined = [];
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
      combined.addAll(_listWisata);
    }
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
      combined.addAll(_listEvent);
    }
    combined.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return combined;
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    const String domainHost =
        'https://c4eb-2402-8780-103b-abc-d45e-c0c5-b397-1bce.ngrok-free.app';
    return '$domainHost/storage/$path';
  }

  // --- HINT SEARCH DINAMIS ---
  String get _searchHintText {
    if (_selectedFilterIndex == 1)
      return 'Cari destinasi wisata, pantai, museum...';
    if (_selectedFilterIndex == 2)
      return 'Cari konser musik, festival, pameran...';
    return 'Cari pantai, konser, festival...';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER & SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Reservasi Tiket",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Temukan pengalaman wisata dan event terbaik di sekitar Anda.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),

                // Kolom Pencarian
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: _searchHintText,
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _fetchData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(
                        color: Color(0xFF0D6EFD),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // --- FILTER CHIPS ---
          SizedBox(
            height: 38,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilterIndex = index;
                          _searchController.clear();
                        });
                        _fetchData();
                      }
                    },
                    selectedColor: const Color(0xFF0D6EFD),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0D6EFD)
                            : Colors.grey.shade300,
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // --- KONTEN LIST ---
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0D6EFD)),
                  )
                : items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Tiket belum tersedia",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Coba ganti kata kunci atau kategori pencarian",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetchData(query: _searchController.text),
                    color: const Color(0xFF0D6EFD),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildDynamicTicketCard(items[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CARD DINAMIS ---
  Widget _buildDynamicTicketCard(dynamic item) {
    final bool isWisata = item is TiketWisataModel;
    final String title = isWisata ? item.namaWisata : item.namaEvent;
    final String location = isWisata ? item.alamat : item.lokasi;
    final String category = isWisata ? item.kategoriWisata : item.kategoriEvent;
    final String imageUrl = _getImageUrl(item.fotoUtamaUrl);

    // Menentukan teks harga
    String priceText = "";
    String labelPrice = isWisata ? "Tiket Masuk" : "Mulai dari";

    if (isWisata) {
      priceText = "Rp ${item.hargaTiket}";
    } else {
      if (item.varians.isNotEmpty) {
        int minPrice = item.varians
            .map((v) => v.harga)
            .reduce((a, b) => a < b ? a : b);
        priceText = "Rp $minPrice";
      } else {
        priceText = "TBA";
      }
    }

    // --- LOGIKA KEDALUWARSA & STATUS AKTIF ---
    bool isExpired = false;
    bool isActive = item.isActive;

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

    bool isUnavailable = !isActive || isExpired;
    String badgeStatusText = "Aktif";
    Color badgeStatusColor = Colors.green;

    if (!isActive) {
      badgeStatusText = "Tidak Aktif";
      badgeStatusColor = Colors.redAccent;
    } else if (isExpired) {
      badgeStatusText = "Berakhir";
      badgeStatusColor = Colors.grey.shade600;
    }

    return GestureDetector(
      onTap: isUnavailable
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailTiketUserScreen(item: item),
                ),
              );
            },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      isUnavailable ? Colors.grey : Colors.transparent,
                      BlendMode.saturation,
                    ),
                    child: Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: (isWisata ? Colors.teal : Colors.orange.shade700)
                          .withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isWisata ? Icons.landscape : Icons.festival,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isWisata ? "WISATA" : "EVENT",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeStatusColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUnavailable
                              ? Icons.do_not_disturb_alt
                              : Icons.check_circle,
                          color: Colors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badgeStatusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: isUnavailable ? Colors.grey : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.0),
                        child: Text("•", style: TextStyle(color: Colors.grey)),
                      ),
                      Icon(
                        isWisata ? Icons.location_on : Icons.calendar_month,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          !isWisata
                              ? "${item.tanggalEvent} • ${item.jamEvent}"
                              : location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, thickness: 0.5),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labelPrice,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            priceText,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isUnavailable
                                  ? Colors.grey
                                  : const Color(0xFF0D6EFD),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isUnavailable
                              ? Colors.grey.shade300
                              : const Color(0xFF0D6EFD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeStatusText == "Aktif"
                              ? "Lihat Detail"
                              : badgeStatusText,
                          style: TextStyle(
                            color: isUnavailable
                                ? Colors.grey.shade500
                                : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
