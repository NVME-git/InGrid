/// OCR/camera import — not implemented in MVP.
class ImportService {
  const ImportService._();
  static const ImportService instance = ImportService._();

  /// Import puzzle from camera/image — stub, always returns null.
  Future<List<List<int>>?> importFromCamera() async => null;
}
