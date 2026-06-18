import 'package:flutter/material.dart';
import 'kelola_metode_pembayaran_screen.dart'; // <-- Pastikan file ini ada
import 'kelola_ongkir_screen.dart'; // <-- Pastikan file ini ada

class PengaturanTokoView extends StatelessWidget {
  const PengaturanTokoView({super.key});

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // [PERBAIKAN]
          // Kita tidak lagi menggunakan Card pembungkus.
          // Setiap item sekarang adalah Card-nya sendiri.
          _buildSettingsTile(
            context,
            icon: Icons.account_balance_wallet_outlined,
            iconColor: Colors.blue.shade700,
            title: 'Metode Pembayaran',
            subtitle: 'Atur rekening bank, e-wallet, atau QRIS Anda.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KelolaMetodePembayaranScreen(),
                ),
              );
            },
          ),

          _buildSettingsTile(
            context,
            icon: Icons.local_shipping_outlined,
            iconColor: Colors.green.shade700,
            title: 'Opsi Pengiriman (Ongkir)',
            subtitle: 'Atur jangkauan dan biaya pengiriman produk.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KelolaOngkirScreen(),
                ),
              );
            },
          ),

          // Anda bisa menambahkan Card pengaturan lainnya di sini
          // _buildSettingsTile( ... )
        ],
      ),
    );
  }

  // [PERBAIKAN UTAMA DI SINI]
  // Widget ini sekarang mengembalikan Card, bukan hanya ListTile.
  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Setiap item dibungkus Card-nya sendiri
    return Card(
      elevation: 1, // Tetap subtle
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12.0), // Memberi jarak antar Card
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        // Pastikan area tap dan ripple effect sesuai bentuk Card
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
