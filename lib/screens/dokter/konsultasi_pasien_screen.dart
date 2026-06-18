import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_styled_toast/flutter_styled_toast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/user_model.dart' as app_user_model;
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/screens/layanan/sehat/chat_screen.dart';
import 'package:reang_app/screens/main_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:reang_app/services/api_service.dart';

class KonsultasiPasienScreen extends StatefulWidget {
  const KonsultasiPasienScreen({super.key});

  @override
  State<KonsultasiPasienScreen> createState() => _KonsultasiPasienScreenState();
}

class _KonsultasiPasienScreenState extends State<KonsultasiPasienScreen> {
  late Stream<QuerySnapshot> _chatsStream;

  /// Menyimpan waktu (local) saat kita melakukan "clear" unread untuk sebuah chat.
  /// Digunakan untuk menyembunyikan badge secara instan sampai Firestore mengonfirmasi.
  final Map<String, DateTime> _localClearedAt = {};

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  // Inisialisasi stream chat sekali di initState agar tidak re-create tiap build.
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

  // Clear unread untuk chat doc. Jika update gagal, fallback ke set(merge).
  Future<void> _clearUnreadForChat(String chatDocId, String myId) async {
    if (chatDocId.isEmpty || myId.isEmpty) return;
    final chatDocRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatDocId);
    try {
      await chatDocRef.update({'unreadCount.$myId': 0});
    } catch (e) {
      try {
        await chatDocRef.set({
          'unreadCount': {myId: 0},
        }, SetOptions(merge: true));
      } catch (e2) {
        debugPrint('Gagal membersihkan unread untuk $chatDocId: $e2');
      }
    }
    // Tandai waktu clear lokal agar UI segera merespon (hide badge).
    _localClearedAt[chatDocId] = DateTime.now();
    if (mounted) setState(() {}); // paksa rebuild supaya badge hilang seketika
  }

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
        itemBuilder: (context, index) {
          return const ListTile(
            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            leading: CircleAvatar(radius: 28, backgroundColor: Colors.white),
            title: ShimmerBox(width: 150, height: 16),
            subtitle: ShimmerBox(width: 200, height: 14),
            trailing: ShimmerBox(width: 50, height: 12),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              const Text('Yakin ingin keluar?'),
            ],
          ),
          content: const Text('Anda akan keluar dari akun dokter ini.'),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(ctx).pop();
                await authProvider.logout();

                if (!context.mounted) return;
                showToast(
                  "Anda telah keluar.",
                  context: context,
                  position: StyledToastPosition.bottom,
                  animation: StyledToastAnimation.scale,
                  reverseAnimation: StyledToastAnimation.fade,
                  animDuration: const Duration(milliseconds: 150),
                  duration: const Duration(seconds: 2),
                  borderRadius: BorderRadius.circular(25),
                  textStyle: const TextStyle(color: Colors.white),
                  curve: Curves.fastOutSlowIn,
                );

                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Ya, keluar'),
            ),
          ],
        );
      },
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

    if (messageDate.isAfter(today))
      return DateFormat('HH:mm').format(messageDate);
    if (messageDate.isAfter(yesterday)) return 'Kemarin';
    return DateFormat('dd/MM/yy').format(messageDate);
  }

  @override
  Widget build(BuildContext context) {
    final myId = FirebaseAuth.instance.currentUser?.uid;

    if (myId == null) {
      // Tetap gunakan indikator sederhana — namun Anda minta shimmer saja; di sini user belum login ke Firebase, jadi tampilkan shimmer singkat
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Konsultasi Pasien',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmationDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerEffect();
          }
          if (snapshot.hasError) {
            if (snapshot.error.toString().contains('requires an index')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Database sedang menyiapkan daftar chat Anda. Ini bisa memakan waktu beberapa menit. Silakan kembali lagi nanti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada percakapan.'));
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.separated(
            itemCount: chatDocs.length,
            separatorBuilder: (context, index) =>
                const Divider(indent: 80, height: 1),
            itemBuilder: (context, index) {
              final chatDoc = chatDocs[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              String patientName = 'Pasien';
              String patientId = '';
              final pNames = List<String>.from(
                chatData['participantNames'] ?? [],
              );
              final pIds = List<String>.from(chatData['participants'] ?? []);

              for (int i = 0; i < pIds.length; i++) {
                if (pIds[i] != myId) {
                  patientId = pIds[i];
                  if (i < pNames.length) patientName = pNames[i];
                  break;
                }
              }

              // Ambil unread dengan aman
              int unreadCount = 0;
              try {
                final unreadMap = Map<String, dynamic>.from(
                  chatData['unreadCount'] ?? {},
                );
                final value = unreadMap[myId];
                if (value is int) {
                  unreadCount = value;
                } else if (value is double) {
                  unreadCount = value.toInt();
                } else if (value is String) {
                  unreadCount = int.tryParse(value) ?? 0;
                } else {
                  unreadCount = 0;
                }
              } catch (_) {
                unreadCount = 0;
              }

              // Ambil last message timestamp untuk logika hide badge lokal
              final Timestamp? lastTs =
                  chatData['lastMessageTimestamp'] as Timestamp?;
              final DateTime? lastMsgDate = lastTs?.toDate();
              final DateTime? clearedAt = _localClearedAt[chatDoc.id];

              // Logika menampilkan badge:
              // - Jika ada unread > 0 dan lastMsgDate lebih baru daripada clearedAt (atau clearedAt null) -> tampilkan badge
              // - Jika unread > 0 tetapi clearedAt ada dan lastMsgDate tidak lebih baru (artinya clear lokal sudah lebih baru) -> sembunyikan badge
              // - Jika unread == 0 -> sembunyikan badge
              bool showBadge;
              if (unreadCount > 0) {
                if (clearedAt != null &&
                    lastMsgDate != null &&
                    !lastMsgDate.isAfter(clearedAt)) {
                  // last message tidak lebih baru dari waktu kita clear -> anggap sudah terbaca
                  showBadge = false;
                } else {
                  showBadge = true;
                }
              } else {
                showBadge = false;
              }

              final dummyPivot = app_user_model.PivotModel(
                userId: int.tryParse(patientId) ?? 0,
                roleId: 1, // Asumsi ID untuk role 'user' adalah 1
              );

              // 2. Buat data 'role' dummy
              final dummyRole = app_user_model.RoleModel(
                id: 1, // Asumsi ID untuk role 'user' adalah 1
                name: 'user',
                pivot: dummyPivot,
              );

              // 3. Masukkan 'dummyRole' sebagai LIST (menggunakan [ ])
              final patientUser = app_user_model.UserModel(
                id: int.tryParse(patientId) ?? 0,
                name: patientName,
                email: '',
                phone: '',
                noKtp: '',
                role: [dummyRole], // <--- SEKARANG MENJADI LIST
              );

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                leading: CircleAvatar(
                  radius: 28,
                  child: Text(
                    getInitials(patientName),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  patientName,
                  style: TextStyle(
                    fontWeight: showBadge ? FontWeight.bold : FontWeight.normal,
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
                      _formatTimestamp(lastTs),
                      style: TextStyle(
                        fontSize: 12,
                        color: showBadge
                            ? Colors.green
                            : Theme.of(context).hintColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (showBadge)
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
                  // Pastikan login ke Firebase, jika belum signInWithCustomToken dulu
                  if (FirebaseAuth.instance.currentUser == null) {
                    try {
                      final token = Provider.of<AuthProvider>(
                        context,
                        listen: false,
                      ).token;
                      if (token == null) throw Exception('Token auth kosong');
                      final firebaseToken = await ApiService().getFirebaseToken(
                        token,
                      );
                      await FirebaseAuth.instance.signInWithCustomToken(
                        firebaseToken,
                      );
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Gagal terhubung kembali ke server chat.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                  }

                  if (!mounted) return;

                  // 1) Clear unread sebelum membuka chat (agar backend tau dan UI lokal hide)
                  try {
                    if (unreadCount > 0) {
                      await _clearUnreadForChat(chatDoc.id, myId);
                    } else {
                      // set clearedAt agar bila unreadCount==0 tapi kita ingin sinkron, simpan clearedAt juga
                      _localClearedAt[chatDoc.id] = DateTime.now();
                      if (mounted) setState(() {});
                    }
                  } catch (e) {
                    debugPrint('Error saat clear unread sebelum buka chat: $e');
                  }

                  // 2) Buka ChatScreen dan tunggu kembali (agar kita bisa memastikan clear lagi saat kembali)
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(recipient: patientUser),
                    ),
                  );

                  // 3) Setelah kembali (pop), pastikan unread di-clear lagi (jika ada race condition)
                  try {
                    await _clearUnreadForChat(chatDoc.id, myId);
                  } catch (e) {
                    debugPrint('Error saat clear unread pas kembali: $e');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _localClearedAt.clear();
    super.dispose();
  }
}

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
