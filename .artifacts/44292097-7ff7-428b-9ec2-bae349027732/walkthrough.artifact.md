# Offline ONNX Translation Integration Walkthrough

I have successfully integrated the offline INT8 quantized MarianMT translation model into your Flutter app. The app now attempts to translate English to Higaonon locally using `onnxruntime` before falling back to the network.

## Changes Made

### 1. Dependency Update
*   Added `dart_sentencepiece_tokenizer: ^1.3.2` to `pubspec.yaml`. This is a pure-Dart implementation of SentencePiece that ensures compatibility with your `source.spm` model.

### 2. New Translation Service
*   **[OnnxTranslationService](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/onnx_translation_service.dart)**:
    *   **Lazy Initialization**: Models are loaded and sessions created only when the first translation is requested.
    *   **Asset Management**: ONNX models and SentencePiece files are automatically copied from assets to the local app directory for compatibility with `onnxruntime`.
    *   **Full Pipeline**: Implemented a complete MarianMT inference pipeline:
        1.  **Tokenization**: English text -> Token IDs.
        2.  **Encoder**: IDs -> Hidden States.
        3.  **Initial Decoder**: Hidden States -> First set of Logits + 24 KV Cache tensors.
        4.  **Autoregressive Loop**: Greedy decoding using `decoder_with_past_model.onnx`.
        5.  **KV Cache Management**: Fixed the encoder cache and updated the rolling decoder cache as required by the MarianMT architecture.
        6.  **Detokenization**: Token IDs -> Higaonon string.

### 3. UI Integration
*   **[text_translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/text_translate_screen.dart)** and **[translate_screen.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/translate_screen.dart)**:
    *   Updated the translation logic to try `OnnxTranslationService` immediately after the dictionary lookup fails.
    *   The existing `TranslationFallbackService` is retained as a final fallback if the offline model fails or isn't initialized.
    *   Successfully maintained all existing TTS, history, and analytics integrations.

## Verification Results

### Tokenizer Validation
> [!NOTE]
> I verified the tokenizer using a standalone script. For the input **"I love you."**, the tokenizer produced the IDs **`[32, 280, 39, 4, 0]`**, which exactly matches your Python reference implementation.

### Implementation Correctness
*   The service correctly identifies special tokens: EOS (`0`) and Decoder Start (`56823`).
*   The greedy decoding loop stops at EOS or after 200 tokens.
*   The KV cache handling follows the specific rule: `encoderCache` remains fixed from the initial decoder call, while `decoderCache` is updated at every step.

## Next Steps
1.  **Android Test**: Run the app on an Android device to verify the model loading and inference performance.
2.  **Offline Check**: Disable Wi-Fi/Data and confirm translation still works.
3.  **Cleanup**: Once verified, we can eventually remove the `TranslationFallbackService` and the FastAPI-related files if you desire a 100% offline app.

render_diffs(file:///C:/Users/yuihi/HigaononTranslator/pubspec.yaml)
render_diffs(file:///C:/Users/yuihi/HigaononTranslator/lib/screens/text_translate_screen.dart)
render_diffs(file:///C:/Users/yuihi/HigaononTranslator/lib/screens/translate_screen.dart)
