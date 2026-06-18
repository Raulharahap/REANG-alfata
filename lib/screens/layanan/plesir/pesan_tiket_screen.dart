import 'package:flutter/material.dart';
import 'tiket_saya_screen.dart';
import 'checkout_detail_screen.dart';

class PesanTiketScreen extends StatelessWidget {
  const PesanTiketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0FDF4),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Reservasi Tiket",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Text(
            "Temukan pengalaman wisata dan event terbaik di sekitar Anda.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Card Pantai Balongan
          _buildTicketCard(
            context,
            title: "Pantai Balongan",
            location: "Kesambi, Jawa Tengah",
            price: "Rp 50.000",
            rating: "4.9",
            category: "Wisata",
            isEvent: false,
            imageUrl:
                "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?q=80&w=500",
          ),

          // Card Konser Band
          _buildTicketCard(
            context,
            title: "Konser Sheila on 7",
            location: "Stadion Utama, 21-23 Juli 2024",
            price: "Rp 250.000",
            rating: "4.8",
            category: "Event",
            isEvent: true,
            imageUrl:
                "https://images.unsplash.com/photo-1501386761578-eac5c94b800a?q=80&w=500",
          ),

          // Card Taman Sawah
          _buildTicketCard(
            context,
            title: "Taman Sawah",
            location: "Desa Lowat, Cikedung",
            price: "Rp 450.000",
            rating: "4.9",
            category: "Wisata",
            labelPrice: "wisata",
            isEvent: false,
            imageUrl:
                "https://images.unsplash.com/photo-1542332213-31f87348057f?q=80&w=500",
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(
    BuildContext context, {
    required String title,
    required String location,
    required String price,
    required String rating,
    required String category,
    required String imageUrl,
    String labelPrice = "Harga mulai",
    bool isEvent = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutDetailScreen(
                    title: title,
                    location: location,
                    price: price,
                    imageUrl: imageUrl,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(25),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                if (isEvent)
                  Positioned(
                    top: 15,
                    left: 15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "Bisa Dipesan",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 16),
                        Text(
                          rating,
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isEvent ? Icons.calendar_today : Icons.location_on,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          labelPrice,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF0D674D),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // PERUBAHAN DI SINI: Sekarang mengarah ke CheckoutDetailScreen membawa data dinamis
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutDetailScreen(
                              title: title,
                              location: location,
                              price: price,
                              imageUrl: imageUrl,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: const Text(
                        "Pesan Sekarang",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
