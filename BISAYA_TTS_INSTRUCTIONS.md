# Bisaya (Cebuano) TTS Audio Generation Instructions

## Overview

This guide demonstrates how to generate Bisaya (Cebuano) audio using the Facebook MMS TTS model `facebook/mms-tts-1b-all`.

## ✅ Confirmed Support

- **Language**: Bisaya (Cebuano)
- **ISO 639-3 Code**: `ceb`
- **Model**: `facebook/mms-tts-1b-all` (multilingual)
- **Alternative**: `facebook/mms-tts-ceb` (dedicated Cebuano model)

## 🚀 Quick Start

### 1. Install Dependencies

```bash
pip install torch transformers scipy
```

### 2. Run the Demo Script

```bash
python bisaya_tts_demo.py
```

## 📝 Example Code

### Basic Usage

```python
import torch
from transformers import VitsModel, AutoTokenizer
import scipy.io.wavfile

# Load the multilingual model
model = VitsModel.from_pretrained("facebook/mms-tts-1b-all")
tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-1b-all")

# Set language to Cebuano (Bisaya)
tokenizer.set_target_language("ceb")

# Bisaya text to synthesize
text = "Kumusta ka? Maayong adlaw."

# Generate audio
inputs = tokenizer(text, return_tensors="pt")
with torch.no_grad():
    output = model(**inputs).waveform

# Save as WAV file
scipy.io.wavfile.write("bisaya_audio.wav", rate=model.config.sampling_rate, data=output.numpy().flatten())
```

### Advanced Usage with Multiple Phrases

```python
bisaya_phrases = [
    "Kumusta ka?",  # How are you?
    "Maayong adlaw.",  # Good day
    "Salamat kaayo.",  # Thank you very much
    "Unsa imong ngalan?",  # What is your name?
    "Nalingaw ko sa pagpangita sa imo.",  # I was happy looking for you
]

for i, phrase in enumerate(bisaya_phrases):
    inputs = tokenizer(phrase, return_tensors="pt")
    with torch.no_grad():
        output = model(**inputs).waveform
    
    filename = f"bisaya_{i+1:02d}.wav"
    scipy.io.wavfile.write(filename, rate=model.config.sampling_rate, data=output.numpy().flatten())
    print(f"Generated: {filename}")
```

## 🎵 Test Phrases

The demo script includes these Bisaya phrases:

| Bisaya | English |
|--------|---------|
| Kumusta ka? | How are you? |
| Maayong adlaw. | Good day. |
| Salamat kaayo. | Thank you very much. |
| Unsa imong ngalan? | What is your name? |
| Nalingaw ko sa pagpangita sa imo. | I was happy looking for you. |
| Gusto ko mogamit sa Bisaya nga pinulongan. | I want to use the Bisaya language. |
| Kining awtoromobil kay daghan kwarta. | This car is expensive. |
| Mangaon kita karon. | Let's eat now. |

## 🔧 Troubleshooting

### Common Issues

1. **ModuleNotFoundError**: Install the required packages
   ```bash
   pip install torch transformers scipy
   ```

2. **CUDA/GPU Issues**: The model will automatically use CPU if GPU is not available

3. **Memory Issues**: The model requires ~2GB of RAM for loading

4. **Internet Connection**: First run requires downloading the model (~1GB)

### Alternative Models

If the multilingual model has issues, try the dedicated Cebuano model:

```python
# Dedicated Cebuano model (better quality)
model = VitsModel.from_pretrained("facebook/mms-tts-ceb")
tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-ceb")
# No need to set language - it's Cebuano-only
```

## 📊 Model Specifications

- **Architecture**: VITS (Variational Inference with adversarial learning)
- **Sampling Rate**: 16,000 Hz
- **Model Size**: ~1GB
- **Languages Supported**: 1,107 (multilingual model)
- **Framework**: 🤗 Transformers (v4.33+)
- **Backend**: PyTorch

## 🎯 Expected Output

When you run the demo successfully, you should see:

```
🎤 Bisaya Text-to-Speech Demo
==================================================
📥 Loading Facebook MMS TTS model...
✅ Model loaded successfully!
📊 Model sampling rate: 16000 Hz

🌍 Setting language to Cebuano (Bisaya)...
✅ Language set to 'ceb' (Cebuano/Bisaya)

🎵 Generating audio for 8 Bisaya phrases...

📝 Phrase 1:
   Bisaya: 'Kumusta ka?'
   English: 'How are you?'
   ✅ Audio saved: bisaya_01_Kumusta_ka.wav
   ⏱️  Duration: 1.23 seconds
...
```

## 📁 Output Files

The generated audio files will be saved in the `bisaya_audio_output/` directory:

- `bisaya_01_Kumusta_ka.wav`
- `bisaya_02_Maayong_adlaw.wav`
- `bisaya_03_Salamat_kaayo.wav`
- etc.

## 🎧 Playing the Audio

You can play the generated WAV files using:
- Windows Media Player
- VLC Media Player
- Python: `import os; os.startfile("bisaya_01_Kumusta_ka.wav")`
- Jupyter: `from IPython.display import Audio; Audio("bisaya_01_Kumusta_ka.wav")`

## 📚 References

- [Facebook MMS TTS Cebuano Model](https://huggingface.co/facebook/mms-tts-ceb)
- [Facebook MMS TTS Multilingual Model](https://huggingface.co/facebook/mms-tts-1b-all)
- [MMS Paper: Scaling Speech Technology to 1,000+ Languages](https://arxiv.org/abs/2305.13516)

## 🎉 Success Criteria

✅ **Model loads successfully**  
✅ **Language set to 'ceb' (Cebuano)**  
✅ **Bisaya text tokenized properly**  
✅ **Audio waveform generated**  
✅ **WAV files saved with correct format**  
✅ **Audio playback works**  

If all these steps work, the Bisaya TTS implementation is successful!
