from gradio_client import Client
import traceback

HF_TTS_SPACE = "Jaykerd/higaonon-tts"

try:
    print(f"Connecting to {HF_TTS_SPACE}...")
    client = Client(HF_TTS_SPACE)
    print("API Details:")
    client.view_api()
except Exception as e:
    print(f"Error: {e}")
    traceback.print_exc()
