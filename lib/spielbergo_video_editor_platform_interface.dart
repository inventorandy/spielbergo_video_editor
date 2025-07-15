import 'dart:io';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'spielbergo_video_editor_method_channel.dart';

abstract class SpielbergoVideoEditorPlatform extends PlatformInterface {
  /// Constructs a SpielbergoVideoEditorPlatform.
  SpielbergoVideoEditorPlatform() : super(token: _token);

  static final Object _token = Object();

  static SpielbergoVideoEditorPlatform _instance =
      MethodChannelSpielbergoVideoEditor();

  /// The default instance of [SpielbergoVideoEditorPlatform] to use.
  ///
  /// Defaults to [MethodChannelSpielbergoVideoEditor].
  static SpielbergoVideoEditorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SpielbergoVideoEditorPlatform] when
  /// they register themselves.
  static set instance(SpielbergoVideoEditorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  Future<File?> pickVideo(List<String>? recordTimes) {
    throw UnimplementedError('pickVideo() has not been implemented.');
  }
}
