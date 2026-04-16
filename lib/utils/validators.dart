class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final regex = RegExp(r'^[\+]?[0-9]{10,13}$');
    if (!regex.hasMatch(value.replaceAll(' ', ''))) return 'Enter a valid phone number';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return 'Enter a valid price';
    return null;
  }

  static String? quantity(String? value) {
    if (value == null || value.isEmpty) return 'Quantity is required';
    final parsed = double.tryParse(value.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return 'Enter a valid quantity';
    return null;
  }
}
