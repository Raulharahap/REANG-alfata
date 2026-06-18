import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/ecomerce/chat_umkm_screen.dart'; // Pakai layar chat yang sama
import 'package:shimmer/shimmer.dart';

class AdminUmkmChatListScreen extends StatefulWidget {
  const AdminUmkmChatListScreen({super.key});

  @override
  State<AdminUmkmChatListScreen> createState() =>
      _AdminUmkmChatListScreenState();
}

class _AdminUmkmChatListScreenState extends State<AdminUmkmChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Pastikan login
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pesan Masuk")),
        body: const Center(child: Text("Silakan login kembali.")),
      );
    }

    final myId = authProvider.user!.id.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat Pelanggan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // QUERY: Ambil semua chat yang melibatkan saya & bertipe UMKM
        // (Indexnya sama dengan yang User, jadi aman tidak perlu buat index baru)
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: myId)
            .where('isUmkmChat', isEqualTo: true)
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList(theme);
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(child: Text("Terjadi kesalahan: ${snapshot.error}"));
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(theme);
          }

          // --- FILTER LOGIC (PENTING) ---
          // Di sini kita memfilter: Hanya tampilkan chat di mana SAYA adalah PENJUAL.
          // Artinya: userId (ID Pembeli di dokumen) TIDAK BOLEH SAMA dengan myId (Saya).
          final chatDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Jika userId di dokumen == ID Saya, berarti ini chat belanja saya (skip)
            // Kita mau chat di mana saya jadi penjual (userId != ID Saya)
            final chatUserId = data['userId'].toString();
            return chatUserId != myId;
          }).toList();

          if (chatDocs.isEmpty) {
            return _buildEmptyState(theme);
          }

          // 4. List Chat Data
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chatDocs.length,
            separatorBuilder: (ctx, index) =>
                const Divider(height: 1, indent: 82),
            itemBuilder: (context, index) {
              return _buildChatItem(context, chatDocs[index], myId, theme);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: theme.hintColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada pesan dari pelanggan",
            style: TextStyle(color: theme.hintColor, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    DocumentSnapshot doc,
    String myId,
    ThemeData theme,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    // Data Pesan
    final String lastMessage = data['lastMessage'] ?? '';
    final Timestamp? timestamp = data['lastMessageTimestamp'];
    final String lastSenderId = data['lastMessageSenderId'] ?? '';

    // Unread Count
    final Map<String, dynamic> unreadMap = data['unreadCount'] != null
        ? Map<String, dynamic>.from(data['unreadCount'])
        : {};
    final int unreadCount = unreadMap[myId] ?? 0;

    // --- LOGIKA NAMA & FOTO (KHUSUS ADMIN) ---
    // Admin melihat Nama USER/PEMBELI, bukan nama Toko sendiri.
    final String displayName = data['userName'] ?? 'Pelanggan';

    // Ambil foto user (bisa null)
    final String? displayImage = data['userFoto'];

    // Ambil ID User (Pembeli) untuk keperluan navigasi chat
    final int buyerId = data['userId'] is int
        ? data['userId']
        : int.tryParse(data['userId'].toString()) ?? 0;

    // Format Waktu
    String timeString = '';
    if (timestamp != null) {
      final dt = timestamp.toDate().toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        timeString = DateFormat('HH:mm').format(dt);
      } else if (dt.year == now.year) {
        timeString = DateFormat('dd MMM').format(dt);
      } else {
        timeString = DateFormat('dd/MM/yy').format(dt);
      }
    }

    final FontWeight fontWeight = unreadCount > 0
        ? FontWeight.bold
        : FontWeight.normal;
    final Color textColor = unreadCount > 0
        ? theme.colorScheme.onSurface
        : theme.hintColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        // --- TRIK NAVIGASI (PENTING) ---
        // ChatUMKMScreen didesain menerima 'TokoModel'.
        // Agar logic ID Pengirim/Penerima tetap jalan, kita kirim object TokoModel "Palsu".
        // Di mana:
        // - idUser -> Kita isi dengan ID PEMBELI (agar pesan terkirim ke pembeli)
        // - nama   -> Kita isi dengan Nama PEMBELI (agar di header chat muncul nama pembeli)

        final buyerAsTarget = TokoModel(
          id: data['tokoId'] ?? 0, // ID Toko tetap sama
          idUser: buyerId, // TARGETNYA ADALAH PEMBELI
          nama: displayName, // NAMA TARGET ADALAH NAMA PEMBELI
          alamat: '',
          noHp: '',
          foto: displayImage, // FOTO TARGET ADALAH FOTO PEMBELI
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ChatUMKMScreen(toko: buyerAsTarget, isSeller: true),
          ),
        );
        // Tidak perlu setState manual saat kembali, karena StreamBuilder otomatis update
        // begitu unreadCount di database berubah jadi 0.
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.primaryContainer,
        backgroundImage: (displayImage != null && displayImage.isNotEmpty)
            ? NetworkImage(
                displayImage.startsWith('http')
                    ? displayImage
                    : 'https://72ec59a5c57b.ngrok-free.app/storage/$displayImage', // SESUAIKAN BASE URL
                headers: const {'ngrok-skip-browser-warning': 'true'},
              )
            : null,
        child: (displayImage == null || displayImage.isEmpty)
            ? Text(
                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 20,
                ),
              )
            : null,
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeString,
            style: TextStyle(
              fontSize: 12,
              color: unreadCount > 0
                  ? theme.colorScheme.primary
                  : theme.hintColor,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            if (lastSenderId == myId) ...[
              Icon(Icons.done_all, size: 16, color: theme.hintColor),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textColor, fontWeight: fontWeight),
              ),
            ),
            if (unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: theme.brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
            ),
            title: Container(
              height: 16,
              color: Colors.white,
              margin: const EdgeInsets.only(right: 100),
            ),
            subtitle: Container(
              height: 12,
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8, right: 40),
            ),
          );
        },
      ),
    );
  }
}
