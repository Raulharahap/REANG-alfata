import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/detail_transaksi_response.dart';
import 'package:reang_app/models/riwayat_transaksi_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/models/user_model.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/screens/ecomerce/chat_umkm_screen.dart';

class DetailPesananAdminScreen extends StatefulWidget {
  final String noTransaksi;
  final VoidCallback onActionSuccess;

  const DetailPesananAdminScreen({
    super.key,
    required this.noTransaksi,
    required this.onActionSuccess,
  });

  @override
  State<DetailPesananAdminScreen> createState() =>
      _DetailPesananAdminScreenState();
}

class _DetailPesananAdminScreenState extends State<DetailPesananAdminScreen> {
  final ApiService _apiService = ApiService();
  late Future<DetailTransaksiResponse> _detailFuture;
  late String _token;
  late AuthProvider _authProvider;

  final TextEditingController _resiController = TextEditingController();
  final TextEditingController _jasaKirimController = TextEditingController();
  List<String> _listKurir = [];
  bool _isLoadingKurir = true;

  // [BARU] Variabel untuk menyimpan pilihan
  String? _selectedKurir;

  bool _isLoading = false;
  bool _isConfirming = false;
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _token = _authProvider.token ?? '';
    _loadDetails();
    _loadJasaKirim();

    // Listener untuk update UI saat Jasa Kirim diketik (untuk buka/tutup akses Resi)
    _jasaKirimController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _resiController.dispose();
    _jasaKirimController.dispose();
    super.dispose();
  }

  void _loadDetails() {
    _detailFuture = _apiService.fetchDetailTransaksi(
      token: _token,
      noTransaksi: widget.noTransaksi,
    );
  }

  Future<void> _loadJasaKirim() async {
    final listDariApi = await _apiService.fetchJasaPengiriman();

    if (mounted) {
      setState(() {
        _listKurir = listDariApi;

        _isLoadingKurir = false;
      });
    }
  }

  // Mengisi data otomatis (Hanya dipanggil jika Anda ingin pre-fill dari pilihan user)
  // Saat ini dikosongkan agar admin mengisi manual sesuai permintaan
  void _prefillData(RiwayatTransaksiModel transaksi) {
    // Biarkan kosong agar admin input manual
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
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

  // --- FUNGSI HUBUNGI PEMBELI (KHUSUS ADMIN) ---
  Future<void> _goToChatWithPembeli(
    int idUserPembeli,
    String namaPembeli,
  ) async {
    // 1. Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 2. [PENTING] Pastikan Admin sudah login Firebase (Tukar Token)
      // Ini wajib karena admin biasanya login pakai username/password biasa
      await _authProvider.ensureFirebaseLoggedIn();

      if (mounted) {
        Navigator.pop(context); // Tutup Loading

        // 3. MANIPULASI DATA: Bungkus data Pembeli seolah-olah 'Toko'
        // Supaya bisa pakai ChatUMKMScreen yang sudah ada tanpa bikin screen baru.
        final buyerAsTarget = TokoModel(
          id: 0, // ID Toko dummy (tidak dipakai untuk kirim pesan)
          idUser: idUserPembeli, // <--- TARGET: ID USER PEMBELI
          nama: namaPembeli, // <--- NAMA: NAMA PENERIMA
          alamat: '',
          noHp: '',
          foto: null, // Foto null akan tampil inisial
        );

        // 4. Buka Halaman Chat
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatUMKMScreen(toko: buyerAsTarget, isSeller: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup Loading
        _showToast('Gagal membuka chat: $e', isError: true);
      }
    }
  }

  Future<void> _runApiAction(
    Future<dynamic> Function() apiCall,
    String successMessage,
    Function(bool) setLoading,
  ) {
    setLoading(true);
    return apiCall()
        .then((response) {
          _showToast(response['message'] ?? successMessage);
          Navigator.pop(context);
          widget.onActionSuccess();
        })
        .catchError((e) {
          _showToast(e.toString().replaceAll("Exception: ", ""), isError: true);
        })
        .whenComplete(() {
          if (mounted) setLoading(false);
        });
  }

  void _onConfirm() {
    _runApiAction(
      () => _apiService.adminKonfirmasiPembayaran(
        token: _token,
        noTransaksi: widget.noTransaksi,
      ),
      'Pembayaran dikonfirmasi!',
      (isLoading) => setState(() => _isConfirming = isLoading),
    );
  }

  void _onReject() {
    _runApiAction(
      () => _apiService.adminTolakPembayaran(
        token: _token,
        noTransaksi: widget.noTransaksi,
      ),
      'Pembayaran ditolak.',
      (isLoading) => setState(() => _isRejecting = isLoading),
    );
  }

  void _onKirim() {
    String resi = _resiController.text.trim();
    String jasaKirim = _jasaKirimController.text.trim();

    // [LOGIKA BARU]
    // Jika kosong, isi dengan "-" agar backend menerima
    if (jasaKirim.isEmpty) jasaKirim = "-";
    if (resi.isEmpty) resi = "-";

    _runApiAction(
      () => _apiService.adminKirimPesanan(
        token: _token,
        noTransaksi: widget.noTransaksi,
        nomorResi: resi,
        jasaPengiriman: jasaKirim,
      ),
      'Pesanan ditandai terkirim!',
      (isLoading) => setState(() => _isLoading = isLoading),
    );
  }

  void _onBatalkan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Stok tidak otomatis kembali (manual).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog
              _runApiAction(
                () => _apiService.adminBatalkanPesanan(
                  token: _token,
                  noTransaksi: widget.noTransaksi,
                ),
                'Pesanan berhasil dibatalkan.',
                (isLoading) => setState(() => _isLoading = isLoading),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _onSelesai() {
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
              // Gunakan 'onSurface' agar otomatis Hitam/Putih sesuai tema
              foregroundColor: Theme.of(context).colorScheme.onSurface,

              // Garis pinggir juga menyesuaikan tema (tidak terlalu pudar)
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

                // Panggil API
                final response = await api.adminTandaiSelesai(
                  token: token,
                  noTransaksi: widget.noTransaksi, // <-- Pakai widget.
                );

                if (!context.mounted) return;

                _showToast(response['message'] ?? 'Pesanan selesai!');
                widget.onActionSuccess(); // <-- Pakai widget.
              } catch (e) {
                if (!context.mounted) return;
                _showToast(
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

  void _openImagePreview(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _ImagePreviewScreen(imageUrl: imageUrl),
      ),
    );
  }

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DetailTransaksiResponse>(
      future: _detailFuture,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        Widget body;
        RiwayatTransaksiModel? transaksi;

        if (snapshot.connectionState == ConnectionState.waiting) {
          body = const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          body = Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          transaksi = snapshot.data!.transaksi;
          final items = snapshot.data!.items;
          final String? buktiBayarUrl = transaksi.buktiPembayaran;

          _prefillData(transaksi);

          body = SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusCard(theme, transaksi, _authProvider.user),
                const SizedBox(height: 16),

                if (transaksi.status == 'menunggu_konfirmasi') ...[
                  _buildPaymentProofCard(theme, buktiBayarUrl, transaksi),
                  const SizedBox(height: 16),
                ],

                // Card Input Resi (Tampil saat 'diproses')
                if (transaksi.status == 'diproses') ...[
                  _buildInputResiCard(theme),
                  const SizedBox(height: 16),
                ],

                _buildProductListCard(theme, items),
                const SizedBox(height: 16),
                _buildCostCard(theme, transaksi),
                const SizedBox(height: 16),
                _buildBantuanCard(theme, transaksi),
              ],
            ),
          );
        } else {
          body = const Center(child: Text('Data tidak ditemukan.'));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Pesanan'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(4.0),
              child: (_isLoading || _isConfirming || _isRejecting)
                  ? const LinearProgressIndicator()
                  : Container(),
            ),
          ),
          body: body,
          bottomNavigationBar: transaksi != null
              ? _buildDynamicActionButtons(context, theme, transaksi)
              : null,
        );
      },
    );
  }

  // --- WIDGET BUILDER ---

  // Card Bantuan (Versi Admin)
  Widget _buildBantuanCard(ThemeData theme, RiwayatTransaksiModel transaksi) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Butuh Bantuan?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 1),

            // MENU: Hubungi Pembeli
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('Hubungi Pembeli'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                // Ambil nama penerima atau fallback ke 'Pembeli'
                final namaTarget = transaksi.namaPenerima ?? 'Pembeli';
                _goToChatWithPembeli(transaksi.idUser, namaTarget);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputResiCard(ThemeData theme) {
    bool isJasaKirimFilled = _jasaKirimController.text.trim().isNotEmpty;

    // 1. Definisikan teks opsi batal di sini biar konsisten
    const String opsiBatal = "- Batalkan Pilihan -";

    // 2. Gabungkan opsi batal ke dalam list
    // Opsi ini akan SELALU ADA di dalam list dropdown
    final List<String> itemsTampil = [opsiBatal, ..._listKurir];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Text(
                  'Informasi Pengiriman',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              // Value ini yang menentukan apa yang tampil di kotak
              // Jika null -> Tampil Hint
              // Jika ada isi -> Tampil Teks
              value: _selectedKurir,

              hint: Text(
                _isLoadingKurir ? 'Memuat data...' : 'Pilih Jasa Pengiriman',
              ),

              // [BAGIAN KRUSIAL] Logika reset ada di sini
              onChanged: _isLoadingKurir
                  ? null
                  : (newValue) {
                      setState(() {
                        // Cek apakah yang dipilih adalah opsi batal?
                        if (newValue == opsiBatal) {
                          // JANGAN simpan teksnya. PAKSA jadi NULL.
                          // Dengan jadi null, Dropdown akan otomatis menampilkan Hint Text lagi.
                          _selectedKurir = null;
                          _jasaKirimController.clear();
                        } else {
                          // Kalau bukan batal, baru simpan nilainya
                          _selectedKurir = newValue;
                          _jasaKirimController.text = newValue ?? "";
                        }
                      });
                    },

              decoration: InputDecoration(
                labelText: 'Jasa Pengiriman (Opsional)',
                labelStyle: TextStyle(color: Colors.blue.shade800),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.directions_car,
                  color: Colors.blue.shade300,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),

              // Tampilan item saat dropdown dibuka
              items: itemsTampil.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      // Merah jika itu tombol batal
                      color: value == opsiBatal ? Colors.red : Colors.black,
                      // Tebal jika itu tombol batal
                      fontWeight: value == opsiBatal
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // TextField Resi (Logika Enable/Disable)
            TextField(
              controller: _resiController,
              enabled: isJasaKirimFilled,
              decoration: InputDecoration(
                labelText: 'Nomor Resi (Opsional)',
                labelStyle: TextStyle(
                  color: isJasaKirimFilled ? Colors.blue.shade800 : Colors.grey,
                ),
                hintText: isJasaKirimFilled
                    ? 'Masukkan nomor resi...'
                    : 'Isi Jasa Pengiriman dulu untuk input resi',
                filled: true,
                fillColor: isJasaKirimFilled
                    ? Colors.white
                    : Colors.grey.shade300,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  Icons.receipt,
                  color: isJasaKirimFilled ? Colors.blue.shade300 : Colors.grey,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              isJasaKirimFilled
                  ? '*Kosongkan resi jika tidak ada (misal: kurir internal).'
                  : '*Anda bisa langsung tekan "Kirim" jika tanpa jasa pengiriman.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    ThemeData theme,
    RiwayatTransaksiModel transaksi,
    UserModel? user,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Pesanan', style: theme.textTheme.titleSmall),
            Text(
              transaksi.getUiStatus,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (transaksi.status == 'dikirim' ||
                transaksi.status == 'selesai') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      theme: theme,
                      label: "Jasa Kirim",
                      value: transaksi.jasaPengiriman,
                      valueWeight: FontWeight.bold,
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      theme: theme,
                      label: "Resi",
                      value: transaksi.nomorResi ?? "-",
                      valueWeight: FontWeight.bold,
                    ),
                  ],
                ),
              ),
            ],
            const Divider(height: 24),
            Text('Info Pelanggan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _InfoRow(theme: theme, label: 'Nama', value: user?.name ?? '...'),
            _InfoRow(
              theme: theme,
              label: 'No. HP',
              value: user?.phone ?? '...',
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: transaksi.alamat));
                _showToast('Alamat pengiriman disalin');
              },
              borderRadius: BorderRadius.circular(4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alamat Pengiriman:',
                            style: theme.textTheme.bodySmall,
                          ),
                          Text(
                            transaksi.alamat,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.copy_outlined, size: 18, color: theme.hintColor),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5),
            const SizedBox(height: 16),

            // [TAMBAHAN BARU: METODE PEMBAYARAN]
            _InfoRow(
              theme: theme,
              label: 'Metode Pembayaran',
              value: transaksi.metodePembayaran ?? 'Tidak Diketahui',
              valueWeight: FontWeight.bold, // Teks tebal agar jelas
              valueColor:
                  theme.colorScheme.primary, // Warna primary agar menonjol
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentProofCard(
    ThemeData theme,
    String? buktiBayarUrl,
    RiwayatTransaksiModel transaksi,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bukti Pembayaran Pelanggan",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                if (buktiBayarUrl != null &&
                    buktiBayarUrl.isNotEmpty &&
                    buktiBayarUrl != 'ditolak') {
                  _openImagePreview(context, buktiBayarUrl);
                } else {
                  _showToast(
                    'Tidak ada bukti pembayaran untuk dilihat.',
                    isError: true,
                  );
                }
              },
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child:
                    (buktiBayarUrl == null ||
                        buktiBayarUrl.isEmpty ||
                        buktiBayarUrl == 'ditolak')
                    ? Center(
                        child: Text(
                          'Bukti bayar tidak ditemukan.',
                          style: TextStyle(color: theme.hintColor),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              buktiBayarUrl,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Text(
                                      'Gagal memuat gambar',
                                      style: TextStyle(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                            ),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              theme: theme,
              label: "Total Tagihan",
              value: _formatCurrency(transaksi.total),
              isTotal: true,
            ),
            const Divider(height: 20),
            _InfoRow(
              theme: theme,
              label: "Metode Tujuan",
              value: transaksi.metodePembayaran ?? '-',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              label: "A.n. Penerima",
              value: transaksi.namaPenerima ?? '-',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              label: "No. Rek/Tujuan",
              value: transaksi.nomorTujuan ?? '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductListCard(ThemeData theme, List<ItemDetailModel> items) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Produk (${items.length} item)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            Column(
              children: items.map((item) {
                return _ProductDetailRow(
                  theme: theme,
                  item: item,
                  showDivider: item != items.last,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostCard(ThemeData theme, RiwayatTransaksiModel transaksi) {
    double biayaLayanan =
        transaksi.total - transaksi.subtotal - transaksi.ongkir;
    if (biayaLayanan < 0) biayaLayanan = 0;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rincian Biaya',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _InfoRow(
              theme: theme,
              label: 'Subtotal Produk',
              value: _formatCurrency(transaksi.subtotal),
            ),
            const SizedBox(height: 8),
            _InfoRow(
              theme: theme,
              label: 'Ongkos Kirim',
              value: _formatCurrency(transaksi.ongkir),
            ),
            if (biayaLayanan > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: _InfoRow(
                  theme: theme,
                  label: 'Biaya Layanan',
                  value: _formatCurrency(biayaLayanan),
                ),
              ),
            const Divider(height: 24, thickness: 1),
            _InfoRow(
              theme: theme,
              label: 'Total Pembayaran',
              value: _formatCurrency(transaksi.total),
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildDynamicActionButtons(
    BuildContext context,
    ThemeData theme,
    RiwayatTransaksiModel transaksi,
  ) {
    bool isActionLoading = _isLoading || _isConfirming || _isRejecting;
    Widget content;

    switch (transaksi.status) {
      case 'menunggu_konfirmasi':
        content = Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isActionLoading ? null : _onReject,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRejecting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.error,
                        ),
                      )
                    : const Text(
                        "Tolak",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isActionLoading ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isConfirming
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Konfirmasi Pembayaran",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        );
        break;

      case 'diproses':
        content = Row(
          children: [
            // 1. Tombol Batalkan (Merah)
            Expanded(
              child: OutlinedButton(
                onPressed: isActionLoading ? null : _onBatalkan,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Batalkan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Tombol Input Resi (Biru)
            Expanded(
              flex: 2, // Lebih lebar
              child: ElevatedButton.icon(
                onPressed: isActionLoading ? null : _onKirim,
                icon: const Icon(Icons.local_shipping),
                label: const Text(
                  "Kirim Pesanan",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        );
        break;

      case 'dikirim':
        content = ElevatedButton(
          onPressed: isActionLoading ? null : _onSelesai,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.green.shade800,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            "Tandai Pesanan Selesai",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        );
        break;

      default:
        return null;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: content,
    );
  }
}

class _ProductDetailRow extends StatelessWidget {
  const _ProductDetailRow({
    required this.theme,
    required this.item,
    required this.showDivider,
  });

  final ThemeData theme;
  final ItemDetailModel item;
  final bool showDivider;

  String _formatCurrency(double value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.foto ?? "",
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 64,
                    height: 64,
                    color: theme.colorScheme.surfaceContainer,
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      color: theme.hintColor.withOpacity(0.7),
                      size: 30,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.namaProduk,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.jumlah} item x ${_formatCurrency(item.harga)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _formatCurrency(item.subtotal),
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        if (showDivider) const Divider(height: 24),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.theme,
    required this.label,
    required this.value,
    this.isTotal = false,
    this.valueWeight,
    this.valueColor, // [1. TAMBAHKAN INI DI CONSTRUCTOR]
  });

  final ThemeData theme;
  final String label;
  final String value;
  final bool isTotal;
  final FontWeight? valueWeight;
  final Color? valueColor; // [2. TAMBAHKAN VARIABEL INI]

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isTotal
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  )
                : theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: valueWeight ?? FontWeight.w600,
                    color: valueColor, // [3. GUNAKAN DI SINI]
                  ),
          ),
        ),
      ],
    );
  }
}

class _ImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  const _ImagePreviewScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  return progress == null
                      ? child
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                },
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: Material(
                color: Colors.black.withOpacity(0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
