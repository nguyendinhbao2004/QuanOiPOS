import 'unmatched_voice_order_item.dart';
import 'voice_order_item.dart';

class VoiceOrderRecognition {
  final String transcript;
  final List<VoiceOrderItem> items;
  final List<UnmatchedVoiceOrderItem> unmatchedItems;
  final int estimatedTotal;

  const VoiceOrderRecognition({
    required this.transcript,
    required this.items,
    required this.unmatchedItems,
    required this.estimatedTotal,
  });

  bool get hasRecognizedItems => items.isNotEmpty;
}
