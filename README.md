# MeshFamily Android App (APK-ready project)

MeshFamily is an **Android-only** family messenger designed for **no mobile internet** usage.
It uses phone radios via Google Nearby Connections (`P2P_CLUSTER`) to exchange messages over local peer links (Bluetooth + Wi‑Fi Direct/local hotspot under the hood, without internet dependency).

## Features implemented

- Passkey gate for family-only access.
- Text messaging over nearby mesh-style relay.
- Image sharing.
- SOS message with last known location coordinates.
- Android project structure so you can build/share APK.

## Important note about “global hardware available on phones”

True long-range, guaranteed multi-hop mesh on all phones globally is not standardized in the same way as LoRa mesh hardware.
This app uses **Nearby Connections**, which is the most practical globally-available phone-radio option on Android.

## Build APK

### Option A: Android Studio (recommended)

1. Open this folder in Android Studio.
2. Let Gradle sync.
3. Build -> Build Bundle(s) / APK(s) -> Build APK(s).
4. Share generated APK from:
   - `app/build/outputs/apk/debug/app-debug.apk`

### Option B: CLI

```bash
./gradlew assembleDebug
```

APK output:

```text
app/build/outputs/apk/debug/app-debug.apk
```

## Usage flow

1. Install APK on family phones.
2. First family member opens app and sets the passkey.
3. Share passkey privately with family members.
4. Each member enters same passkey and taps **Start Mesh**.
5. Send text/images and use **SOS + Location** when needed.

## Next hardening recommended

- Replace plain passkey storage with Android Keystore-backed hash.
- Add message encryption (X25519 session + AES-GCM).
- Add delivery receipts and dedupe cache.
- Add QR-based passkey enrollment.
