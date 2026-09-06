# Implementation Plan - Integrate Cloudflare Public Translation Endpoint

Integrate the new Cloudflare public HTTPS endpoint as the primary AI translation source while preserving the existing dictionary-based translation priority.

## User Review Required

> [!IMPORTANT]
> The Cloudflare URL is a temporary Quick Tunnel URL (`https://meetings-loan-write-wallet.trycloudflare.com`). I have placed it in a constant for easy updates.

> [!NOTE]
> Dictionary priority remains exactly as it is: Word Match > Example Match > Second Dictionary Match > AI Fallback (Cloudflare).

## Proposed Changes

### Translation Service

#### [MODIFY] [translation_fallback_service.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/screens/services/translation_fallback_service.dart)
- Add a constant `publicApiBaseUrl` for the Cloudflare endpoint.
- Update `translateEnglishToBisaya` to prioritize this public URL.
- Increase the timeout to **6 seconds** to accommodate potential tunnel latency.
- Maintain existing local discovery and Google Translate as secondary/tertiary fallbacks.

## Verification Plan

### Manual Verification
- **Dictionary Test:** Input a word known to be in `dictionary.json` (e.g., "stomach organ"). Verify it translates to "tungol" immediately without network activity to Cloudflare.
- **AI Fallback Test:** Input a sentence NOT in the dictionary. Verify the app sends a POST request to the Cloudflare endpoint and displays the returned `translation` field.
- **Offline/Failure Test:** Simulate a Cloudflare failure (e.g., wrong URL) and verify the app still falls back to the local discovery service and eventually Google Translate.
