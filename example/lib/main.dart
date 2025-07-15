import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:spielbergo_video_editor/spielbergo_video_editor.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _spielbergoVideoEditorPlugin = SpielbergoVideoEditor();
  late VideoPlayerController _videoPlayerController;
  bool _isVideoLoaded = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _spielbergoVideoEditorPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Spielbergo Video Editor')),
        body: (_isVideoLoaded && _videoPlayerController.value.isInitialized)
            ? Center(
                child: AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController),
                ),
              )
            : Center(child: Text('Running on: $_platformVersion\n')),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            // You can add functionality here to trigger video editing
            File? videoFile = await SpielbergoVideoEditor().pickVideo(
              recordTimes: ["10s", "30s", "1m", "10m"],
            );
            if (videoFile != null) {
              // Handle the selected video file
              debugPrint('Selected video: ${videoFile.path}');
              _videoPlayerController = VideoPlayerController.file(videoFile)
                ..initialize().then((_) async {
                  // Delay by 2 seconds to ensure the video is ready
                  // await Future.delayed(const Duration(seconds: 2));

                  setState(() {
                    _isVideoLoaded = true;
                  });
                  // Ensure the first frame is shown
                  _videoPlayerController.setLooping(true);
                  _videoPlayerController.play();
                });
            } else {
              debugPrint('No video selected');
            }
          },
          tooltip: 'Edit Video',
          child: const Icon(Icons.video_call),
        ),
      ),
    );
  }
}
