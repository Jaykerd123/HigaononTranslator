# Facebook MMS TTS Model Investigation: Bisaya (Cebuano) Support

## Summary

✅ **CONFIRMED**: The Facebook MMS TTS model supports Bisaya (Cebuano) language.

## Key Findings

### 1. Language Code for Bisaya/Cebuano
- **ISO 639-3 Code**: `ceb`
- **Language Name**: Cebuano (Bisaya)

### 2. Available Models

#### Option A: Dedicated Cebuano Model (Recommended)
- **Model**: `facebook/mms-tts-ceb`
- **Description**: Specifically trained for Cebuano language
- **Usage**: 
```python
from transformers import VitsModel, AutoTokenizer
import torch

model = VitsModel.from_pretrained("facebook/mms-tts-ceb")
tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-ceb")
text = "some example text in the Cebuano language"
inputs = tokenizer(text, return_tensors="pt")
with torch.no_grad():
    output = model(**inputs).waveform
```

#### Option B: Multilingual Model
- **Model**: `facebook/mms-tts-1b-all`
- **Description**: Supports 1,107 languages including Cebuano
- **Language Code**: `ceb`
- **Usage**: 
```python
from transformers import VitsModel, AutoTokenizer
import torch

model = VitsModel.from_pretrained("facebook/mms-tts-1b-all")
tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-1b-all")

# Set language to Cebuano
tokenizer.set_target_language("ceb")
text = "some example text in the Cebuano language"
inputs = tokenizer(text, return_tensors="pt")
with torch.no_grad():
    output = model(**inputs).waveform
```

### 3. Model Details

#### Technology
- **Architecture**: VITS (Variational Inference with adversarial learning for end-to-end Text-to-Speech)
- **Framework**: 🤗 Transformers (version 4.33+)
- **Backend**: PyTorch

#### Features
- End-to-end speech synthesis
- Supports multiple rhythms from same text (stochastic duration predictor)
- High-fidelity audio generation
- Non-deterministic output (requires fixed seed for reproducibility)

### 4. Installation Requirements

```bash
pip install --upgrade transformers accelerate torch
```

For audio processing:
```bash
pip install scipy  # for saving .wav files
```

### 5. Audio Output

#### Save as WAV file
```python
import scipy
scipy.io.wavfile.write("output.wav", rate=model.config.sampling_rate, data=output)
```

#### Play in Jupyter/Colab
```python
from IPython.display import Audio
Audio(output, rate=model.config.sampling_rate)
```

## Recommendations

1. **Use the dedicated model** (`facebook/mms-tts-ceb`) for better quality and performance
2. The multilingual model (`facebook/mms-tts-1b-all`) is useful if you need to support multiple languages in a single model
3. Both models use the same language code `ceb` for Cebuano
4. Ensure you have transformers version 4.33 or later

## Language Code Verification

The ISO 639-3 code `ceb` is confirmed in the official MMS TTS language list, which includes 1,107 supported languages.

## References

- [Facebook MMS TTS Cebuano Model](https://huggingface.co/facebook/mms-tts-ceb)
- [Facebook MMS TTS Multilingual Model](https://huggingface.co/facebook/mms-tts)
- [MMS Language Coverage Overview](https://dl.fbaipublicfiles.com/mms/misc/language_coverage_mms.html)
- [MMS Paper: Scaling Speech Technology to 1,000+ Languages](https://arxiv.org/abs/2305.13516)
