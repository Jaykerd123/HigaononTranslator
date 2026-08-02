class TranslationHistoryEntry {
  final String source;
  final String result;
  final String type;
  final DateTime timestamp;

  const TranslationHistoryEntry({
    required this.source,
    required this.result,
    required this.type,
    required this.timestamp,
  });
}

class TranslationHistoryStore {
  static List<TranslationHistoryEntry> addEntry(
    List<TranslationHistoryEntry> history,
    TranslationHistoryEntry entry, {
    int maxItems = 20,
  }) {
    final updatedHistory = List<TranslationHistoryEntry>.from(history);

    updatedHistory.removeWhere((existing) =>
        existing.source.trim().toLowerCase() == entry.source.trim().toLowerCase() &&
        existing.result.trim().toLowerCase() == entry.result.trim().toLowerCase() &&
        existing.type == entry.type);

    updatedHistory.insert(0, entry);

    if (updatedHistory.length > maxItems) {
      updatedHistory.removeRange(maxItems, updatedHistory.length);
    }

    return updatedHistory;
  }
}
