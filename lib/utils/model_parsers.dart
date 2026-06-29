import 'package:cloud_firestore/cloud_firestore.dart';

/// Tolerant conversions for data read from Firestore.
String readString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

String? readNullableString(dynamic value) {
  if (value == null) return null;
  final result = readString(value).trim();
  return result.isEmpty ? null : result;
}

double readDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? fallback;
  }
  return fallback;
}

int readInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
}

bool readBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}

DateTime readDate(dynamic value, {DateTime? fallback}) {
  final safeFallback = fallback ?? DateTime.now();
  if (value == null) return safeFallback;
  if (value is DateTime) return value.toLocal();
  if (value is Timestamp) return value.toDate().toLocal();
  if (value is int) {
    final milliseconds = value.abs() < 100000000000 ? value * 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds).toLocal();
  }
  if (value is String) {
    return DateTime.tryParse(value.trim())?.toLocal() ?? safeFallback;
  }
  return safeFallback;
}

List<String> readStringList(dynamic value) {
  if (value is! Iterable) return const [];
  return value
      .map(readNullableString)
      .whereType<String>()
      .toList(growable: false);
}

Map<String, dynamic>? readStringMap(dynamic value) {
  if (value is! Map) return null;
  return value.map((key, item) => MapEntry(key.toString(), item));
}
