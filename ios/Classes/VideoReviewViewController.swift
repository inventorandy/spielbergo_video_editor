import UIKit
import AVFoundation
import Flutter

/// This class handles the review screen where users can add basic effects
/// like text overlays and filters. There are also buttons for the timeline
/// editor and more complex effects.
class VideoReviewViewController: UIViewController {
  // Composition and Video Composition
  var composition: AVMutableComposition?
  var videoComposition: AVMutableVideoComposition?

  // Player
  private var playerLayer: AVPlayerLayer = AVPlayerLayer()
  private var queuePlayer: AVQueuePlayer?
  private var playerLooper: AVPlayerLooper?

  // Buttons
  private var closeButton: UIButton!
  private var addTextButton: UIButton!

  // Required initializer for Storyboards
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Initialize with parameters
  init(
    composition: AVMutableComposition,
    videoComposition: AVMutableVideoComposition
  ) {
    // Set the composition and videoComposition properties
    self.composition = composition
    self.videoComposition = videoComposition

    // Initialize the buttons
    self.closeButton = UIButton(type: .system)
    self.addTextButton = UIButton(type: .custom)

    super.init(nibName: nil, bundle: nil)
    self.modalPresentationStyle = .fullScreen
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    setupVideoPlayer()
    setupCloseButton()
    setupAddTextButton()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    playerLayer.frame = view.bounds
  }

  /// UI Element Setup
  // MARK: - Setup Video Player
  private func setupVideoPlayer() {
    guard let composition = composition else { return }

    let playerItem = AVPlayerItem(asset: composition)
    playerItem.videoComposition = videoComposition

    // Setup AVQueuePlayer and AVPlayerLooper for looping
    queuePlayer = AVQueuePlayer(playerItem: playerItem)
    if let queuePlayer = queuePlayer {
      playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

      playerLayer = AVPlayerLayer(player: queuePlayer)
      playerLayer.videoGravity = .resizeAspectFill
      playerLayer.frame = view.bounds
      view.layer.addSublayer(playerLayer)

      queuePlayer.play()
    }
  }

  // MARK: - Setup Close Button
  private func setupCloseButton() {
    self.closeButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
    self.closeButton.tintColor = .white
    self.closeButton.translatesAutoresizingMaskIntoConstraints = false
    self.closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    view.addSubview(self.closeButton)

    NSLayoutConstraint.activate([
      self.closeButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      self.closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      self.closeButton.widthAnchor.constraint(equalToConstant: 32),
      self.closeButton.heightAnchor.constraint(equalToConstant: 32)
    ])
  }

  // MARK: - Add Text Button
  private func setupAddTextButton() {
    self.addTextButton.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(
      systemName: "textformat",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    )

    self.addTextButton.setImage(image, for: .normal)
    self.addTextButton.tintColor = .white

    // Remove extra padding around image
    self.addTextButton.contentEdgeInsets = .zero
    self.addTextButton.imageEdgeInsets = .zero
    self.addTextButton.imageView?.contentMode = .scaleAspectFit

    // Optional: round background
    self.addTextButton.layer.cornerRadius = 8
    self.addTextButton.clipsToBounds = true

    self.view.addSubview(self.addTextButton)

    NSLayoutConstraint.activate([
      self.addTextButton.centerYAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor,
        constant: 48.0
      ),
      self.addTextButton.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -16.0
      ),
      self.addTextButton.widthAnchor.constraint(equalToConstant: 36),
      self.addTextButton.heightAnchor.constraint(equalToConstant: 36)
    ])

    // Add the target action for the Switch Camera Button
    self.addTextButton.addTarget(self, action: #selector(addTextTapped), for: .touchUpInside)
  }

  /// Button Actions
  // MARK: - Close Button Action
  @objc private func closeTapped() {
    dismiss(animated: true)
  }

  /// MARK: - Add Text Button Action
  @objc private func addTextTapped() {
    print("Add Text button tapped")
    _ = TextOverlayView(containerView: view)
  }
}
