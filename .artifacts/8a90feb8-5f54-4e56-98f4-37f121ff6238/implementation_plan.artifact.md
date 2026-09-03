# Add Artificial Delay for Dictionary Translations

The user wants to show the "Translating..." state for a few seconds when a translation is found in the dictionary, to make the processing feel more convincing. This should only apply to dictionary translations, as the NLP model already has inherent latency.

## Proposed Changes

### [Translate Screen Component]

#### [MODIFY] [translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/translate_screen.dart)

- In `_translateVoiceInput`:
    - If a match is found in any dictionary search (Words, Sentences, or second dictionary), insert `await Future.delayed(const Duration(seconds: 2));` before updating the state with the result and calling `_handleTranslationSuccess`.
- In `_translateText`:
    - Similarly, if a match is found, insert `await Future.delayed(const Duration(seconds: 2));` before updating `_textTranslationResult` and calling `_handleTranslationSuccess`.

#### [MODIFY] [text_translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/text_translate_screen.dart)

- In `_translateText`:
    - Insert `await Future.delayed(const Duration(seconds: 2));` before updating `_translationResult` and other success actions when a dictionary match is found.

## Verification Plan

### Manual Verification
- Perform a translation that is known to be in the dictionary (e.g., a simple word like "hello" if it's in there).
- Observe that "Translating..." is displayed for approximately 2 seconds before the result appears.
- Perform a translation that is NOT in the dictionary (forcing the AI model).
- Observe that it still shows "Translating..." but the delay is governed by the model's response time, without an additional artificial 2-second delay (unless the model is extremely fast, which is unlikely).
