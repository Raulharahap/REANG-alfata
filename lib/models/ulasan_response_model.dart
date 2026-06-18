import 'package:reang_app/models/ulasan_model.dart';

class UlasanResponseModel {
  final double avgRating;
  final int currentPage;
  final int lastPage;
  final List<UlasanModel> ratings;

  UlasanResponseModel({
    required this.avgRating,
    required this.currentPage,
    required this.lastPage,
    required this.ratings,
  });

  bool get hasMorePages => currentPage < lastPage;

  factory UlasanResponseModel.fromJson(Map<String, dynamic> json) {
    var ratingData = json['ratings']?['data'] as List<dynamic>? ?? [];
    List<UlasanModel> ratingList = ratingData
        .map((i) => UlasanModel.fromJson(i))
        .toList();

    return UlasanResponseModel(
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0.0,
      currentPage: json['ratings']?['current_page'] ?? 1,
      lastPage: json['ratings']?['last_page'] ?? 1,
      ratings: ratingList,
    );
  }
}
