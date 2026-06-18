class DumasAnalitikModel {
  final DumasSummaryModel summary;
  final List<DumasChartDataModel> chartData;
  final List<DumasListDataModel> listData;

  DumasAnalitikModel({
    required this.summary,
    required this.chartData,
    required this.listData,
  });

  factory DumasAnalitikModel.fromJson(Map<String, dynamic> json) {
    return DumasAnalitikModel(
      summary: DumasSummaryModel.fromJson(json['summary']),
      chartData: (json['chart_data'] as List)
          .map((e) => DumasChartDataModel.fromJson(e))
          .toList(),
      listData: (json['list_data'] as List)
          .map((e) => DumasListDataModel.fromJson(e))
          .toList(),
    );
  }
}

class DumasSummaryModel {
  final int totalMasuk;
  final int totalDiproses;
  final int totalSelesai;
  final String persentase;

  DumasSummaryModel({
    required this.totalMasuk,
    required this.totalDiproses,
    required this.totalSelesai,
    required this.persentase,
  });

  factory DumasSummaryModel.fromJson(Map<String, dynamic> json) {
    return DumasSummaryModel(
      totalMasuk: json['total_masuk'] ?? 0,
      totalDiproses: json['total_diproses'] ?? 0,
      totalSelesai: json['total_selesai'] ?? 0,
      persentase: json['persentase'] ?? '0%',
    );
  }
}

class DumasChartDataModel {
  final String name;
  final int total;
  final int done;
  final String color;

  DumasChartDataModel({
    required this.name,
    required this.total,
    required this.done,
    required this.color,
  });

  factory DumasChartDataModel.fromJson(Map<String, dynamic> json) {
    return DumasChartDataModel(
      name: json['name'] ?? '',
      total: json['total'] ?? 0,
      done: json['done'] ?? 0,
      color: json['color'] ?? '#000000',
    );
  }
}

class DumasListDataModel {
  final String name;
  final int total;
  final int done;
  final num percentage; // Pakai num agar aman (bisa int 0 atau double 0.5)
  final String statusLabel;
  final String statusColor;
  final String color;

  DumasListDataModel({
    required this.name,
    required this.total,
    required this.done,
    required this.percentage,
    required this.statusLabel,
    required this.statusColor,
    required this.color,
  });

  factory DumasListDataModel.fromJson(Map<String, dynamic> json) {
    return DumasListDataModel(
      name: json['name'] ?? '',
      total: json['total'] ?? 0,
      done: json['done'] ?? 0,
      percentage: json['percentage'] ?? 0,
      statusLabel: json['status_label'] ?? '-',
      statusColor: json['status_color'] ?? '#000000',
      color: json['color'] ?? '#000000',
    );
  }
}
