from fastapi import FastAPI
from pydantic import BaseModel
from transformers import VitsModel, AutoTokenizer
import torch
import soundfile as sf
import io
from fastapi.responses import StreamingResponse

app = FastAPI()

model = VitsModel.from_pretrained("facebook/mms-tts-ceb")
tokenizer = AutoTokenizer.from_pretrained("facebook/mms-tts-ceb")

class TextRequest(BaseModel):
    text: str

@app.post("/tts")
def generate_tts(req: TextRequest):

    inputs = tokenizer(req.text, return_tensors="pt")

    with torch.no_grad():
        output = model(**inputs).waveform

    audio = output.squeeze().cpu().numpy()

    buffer = io.BytesIO()
    sf.write(buffer, audio, 16000, format="WAV")
    buffer.seek(0)

    return StreamingResponse(buffer, media_type="audio/wav")