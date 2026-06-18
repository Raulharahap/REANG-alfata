import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/toko_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/ecomerce/chat_umkm_screen.dart';
import 'package:shimmer/shimmer.dart';

class UmkmChatListScreen extends StatefulWidget {
  const UmkmChatListScreen({super.key});

  @override
  State<UmkmChatListScreen> createState() => _UmkmChatListScreenState();
}

class _UmkmChatListScreenState extends State<UmkmChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Pastikan user login
    if (!authProvider.isLoggedIn || authProvider.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Pesan")),
        body: const Center(child: Text("Silakan login untuk melihat pesan.")),
      );
    }

    final myId = authProvider.user!.id.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat UMKM',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query: Cari chat yang pesertanya ada saya DAN khusus tipe UMKM
        stream: FirebaseFirestore.instance
            .collection('chats')
            // 1. Syarat Wajib Rules (Agar tidak Permission Denied)
            .where('participants', arrayContains: myId)
            // 2. Syarat Logika Mas (Hanya tampilkan chat di mana SAYA sebagai Pembeli)
            .where('userId', isEqualTo: int.tryParse(myId) ?? 0)
            // 3. Syarat Tipe Chat
            .where('isUmkmChat', isEqualTo: true)
            // 4. Urutan
            .orderBy('lastMessageTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State (Pakai Shimmer biar mirip Puskesmas)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList(theme);
          }

          // 2. Error State
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 8),
                  Text("Terjadi kesalahan: ${snapshot.error}"),
                ],
              ),
            );
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                    "Belum ada percakapan",
                    style: TextStyle(color: theme.hintColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 4. List Chat Data
          // 4. List Chat Data (DENGAN FILTER SELF-CHAT)
          final chatDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final List<dynamic> participants = data['participants'] ?? [];

            // Cek apakah Chat ke Diri Sendiri?
            // Logikanya: Jika peserta 1 dan peserta 2 adalah ORANG YANG SAMA (ID-nya sama)
            // Maka sembunyikan chat ini.
            if (participants.length >= 2 &&
                participants[0] == participants[1]) {
              return false; // Sembunyikan (Skip)
            }

            return true; // Tampilkan chat normal
          }).toList();

          // Cek lagi kalau setelah difilter jadi kosong
          if (chatDocs.isEmpty) {
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
                    "Belum ada percakapan",
                    style: TextStyle(color: theme.hintColor, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: chatDocs.length, // <-- Pakai chatDocs
            separatorBuilder: (ctx, index) =>
                const Divider(height: 1, indent: 82),
            itemBuilder: (context, index) {
              return _buildChatItem(
                context,
                chatDocs[index],
                myId,
                theme,
              ); // <-- Pakai chatDocs
            },
          );
        },
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

    // Ambil data dasar
    final String lastMessage = data['lastMessage'] ?? '';
    final Timestamp? timestamp = data['lastMessageTimestamp'];
    final String lastSenderId = data['lastMessageSenderId'] ?? '';

    // Unread Count
    final Map<String, dynamic> unreadMap = data['unreadCount'] != null
        ? Map<String, dynamic>.from(data['unreadCount'])
        : {};
    final int unreadCount = unreadMap[myId] ?? 0;

    // --- LOGIKA NAMA & FOTO ---
    // Karena kita sudah simpan 'tokoName' dan 'tokoFoto' di dokumen chat,
    // kita pakai itu saja. Jauh lebih mudah & akurat.
    final String displayName = data['tokoName'] ?? 'Toko';
    final String? displayImage = data['tokoFoto'];

    // Cari ID Lawan Bicara (Untuk keperluan navigasi)
    final List<dynamic> participants = data['participants'] ?? [];
    final String otherIdString = participants.firstWhere(
      (id) => id != myId,
      orElse: () => '0',
    );
    final int otherId = int.tryParse(otherIdString) ?? 0;

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

    // Styling Font (Bold jika ada pesan belum dibaca)
    final FontWeight fontWeight = unreadCount > 0
        ? FontWeight.bold
        : FontWeight.normal;
    final Color textColor = unreadCount > 0
        ? theme.colorScheme.onSurface
        : theme.hintColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        // --- NAVIGASI KE CHAT SCREEN ---
        // Kita harus membuat object TokoModel "Sementara" dari data yang ada di chat
        // agar bisa masuk ke ChatUMKMScreen tanpa request API lagi.
        final tokoTarget = TokoModel(
          id: data['tokoId'] ?? 0,
          idUser: otherId, // ID Pemilik Toko (Lawan Bicara)
          nama: displayName,
          alamat: '', // Tidak perlu untuk chat
          noHp: '', // Tidak perlu untuk chat
          foto: displayImage,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatUMKMScreen(toko: tokoTarget),
          ),
        );
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
            // Ikon "dibaca" jika pesan terakhir dari saya
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

  // Widget Loading (Sama persis dengan Puskesmas)
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
