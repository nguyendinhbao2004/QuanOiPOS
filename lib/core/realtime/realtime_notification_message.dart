class RealtimeNotificationMessage {
  final String eventName;
  final String title;
  final String content;
  final String audience;
  final Map<String, dynamic> payload;
  final DateTime? occurredAt;

  const RealtimeNotificationMessage({
    required this.eventName,
    required this.title,
    required this.content,
    required this.audience,
    required this.payload,
    required this.occurredAt,
  });

  factory RealtimeNotificationMessage.fromJson(Object? json) {
    if (json is! Map) {
      throw const FormatException('Invalid realtime notification data');
    }
    final map = json.map((key, value) => MapEntry(key.toString(), value));

    return RealtimeNotificationMessage(
      eventName: _stringValue(map['eventName'] ?? map['EventName']),
      title: _stringValue(map['title'] ?? map['Title']),
      content: _stringValue(map['content'] ?? map['Content']),
      audience: _stringValue(map['audience'] ?? map['Audience']),
      payload: _mapValue(map['payload'] ?? map['Payload']),
      occurredAt: _dateValue(map['occurredAt'] ?? map['OccurredAt']),
    );
  }

  static String _stringValue(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static Map<String, dynamic> _mapValue(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }

    return const {};
  }

  static DateTime? _dateValue(Object? value) {
    if (value is DateTime) {
      return value;
    }

    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}
