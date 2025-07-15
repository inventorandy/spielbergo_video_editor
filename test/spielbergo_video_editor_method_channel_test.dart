import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spielbergo_video_editor/spielbergo_video_editor_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelSpielbergoVideoEditor platform = MethodChannelSpielbergoVideoEditor();
  const MethodChannel channel = MethodChannel('spielbergo_video_editor');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
