import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/tiket_wisata_model.dart';
import 'package:reang_app/models/tiket_event_model.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';

// Import Form
import 'form_input_event.dart';
import 'form_input_wisata.dart';
// Import Detail (Akan kita buat setelah ini)
import 'detail_wisata_mitra_screen.dart';
import 'detail_event_mitra_screen.dart';

class ManageEventScreen extends StatefulWidget {
  const ManageEventScreen({super.key});

  @override
  State<ManageEventScreen> createState() => _ManageEventScreenState();
}

class _ManageEventScreenState extends State<ManageEventScreen> {
  final ApiService _apiService = ApiService();
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

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    try {
      if (auth.token != null) {
        final data = await _apiService.getTiketMitra(auth.token!);
        setState(() {
          _listWisata = data['wisata'] ?? [];
          _listEvent = data['event'] ?? [];
        });
      }
    } catch (e) {
      showToast(
        "Gagal memuat data: $e",
        context: context,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Menggabungkan dan memfilter list
  List<dynamic> get _filteredItems {
    List<dynamic> combined = [];
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) {
      combined.addAll(_listWisata);
    }
    if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) {
      combined.addAll(_listEvent);
    }

    // Sortir berdasarkan ID terbaru (asumsi ID lebih besar = lebih baru)
    combined.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
    return combined;
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    const String domainHost =
        'https://c4eb-2402-8780-103b-abc-d45e-c0c5-b397-1bce.ngrok-free.app';
    return '$domainHost/storage/$path';
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: items.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showSelectionBottomSheet(context),
              backgroundColor: const Color(0xFF005691),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Tambah Tiket",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          Padding(
            padding: const EdgeInsets.only(
              left: 20.0,
              right: 20.0,
              top: 24.0,
              bottom: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Kelola Tiket',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Kelola semua event atau destinasi pariwisata Anda di sini',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),

          // --- FILTER CHIPS ---
          SizedBox(
            height: 40,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected)
                        setState(() => _selectedFilterIndex = index);
                    },
                    selectedColor: const Color(0xFF005691),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF005691)
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

          // --- KONTEN LIST / EMPTY STATE ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                ? _buildEmptyStateContent(context)
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    color: const Color(0xFF005691),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _buildItemCard(item);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Desain Card List yang Elegan
  // Desain Card List yang Elegan (Vertical Full Width)
  Widget _buildItemCard(dynamic item) {
    final bool isWisata = item is TiketWisataModel;

    final String title = isWisata ? item.namaWisata : item.namaEvent;
    final String location = isWisata ? item.alamat : item.lokasi;
    final String category = isWisata ? item.kategoriWisata : item.kategoriEvent;
    final String imageUrl = _getImageUrl(item.fotoUtamaUrl);
    final String status = item.isActive ? "Aktif" : "Non-Aktif";

    // Ambil info spesifik (Harga untuk Wisata, Tanggal untuk Event)
    final String extraInfo = isWisata
        ? "Rp ${item.hargaTiket}"
        : "${item.tanggalEvent} • ${item.jamEvent}";

    final IconData extraIcon = isWisata
        ? Icons.confirmation_number_outlined
        : Icons.calendar_month_outlined;

    return GestureDetector(
      onTap: () async {
        // Navigasi ke halaman detail dan tunggu jika ada update (refresh)
        final bool? needRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => isWisata
                ? DetailWisataMitraScreen(wisata: item)
                : DetailEventMitraScreen(event: item),
          ),
        );
        if (needRefresh == true) _fetchData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER FOTO FULL WIDTH ---
            Stack(
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 40,
                      ),
                    ),
                  ),
                ),

                // Badge Kategori Kiri Atas
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isWisata
                          ? Colors.teal.shade700
                          : Colors.orange.shade800,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      isWisata ? "WISATA" : "EVENT",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                // Badge Status Kanan Atas
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: item.isActive
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- KONTEN BAWAH (INFO TIKET) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Detail Baris 1: Kategori & Harga/Tanggal
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "•",
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),

                      Icon(extraIcon, size: 16, color: const Color(0xFF0D6EFD)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          extraInfo,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0D6EFD),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Detail Baris 2: Lokasi
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
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
          ],
        ),
      ),
    );
  }

  // --- KODE EMPTY STATE DAN BOTTOM SHEET TETAP SAMA ---
  Widget _buildEmptyStateContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Belum Ada Tiket Terdaftar',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Tiket pariwisata atau event yang telah Anda publikasikan akan muncul di halaman ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () => _showSelectionBottomSheet(context),
                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                label: const Text(
                  'Tambah Tiket',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005691),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Tips Event
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: Color(0xFF1A73E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Tips Event',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Event yang memiliki deskripsi lengkap dan foto berkualitas tinggi memiliki peluang 80% lebih besar untuk dikunjungi wisatawan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text(
                'Pilih Kategori Tiket',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tentukan jenis tiket pariwisata atau event yang ingin Anda buat',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.landscape, color: Color(0xFF0369A1)),
                ),
                title: const Text(
                  'Kategori Pariwisata / Wisata',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Pantai, kolam renang, situs sejarah, museum, dll.',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final refresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormInputWisata(),
                    ),
                  );
                  if (refresh == true) _fetchData();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.festival, color: Color(0xFFB91C1C)),
                ),
                title: const Text(
                  'Kategori Event / Acara',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Konser, festival budaya, seminar, pameran, dll.',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final refresh = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FormInputEvent(),
                    ),
                  );
                  if (refresh == true) _fetchData();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
