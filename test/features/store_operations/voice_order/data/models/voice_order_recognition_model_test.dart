import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/voice_order/data/models/voice_order_recognition_model.dart';

void main() {
  test('parses backend success response with matched items', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'success': true,
      'message': 'Voice order recognized successfully',
      'data': {
        'transcript':
            'Cho tôi 2 ly trà sữa trân châu đường đen và 1 bánh mì bò',
        'items': [
          {
            'productId': 1,
            'productName': 'Trà sữa trân châu đường đen',
            'quantity': 2,
            'unitPrice': 45000,
            'totalPrice': 90000,
            'confidence': 0.92,
          },
          {
            'productId': 5,
            'productName': 'Bánh mì bò',
            'quantity': 1,
            'unitPrice': 30000,
            'totalPrice': 30000,
            'confidence': 0.88,
          },
        ],
        'unmatchedItems': [],
        'estimatedTotal': 120000,
      },
    });

    expect(model.transcript, contains('trà sữa'));
    expect(model.items, hasLength(2));
    expect(model.items.first.productId, 1);
    expect(model.items.first.quantity, 2);
    expect(model.items.first.totalPrice, 90000);
    expect(model.unmatchedItems, isEmpty);
    expect(model.estimatedTotal, 120000);
  });

  test('parses app envelope response with unmatched items', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'succeeded': true,
      'message': 'Some items could not be matched',
      'data': {
        'transcript': 'Cho tôi 2 ly trà đào và 1 bánh mì bò đặc biệt',
        'items': [
          {
            'productId': 5,
            'productName': 'Bánh mì bò',
            'quantity': 1,
            'unitPrice': 30000,
            'totalPrice': 30000,
            'confidence': 0.75,
          },
        ],
        'unmatchedItems': [
          {
            'rawText': 'trà đào',
            'quantity': 2,
            'reason': 'Product not found in database',
          },
        ],
        'estimatedTotal': 30000,
      },
    });

    expect(model.items.single.productName, 'Bánh mì bò');
    expect(model.unmatchedItems.single.rawText, 'trà đào');
    expect(model.unmatchedItems.single.quantity, 2);
    expect(model.estimatedTotal, 30000);
  });

  test('throws when response reports failure', () {
    expect(
      () => VoiceOrderRecognitionModel.fromApiResponse({
        'success': false,
        'message': 'Audio file is required',
      }),
      throwsFormatException,
    );
  });
}
