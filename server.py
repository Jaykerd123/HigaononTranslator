from fastapi import FastAPI
from pydantic import BaseModel
from transformers import VitsModel, AutoTokenizer, MarianMTModel, MarianTokenizer
import torch
import soundfile as sf
import io
import os
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

@app.post("/tts")
def generate_tts(req: TextRequest):
    inputs = tts_tokenizer(req.text, return_tensors="pt")
    with torch.no_grad():
        output = tts_model(**inputs).waveform
    audio = output.squeeze().cpu().numpy()
    buffer = io.BytesIO()
    sf.write(buffer, audio, 16000, format="WAV")
    buffer.seek(0)
    return StreamingResponse(buffer, media_type="audio/wav")

@app.post("/translate")
def translate_text(req: TextRequest):
    inputs = translation_tokenizer(req.text, return_tensors="pt", padding=True)
    with torch.no_grad():
        translated = translation_model.generate(**inputs)
    result = translation_tokenizer.batch_decode(translated, skip_special_tokens=True)
    return {"translation": result[0]}