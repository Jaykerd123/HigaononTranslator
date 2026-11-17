# fireb

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

running tts server for physical device
1st terminal:
.\.venv_win\Scripts\Activate.ps1
uvicorn server:app --host 0.0.0.0 --port 8080

2nd terminal: 
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080

## Translation reference retrieval

The FastAPI backend exposes `POST /retrieve` for looking up the bundled
English-Higaonon references without generating a translation. It searches
`assets/dictionary.json`, `assets/dictionary-second.json`, and the additional
`assets/cleaned_dataset.csv` source (UTF-8 with BOM; `english` and `higaonon`
columns). The request body is `{"text":"..."}`. The response has `match_type`
set to `exact`, `related`, or `none`, a `candidate_count`, and the matching
`references`. Exact matches are returned first and preserve duplicate source
entries; otherwise, related entries are ranked lexically. References include
their source file and entry index. Speaker-review status is unknown; a dataset
match must not be presented as a verified translation.

## Gemini Higaonon assistant

The Translate screen's sparkle button opens a separate Gemini assistant screen.
It calls the Hugging Face Gradio `ask_higaonon_assistant` endpoint and does not
change the dictionary, ONNX, fallback translation, or TTS flows. Run
`flutter test test/gemini_assistant_service_test.dart` to test the request and
event-stream handling.

The Hugging Face Space source uses `gemini_assistant.py` and
`translation_retrieval.py` to load `cleaned_dataset.csv`, retrieve reference
examples, and pass them to Gemini with Higaonon-only language instructions.
Copy these updated Python files to the Space repository and redeploy the Space
for the prompt and retrieval changes to affect the hosted endpoint. The Gradio
function name and Flutter API contract remain unchanged.

## Debug logging

Flutter processing details are emitted in debug builds with timestamps and
`[TRANSLATION]`, `[API]`, `[Gemini]`, `[TTS]`, and `[FIRESTORE]` prefixes.
Sensitive request headers, API query strings, and Firebase user identifiers are
not logged. Python
retrieval queries, retrieved pairs, and stack traces are debug-level details;
set `LOG_LEVEL=DEBUG` in the local backend or Hugging Face Space environment
to enable them. Do not set this level in production if translation text should
not appear in logs.
