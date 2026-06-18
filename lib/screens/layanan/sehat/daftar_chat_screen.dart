import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reang_app/models/puskesmas_model.dart'; // <-- DIUBAH
import 'package:reang_app/services/api_service.dart';
import 'package:shimmer/shimmer.dart';
import 'chat_screen.dart';

class DaftarChatScreen extends StatefulWidget {
  const DaftarChatScreen({super.key});

  @override
  State<DaftarChatScreen> createState() => _DaftarChatScreenState();
}

class _DaftarChatScreenState extends State<DaftarChatScreen> {
  final ApiService _apiService = ApiService();
  Stream<QuerySnapshot>? _chatsStream;
  StreamSubscription<User?>? _authSub;

  // Cache futures untuk menghindari fetch ulang setiap rebuild
  final Map<String, Future<PuskesmasModel?>> _puskesmasCache = {}; // <-- DIUBAH

  @override
  void initState() {
    super.initState();
    _initializeStream();

    // Hanya re-init stream jika UID berubah (mis. login/logout)
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final currentUid = _chatsStream == null
          ? null
          : FirebaseAuth.instance.currentUser?.uid;
      if (user?.uid != currentUid) {
        _initializeStream();
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _initializeStream() {
    final myId = FirebaseAuth.instance.currentUser?.uid;
    if (myId != null) {
      _chatsStream = FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: myId)
          .orderBy('lastMessageTimestamp', descending: true)
          .snapshots();
    } else {
      _chatsStream = const Stream.empty();
    }
  }

  // --- FUNGSI DIGANTI UNTUK MENGAMBIL PUSKESMAS ---
  Future<PuskesmasModel?> _getPuskesmasFuture(String adminId) {
    if (adminId.isEmpty) {
      return Future.value(null);
    }
    return _puskesmasCache.putIfAbsent(
      adminId,
      () => _apiService.getPuskesmasByAdminId(adminId), // <-- DIUBAH
    );
  }

  String getInitials(String name) {
    if (name.isEmpty) return '?';
    List<String> names = name.split(' ');
    String initials = '';
    int numWords = names.length > 1 ? 2 : 1;
    for (var i = 0; i < numWords; i++) {
      if (names[i].isNotEmpty) {
        initials += names[i][0];
      }
    }
    return initials.toUpperCase();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final messageDate = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (messageDate.isAfter(today)) {
      return DateFormat('HH:mm').format(messageDate);
    } else if (messageDate.isAfter(yesterday)) {
      return 'Kemarin';
    }
    return DateFormat('dd/MM/yy').format(messageDate);
  }

  // helper: tampilkan loading dialog (blocking kecil)
  Future<void> _showLoadingDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid;

    if (myId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daftar Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Anda belum memulai percakapan.'));
          }

          // --- FILTER BARU: Hapus chat yang bertipe UMKM ---
          // Kita hanya ambil chat yang TIDAK PUNYA field 'isUmkmChat' atau nilainya false
          final chatDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Kalau isUmkmChat == true, berarti ini chat Toko -> JANGAN DIAMBIL
            return data['isUmkmChat'] != true;
          }).toList();
          // --------------------------------------------------

          // Cek lagi setelah difilter, kalau kosong -> Tampilkan pesan kosong
          if (chatDocs.isEmpty) {
            return const Center(child: Text('Anda belum memulai percakapan.'));
          }
          return ListView.separated(
            itemCount: chatDocs.length,
            separatorBuilder: (context, index) =>
                const Divider(indent: 80, height: 1),
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              String recipientName = 'Puskesmas'; // <-- DIUBAH
              String recipientAdminId = '';
              final pNames = List<String>.from(
                chatData['participantNames'] ?? [],
              );
              final pIds = List<String>.from(chatData['participants'] ?? []);

              for (int i = 0; i < pIds.length; i++) {
                if (pIds[i] != myId) {
                  recipientAdminId = pIds[i];
                  if (i < pNames.length) {
                    recipientName = pNames[i];
                  }
                  break;
                }
              }

              final unreadCount = ((chatData['unreadCount'] ?? {})[myId] ?? 0)
                  .toInt();
              final hasUnread = unreadCount > 0;

              // PREFETCH
              _getPuskesmasFuture(recipientAdminId); // <-- DIUBAH

              return FutureBuilder<PuskesmasModel?>(
                // <-- DIUBAH
                future: _puskesmasCache[recipientAdminId], // <-- DIUBAH
                builder: (context, puskesmasSnapshot) {
                  // <-- DIUBAH
                  if (puskesmasSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      !_puskesmasCache.containsKey(recipientAdminId)) {
                    return _buildShimmerTile();
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    leading: CircleAvatar(
                      radius: 28,
                      // Puskesmas tidak punya fotoUrl, jadi kita hapus backgroundImage
                      // dan langsung gunakan 'child' untuk inisial.
                      child: Text(
                        getInitials(
                          recipientName,
                        ), // Gunakan fungsi getInitials
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:
                              18, // Samakan style-nya dengan halaman dokter
                        ),
                      ),
                    ),
                    title: Text(
                      recipientName,
                      style: TextStyle(
                        fontWeight: hasUnread
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      chatData['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatTimestamp(
                            chatData['lastMessageTimestamp'] as Timestamp?,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread
                                ? Colors.green
                                : Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (hasUnread)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 24, height: 24),
                      ],
                    ),
                    onTap: () async {
                      // Set unreadCount to 0 (fire-and-forget)
                      chatDoc.reference
                          .set({
                            'unreadCount': {myId: 0},
                          }, SetOptions(merge: true))
                          .catchError((e) {});

                      _showLoadingDialog(context);

                      PuskesmasModel? puskesmasToOpen; // <-- DIUBAH
                      try {
                        puskesmasToOpen = await _getPuskesmasFuture(
                          // <-- DIUBAH
                          recipientAdminId,
                        ).timeout(const Duration(seconds: 7));
                      } catch (e) {
                        puskesmasToOpen = null;
                      }

                      if (mounted) {
                        Navigator.of(context, rootNavigator: true).pop();
                      }

                      if (puskesmasToOpen == null) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Gagal memuat data puskesmas. Coba lagi.',
                              ),
                            ),
                          );
                        }
                        return;
                      }

                      // Navigasi ke ChatScreen dengan PuskesmasModel
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            recipient: puskesmasToOpen,
                          ), // <-- DIUBAH
                        ),
                      );

                      // Refresh setelah kembali
                      if (!mounted) return;
                      chatDoc.reference
                          .set({
                            'unreadCount': {myId: 0},
                          }, SetOptions(merge: true))
                          .catchError((e) {});
                      if (mounted) setState(() {});
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Widget untuk Shimmer Effect (Loading)
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: ListView.separated(
        itemCount: 8,
        separatorBuilder: (context, index) =>
            const Divider(indent: 80, height: 1),
        itemBuilder: (context, index) => _buildShimmerTile(),
      ),
    );
  }

  // Widget untuk satu item Shimmer Tile
  Widget _buildShimmerTile() {
    return const ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      leading: CircleAvatar(radius: 28, backgroundColor: Colors.white),
      title: ShimmerBox(width: 150, height: 16),
      subtitle: ShimmerBox(width: 200, height: 14),
      trailing: ShimmerBox(width: 50, height: 12),
    );
  }
}

// Widget helper kecil untuk kotak shimmer
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  const ShimmerBox({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
