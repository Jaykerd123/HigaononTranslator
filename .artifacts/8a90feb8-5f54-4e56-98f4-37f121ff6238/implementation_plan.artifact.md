# Implementation Plan - Frequently Requested Translations

Add a "Frequently Requested Translations" section to the Menu screen that displays random English-to-Higaonon words. These words will change daily, similar to the "Word of the Day" feature on the Home screen.

## User Review Required

> [!NOTE]
> For now, "frequently requested" will be simulated by picking 3 random words from the dictionary daily. In the future, this could be tied to actual usage statistics if a backend service tracks popular searches.

## Proposed Changes

### Learning Feature

#### [MODIFY] [menu_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/menu_screen.dart)

- Add imports for `dart:convert`, `dart:math`, `Word` model, and `WordDetailScreen`.
- Add `List<Word> _frequentTranslations = []` to `_MenuScreenState`.
- Implement `_loadFrequentTranslations()` to fetch 3 random words from `assets/dictionary.json` using a daily seed.
- Call `_loadFrequentTranslations()` in `initState()`.
- Update the `build` method to dynamically generate `_MenuData` items for the "Frequently Requested Translations" section based on the loaded words.
- Each item will navigate to `WordDetailScreen` for the respective word.

## Verification Plan

### Automated Tests
- N/A (UI focused change, but will ensure code compiles and runs).

### Manual Verification
- Open the Menu screen.
- Verify that 3 words are displayed under "Frequently Requested Translations".
- Verify that tapping a word navigates to its detail screen.
- Verify that the words remain the same throughout the day and change the next day (can be simulated by changing device date or modifying the seed logic temporarily).
