# Plan: Streamline TTS Architecture (HF Space + FastAPI)

The goal is to move away from the local-network discovery and multi-IP fallback system for TTS. Instead, the app will point to a single, stable FastAPI server URL which acts as a proxy for the Hugging Face Space. We will also increase timeouts to accommodate AI generation latency.

## User Review Required

> [!IMPORTANT]
> The `DiscoveryService` and multi-IP scanning logic will be removed from the TTS path. The app will rely on a single configured `baseUrl`. If the server IP changes during development, you will need to update the `baseUrl` constant in `tts_service.dart`.

## Proposed Changes

### [Component] Backend Server

#### [MODIFY] [server.py](file:///C:/Users/yuihi/HigaononTranslator/server.py)
- **Lazy HF Client**: Initialize the Gradio `Client` only when needed and attempt to reconnect if the connection is lost or the space was sleeping.
- **Improved Logging**: Maintain the detailed logging added previously to track request lifecycle and HF Space response times.

### [Component] Flutter App - Services

#### [MODIFY] [tts_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/tts_service.dart)
- **Simplify URL Logic**: Remove the `possibleBaseUrls` list and the loop that iterates through them.
- **Configurable Base URL**: Use a single `baseUrl` constant (initially set to `http://10.26.240.236:8000`).
- **60-Second Timeout**: Increase the request timeout to 60 seconds to allow the HF Space to wake up and generate audio.
- **Granular Logging**: Distinguish between `SocketException` (Connection Refused) and `TimeoutException` in the logs.
- **Remove Discovery Fallback**: Stop calling `DiscoveryService` for TTS.

## Verification Plan

### Automated Tests
- Trigger a TTS request from the app and verify it makes exactly one attempt to the configured IP.
- Verify the timeout duration by checking the time elapsed before a failure is logged.

### Manual Verification
- Observe `server.py` logs to see the lazy initialization of the HF client.
- Confirm the audio plays on the device after the longer wait period.
