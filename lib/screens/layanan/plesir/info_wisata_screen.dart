import 'package:flutter/material.dart';
import 'package:reang_app/models/plesir_model.dart';
import 'package:reang_app/screens/layanan/plesir/detail_plesir_screen.dart';

class InfoWisataScreen extends StatelessWidget {
  final List<PlesirModel> items;
  const InfoWisataScreen({super.key, required this.items});

  // Fungsi helper untuk menghilangkan tag HTML (seperti <p>, <br>, <strong>, dll)
  String _removeAllHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    // Hapus tag HTML dan bersihkan spasi yang berlebihan
    return htmlText.replaceAll(exp, '').trim();
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text("Data tidak ditemukan."));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items[index];
        // Bersihkan deskripsi dari tag HTML
        final String cleanDeskripsi = _removeAllHtmlTags(data.deskripsi);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPlesirScreen(destinationData: data),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  child: Image.network(
                    data.foto,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    headers: const {
                      'ngrok-skip-browser-warning': 'true',
                    }, // Bypass ngrok
                    // Placeholder saat gambar dimuat
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    // Gambar pengganti (Alt) jika URL error/kosong
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Gambar tidak tersedia",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gunakan Expanded agar judul panjang tidak overflow ke samping
                          Expanded(
                            child: Text(
                              data.judul,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ), // Jarak antara judul dan rating
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.orange,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data.rating.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2.0),
                            child: Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Gunakan Expanded agar alamat panjang turun ke bawah otomatis
                          Expanded(
                            child: Text(
                              data.alamat,
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
                      const SizedBox(height: 8),
                      Text(
                        cleanDeskripsi, // Gunakan variabel yang sudah dibersihkan
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        maxLines: 2, // Batasi 2 baris agar rapi
                        overflow: TextOverflow
                            .ellipsis, // Tambah ... jika terlalu panjang
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
