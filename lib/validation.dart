class Validation {
  static String? email(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? password(String? value, {bool register = false}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (register && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirm(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    return value == password ? null : 'Passwords do not match';
  }

  static String? title(String? value) => _required(value, 'Title', 100);
  static String? author(String? value) => _required(value, 'Author', 60);
  static String? _required(String? value, String label, int max) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    if (value.runes.length > max) {
      return '$label must be at most $max characters';
    }
    return null;
  }

  static String? rating(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final number = int.tryParse(text);
    if (!RegExp(r'^\d+$').hasMatch(text) ||
        number == null ||
        number < 0 ||
        number > 5) {
      return 'Rating must be a whole number from 0 to 5';
    }
    return null;
  }

  static String? notes(String? value) => (value ?? '').runes.length > 300
      ? 'Notes must be at most 300 characters'
      : null;
}
