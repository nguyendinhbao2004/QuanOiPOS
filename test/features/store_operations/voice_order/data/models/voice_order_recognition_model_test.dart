import 'package:flutter_test/flutter_test.dart';
import 'package:quan_oi/features/store_operations/voice_order/data/models/voice_order_recognition_model.dart';

void main() {
  test('parses raw voice order response', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'storeId': 8,
      'tableName': 8,
      'items': [
        {'productName': 'mi hai san', 'quantity': 1, 'note': 'cay'},
        {'productName': 'lau bo', 'quantity': 1, 'note': null},
      ],
      'missingFields': [],
    });

    expect(model.storeId, 8);
    expect(model.tableName, '8');
    expect(model.missingFields, isEmpty);
    expect(model.items, hasLength(2));
    expect(model.items.first.productName, 'mi hai san');
    expect(model.items.first.note, 'cay');
    expect(model.items.last.note, isNull);
  });

  test('parses wrapped orderJson response', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'filename': 'order.wav',
      'text': 'ban 8 mi hai san cay',
      'orderValidation': {
        'succeeded': true,
        'message': 'OK',
        'errors': [],
        'data': {
          'orderJson': {
            'storeId': 8,
            'tableName': '8',
            'items': [
              {'productName': 'mi hai san', 'quantity': 1, 'note': 'cay'},
            ],
            'missingFields': [],
          },
        },
      },
    });

    expect(model.storeId, 8);
    expect(model.tableName, '8');
    expect(model.transcript, 'ban 8 mi hai san cay');
    expect(model.items.single.note, 'cay');
  });

  test('parses direct orderValidation orderJson with variants and toppings', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'filename': 'voice-order.wav',
      'text':
          'bàn chín gọi một phần chân gà sốt thái size nhỏ một lon cô ca cô la',
      'orderValidation': {
        'succeeded': false,
        'message': 'Order voice chưa hợp lệ.',
        'orderJson': {
          'storeId': 5,
          'table': null,
          'items': [
            {
              'productId': 23,
              'productName': 'CHÂN GÀ RÚT XƯƠNG SỐT THÁI',
              'variantId': 36,
              'variantName': 'nhỏ',
              'quantity': 1,
              'note': null,
              'toppings': [
                {'id': 201, 'name': 'Mè rang', 'quantity': 2},
              ],
              'available': true,
              'message': null,
            },
          ],
          'missingFields': ['table'],
        },
        'errors': ["Không tìm thấy bàn 'Bàn 9'."],
      },
    });

    expect(model.filename, 'voice-order.wav');
    expect(model.storeId, 5);
    expect(model.validationSucceeded, isFalse);
    expect(model.table, isNull);
    expect(model.missingFields, ['table']);
    expect(model.errors.single, contains('Bàn 9'));
    expect(model.items.single.productId, 23);
    expect(model.items.single.variantId, 36);
    expect(model.items.single.variantName, 'nhỏ');
    expect(model.items.single.toppings.single.name, 'Mè rang');
    expect(model.items.single.toppings.single.quantity, 2);
  });

  test('parses voice service success response with validated items', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'filename': 'order.wav',
      'text': 'ban 3 goi 2 ca phe sua',
      'orderValidation': {
        'succeeded': true,
        'message': 'Order voice hop le.',
        'errors': [],
        'data': {
          'rawText': 'ban 3 goi 2 ca phe sua',
          'table': {'id': 3, 'name': 'Ban 3', 'status': 'Available'},
          'items': [
            {
              'productId': 10,
              'name': 'Ca phe sua',
              'quantity': 2,
              'available': true,
              'message': null,
            },
          ],
        },
      },
    });

    expect(model.filename, 'order.wav');
    expect(model.transcript, 'ban 3 goi 2 ca phe sua');
    expect(model.validationSucceeded, isTrue);
    expect(model.table?.name, 'Ban 3');
    expect(model.items.single.productId, 10);
    expect(model.items.single.productName, 'Ca phe sua');
    expect(model.items.single.available, isTrue);
    expect(model.unmatchedItems, isEmpty);
  });

  test('parses validation failure with errors and unavailable item', () {
    final model = VoiceOrderRecognitionModel.fromApiResponse({
      'filename': 'order.wav',
      'text': 'ban 3 goi 2 tra dao',
      'orderValidation': {
        'succeeded': false,
        'message': 'Order voice chua hop le.',
        'errors': ["Khong tim thay san pham 'tra dao'."],
        'data': {
          'rawText': 'ban 3 goi 2 tra dao',
          'table': {'id': 3, 'name': 'Ban 3', 'status': 'Available'},
          'items': [
            {
              'productId': null,
              'name': 'tra dao',
              'quantity': 2,
              'available': false,
              'message': 'San pham khong ton tai.',
            },
          ],
        },
      },
    });

    expect(model.validationSucceeded, isFalse);
    expect(model.errors.single, contains('tra dao'));
    expect(model.items.single.productId, isNull);
    expect(model.items.single.available, isFalse);
    expect(model.unmatchedItems.single.rawText, 'tra dao');
    expect(model.unmatchedItems.single.reason, 'San pham khong ton tai.');
  });

  test('throws when transport envelope reports failure', () {
    expect(
      () => VoiceOrderRecognitionModel.fromApiResponse({
        'success': false,
        'message': 'Audio file is required',
      }),
      throwsFormatException,
    );
  });
}
