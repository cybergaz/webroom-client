extension StringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.isEmpty;
  String get orEmpty => this ?? '';

  bool get isValidPhone {
    if (this == null) return false;
    return RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(this!);
  }

  bool get isValidEmail {
    if (this == null) return false;
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this!);
  }
}
