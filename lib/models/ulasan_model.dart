import 'package:timeago/timeago.dart' as timeago;

class UlasanModel {
  final int id;
  final int parentId; // ID dari parent (bisa dumas_id atau info_plesir_id)
  final int userId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String userName;

  UlasanModel({
    required this.id,
    required this.parentId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userName,
  });

  String get timeAgo {
    return timeago.format(createdAt, locale: 'id');
  }

  factory UlasanModel.fromJson(Map<String, dynamic> json) {
    // --- PERBAIKAN: Logika cerdas untuk menangani berbagai sumber JSON ---

    // 1. Tentukan Parent ID secara dinamis
    int parentIdValue = 0;
    if (json.containsKey('dumas_id')) {
      parentIdValue = json['dumas_id'] ?? 0;
    } else if (json.containsKey('info_plesir_id')) {
      parentIdValue = json['info_plesir_id'] ?? 0;
    }

    // 2. Tentukan Nama User secara dinamis
    String nameValue = 'Warga'; // Default
    if (json['user'] != null &&
        json['user'] is Map &&
        json['user']['name'] != null) {
      // Untuk format Plesir: "user": { "name": "Budi" }
      nameValue = json['user']['name'];
    } else if (json['user_name'] != null) {
      // Untuk format Dumas: "user_name": "Ani"
      nameValue = json['user_name'];
    }

    return UlasanModel(
      id: json['id'] ?? 0,
      parentId: parentIdValue,
      userId: json['user_id'] ?? 0,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      userName: nameValue,
    );
  }
}
