import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessageModel {
  final String senderId;
  final String text;
  final Timestamp? timestamp;

  ChatMessageModel({
    required this.senderId,
    required this.text,
    this.timestamp,
  });

  factory ChatMessageModel.fromDoc(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return ChatMessageModel(
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] as Timestamp?,
    );
  }
}
