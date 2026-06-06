Object? readJson(Map<String, dynamic> json, String lowerKey, String pascalKey) {
  return json[lowerKey] ?? json[pascalKey];
}

int intValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? 0;
  }

  return 0;
}

int? nullableIntValue(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

bool boolValue(Object? value) {
  if (value is bool) {
    return value;
  }

  if (value is num) {
    return value != 0;
  }

  if (value is String) {
    return value.toLowerCase() == 'true';
  }

  return false;
}

String stringValue(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }

  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

DateTime? nullableDateTimeValue(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}

List<int> intListValue(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map(intValue).where((id) => id > 0).toList();
}
