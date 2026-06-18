import 'package:flutter/material.dart';
import 'package:reang_app/screens/layanan/sehat/konsultasi_dokter_screen.dart';

class KonsultasiDokterCard extends StatelessWidget {
  const KonsultasiDokterCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Card(
      // Properti shadow dan border tetap dipertahankan
      elevation: 8,
      shadowColor: theme.shadowColor.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 1.0,
        ),
      ),
      // PERBAIKAN: Menambahkan clipBehavior agar gambar di dalamnya ikut melengkung
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KonsultasiDokterScreen(),
            ),
          );
        },
        child:
            // --- PERUBAHAN: Semua konten diganti dengan satu wadah untuk gambar ---
            SizedBox(
              height: 120, // Tentukan tinggi yang Anda inginkan untuk banner
              width: double.infinity,
              // Ganti Image.asset dengan Image.network jika gambar dari internet
              child: Image.asset(
                'assets/konsultasi.webp', // GANTI dengan path gambar Anda
                fit: BoxFit.cover,
                // Fallback jika gambar gagal dimuat
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.local_hospital_outlined,
                      color: theme.hintColor,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}
