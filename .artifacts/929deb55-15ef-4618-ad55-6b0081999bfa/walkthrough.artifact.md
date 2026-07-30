# Walkthrough - Wi-Fi Connectivity for TTS

I have updated the Flutter application to allow connection to the local Python TTS server over Wi-Fi. This ensures that the high-quality Higaonon/Cebuano models are used even when the USB cable is disconnected.

## Changes Made

### Services

#### [tts_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/tts_service.dart)
Added the laptop's IP address (`10.242.148.236`) to the list of possible base URLs for the TTS service.
```diff
     List<String> possibleBaseUrls = ['http://127.0.0.1:8000'];
     if (!kIsWeb && Platform.isAndroid) {
-      possibleBaseUrls = ['http://127.0.0.1:8000'];
+      possibleBaseUrls = ['http://127.0.0.1:8000', 'http://10.242.148.236:8000'];
     }
```

#### [translation_fallback_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/translation_fallback_service.dart)
Updated the translation service to also include the laptop's IP address.
```diff
     List<String> possibleBaseUrls = ['http://127.0.0.1:8000'];
     if (!kIsWeb && Platform.isAndroid) {
-      possibleBaseUrls = ['http://10.0.2.2:8000', 'http://10.0.0.48:8000', 'http://10.0.0.10:8000'];
+      possibleBaseUrls = ['http://127.0.0.1:8000', 'http://10.242.148.236:8000'];
     }
```

## How to Test

1.  **Start the Server**: On your laptop, run:
    `uvicorn server:app --host 0.0.0.0 --port 8000`
2.  **Connect to Wi-Fi**: Ensure your phone and laptop are on the same Wi-Fi network.
3.  **Unplug Cable**: You can now safely unplug the USB cable.
4.  **Use the App**: Try translating and playing TTS. The app will now try `127.0.0.1` first (fails if unplugged) and then automatically fallback to `10.242.148.236`, which should succeed over Wi-Fi.

> [!TIP]
> If it still doesn't work, double-check your **Windows Firewall**. You may need to "Allow an app through firewall" for `python.exe` or simply allow inbound traffic on port `8000`.
