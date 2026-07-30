# Fix TTS Connectivity When Unplugged

The goal is to allow the Higaonon Translator app to connect to the local Python server over Wi-Fi using the laptop's local IP address (`10.242.148.236`).

## User Review Required

> [!IMPORTANT]
> To connect over Wi-Fi, your laptop and phone **must be on the same Wi-Fi network**.

> [!CAUTION]
> Your laptop's **Firewall** must allow incoming connections on port **8000**. You may need to add an exclusion for `python.exe` or `uvicorn`.

## Proposed Changes

### Android Service Layer

#### [MODIFY] [tts_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/tts_service.dart)
Update `_speakFromLocalServer` to include `http://10.242.148.236:8000` in the `possibleBaseUrls` list.

#### [MODIFY] [translation_fallback_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/translation_fallback_service.dart)
Update `translateEnglishToBisaya` to include `http://10.242.148.236:8000` in the `possibleBaseUrls` list.

## Verification Plan

### Manual Verification
1.  Run the server: `uvicorn server:app --host 0.0.0.0 --port 8000`.
2.  Unplug the phone and test the TTS.
3.  Check the Flutter logs for `[TtsService] SUCCESS via http://10.242.148.236:8000`.
