class StoreAccessDeniedException implements Exception {
  final String message;

  const StoreAccessDeniedException(this.message);

  @override
  String toString() => message;
}
