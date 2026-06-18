import 'package:flutter/material.dart';
import 'instruksi_checkout_screen.dart'; // Import halaman instruksi checkout pembeli

class CheckoutDetailScreen extends StatefulWidget {
  // Tambahkan parameter konstruktor untuk menerima data
  final String title;
  final String location;
  final String price;
  final String imageUrl;

  const CheckoutDetailScreen({
    super.key,
    required this.title,
    required this.location,
    required this.price,
    required this.imageUrl,
  });

  @override
  State<CheckoutDetailScreen> createState() => _CheckoutDetailScreenState();
}

class _CheckoutDetailScreenState extends State<CheckoutDetailScreen> {
  String _selectedPaymentMethod = 'OVO';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Plesir–Yu',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pembayaran',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xff0f172a),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Konfirmasi pesanan Anda dan lanjutkan ke pembayaran',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // ================= CARD DETAIL KUNJUNGAN & RINCIAN HARGA =================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffe2e8f0), width: 1),
              ),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        // DINAMIS: Menggunakan gambar dari card yang diklik
                        child: Image.network(
                          widget.imageUrl,
                          width: 85,
                          height: 85,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 85,
                              height: 85,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Destinasi',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // DINAMIS: Menggunakan nama destinasi yang diklik
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff0f172a),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Colors.grey,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                // DINAMIS: Menggunakan lokasi dari card yang diklik
                                Expanded(
                                  child: Text(
                                    widget.location,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
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
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xffedf2f7), thickness: 1),
                  const SizedBox(height: 12),

                  // Row Tanggal Kunjungan & Jumlah Tiket
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TANGGAL KUNJUNGAN',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '24 Okt 2024',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xff334155),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
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
                            const SizedBox(height: 6),
                            Row(
                              children: const [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '2 Tiket Dewasa',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xff334155),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Section Price Breakdown
                  const Text(
                    'RINCIAN HARGA',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // DINAMIS: Menggunakan harga asli yang dikirim dari card
                  _buildPriceRow('Harga Tiket (2x)', widget.price),
                  const SizedBox(height: 8),

                  // Custom Dashed Line Pembatas
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final boxWidth = constraints.constrainWidth();
                          const dashWidth = 5.0;
                          const dashSpace = 3.0;
                          final dashCount = (boxWidth / (dashWidth + dashSpace))
                              .floor();
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(dashCount, (_) {
                              return const SizedBox(
                                width: dashWidth,
                                height: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Color(0xffcbd5e1),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                  ),
                  const SizedBox(height: 16),

                  // Total Payment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total\nPembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      // DINAMIS: Total pembayaran disesuaikan dengan harga tiket
                      Text(
                        widget.price,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
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
                color: Color(0xff334155),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'E-Wallet',
              style: TextStyle(fontSize: 13, color: Colors.grey),
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
            const SizedBox(height: 16),
            const Text(
              'Transfer Bank',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            _buildPaymentMethodItem(
              'Transfer Virtual Account',
              Icons.account_balance,
              Colors.teal,
            ),
            const SizedBox(height: 32),

            // ================= TOMBOL KONFIRMASI PEMBAYARAN =================
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  // Navigasi langsung menuju halaman InstruksiCheckoutScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const InstruksiCheckoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4a90e2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Konfirmasi Pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xff4a90e2)
                : const Color(0xffe2e8f0),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xff334155),
                ),
              ),
            ),
            Radio<String>(
              value: name,
              groupValue: _selectedPaymentMethod,
              activeColor: const Color(0xff4a90e2),
              onChanged: (String? value) =>
                  setState(() => _selectedPaymentMethod = value!),
            ),
          ],
        ),
      ),
    );
  }
}
