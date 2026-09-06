# Remove Debug UI (Flutter DEBUG Banner)

The user wants to remove the "debug UI" from the screen. In Flutter applications, this typically refers to the "DEBUG" banner displayed in the top-right corner of the app when running in debug mode.

## User Review Required

> [!NOTE]
> This change will remove the "DEBUG" ribbon that Flutter automatically displays in the corner of the screen during development. It does not affect functionality, but makes the app look more like a production release.

## Proposed Changes

### [HigaononTranslator]

#### [MODIFY] [main.dart](file:///C:/Users/yuihi/HigaononTranslator/lib/main.dart)

Add `debugShowCheckedModeBanner: false` to the `MaterialApp` widget to hide the debug banner.

## Verification Plan

### Manual Verification
- Run the app in a Flutter environment.
- Observe the top-right corner of the screen to ensure the "DEBUG" banner is no longer visible.
