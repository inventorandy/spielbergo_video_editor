# spielbergo_video_editor

A new Flutter plugin project.

## Getting Started

This project is a starting point for a Flutter
[plug-in package](https://flutter.dev/to/develop-plugins),
a specialized package that includes platform-specific implementation code for
Android and/or iOS.

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

# Spielbergo Video Editor

Spielbergo Video Editor is a vertical video recording and editing plugin for Flutter.

## Compatibility

* iOS version 18 and above
* Android version 15 and above

## Permissions

### iOS Permissions

Add the following to your `Info.plist` (`ios/Runner/Info.plist`):

```xml
<key>NSCameraUsageDescription</key>
<string>This app requires access to the camera for video recording.</string>
<key>NSMicrophoneUsageDescription</key>
<string>This app requires access to the microphone for audio recording in videos.</string>
```
