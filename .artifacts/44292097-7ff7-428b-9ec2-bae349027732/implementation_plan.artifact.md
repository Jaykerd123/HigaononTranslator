# Fix Build Failure (Memory Allocation Error)

The build is failing during the `packageDebug` task because the system/Gradle is unable to allocate enough memory to process the ~150MB of new ONNX model assets. This is common on systems with 8GB of RAM when large files are added to the APK.

## User Review Required

> [!IMPORTANT]
> **System Memory**: Your system has ~7-8GB of RAM. Building an Android app with 150MB+ of additional assets is memory-intensive. I recommend closing other heavy applications (like web browsers) during the build process.

## Proposed Changes

### 1. Optimize Gradle Packaging
We will instruct Gradle not to compress the `.onnx` and `.spm` files. This reduces the memory overhead during the packaging phase and can also improve model loading speed at runtime.

#### [MODIFY] [android/app/build.gradle.kts](file:///C:/Users/yuihi/HigaononTranslator/android/app/build.gradle.kts)
*   Add `android.packaging.resources.excludes` or `aaptOptions.noCompress` to skip compression for model files.

### 2. Increase Gradle Heap Size
We will increase the memory allocated to the Gradle daemon to handle the larger project size.

#### [MODIFY] [android/gradle.properties](file:///C:/Users/yuihi/HigaononTranslator/android/gradle.properties)
*   Increase `org.gradle.jvmargs` to `-Xmx4g` (or `-Xmx3g` if 4g causes system-wide issues).
*   Enable `org.gradle.daemon=true` to keep the warmed-up JVM ready.

## Verification Plan

### Manual Verification
1.  Run `flutter clean` to ensure a fresh state.
2.  Run `flutter run --dart-define=HF_TOKEN=...` again.
3.  Verify the build completes successfully and the app launches on the device.
