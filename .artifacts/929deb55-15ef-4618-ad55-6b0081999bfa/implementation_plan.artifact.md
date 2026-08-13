# Automatic Server Discovery (Subnet Scanning)

The goal is to stop hardcoding IP addresses. When the app cannot reach the server at the last known IP, it will automatically scan the current Wi-Fi subnet (e.g., `10.0.0.1` to `10.0.0.255`) to find where the Python server is running.

## Proposed Changes

### 1. Service Enhancement

#### [MODIFY] [tts_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/tts_service.dart)
- Add a new method `_discoverServer()` that:
    1. Uses `NetworkInterface.list()` to find the device's local IP.
    2. Determines the subnet (e.g., `10.0.0.x`).
    3. Pings ports `8000` and `8080` across the entire subnet in parallel.
    4. Updates the `possibleBaseUrls` and saves the new IP to `shared_preferences`.
- Modify `_speakFromLocalServer` to call `_discoverServer()` if all current URLs fail.

#### [MODIFY] [translation_fallback_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/translation_fallback_service.dart)
- Update to use the same cached IP discovered by the TTS service.

### 2. Permissions

#### [MODIFY] [AndroidManifest.xml](file:///C:/Users/yuihi/HigaononTranslator/android/app/src/main/AndroidManifest.xml)
- Ensure `ACCESS_WIFI_STATE` and `ACCESS_NETWORK_STATE` are present.

## User Review Required

> [!IMPORTANT]
> **Discovery Speed**: The scan takes about 2-5 seconds. During this time, the first TTS attempt might feel slightly delayed, but the IP will be saved for all subsequent uses.

> [!TIP]
> This method is very robust because it doesn't matter if your laptop's IP changes; the app will just "find" it again on the new network.

## Open Questions
- Should I add a "Server Found" notification or just let it work silently in the background? (I recommend silent).

## Verification Plan

### Manual Verification
1. Change the laptop's network or restart the router to get a new IP.
2. Run the server.
3. Open the app and try TTS.
4. Verify in logs that it says `[TtsService] Auto-discovered server at: http://...`
