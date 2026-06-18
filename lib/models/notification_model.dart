class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type; // 'transaksi', 'dumas', dll
  final String? dataId; // ID data terkait (misal: 'TRX-123')
  final int isRead; // 0 atau 1
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.dataId,
    required this.isRead,
    required this.createdAt,
  });

  // Helper untuk cek status dibaca (boolean)
  bool get alreadyRead => isRead == 1;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'info',
      dataId: json['data_id'],
      isRead: json['is_read'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
