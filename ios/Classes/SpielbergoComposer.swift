import Foundation
import AVFoundation

enum CompositionCreateResult {
  case success(AVMutableComposition, AVMutableVideoComposition)
  case failure(String, Error? = nil)
}

class SpielbergoComposer {
  /// Default initializer
  public init() {
    // TODO: any initialization logic if needed
  }

  /// Creates a mutable composition from an array of AVURLAssets.
  public func createMutableComposition(assets: [AVURLAsset], onCompletion: @escaping (CompositionCreateResult) -> Void) async {
    // Check we have assets to work with
    guard !assets.isEmpty else {
      onCompletion(.failure("no assets provided for composition"))
      return
    }

    // Create a mutable composition
    let composition: AVMutableComposition = AVMutableComposition()

    // Set the Start Time
    var start: CMTime = .zero

    // Use a single video track for all video assets and merge them
    guard let videoTrack: AVMutableCompositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
      onCompletion(.failure("failed to create video track"))
      return
    }
    // Iterate through each asset and add its video track to the composition
    for asset: AVURLAsset in assets {
      // Fetch the duration of the asset
      var duration: CMTime = .zero
      do {
        duration = try await asset.load(.duration)
      } catch {
        onCompletion(.failure("failed to load duration for asset \(asset.url)", error))
        return
      }
      // Fetch the first video track from the asset
      var videoTracks: [AVAssetTrack] = []
      do {
        // Get the video track from the asset
        videoTracks = try await asset.loadTracks(withMediaType: .video)
      } catch {
        onCompletion(.failure("failed to load video track for asset \(asset.url)", error))
        return
      }
      guard let track: AVAssetTrack = videoTracks.first else {
        onCompletion(.failure("no video track found for asset \(asset.url)"))
        return
      }
      // Insert the video track into the composition track
      do {
        try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: track, at: start)
      } catch {
        onCompletion(.failure("failed to insert time range for asset \(asset.url)", error))
        return

      }
      // Update the start time for the next asset
      start = CMTimeAdd(start, duration)
    }

    // Video Instructions
    var videoInstructions: [AVMutableVideoCompositionLayerInstruction] = []

    // Reset the Time
    start = .zero

    // Iterate through each asset again to create layer instructions
    for asset: AVURLAsset in assets {
      // Fetch the first video track from the asset
      var videoTracks: [AVAssetTrack] = []
      // Fetch the duration of the asset
      var duration: CMTime = .zero
      do {
        // Get the video track from the asset
        videoTracks = try await asset.loadTracks(withMediaType: .video)
        // Get the duration of the asset
        duration = try await asset.load(.duration)
      } catch {
        onCompletion(.failure("failed to load video track for asset \(asset.url)", error))
        return
      }
      guard let track: AVAssetTrack = videoTracks.first else {
        onCompletion(.failure("no video track found for asset \(asset.url)"))
        return
      }
      // Get the natural size of the track
      var naturalSize: CGSize
      do {
        naturalSize = try await track.load(.naturalSize)
      } catch {
        onCompletion(.failure("failed to load natural size for asset \(asset.url)", error))
        return
      }

      // Create a layer instruction for this track
      let instruction: AVMutableVideoCompositionLayerInstruction = forceVerticalInstruction(assetTrack: track, naturalSize: naturalSize)
      // Set the Opacity to 1.0 (fully opaque)
      instruction.setOpacity(1.0, at: start)
      // Add the instruction to the array
      videoInstructions.append(instruction)
      // Update the start time for the next asset
      start = CMTimeAdd(start, duration)
    }

    // Create a single mutable audio track for the whole composition
    guard let audioTrack = composition.addMutableTrack(
      withMediaType: .audio,
      preferredTrackID: kCMPersistentTrackID_Invalid
    ) else {
      onCompletion(.failure("failed to create audio track for composition"))
      return
    }

    // Reset start time
    start = .zero

    // Iterate through each asset and append its audio to the single track
    for asset in assets {
      var duration: CMTime = .zero
      var assetAudioTracks: [AVAssetTrack] = []

      do {
        assetAudioTracks = try await asset.loadTracks(withMediaType: .audio)
        duration = try await asset.load(.duration)
      } catch {
        onCompletion(.failure("failed to load audio track or duration for asset \(asset.url)", error))
        return
      }

      guard let track = assetAudioTracks.first else {
        onCompletion(.failure("no audio track found for asset \(asset.url)"))
        return
      }

      do {
        try audioTrack.insertTimeRange(
          CMTimeRange(start: .zero, duration: duration),
          of: track,
          at: start
        )
      } catch {
        onCompletion(.failure("failed to insert time range for audio track \(asset.url)", error))
        return
      }

      start = CMTimeAdd(start, duration)
    }

    // Create a video composition
    let videoComposition: AVMutableVideoComposition = AVMutableVideoComposition()
    let videoInstruction: AVMutableVideoCompositionInstruction = AVMutableVideoCompositionInstruction()
    videoInstruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)
    videoInstruction.layerInstructions = videoInstructions
    videoComposition.instructions = [videoInstruction]
    videoComposition.frameDuration = CMTime(value: 1, timescale: 30) // 30 FPS
    videoComposition.renderSize = CGSize(width: 1080, height: 1920) // Set the render size to vertical

    // Return the composition and video composition
    onCompletion(.success(composition, videoComposition))
  }

  /// Creates a composition instruction that forces the video to be in a vertical orientation.
  private func forceVerticalInstruction(
    assetTrack: AVAssetTrack,
    naturalSize: CGSize = CGSize(width: 1080, height: 1920)
  ) -> AVMutableVideoCompositionLayerInstruction {
    let instruction: AVMutableVideoCompositionLayerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: assetTrack)
    // This function forces the video to be in a vertical orientation (1080x1920).
    // 1. Rotate 90 degrees clockwise
    let rotate: CGAffineTransform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)

    // 2. Translate the rotated video to origin (since rotating moves it out of frame)
    let translate: CGAffineTransform = CGAffineTransform(translationX: naturalSize.height, y: 0)

    // 3. Combine rotation and translation
    let rotateAndTranslate: CGAffineTransform = rotate.concatenating(translate)

    // 4. Scale to fit 1080x1920
    let targetSize: CGSize = CGSize(width: 1080, height: 1920)
    let scaleX: CGFloat = targetSize.width / naturalSize.height
    let scaleY: CGFloat = targetSize.height / naturalSize.width
    let scale: CGAffineTransform = CGAffineTransform(scaleX: scaleX, y: scaleY)

    // 5. Final transform: scale, then rotate+translate
    let finalTransform: CGAffineTransform = rotateAndTranslate.concatenating(scale)

    // 6. Apply it
    instruction.setTransform(finalTransform, at: .zero)

    return instruction
  }
}