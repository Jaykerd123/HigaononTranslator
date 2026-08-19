# Plan: Migrate to Hugging Face Space TTS and Add Detailed Logging

The goal is to update `server.py` to use the `Jaykerd/higaonon-tts` Hugging Face Space for all TTS requests, replacing the local `mms-tts-ceb` model. We will also add robust logging and error handling to identify why the connection might be failing.

## User Review Required

> [!IMPORTANT]
> The Hugging Face Space `Jaykerd/higaonon-tts` is used as the primary TTS engine. If this space requires an authentication token (for private spaces), we may need to add a `token` parameter to the `Client` initialization.

## Proposed Changes

### [Component] Backend Server

#### [MODIFY] [server.py](file:///C:/Users/yuihi/HigaononTranslator/server.py)
- **Remove Local TTS Logic**: Delete `VitsModel`, `AutoTokenizer` imports and the code that loads the `facebook/mms-tts-ceb` model.
- **Add Logging**: Configure the `logging` module to output info and error logs to the console, including full stack traces for exceptions.
- **Enhance HF Space Integration**:
    - Add detailed logging around `hf_tts_client.predict`.
    - Handle potential `gradio_client` errors gracefully.
    - Ensure the audio file returned by the space is correctly read and streamed.
- **Cleanup**: Remove unused `multiprocessing` and thread settings if they were only for the local TTS (though `torch` settings might still apply to the translation model).

#### [MODIFY] [requirements.txt](file:///C:/Users/yuihi/HigaononTranslator/requirements.txt)
- Add `gradio_client` to the dependencies list.

## Verification Plan

### Automated Tests
- Run `python server.py` and check the startup logs to ensure it connects to the HF Space.
- Trigger a TTS request via the app or `curl` and observe the logs.
    - `curl -X POST http://localhost:8000/tts -H "Content-Type: application/json" -d "{\"text\": \"Maayad ha maudom\"}"`

### Manual Verification
- Verify that the terminal shows the detailed error logs if the Hugging Face request fails.
- Confirm the audio plays in the app when the server successfully proxies the HF Space output.
