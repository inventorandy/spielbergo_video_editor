import 'dart:io';

import 'spielbergo_video_editor_platform_interface.dart';

class SpielbergoVideoEditor {
  Future<String?> getPlatformVersion() {
    return SpielbergoVideoEditorPlatform.instance.getPlatformVersion();
  }

  Future<File?> pickVideo({List<String>? recordTimes}) async {
    return await SpielbergoVideoEditorPlatform.instance.pickVideo(recordTimes);
  }
}
