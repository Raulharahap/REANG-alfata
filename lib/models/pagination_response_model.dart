class PaginationResponseModel<T> {
  final int currentPage;
  final int lastPage;
  final List<T> data;

  PaginationResponseModel({
    required this.currentPage,
    required this.lastPage,
    required this.data,
  });

  // Helper untuk memeriksa apakah masih ada halaman berikutnya
  bool get hasMorePages => currentPage < lastPage;
}
