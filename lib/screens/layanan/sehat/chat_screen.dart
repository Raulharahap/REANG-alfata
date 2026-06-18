import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:reang_app/models/dokter_model.dart';
import 'package:reang_app/models/puskesmas_model.dart';
import 'package:reang_app/models/user_model.dart';
import 'package:reang_app/providers/auth_provider.dart';
import 'package:reang_app/services/api_service.dart';
import 'package:reang_app/screens/layanan/sehat/image_preview_screen.dart';
import 'package:reang_app/screens/layanan/sehat/full_screen_image_viewer.dart';
import 'package:shimmer/shimmer.dart';

// Model untuk pesan dari Firestore
class FirestoreMessage {
  final String senderId;
  final String? text;
  final Timestamp? timestamp;
  final String type;
  final String? imageUrl;

  FirestoreMessage({
    required this.senderId,
    this.text,
    this.timestamp,
    required this.type,
    this.imageUrl,
  });

  factory FirestoreMessage.fromDoc(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return FirestoreMessage(
      senderId: data['senderId'] ?? '',
      text: data['text'],
      timestamp: data['timestamp'] as Timestamp?,
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
    );
  }
}

class ChatScreen extends StatefulWidget {
  final dynamic recipient;
  const ChatScreen({super.key, required this.recipient});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // State UI
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _lastMessageKey = GlobalKey();
  final GlobalKey _composerKey = GlobalKey();
  double _listViewBottomPadding = 16.0;
  bool _canScroll = false;

  // State Logika
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  List<FirestoreMessage> _messages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _chatId = '';
  String _myId = '';
  String _recipientId = '';
  StreamSubscription? _chatSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupChatAndListen();
    });
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _updateComposerHeightAndEnsureVisible(immediate: true);
      }
    });
    _scrollController.addListener(() {
      _updateCanScroll();
    });
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setupChatAndListen() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isLoggedIn ||
        (authProvider.user == null && authProvider.admin == null)) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Sesi tidak valid. Silakan login kembali.";
      });
      return;
    }

    _myId =
        (authProvider.role == 'puskesmas'
                ? authProvider.admin!.id
                : authProvider.user!.id)
            .toString();

    if (widget.recipient is DokterModel) {
      _recipientId = (widget.recipient as DokterModel).adminId.toString();
    } else if (widget.recipient is PuskesmasModel) {
      _recipientId = (widget.recipient as PuskesmasModel).adminId.toString();
    } else if (widget.recipient is UserModel) {
      _recipientId = widget.recipient.id.toString();
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = "Penerima tidak valid.";
      });
      return;
    }

    List<String> ids = [_myId, _recipientId]..sort();
    _chatId = ids.join('_');

    _listenToMessages();
    _clearUnreadForChat(_chatId, _myId);
  }

  void _listenToMessages() {
    _chatSubscription = FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            if (mounted) {
              setState(() {
                _messages = snapshot.docs
                    .map((doc) => FirestoreMessage.fromDoc(doc))
                    .toList();
                _isLoading = false;
                _errorMessage = null;
              });
              _scrollToBottomAfterBuild(animated: false);
              _updateCanScroll();
            }
          },
          onError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              debugPrint("Firestore Listen Error: $error");
            }
          },
        );
  }

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
        debugPrint('Gagal membersihkan unread count: $e2');
      }
    }
  }

  Future<void> _sendFirestoreMessage(
    Map<String, dynamic> messageData,
    String lastMessageText,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // --- PERBAIKAN NULL CHECK DI SINI ---
    final myName = authProvider.role == 'puskesmas'
        ? (authProvider.puskesmas?.nama ??
              authProvider
                  .admin!
                  .name) // Fallback ke nama admin jika puskesmas null
        : authProvider.user!.name;

    String recipientName = 'Tidak Dikenal';
    if (widget.recipient is UserModel) {
      recipientName = (widget.recipient as UserModel).name;
    } else if (widget.recipient is DokterModel) {
      recipientName = (widget.recipient as DokterModel).nama;
    } else if (widget.recipient is PuskesmasModel) {
      recipientName = (widget.recipient as PuskesmasModel).nama;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      final chatDocRef = firestore.collection('chats').doc(_chatId);
      final messageDocRef = chatDocRef.collection('messages').doc();

      batch.set(chatDocRef, {
        'participants': [_myId, _recipientId],
        'participantNames': [myName, recipientName],
        'lastMessage': lastMessageText,
        'lastMessageTimestamp': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _myId,
        'unreadCount': {_recipientId: FieldValue.increment(1)},
      }, SetOptions(merge: true));
      batch.set(messageDocRef, messageData);

      await batch.commit();

      // --- PERBAIKAN: PANGGIL API NOTIFIKASI SETELAH PESAN BERHASIL DISIMPAN ---
      if (authProvider.token != null) {
        // 1. Tentukan role penerima (ini sudah benar)
        String recipientRole = 'user'; // Default
        if (widget.recipient is PuskesmasModel ||
            widget.recipient is DokterModel) {
          recipientRole = 'puskesmas';
        }

        // 2. Panggil API (di luar 'if' penentu role)
        // Ini akan berjalan baik saat user mengirim atau admin mengirim
        _apiService.sendChatNotification(
          laravelToken: authProvider.token!,
          recipientId: _recipientId,
          recipientRole: recipientRole,
          messageText: lastMessageText,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendTextMessage() async {
    if (_controller.text.trim().isEmpty) return;
    final messageText = _controller.text.trim();
    _controller.clear();

    final messageData = {
      'senderId': _myId,
      'text': messageText,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _sendFirestoreMessage(messageData, messageText);

    _scrollToBottomAfterBuild(animated: true);

    if (_focusNode.canRequestFocus) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1080,
    );
    if (image == null) return;

    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(imageFile: File(image.path)),
      ),
    );

    if (result != null) {
      final String caption = result;
      _uploadAndSendImage(File(image.path), caption);
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAndSendImage(File imageFile, String caption) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final imageUrl = await _apiService.uploadChatImage(imageFile, token);

      final messageData = {
        'senderId': _myId,
        'type': 'image',
        'imageUrl': imageUrl,
        'text': caption,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final lastMessageText = caption.isNotEmpty ? caption : "🖼️ Gambar";
      await _sendFirestoreMessage(messageData, lastMessageText);
      _scrollToBottomAfterBuild(animated: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal meng-upload gambar.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void didChangeMetrics() {
    _updateComposerHeightAndEnsureVisible(immediate: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateCanScroll());
    super.didChangeMetrics();
  }

  void _updateComposerHeightAndEnsureVisible({bool immediate = false}) {
    double composerHeight = 0;
    try {
      final renderBox =
          _composerKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        composerHeight = renderBox.size.height;
      }
    } catch (_) {}
    final desiredPadding = 16.0 + composerHeight;
    if ((desiredPadding - _listViewBottomPadding).abs() > 1.0) {
      setState(() {
        _listViewBottomPadding = desiredPadding;
      });
    }
    _ensureLastMessageVisibleImmediate(immediate: immediate);
  }

  void _ensureLastMessageVisibleImmediate({bool immediate = false}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (_lastMessageKey.currentContext != null) {
          Scrollable.ensureVisible(
            _lastMessageKey.currentContext!,
            duration: immediate
                ? Duration.zero
                : const Duration(milliseconds: 300),
            alignment: 1.0,
            curve: Curves.easeOut,
          );
        } else if (_scrollController.hasClients &&
            _scrollController.position.hasContentDimensions) {
          final max = _scrollController.position.maxScrollExtent;
          _scrollController.jumpTo(max);
        }
      } catch (e) {}
    });
  }

  void _scrollToBottomAfterBuild({bool animated = false, int delayMs = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // opsional delay kecil jika konten belum terukur (biasanya tidak perlu)
      if (delayMs > 0) await Future.delayed(Duration(milliseconds: delayMs));
      if (!_scrollController.hasClients) return;
      try {
        final max = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            max,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(max);
        }
      } catch (e) {
        // ignore; kadang posisi belum siap — aman diabaikan
      }
    });
  }

  void _updateCanScroll() {
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      if (_canScroll != false) setState(() => _canScroll = false);
      return;
    }
    bool newCanScroll;
    try {
      newCanScroll = _scrollController.position.maxScrollExtent > 0.0;
    } catch (_) {
      newCanScroll = false;
    }
    if (newCanScroll != _canScroll) {
      setState(() => _canScroll = newCanScroll);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String recipientName;
    String? recipientFotoUrl;

    if (widget.recipient is DokterModel) {
      recipientName = (widget.recipient as DokterModel).nama;
      recipientFotoUrl = (widget.recipient as DokterModel).fotoUrl;
    } else if (widget.recipient is UserModel) {
      recipientName = (widget.recipient as UserModel).name;
      recipientFotoUrl = null;
    } else if (widget.recipient is PuskesmasModel) {
      recipientName = (widget.recipient as PuskesmasModel).nama;
      recipientFotoUrl = null;
    } else {
      recipientName = 'Tidak Dikenal';
      recipientFotoUrl = null;
    }

    final ScrollPhysics physics = _canScroll
        ? const BouncingScrollPhysics()
        : const NeverScrollableScrollPhysics();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: Row(
          children: [
            const BackButton(),
            CircleAvatar(
              backgroundImage:
                  (recipientFotoUrl != null && recipientFotoUrl.isNotEmpty)
                  ? NetworkImage(
                      recipientFotoUrl,
                      headers: const {'ngrok-skip-browser-warning': 'true'},
                    )
                  : null,
              child: (recipientFotoUrl == null || recipientFotoUrl.isEmpty)
                  ? (widget.recipient is PuskesmasModel
                        ? const Icon(Icons.local_hospital)
                        : Text(
                            recipientName.isNotEmpty
                                ? recipientName.substring(0, 1).toUpperCase()
                                : '?',
                          ))
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipientName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 10),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildShimmerEffect(theme)
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _messages.isEmpty
                ? const Center(child: Text('Mulai percakapan Anda.'))
                : AbsorbPointer(
                    absorbing:
                        !_canScroll &&
                        MediaQuery.of(context).viewInsets.bottom > 0,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: physics,
                      padding: EdgeInsets.fromLTRB(
                        16.0,
                        16.0,
                        16.0,
                        _listViewBottomPadding,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isMyMessage = message.senderId == _myId;
                        final bubble = _ChatMessageBubble(
                          message: message,
                          isMyMessage: isMyMessage,
                        );

                        if (index == _messages.length - 1) {
                          return Container(key: _lastMessageKey, child: bubble);
                        } else {
                          return bubble;
                        }
                      },
                    ),
                  ),
          ),
          Container(
            key: _composerKey,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.attach_file, color: theme.hintColor),
                    onPressed: _showImagePickerOptions,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan Anda...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      onSubmitted: (_) => _sendTextMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _sendTextMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerEffect(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.dark
          ? Colors.grey[800]!
          : Colors.grey[300]!,
      highlightColor: theme.brightness == Brightness.dark
          ? Colors.grey[700]!
          : Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _ShimmerBubble(isMyMessage: false),
          _ShimmerBubble(isMyMessage: true),
          _ShimmerBubble(isMyMessage: false),
          _ShimmerBubble(isMyMessage: true, isShort: true),
          _ShimmerBubble(isMyMessage: false),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final FirestoreMessage message;
  final bool isMyMessage;
  const _ChatMessageBubble({required this.message, required this.isMyMessage});

  String _formatTime(BuildContext context, Timestamp? timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = timestamp.toDate().toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '--:--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alignment = isMyMessage
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final color = isMyMessage
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;

    Widget messageContent;
    if (message.type == 'image' && message.imageUrl != null) {
      messageContent = GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FullScreenImageViewer(imageUrl: message.imageUrl!),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: color,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Icon(Icons.broken_image, size: 40),
                  ),
                ),
                if (message.text != null && message.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Text(
                      message.text!,
                      style: TextStyle(
                        color: isMyMessage
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    } else {
      final textColor = isMyMessage
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface;
      messageContent = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text ?? '',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: messageContent,
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(context, message.timestamp),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ShimmerBubble extends StatelessWidget {
  final bool isMyMessage;
  final bool isShort;
  const _ShimmerBubble({this.isMyMessage = false, this.isShort = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMyMessage
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Container(
          width: isShort ? 150 : MediaQuery.of(context).size.width * 0.6,
          height: isShort ? 30 : 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 50,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
