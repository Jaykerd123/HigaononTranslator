# Implementation Plan - Fix and Unify Translation Flow

The user reports that the previous translation implementation was broken, specifically that `dictionary.json` is being ignored, and `dictionary-second.json` keys were swapped. The user wants a cleaner conditional approach that reuses existing functionality.

## User Review Required

> [!IMPORTANT]
> I will unify the translation logic into a single private helper method in each screen. This method will check:
> 1. `dictionary.json` (Word match)
> 2. `dictionary.json` (Sentence match)
> 3. `dictionary-second.json` (Match)
> 4. AI/Fallback Model
>
> I will also fix the mapping for `dictionary-second.json`:
> - `example_english` -> mapped to English
> - `example_higaonon` -> mapped to Higaonon

## Proposed Changes

### [Models]

#### [MODIFY] [sentence_match.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/models/sentence_match.dart)
Fix the `fromJson` mapping to match the swapped keys.
```dart
  factory SentenceMatch.fromJson(Map<String, dynamic> json) {
    return SentenceMatch(
      english: json['example_english'] ?? '', // Corrected: example_english is English
      higaonon: json['example_higaonon'] ?? '', // Corrected: example_higaonon is Higaonon
    );
  }
```

### [Screens]

#### [MODIFY] [translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/translate_screen.dart)
1. **Improve Loading:** Separate the loading of `dictionary.json` and `dictionary-second.json` so one failing doesn't break the other.
2. **Refactor Translation:** Create a unified `_performTranslation(String input)` method that handles the tiered search and fallback.
3. **Simplify Voice/Text Handlers:** Update `_translateVoiceInput` and `_translateText` to call the unified method.

#### [MODIFY] [text_translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/text_translate_screen.dart)
Apply similar refactoring as `TranslateScreen` to ensure consistency.

## Verification Plan

### Manual Verification
1. **Test `dictionary.json`:** Search for "Husband" (English) or "Bana" (Higaonon) to ensure the primary dictionary is working.
2. **Test `dictionary-second.json`:** Search for "stomach organ" and verify it returns "tungol" (from the new mapping).
3. **Test AI Fallback:** Search for a random sentence and verify it uses the fallback service.
4. **History Check:** Verify that matches from BOTH dictionaries are saved to the translation history.
