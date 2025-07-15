import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:spielbergo_video_editor/spielbergo_video_editor.dart';
import 'package:spielbergo_video_editor/spielbergo_video_editor_platform_interface.dart';
import 'package:spielbergo_video_editor/spielbergo_video_editor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSpielbergoVideoEditorPlatform
    with MockPlatformInterfaceMixin
    implements SpielbergoVideoEditorPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<File?> pickVideo(List<String>? recordTimes) =>
      Future.value(File('test_video.mp4'));
}

void main() {
  final SpielbergoVideoEditorPlatform initialPlatform =
      SpielbergoVideoEditorPlatform.instance;

  test('$MethodChannelSpielbergoVideoEditor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSpielbergoVideoEditor>());
  });

  test('getPlatformVersion', () async {
    SpielbergoVideoEditor spielbergoVideoEditorPlugin = SpielbergoVideoEditor();
    MockSpielbergoVideoEditorPlatform fakePlatform =
        MockSpielbergoVideoEditorPlatform();
    SpielbergoVideoEditorPlatform.instance = fakePlatform;

    expect(await spielbergoVideoEditorPlugin.getPlatformVersion(), '42');
  });

  test('pickVideo returns a File', () async {
    SpielbergoVideoEditor spielbergoVideoEditorPlugin = SpielbergoVideoEditor();
    MockSpielbergoVideoEditorPlatform fakePlatform =
        MockSpielbergoVideoEditorPlatform();
    SpielbergoVideoEditorPlatform.instance = fakePlatform;

    final file = await spielbergoVideoEditorPlugin.pickVideo();
    expect(file, isA<File>());
    expect(file?.path, 'test_video.mp4');
  });
}
