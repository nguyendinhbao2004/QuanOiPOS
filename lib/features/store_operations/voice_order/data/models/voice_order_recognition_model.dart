import '../../domain/entities/unmatched_voice_order_item.dart';
import '../../domain/entities/voice_order_item.dart';
import '../../domain/entities/voice_order_recognition.dart';

class VoiceOrderRecognitionModel {
  final String transcript;
  final List<VoiceOrderItemModel> items;
  final List<UnmatchedVoiceOrderItemModel> unmatchedItems;
  final int estimatedTotal;

  const VoiceOrderRecognitionModel({
    required this.transcript,
    required this.items,
    required this.unmatchedItems,
    required this.estimatedTotal,
  });

  factory VoiceOrderRecognitionModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice order recognition data');
    }

    return VoiceOrderRecognitionModel(
      transcript: _stringValue(json['transcript'] ?? json['Transcript']),
      items: VoiceOrderItemModel.listFromJson(json['items'] ?? json['Items']),
      unmatchedItems: UnmatchedVoiceOrderItemModel.listFromJson(
        json['unmatchedItems'] ?? json['UnmatchedItems'],
      ),
      estimatedTotal: _intValue(
        json['estimatedTotal'] ?? json['EstimatedTotal'],
      ),
    );
  }

  factory VoiceOrderRecognitionModel.fromApiResponse(Object? json) {
    if (json is! Map<String, dynamic>) {
      return VoiceOrderRecognitionModel.fromJson(json);
    }

    final successValue =
        json['success'] ??
        json['Success'] ??
        json['succeeded'] ??
        json['Succeeded'];
    if (successValue == false) {
      _throwRequestFailure(json);
    }

    return VoiceOrderRecognitionModel.fromJson(
      json['data'] ?? json['Data'] ?? json,
    );
  }

  VoiceOrderRecognition toEntity() {
    return VoiceOrderRecognition(
      transcript: transcript,
      items: items.map((item) => item.toEntity()).toList(),
      unmatchedItems: unmatchedItems.map((item) => item.toEntity()).toList(),
      estimatedTotal: estimatedTotal,
    );
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }

    return 0;
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }

  static Never _throwRequestFailure(Map<String, dynamic> json) {
    final errors = json['errors'] ?? json['Errors'];
    if (errors is List && errors.isNotEmpty) {
      throw FormatException(errors.first.toString());
    }

    final message = json['message'] ?? json['Message'];
    if (message != null && message.toString().trim().isNotEmpty) {
      throw FormatException(message.toString());
    }

    throw const FormatException('Invalid voice order recognition response');
  }
}

class VoiceOrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final int unitPrice;
  final int totalPrice;
  final double confidence;

  const VoiceOrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.confidence,
  });

  factory VoiceOrderItemModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid voice order item data');
    }

    return VoiceOrderItemModel(
      productId: _intValue(json['productId'] ?? json['ProductId']),
      productName: _stringValue(json['productName'] ?? json['ProductName']),
      quantity: _intValue(json['quantity'] ?? json['Quantity']),
      unitPrice: _intValue(json['unitPrice'] ?? json['UnitPrice']),
      totalPrice: _intValue(json['totalPrice'] ?? json['TotalPrice']),
      confidence: _doubleValue(json['confidence'] ?? json['Confidence']),
    );
  }

  static List<VoiceOrderItemModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(VoiceOrderItemModel.fromJson).toList();
    }

    throw const FormatException('Invalid voice order item list data');
  }

  VoiceOrderItem toEntity() {
    return VoiceOrderItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      confidence: confidence,
    );
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? 0;
    }

    return 0;
  }

  static double _doubleValue(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _stringValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Sản phẩm' : text;
  }
}

class UnmatchedVoiceOrderItemModel {
  final String rawText;
  final int quantity;
  final String reason;

  const UnmatchedVoiceOrderItemModel({
    required this.rawText,
    required this.quantity,
    required this.reason,
  });

  factory UnmatchedVoiceOrderItemModel.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Invalid unmatched voice order item data');
    }

    return UnmatchedVoiceOrderItemModel(
      rawText: _stringValue(json['rawText'] ?? json['RawText']),
      quantity: _intValue(json['quantity'] ?? json['Quantity']),
      reason: _stringValue(json['reason'] ?? json['Reason']),
    );
  }

  static List<UnmatchedVoiceOrderItemModel> listFromJson(Object? json) {
    if (json == null) {
      return const [];
    }

    if (json is List) {
      return json.map(UnmatchedVoiceOrderItemModel.fromJson).toList();
    }

    throw const FormatException('Invalid unmatched voice order item list data');
  }

  UnmatchedVoiceOrderItem toEntity() {
    return UnmatchedVoiceOrderItem(
      rawText: rawText,
      quantity: quantity,
      reason: reason,
    );
  }

  static int _intValue(Object? value) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _stringValue(Object? value) {
    return value?.toString().trim() ?? '';
  }
}
