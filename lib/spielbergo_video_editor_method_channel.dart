import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'spielbergo_video_editor_platform_interface.dart';

/// An implementation of [SpielbergoVideoEditorPlatform] that uses method channels.
class MethodChannelSpielbergoVideoEditor extends SpielbergoVideoEditorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('spielbergo_video_editor');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<File?> pickVideo(List<String>? recordTimes) async {
    // Convert the record times to seconds
    final recordTimesInSeconds = getSecondsFromStringList(recordTimes);
    final videoFile = await methodChannel.invokeMethod<String>('pickVideo', {
      'recordTimes': recordTimesInSeconds,
    });
    if (videoFile == null) {
      return null; // Return null if no video was picked
    }
    // Sleep for a short duration to ensure the file is ready
    await Future.delayed(const Duration(milliseconds: 500));
    // Return a File object pointing to the video file
    return File(videoFile);
  }

  /// Converts a list of time strings (e.g., ["1m", "30s"]) to a list of seconds.
  /// For example, ["1m", "30s"] will be converted to [60, 30].
  /// If the input is null, it returns null.
  List<int>? getSecondsFromStringList(List<String>? recordTimes) {
    if (recordTimes == null) {
      return null;
    }
    List<int> seconds = [];
    for (String time in recordTimes) {
      final regex = RegExp(r'(\d+)([ms])');
      final match = regex.firstMatch(time);
      if (match != null) {
        final value = int.parse(match.group(1)!);
        final unit = match.group(2);
        if (unit == 'm') {
          seconds.add(value * 60);
        } else if (unit == 's') {
          seconds.add(value);
        }
      }
    }
    return seconds;
  }
}
