import 'package:flutter_test/flutter_test.dart';
import 'package:Higa/screens/services/translation_history_store.dart';

void main() {
  group('TranslationHistoryStore', () {
    test('adds a new entry to the front and keeps the newest item first', () {
      final history = <TranslationHistoryEntry>[
        TranslationHistoryEntry(
          source: 'Hello',
          result: 'Hi',
          type: 'Text',
          timestamp: DateTime(2024, 1, 1),
        ),
      ];

      final entry = TranslationHistoryEntry(
        source: 'Goodbye',
        result: 'Paalam',
        type: 'Voice',
        timestamp: DateTime(2024, 1, 2),
      );

      final updated = TranslationHistoryStore.addEntry(history, entry, maxItems: 3);

      expect(updated.first.source, 'Goodbye');
      expect(updated.first.result, 'Paalam');
      expect(updated.length, 2);
    });

    test('deduplicates identical entries for the same source, result, and type', () {
      final history = <TranslationHistoryEntry>[
        TranslationHistoryEntry(
          source: 'Hello',
          result: 'Hi',
          type: 'Text',
          timestamp: DateTime(2024, 1, 1),
        ),
      ];

      final duplicate = TranslationHistoryEntry(
        source: 'Hello',
        result: 'Hi',
        type: 'Text',
        timestamp: DateTime(2024, 1, 2),
      );

      final updated = TranslationHistoryStore.addEntry(history, duplicate, maxItems: 3);

      expect(updated.length, 1);
      expect(updated.first.result, 'Hi');
    });
  });
}
