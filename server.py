import logging
import hashlib
import io
import os
import multiprocessing
import torch
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from transformers import MarianMTModel, MarianTokenizer
from fastapi.responses import StreamingResponse
from fastapi.middleware.cors import CORSMiddleware
from gradio_client import Client

# ============================================================
# LOGGING CONFIGURATION
# ============================================================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("HigaononBackend")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# HEALTH CHECK
# ============================================================
@app.get("/health")
def health_check():
    return {"status": "ok"}

# ============================================================
# CPU SETTINGS
# ============================================================
num_cores = multiprocessing.cpu_count()
torch.set_num_threads(num_cores)
logger.info(f"Set PyTorch CPU threads to {num_cores}.")

# ============================================================
# HUGGING FACE TTS SPACE
# ============================================================
HF_TTS_SPACE = "Jaykerd/higaonon-tts"
hf_tts_client = None

def get_hf_client():
    global hf_tts_client
    if hf_tts_client is None:
        try:
            logger.info(f"Connecting to Hugging Face TTS Space: {HF_TTS_SPACE}...")
            hf_tts_client = Client(HF_TTS_SPACE)
            logger.info("✓ Connected to Hugging Face TTS Space successfully.")
        except Exception as e:
            logger.error(f"FAILED to connect to Hugging Face TTS Space: {e}", exc_info=True)
            hf_tts_client = None
    return hf_tts_client

# ============================================================
# TRANSLATION MODEL
# ============================================================
try:
    translation_dir = os.path.join(
        os.path.dirname(__file__),
        "assets",
        "nlp",
        "model"
    )
    logger.info(f"Loading translation model from: {translation_dir}")
    translation_tokenizer = MarianTokenizer.from_pretrained(translation_dir)
    translation_model = MarianMTModel.from_pretrained(translation_dir)
    logger.info("✓ Translation model loaded successfully.")
except Exception as e:
    logger.error(f"Could not load translation model: {e}", exc_info=True)

class TextRequest(BaseModel):
    text: str

# ============================================================
# TTS CACHE
# ============================================================
tts_cache = {}

# ============================================================
# TTS ENDPOINT
# ============================================================
@app.post("/tts")
def generate_tts(req: TextRequest):
    if not req.text or not req.text.strip():
        logger.warning("Received empty text for TTS.")
        raise HTTPException(status_code=400, detail="Text cannot be empty.")

    clean_text = req.text.lower().strip()
    
    # Bisaya phonetic preprocessing
    clean_text = clean_text.replace("aw ", "au ").replace("aw", "au")
    clean_text = " ".join(clean_text.split())

    text_hash = hashlib.md5(clean_text.encode("utf-8")).hexdigest()

    if text_hash in tts_cache:
        logger.info(f"[TTS Cache Hit] Returning audio for: {clean_text[:50]}...")
        return StreamingResponse(
            io.BytesIO(tts_cache[text_hash]),
            media_type="audio/wav"
        )

    client = get_hf_client()
    if client is None:
        logger.error("Hugging Face TTS Space client is not initialized.")
        raise HTTPException(status_code=503, detail="Hugging Face TTS Space is unavailable.")

    logger.info(f"[TTS Generation] Sending to Hugging Face Space: '{clean_text}'")

    try:
        # Note: Based on API check, it uses predict(text, api_name="/synthesize")
        result = client.predict(
            text=clean_text,
            api_name="/synthesize"
        )
        logger.info(f"[TTS Result] Received file path from HF Space: {result}")
        
        if not result or not os.path.exists(result):
            logger.error(f"HF Space returned an invalid path or non-existent file: {result}")
            raise Exception("Invalid audio file path returned from HF Space.")

        with open(result, "rb") as audio_file:
            audio_bytes = audio_file.read()

        # Cache the result
        tts_cache[text_hash] = audio_bytes
        
        logger.info(f"[TTS Success] Generated and cached {len(audio_bytes)} bytes.")
        return StreamingResponse(
            io.BytesIO(audio_bytes),
            media_type="audio/wav"
        )

    except Exception as e:
        logger.error(f"[TTS Error] Hugging Face request failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Hugging Face TTS generation failed: {str(e)}")

# ============================================================
# TRANSLATION ENDPOINT
# ============================================================
@app.post("/translate")
def translate_text(req: TextRequest):
    logger.info(f"[Translation] Translating: {req.text[:50]}...")
    try:
        inputs = translation_tokenizer(
            req.text,
            return_tensors="pt",
            padding=True
        )

        with torch.no_grad():
            translated = translation_model.generate(**inputs)

        result = translation_tokenizer.batch_decode(
            translated,
            skip_special_tokens=True
        )
        return {"translation": result[0]}
    except Exception as e:
        logger.error(f"[Translation Error] Failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Translation failed.")
