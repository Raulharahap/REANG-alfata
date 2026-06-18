class SliderModel {
  final int id;
  final String imageUrl;

  SliderModel({required this.id, required this.imageUrl});

  factory SliderModel.fromJson(Map<String, dynamic> json) {
    return SliderModel(id: json['id'] ?? 0, imageUrl: json['gambar'] ?? '');
  }
}
