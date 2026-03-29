from fastapi import FastAPI
from pydantic import BaseModel
from transformers import VitsModel, AutoTokenizer, MarianMTModel, MarianTokenizer
import torch
import soundfile as sf
import io
import os
import multiprocessing
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Maximize processor usage for AI TTS Model
num_cores = multiprocessing.cpu_count()
torch.set_num_threads(num_cores)
print(f"Set PyTorch CPU threads to {num_cores} to speed up TTS generation.")

# TTS Model loading
try:
    tts_model = VitsModel.from_pretrained("facebook/mms-tts-ceb")
    tts_tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-ceb")
except Exception as e:
    print("Could not load TTS model:", e)

# Translation Model loading
try:
    translation_dir = os.path.join(os.path.dirname(__file__), "assets", "nlp", "model")
    translation_tokenizer = MarianTokenizer.from_pretrained(translation_dir)
    translation_model = MarianMTModel.from_pretrained(translation_dir)
except Exception as e:
    print("Could not load translation model:", e)

class TextRequest(BaseModel):
    text: str

import hashlib

# Simple ultra-fast cache for TTS generated audio 
tts_cache = {}

@app.post("/tts")
def generate_tts(req: TextRequest):
    # Meta MMS-TTS strictly requires lowercase. Uppercase letters turn into <unk>!
    clean_text = req.text.lower()
    
    # Optional phonetic hotfixes for the AI's "English" accent. 
    # Since MMS is a multilingual model, it often mispronounces "aw" as the english "ow".
    # Converting 'aw' to 'au' helps it pronounce it with a cleaner Bisaya vowel.
    clean_text = clean_text.replace("aw ", "au ").replace("aw", "au")

    # 1. Check if we already generated the audio for this exact text before
    text_hash = hashlib.md5(clean_text.encode('utf-8')).hexdigest()
    if text_hash in tts_cache:
        # Return instantly from server memory
        return StreamingResponse(io.BytesIO(tts_cache[text_hash]), media_type="audio/wav")

    # 2. If new text, run the heavy AI generation
    inputs = tts_tokenizer(clean_text, return_tensors="pt")
    with torch.no_grad():
        output = tts_model(**inputs).waveform
    audio = output.squeeze().cpu().numpy()
    
    buffer = io.BytesIO()
    sf.write(buffer, audio, 16000, format="WAV")
    
    # 3. Store the finished WAV bytes into the dictionary cache
    audio_bytes = buffer.getvalue()
    tts_cache[text_hash] = audio_bytes
    
    buffer.seek(0)
    return StreamingResponse(buffer, media_type="audio/wav")

@app.post("/translate")
def translate_text(req: TextRequest):
    inputs = translation_tokenizer(req.text, return_tensors="pt", padding=True)
    with torch.no_grad():
        translated = translation_model.generate(**inputs)
    result = translation_tokenizer.batch_decode(translated, skip_special_tokens=True)
    return {"translation": result[0]}