# Gaze Link Patient App

Flutter prototype for the patient side of the Gaze Link assistive communication system.

## Run

```powershell
flutter pub get
flutter run
```

## Current prototype flow

Start → front-camera positioning → nine-point calibration simulation → Arabic communication.

The camera preview is real. Calibration and gaze selection are simulated with mouse hover or touch. The nine sample positions are held in memory and are not eye-tracking data. Arabic speech uses the Android/iOS text-to-speech engine when an Arabic voice is installed.

## Source layout

- `lib/app/`: app shell and named routes.
- `lib/core/`: shared theme and reserved shared infrastructure folders.
- `lib/features/`: setup, camera, calibration, communication, gaze, speech, help, and settings.
- `lib/shared/widgets/`: widgets only when they are reused across features.

Feature folders are organized by presentation, domain, and data responsibilities. Empty folders are placeholders for agreed future work; add source files when the relevant feature is implemented.

## Dependencies

See `pubspec.yaml` for the current package versions. The architecture blueprint is a proposal; packages for AI, persistence, and backend work should be activated only when their contracts are agreed and the feature needs them.
