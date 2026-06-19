import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/mitra_plesir_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/plesir/admin/edit_profile_mitra_screen.dart'; // Import halaman edit

class ProviderProfileScreen extends StatefulWidget {
  const ProviderProfileScreen({super.key});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final ApiService _apiService = ApiService();

  MitraPlesirModel? _mitraData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // --- FUNGSI MENGAMBIL DATA PROFIL DARI API ---
  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final data = await _apiService.fetchProfilMitraPlesir(token);
        setState(() {
          _mitraData = data;
        });
      }
    } catch (e) {
      debugPrint("Gagal memuat profil: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D6EFD)),
        ),
      );
    }

    final namaWisata = _mitraData?.nama ?? 'Nama Wisata';
    final alamatWisata = _mitraData?.alamat ?? 'Alamat belum diatur';
    final deskripsiWisata = _mitraData?.deskripsi ?? 'Belum ada deskripsi.';
    final kontakWisata = _mitraData?.kontak ?? 'Belum ada kontak';

    // Cek apakah punya foto
    final hasFoto = _mitraData?.foto != null && _mitraData!.foto!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: AVATAR DAN VERIFIED BADGE ---
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.grey[200],
                        // Jika ada foto pakai NetworkImage, jika tidak biarkan null agar transparan
                        backgroundImage: hasFoto
                            ? NetworkImage(
                                _mitraData!.foto ?? '',
                                headers: const {
                                  'ngrok-skip-browser-warning': 'true',
                                },
                              )
                            : null,
                        // Menampilkan icon kosongan jika foto tidak ada
                        child: !hasFoto
                            ? const Icon(
                                Icons.landscape,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D6EFD),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // --- SECTION 2: NAMA & LOKASI UTAMA ---
              Center(
                child: Column(
                  children: [
                    Text(
                      namaWisata,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            alamatWisata,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTION 3: TOMBOL EDIT PROFIL ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_mitraData == null) return;

                    // Navigasi ke halaman Edit Profil
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditProfileMitraScreen(mitraData: _mitraData!),
                      ),
                    );

                    // Jika result == true (berhasil simpan), reload data profil
                    if (result == true) {
                      _loadProfileData();
                    }
                  },
                  icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                  label: const Text(
                    'Edit Profil',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D9BF0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- SECTION 4: TIGA KOTAK STATISTIK ---
              Row(
                children: [
                  _buildStatCard('24', 'Total Event', isRating: false),
                  const SizedBox(width: 12),
                  _buildStatCard('4.8', 'Rating', isRating: true),
                  const SizedBox(width: 12),
                  _buildStatCard('182', 'Ulasan', isRating: false),
                ],
              ),
              const SizedBox(height: 32),

              // --- SECTION 5: INFORMASI BISNIS ---
              const Text(
                'Informasi Bisnis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // --- SECTION 6: KARTU LIST DETAIL BISNIS ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildBusinessItem(
                      icon: Icons.business,
                      label: 'NAMA PENYEDIA',
                      content: namaWisata,
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildBusinessItem(
                      icon: Icons.category_outlined,
                      label: 'KATEGORI',
                      content: '',
                      customContent: Row(
                        children: [
                          _buildChip('Wisata'),
                          const SizedBox(width: 8),
                          _buildChip('Event Organizer'),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildBusinessItem(
                      icon: Icons.phone_outlined,
                      label: 'KONTAK / WHATSAPP',
                      content: kontakWisata,
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildBusinessItem(
                      icon: Icons.map_outlined,
                      label: 'LOKASI',
                      content: alamatWisata,
                    ),
                    const Divider(height: 1, indent: 70),
                    _buildBusinessItem(
                      icon: Icons.description_outlined,
                      label: 'DESKRIPSI',
                      content: deskripsiWisata,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // --- SECTION 7: BADGE VERIFIKASI REANG ---
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 16,
                        color: Colors.blueGrey,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Penyedia Terverifikasi REANG',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {required bool isRating}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D6EFD),
                  ),
                ),
                if (isRating) ...[
                  const SizedBox(width: 2),
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessItem({
    required IconData icon,
    required String label,
    required String content,
    Widget? customContent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0D6EFD), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                customContent ??
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A73E8),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
