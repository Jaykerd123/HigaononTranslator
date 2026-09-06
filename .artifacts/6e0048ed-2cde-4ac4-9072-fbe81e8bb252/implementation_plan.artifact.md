# Implementation Plan - Debugging "asa ka" Translation Issue

The user reports that the app displays "asa ka" for the input "Where are you going.", while a minimal ONNX test and Python reference produce the correct Higaonon translation "Hindu ka duun nu.".

## User Review Required

> [!IMPORTANT]
> The issue is caused by a phrase match in `dictionary-second.json` that takes precedence over the ONNX model. "asa ka" is Cebuano/Bisaya, not Higaonon, but it is currently mapped to "where are you going" in the secondary dictionary.

## Proposed Research & Debugging

### 1. Identify Source of "asa ka"
- **Findings:** `assets/dictionary-second.json` contains a mapping for "where are you going" to "asa ka" (Line 30895).
- **Execution Flow:** In both `lib/screens/translate_screen.dart` and `lib/screens/text_translate_screen.dart`, the `_translateText` function checks `dictionary-second.json` (Step 3) **before** it calls the ONNX model (Step 4).

### 2. Verify Stale Model File Issue
- **Findings:** `OnnxTranslationService._loadSession` only copies models from assets if the local file in `ApplicationDocumentsDirectory` does not exist. If the models in the app assets were updated, existing installations would still use the old versions.

### 3. Debug Logging
I will add temporary logging to `lib/screens/translate_screen.dart` and `lib/screens/text_translate_screen.dart` to confirm the exact path taken for the translation.

## Proposed Changes

### [MODIFY] [translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/translate_screen.dart) and [text_translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/text_translate_screen.dart)
- Add diagnostic prints to each step of `_translateText`.
- Print `TRANSLATION SOURCE INPUT`, `DICTIONARY MATCH`, `ONNX RESULT`, and `FINAL UI RESULT`.

### [MODIFY] [onnx_translation_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/onnx_translation_service.dart)
- Add a mechanism to force refresh of ONNX models if they are updated in assets. A simple approach is to check for a version file or always overwrite during development/initial testing.

## Verification Plan

### Manual Verification
- Enter "Where are you going." in the app and observe logs.
- Confirm that the Step 3 (dictionary-second.json) match is found and returns "asa ka".
- Confirm that Step 4 (ONNX) is skipped.
- Fix `dictionary-second.json` or adjust priority and verify "Hindu ka duun nu." is produced.
