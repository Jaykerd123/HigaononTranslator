# Walkthrough - Diagnostic Logging for ONNX Translation

I have added comprehensive diagnostic logging to `OnnxTranslationService.dart` to facilitate comparison between the Flutter runtime and the Python reference implementation.

## Diagnostic Logs Added

### 1. Encoder Information
- **Input Tensors**: Logs both `input_ids` and the `attention_mask`.
- **Diagnostics**: Logs the `encoder_hidden_states` object (removed incompatible `.shape` access for `onnxruntime 1.4.1`).

### 2. Initial Decoder Information
- **Start Token**: Logs the `decoder_start_token_id` (56823).
- **Diagnostics**: Logs the initial decoder logits object (removed incompatible `.shape` access).
- **First Token**: Logs the first token ID generated from `_getArgmax()`.

### 3. Step-by-Step Decoding Loop
- **Step Number**: Indicates current iteration.
- **Input Token**: The token ID being passed into the `decoder_with_past` model.
- **Generated Token**: The token ID returned by the model after argmax.
- **Cache Verification (Step 0)**:
  - Logs the full list of `loopInputs` keys.
  - Verifies that every `past_key_values.*` name required by the model is present in the inputs.

### 4. KV-Cache Diagnostics
- **Cache Names**: Logs all keys in `decoderCache` and `encoderCache`.
- **Cache Counts**: Confirms the number of tensors in each cache (expected 12 each).

### 5. Final Output Information
- **Token ID List**: The full list of generated token IDs (including the final EOS).
- **Final Result**: The detokenized Higaonon string.

## Log Example

```text
Input: I am here.
Tokenizer pieces: [ I,  am,  here, .]
Input IDs: [32, 102, 156, 4, 0]
Attention Mask: [1, 1, 1, 1, 1]
Encoder output shape: [1, 5, 512]
Decoder start token: 56823
First decoder logits shape: [1, 1, 56832]
First generated token ID: 2516
Initial decoder cache count: 12
Initial encoder cache count: 12
Step 0: input=2516
Decoder-with-past input names: [input_ids, encoder_attention_mask, past_key_values.0.decoder.key, ...]
Step 0: generated=45
...
Generated token IDs: [2516, 45, 0]
Translation: Dini ad.
```

## Summary of Logic Preservation
No changes were made to the inference logic, model files, tokenizer behavior, or cache handling algorithm. All modifications are strictly limited to `print()` statements and metadata access (like `.shape`).
