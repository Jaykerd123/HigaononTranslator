# Implementation Plan - Fix ONNX KV-Cache and Tokenizer

This plan outlines the changes to `OnnxTranslationService.dart` to match the known-good Python implementation for ONNX translation, specifically focusing on name-based KV-cache mapping and strict tokenization.

## User Review Required

> [!IMPORTANT]
> The implementation will switch from positional cache management to name-based cache management. This ensures that `encoder_model.onnx`, `decoder_model.onnx`, and `decoder_with_past_model.onnx` interact correctly even if tensor ordering differs between models.

> [!WARNING]
> The tokenizer will now throw an `Exception` if a token is missing from the vocabulary, rather than defaulting to `1` (UNK). This is required to ensure translation accuracy matches the Python reference.

## Proposed Changes

### [Component Name] HigaononTranslator

#### [MODIFY] [onnx_translation_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/onnx_translation_service.dart)

- **Constants Update**: Verify `_decoderStartTokenId = 56823` and `_eosTokenId = 0`.
- **Strict Tokenization**:
  - Update `translate` method to throw an `Exception` if a token piece from `_tokenizer!.encode(text)` is not found in `_vocab`.
  - Add debug print for tokenizer pieces and input IDs.
- **Name-Based Cache Management**:
  - Replace `List<OrtValue> cache` with `Map<String, OrtValue> decoderCache` and `Map<String, OrtValue> encoderCache`.
  - Implement a helper to convert `present.*` output names to `past_key_values.*` input names.
  - **Initial Decoder Call**:
    - Iterate through `_decoderSession!.outputNames` starting from index 1.
    - Map outputs to `decoderCache` (if name contains `.decoder.`) or `encoderCache` (if name contains `.encoder.`).
  - **Decoding Loop**:
    - Merge `decoderCache` and `encoderCache` into the `loopInputs` for `_decoderWithPastSession!.run`.
    - After `run`, create a `newDecoderCache` from `loopOutputs` (index 1+).
    - Dispose of old `OrtValue`s in `decoderCache` and replace it with `newDecoderCache`.
    - Ensure `encoderCache` is preserved unchanged throughout the loop.
- **Greedy Decoding**:
  - Ensure `_getArgmax` correctly processes the logits from the last sequence step.
- **Debug Logging**:
  - Add prints for "Tokenizer pieces", "Input IDs", "Initial decoder cache count", and "Initial encoder cache count".
- **Memory Management**:
  - Ensure all `OrtValue` tensors are released when no longer needed, especially the caches at the end of translation.

## Verification Plan

### Manual Verification
- Translate the following reference sentences and compare results with Python reference:
  1. `Hello, how are you?` → `Tag-u, kainu kad?`
  2. `Thank you very much.` → `Kabayaan ku Ikaw.`
  3. `I am here.` → `Dini ad.`
  4. `The sun is shining brightly today.` → `Sa adlaw adlaw aldaw kadagway sa aldaw.`
  5. `What is your name?` → `Inu sa ngalan nu?`
- Monitor logs for the new debug prints to verify cache separation and token IDs.
