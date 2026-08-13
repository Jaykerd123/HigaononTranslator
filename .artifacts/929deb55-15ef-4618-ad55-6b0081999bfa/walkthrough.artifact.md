# Walkthrough - Automatic Server Discovery

I have implemented an automatic discovery system so the app can find your laptop on the local network regardless of your IP address. You no longer need to update the IP in the code when you switch Wi-Fi networks.

## Changes Made

### New Discovery Service

#### [NEW] [discovery_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/discovery_service.dart)
Added a new service that scans the current Wi-Fi subnet (e.g., `10.0.0.1` to `10.0.0.254`) for any device responding on ports `8000` or `8080`. It caches the found IP so it doesn't have to scan every time.

### Service Updates

#### [MODIFY] [tts_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/tts_service.dart)
Modified the TTS service to use the `DiscoveryService`. If the last known IP fails, it triggers a background scan to find the server's new location.

#### [MODIFY] [translation_fallback_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/translation_fallback_service.dart)
Updated the translation service to share the same discovered IP address, ensuring both translation and TTS work seamlessly together.

### Android Configuration

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/yuihi/HigaononTranslator/android/app/src/main/AndroidManifest.xml)
Added `ACCESS_WIFI_STATE` and `ACCESS_NETWORK_STATE` permissions to allow the app to identify the local network subnet for scanning.

## How it Works

1.  **Start your server**: `uvicorn server:app --host 0.0.0.0 --port 8080`
2.  **Open the app**: The app will first try the last working IP.
3.  **Auto-Scan**: If you've switched networks, the app will notice the connection failure and start scanning your subnet.
4.  **Auto-Recovery**: Within a few seconds, it will find your laptop, save the new IP, and complete your request.

> [!NOTE]
> The very first time you use the app on a new network, there might be a 2-3 second delay while it "finds" your laptop. After that, it will be instant until you change networks again.

> [!TIP]
> Make sure your laptop's **Firewall** allows incoming connections on port **8080** (or **8000**), otherwise the app won't be able to "see" the server during its scan.
