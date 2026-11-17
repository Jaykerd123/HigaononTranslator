import 'package:flutter_test/flutter_test.dart';
import 'package:Higa/screens/services/translation_stats_service.dart';

void main() {
  group('TranslationStatsService.calculateDayStreak', () {
    final today = DateTime(2026, 11, 17);

    test('keeps the same streak for another translation that day', () {
      expect(
        TranslationStatsService.calculateDayStreak(
          currentStreak: 4,
          lastTranslationDate: '2026-11-17',
          activityDate: today,
        ),
        4,
      );
    });

    test('increases the streak for activity on the next day', () {
      expect(
        TranslationStatsService.calculateDayStreak(
          currentStreak: 4,
          lastTranslationDate: '2026-11-16',
          activityDate: today,
        ),
        5,
      );
    });

    test(
      'starts a new streak after a missed day or without prior activity',
      () {
        expect(
          TranslationStatsService.calculateDayStreak(
            currentStreak: 4,
            lastTranslationDate: '2026-11-15',
            activityDate: today,
          ),
          1,
        );
        expect(
          TranslationStatsService.calculateDayStreak(
            currentStreak: 0,
            lastTranslationDate: null,
            activityDate: today,
          ),
          1,
        );
      },
    );
  });
}
