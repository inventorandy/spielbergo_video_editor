import UIKit
import AVFoundation
import Flutter

class VideoReviewViewController: UIViewController {
  // Composition and Video Composition
  var composition: AVMutableComposition?
  var videoComposition: AVMutableVideoComposition?

  // Flag for whether the video is playing
  var isPlaying: Bool = true

  // Player for the video
  var playerLayer: AVPlayerLayer = AVPlayerLayer()
  var player: AVPlayer = AVPlayer()

  // Required initializer for using Storyboards
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Initialize with parameters
  init(
    composition: AVMutableComposition,
    videoComposition: AVMutableVideoComposition
  ) {
    // Set the Initial Composition and Video Composition
    self.composition = composition
    self.videoComposition = videoComposition

    // Initialize the player with the composition
    self.player = AVPlayer(playerItem: AVPlayerItem(asset: composition))
    self.playerLayer = AVPlayerLayer(player: player)

    // Call the super initializer
    super.init(nibName: nil, bundle: nil)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    // Additional setup after loading the view
    setupVideoPlayer()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    // Update the player layer frame to match the view bounds
    playerLayer.frame = view.bounds
  }

  /// Setup View Methods
  func setupVideoPlayer() {
    // Set the Constraints for the player layer
    playerLayer.frame = view.bounds
    playerLayer.videoGravity = .resizeAspect
    view.layer.addSublayer(playerLayer)

    // Start playing the video
    player.play()
  }
}
