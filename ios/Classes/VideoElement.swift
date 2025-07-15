import Foundation
import AVFoundation

/// Represents a section of a recorded video with its file path.
/// This class provides methods to access the file path and the AVAsset representation of the video.
class RecordedVideoSection {
  var path: URL

  init(path: URL) {
    self.path = path
  }

  func getPath() -> URL {
    return path
  }

  func getAsset() -> AVAsset {
    return AVURLAsset(url: path)
  }
}

enum MergeAndExportResult {
  case error(String)
  case success(URL)
}

class VideoAsset {
  var asset: AVAsset
  var videoTrack: AVAssetTrack
  var audioTrack: AVAssetTrack

  init(asset: AVAsset) async throws {
    self.asset = asset
    do {
      let videoTracks: [AVAssetTrack] = try await asset.loadTracks(withMediaType: .video)
      guard let firstVideoTrack: AVAssetTrack = videoTracks.first else {
        fatalError("No video track found in asset")
      }
      self.videoTrack = firstVideoTrack

      let audioTracks: [AVAssetTrack] = try await asset.loadTracks(withMediaType: .audio)
      guard let firstAudioTrack: AVAssetTrack = audioTracks.first else {
        fatalError("No audio track found in asset")
      }
      self.audioTrack = firstAudioTrack
    } catch {
      fatalError("Failed to load tracks for asset: \(error.localizedDescription)")
    }
  }

  func getAsset() -> AVAsset {
    return asset
  }

  func getVideoTrack() -> AVAssetTrack {
    return videoTrack
  }

  func getAudioTrack() -> AVAssetTrack {
    return audioTrack
  }
}

/// This class manages the video composition for a collection of recorded video sections.
/// It allows setting the video composition and retrieving it.
/// It also manages a collection of recorded video sections, allowing adding new sections and retrieving the list of sections.
class SpielbergoComposition {
  // Default initializer
  init() {}
  
  // This class manages a mixed video section, which is a special type of recorded video section.
  // It allows setting the mixed video section and retrieving it.
  private(set) var mixedVideo: RecordedVideoSection?

  func quickMerge(fileID: String, clips: [RecordedVideoSection], onCompletion: @escaping (MergeAndExportResult) -> Void) async {
    print("Starting quick merge with \(clips.count) clips")
    // Create the asset list
    guard !clips.isEmpty else {
      onCompletion(.error("No clips provided for merging"))
      return
    }
    let assets: [AVAsset] = clips.map { $0.getAsset() }
    var videoAssets: [VideoAsset] = []
    for asset in assets {
      do {
        let videoAsset: VideoAsset = try await VideoAsset(asset: asset)
        videoAssets.append(videoAsset)
      } catch {
        onCompletion(.error("Failed to create VideoAsset for \(asset): \(error.localizedDescription)"))
        return
      }
    }

    // Check if we have any video assets
    guard !videoAssets.isEmpty else {
      onCompletion(.error("No valid video assets found"))
      return
    }

    // Create the Mix Composition
    let mixComposition: AVMutableComposition = AVMutableComposition()

    // Set the Start Time
    var start: CMTime = .zero

    // Use a single video track for all assets and merge them
    guard let videoTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      onCompletion(.error("Failed to create video track"))
      return
    }
    for videoAsset: VideoAsset in videoAssets {
      let duration: CMTime
      do {
        duration = try await videoAsset.getAsset().load(.duration)
      } catch {
        onCompletion(.error("Failed to load duration for asset \(videoAsset.getAsset()): \(error.localizedDescription)"))
        return
      }
      do {
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoAsset.getVideoTrack(), at: start)
        start = CMTimeAdd(start, duration)
      } catch {
        onCompletion(.error("Failed to insert video track from asset \(videoAsset.getAsset()): \(error.localizedDescription)"))
        return
      }
    }

    // Compute total video duration
    let totalVideoDuration = videoTrack.timeRange.duration
    let videoDuration = CMTimeConvertScale(totalVideoDuration, timescale: 600, method: .roundTowardZero)

    // Video Instructions
    var instructions: [AVMutableVideoCompositionLayerInstruction] = []
    var currentTime: CMTime = .zero

    // Iterate through each clip to create layer instructions
    for videoAsset: VideoAsset in videoAssets {
      let asset: AVAsset = videoAsset.getAsset()
      // Get the natural size
      let naturalSize: CGSize
      let duration: CMTime
      do {
        naturalSize = try await videoAsset.getVideoTrack().load(.naturalSize)
        duration = try await videoAsset.getAsset().load(.duration)
        // Log the natural size for debugging
        print("Natural size for asset \(asset): \(naturalSize)")
      } catch {
        onCompletion(.error("Failed to load natural size for asset \(asset): \(error.localizedDescription)"))
        return
      }

      // Create layer instruction for the current video track
      let instruction: AVMutableVideoCompositionLayerInstruction = forceVerticalInstruction(videoTrack, asset: asset)
      instruction.setOpacity(1.0, at: currentTime)
      instructions.append(instruction)

      // Update current time
      currentTime = CMTimeAdd(currentTime, duration)
    }

    // Merge audio tracks
    var audioTracks: [AVMutableCompositionTrack] = []
    start = .zero
    // Iterate through each clip to create audio tracks
    for videoAsset: VideoAsset in videoAssets {
      let asset: AVAsset = videoAsset.getAsset()
      let duration: CMTime
      do {
        duration = try await asset.load(.duration)
      } catch {
        onCompletion(.error("Failed to load duration for asset \(asset): \(error.localizedDescription)"))
        return
      }

      let sourceAudioTrack: AVAssetTrack = videoAsset.getAudioTrack()
      guard let audioTrack: AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
        onCompletion(.error("Failed to create audio track"))
        return
      }

      do {
        try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceAudioTrack, at: start)
        audioTracks.append(audioTrack)
        start = CMTimeAdd(start, duration)
      } catch {
        onCompletion(.error("Failed to insert audio track from asset \(asset): \(error.localizedDescription)"))
        return
      }
    }

    guard !audioTracks.isEmpty else {
      onCompletion(.error("No audio tracks found in assets"))
      return
    }

    let exportDuration = videoDuration
    print("Export duration: \(exportDuration.seconds) seconds")

    // Build the Main Composition
    let mainComposition = AVMutableVideoComposition()
    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRange(start: .zero, duration: videoDuration)
    mainInstruction.layerInstructions = instructions
    mainComposition.instructions = [mainInstruction]
    mainComposition.frameDuration = CMTime(value: 1, timescale: 30)
    mainComposition.renderSize = CGSize(width: videoTrack.naturalSize.height,
                                        height: videoTrack.naturalSize.width)

    // Create the export session
    guard let exportSession = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else {
      onCompletion(.error("Failed to create export session"))
      return
  }

    // Set the output URL
    let tempDir = FileManager.default.temporaryDirectory
    let outputURL = tempDir.appendingPathComponent(fileID + ".mp4")

    // Remove existing file at output URL if it exists
    if FileManager.default.fileExists(atPath: outputURL.path) {
      do {
        try FileManager.default.removeItem(at: outputURL)
      } catch {
        onCompletion(.error("Failed to remove existing file at \(outputURL.path): \(error.localizedDescription)"))
        return
      }
    }

    // Set up the export session
    exportSession.outputFileType = .mp4
    exportSession.outputURL = outputURL
    exportSession.shouldOptimizeForNetworkUse = true
    exportSession.videoComposition = mainComposition
    exportSession.timeRange = CMTimeRange(start: .zero, duration: exportDuration)

    Task {
      // Launch progress observer in background
      Task.detached {
        for await state: AVAssetExportSession.State in exportSession.states() {
          if case .exporting(let progress) = state {
            print("Progress: \(Int(progress.fractionCompleted * 100))%")
          }
        }
      }

      do {
        try await exportSession.export(to: outputURL, as: .mp4)
        print("✅ Export complete")
        onCompletion(.success(outputURL))
      } catch {
        print("❌ Export failed: \(error.localizedDescription)")
        onCompletion(.error("Export failed: \(error.localizedDescription)"))
      }
    }
  }

  private func forceVerticalInstruction(
    _ track: AVCompositionTrack,
    asset: AVAsset
  ) -> AVMutableVideoCompositionLayerInstruction {
    let assetTrack = asset.tracks(withMediaType: .video)[0]
    let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
    // This function forces the video to be in a vertical orientation (1080x1920).
    // 1. Rotate 90 degrees clockwise
    let rotate = CGAffineTransform(rotationAngle: CGFloat.pi / 2)

    // 2. Translate the rotated video to origin (since rotating moves it out of frame)
    let translate = CGAffineTransform(translationX: assetTrack.naturalSize.height, y: 0)

    // 3. Combine rotation and translation
    let rotateAndTranslate = rotate.concatenating(translate)

    // 4. Scale to fit 1080x1920
    let targetSize = CGSize(width: 1080, height: 1920)
    let scaleX = targetSize.width / assetTrack.naturalSize.height
    let scaleY = targetSize.height / assetTrack.naturalSize.width
    let scale = CGAffineTransform(scaleX: scaleX, y: scaleY)

    // 5. Final transform: scale, then rotate+translate
    let finalTransform = rotateAndTranslate.concatenating(scale)

    // 6. Apply it
    instruction.setTransform(finalTransform, at: .zero)

    return instruction
  }
}