import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'instruksi_checkout_screen.dart';

class CheckoutDetailScreen extends StatefulWidget {
  final int targetId; // ID Wisata atau ID Event dari database
  final String kategoriTiket; // 'wisata' atau 'event'
  final int? varianId; // Opsional: ID Varian kelas tiket jika kategori 'event'
  final String title;
  final String location;
  final String price;
  final String imageUrl;

  const CheckoutDetailScreen({
    super.key,
    required this.targetId,
    required this.kategoriTiket,
    this.varianId,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
  });

  @override
  State<CheckoutDetailScreen> createState() => _CheckoutDetailScreenState();
}

class _CheckoutDetailScreenState extends State<CheckoutDetailScreen> {
  final ApiService _apiService = ApiService();
  String _selectedPaymentMethod = 'OVO';

  // --- STATE DINAMIS ---
  int _ticketCount = 1;
  DateTime? _visitDate;
  bool _isProcessing = false; // State loading saat klik beli

  // Fungsi untuk ekstrak angka dari string harga (misal "Rp 50.000" jadi 50000)
  int get _basePrice {
    final cleanString = widget.price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleanString) ?? 0;
  }

  // Fungsi untuk format angka ke Rupiah yang rapi
  String _formatRupiah(int number) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatCurrency.format(number);
  }

  // Pemilih Kalender
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visitDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF0D6EFD)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _visitDate) {
      setState(() {
        _visitDate = picked;
      });
    }
  }

  // Helper untuk format tanggal (Contoh: 2026-06-20)
  String _getFormattedDate() {
    if (_visitDate == null) return "Pilih Tanggal";
    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return "${_visitDate!.day} ${months[_visitDate!.month - 1]} ${_visitDate!.year}";
  }

  // --- FUNGSI EKSEKUSI CHECKOUT KE API ---
  Future<void> _handleCheckout(int totalPrice) async {
    if (widget.kategoriTiket == 'wisata' && _visitDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tanggal kunjungan terlebih dahulu!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    if (auth.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi Anda berakhir, silakan login ulang.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Ambil format tanggal YYYY-MM-DD untuk backend
      String? tanggalKunjunganFormatted = _visitDate != null
          ? "${_visitDate!.year}-${_visitDate!.month.toString().padLeft(2, '0')}-${_visitDate!.day.toString().padLeft(2, '0')}"
          : null;

      final result = await _apiService.checkoutTiketPlesir(
        token: auth.token!,
        kategoriTiket: widget.kategoriTiket,
        jumlahTiket: _ticketCount,
        totalHarga: totalPrice,
        wisataId: widget.kategoriTiket == 'wisata' ? widget.targetId : null,
        eventId: widget.kategoriTiket == 'event' ? widget.targetId : null,
        varianId: widget.varianId,
        tanggalKunjungan: tanggalKunjunganFormatted,
      );

      if (mounted) {
        // Ambil ID Transaksi yang dihasilkan oleh Laravel
        final int transaksiId = result['data']['id'];

        // Navigasi ke halaman Instruksi dengan membawa ID Transaksi untuk upload bukti transfer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => InstruksiCheckoutScreen(
              transaksiId: transaksiId,
              totalHarga: totalPrice,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrice = _basePrice * _ticketCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Checkout Tiket',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pesanan Anda',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pastikan jumlah tiket dan jadwal kunjungan sudah benar.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ================= CARD 1: DETAIL TIKET & DESTINASI =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            widget.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff0f172a),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.redAccent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    widget.location,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
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
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xffedf2f7), thickness: 1),
                  const SizedBox(height: 16),

                  // --- Tanggal Kunjungan (Hanya Muncul jika kategori Wisata) ---
                  if (widget.kategoriTiket == 'wisata') ...[
                    const Text(
                      'JADWAL KUNJUNGAN',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectDate(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: Color(0xFF0D6EFD),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getFormattedDate(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0D6EFD),
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.edit,
                              size: 16,
                              color: Color(0xFF0D6EFD),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- Jumlah Tiket (+/-) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'JUMLAH TIKET',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRupiah(_basePrice),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              color: _ticketCount > 1
                                  ? Colors.black87
                                  : Colors.grey,
                              onPressed: () {
                                if (_ticketCount > 1)
                                  setState(() => _ticketCount--);
                              },
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              '$_ticketCount',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              color: const Color(0xFF0D6EFD),
                              onPressed: () => setState(() => _ticketCount++),
                              constraints: const BoxConstraints(
                                minWidth: 36,
                                minHeight: 36,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================= CARD 2: RINCIAN HARGA =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RINCIAN HARGA',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow(
                    'Harga Tiket ($_ticketCount x)',
                    _formatRupiah(totalPrice),
                  ),
                  const SizedBox(height: 10),
                  _buildPriceRow('Biaya Layanan', 'Rp 0'),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xffedf2f7), thickness: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      Text(
                        _formatRupiah(totalPrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D6EFD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ================= SECTION METODE PEMBAYARAN =================
            const Text(
              'PILIH METODE PEMBAYARAN',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Transfer Manual',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodItem(
              'OVO',
              Icons.account_balance_wallet_outlined,
              Colors.purple,
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodItem(
              'GoPay',
              Icons.add_moderator_outlined,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodItem(
              'Dana',
              Icons.account_balance_wallet_rounded,
              Colors.blue,
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),

      // ================= STICKY BOTTOM BUTTON =================
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () => _handleCheckout(totalPrice),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Lanjutkan Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String title, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(color: Color(0xff64748b), fontSize: 14),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff0f172a),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem(String name, IconData icon, Color iconColor) {
    bool isSelected = _selectedPaymentMethod == name;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = name),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D6EFD).withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF0D6EFD) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  color: isSelected
                      ? const Color(0xFF0D6EFD)
                      : const Color(0xff334155),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF0D6EFD), size: 22)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey, size: 22),
          ],
        ),
      ),
    );
  }
}
