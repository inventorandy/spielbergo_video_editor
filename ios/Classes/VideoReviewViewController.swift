import UIKit
import AVFoundation
import Flutter

/// This class handles the review screen where users can add basic effects
/// like text overlays and filters. There are also buttons for the timeline
/// editor and more complex effects.
class VideoReviewViewController: UIViewController {
  var flutterResult: FlutterResult?

  // Composition and Video Composition
  var composition: AVMutableComposition?
  var videoComposition: AVMutableVideoComposition?

  // Player
  private var playerLayer: AVPlayerLayer = AVPlayerLayer()
  private var queuePlayer: AVQueuePlayer?
  private var playerLooper: AVPlayerLooper?

  // Buttons
  private var closeButton: UIButton!
  private var doneButton: UIButton!
  private var addTextButton: UIButton!

  // Flags
  private var isAddingElement: Bool = false
  private var doneWasTapped: Bool = false

  // Text overlays
  private var textOverlays: [TextOverlayView] = []
  private var deleteBinView: UIImageView!

  // Required initializer for Storyboards
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Initialize with parameters
  init(
    composition: AVMutableComposition,
    videoComposition: AVMutableVideoComposition,
    flutterResult: @escaping FlutterResult
  ) {
    // Set the composition and videoComposition properties
    self.composition = composition
    self.videoComposition = videoComposition

    // Set the flutterResult property
    self.flutterResult = flutterResult

    // Initialize the buttons
    self.closeButton = UIButton(type: .system)
    self.doneButton = UIButton(type: .custom)
    self.addTextButton = UIButton(type: .custom)

    super.init(nibName: nil, bundle: nil)
    self.modalPresentationStyle = .fullScreen
  }

  override func viewDidLoad() {
    // Call the super method
    super.viewDidLoad()
    // Set the view background color
    view.backgroundColor = .black
    // Setup the Video Player
    setupVideoPlayer()
    // Setup the Done Button
    setupDoneButton()
    // Setup the Close Button
    setupCloseButton()
    // Setup the Add Text Button
    setupAddTextButton()
    // Setup the Delete Bin View
    setupDeleteBinView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    playerLayer.frame = view.bounds
  }

  /// UI Element Setup
  private func setupVideoPlayer() {
    guard let composition: AVMutableComposition = composition else { return }

    let playerItem: AVPlayerItem = AVPlayerItem(asset: composition)
    playerItem.videoComposition = videoComposition

    queuePlayer = AVQueuePlayer(playerItem: playerItem)
    if let queuePlayer: AVQueuePlayer = queuePlayer {
      playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

      playerLayer = AVPlayerLayer(player: queuePlayer)
      playerLayer.videoGravity = .resizeAspectFill
      playerLayer.frame = view.bounds
      view.layer.addSublayer(playerLayer)

      queuePlayer.play()
    }
  }

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

    // Setup Done Button
  private func setupDoneButton() {
    self.doneButton.translatesAutoresizingMaskIntoConstraints = false

    let image = UIImage(
      systemName: "checkmark.circle.fill",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    )

    self.doneButton.setImage(image, for: .normal)
    self.doneButton.tintColor = .white

    // Remove extra padding around image
    self.doneButton.contentEdgeInsets = .zero
    self.doneButton.imageEdgeInsets = .zero
    self.doneButton.imageView?.contentMode = .scaleAspectFit

    // Optional: round background
    self.doneButton.layer.cornerRadius = 8
    self.doneButton.clipsToBounds = true

    self.view.addSubview(self.doneButton)

    NSLayoutConstraint.activate([
      self.doneButton.centerYAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor,
        constant: -56.0
      ),
      self.doneButton.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -16.0
      ),
      self.doneButton.widthAnchor.constraint(equalToConstant: 32),
      self.doneButton.heightAnchor.constraint(equalToConstant: 32)
    ])

    // Add the target action for the Done Button
    self.doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
  }

  private func setupAddTextButton() {
    self.addTextButton.translatesAutoresizingMaskIntoConstraints = false
    let image = UIImage(
      systemName: "textformat",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    )

    self.addTextButton.setImage(image, for: .normal)
    self.addTextButton.tintColor = .white
    self.addTextButton.contentEdgeInsets = .zero
    self.addTextButton.imageEdgeInsets = .zero
    self.addTextButton.imageView?.contentMode = .scaleAspectFit
    self.addTextButton.layer.cornerRadius = 8
    self.addTextButton.clipsToBounds = true
    self.view.addSubview(self.addTextButton)

    NSLayoutConstraint.activate([
      self.addTextButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 96.0),
      self.addTextButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16.0),
      self.addTextButton.widthAnchor.constraint(equalToConstant: 36),
      self.addTextButton.heightAnchor.constraint(equalToConstant: 36)
    ])

    self.addTextButton.addTarget(self, action: #selector(addTextTapped), for: .touchUpInside)
  }

  private func setupDeleteBinView() {
    deleteBinView = UIImageView(image: UIImage(systemName: "trash.circle.fill"))
    deleteBinView.tintColor = .white
    deleteBinView.alpha = 0
    deleteBinView.contentMode = .scaleAspectFit
    deleteBinView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(deleteBinView)

    NSLayoutConstraint.activate([
      deleteBinView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      deleteBinView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      deleteBinView.widthAnchor.constraint(equalToConstant: 60),
      deleteBinView.heightAnchor.constraint(equalToConstant: 60)
    ])
  }

  @objc private func closeTapped() {
    if isAddingElement {
      return
    }

    textOverlays.forEach { $0.exitEditMode(animated: false) }
    view.endEditing(true) // 👈 Kill any active text input
    DispatchQueue.main.async {
      let alert = UIAlertController(title: "Discard Changes?", message: "You have unsaved edits. Are you sure you want to discard them?", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
        self.dismissEditor()
      }))
      self.present(alert, animated: true)
    }
  }

  /// Button Handlers
  // MARK: - Done Button Tapped
  @objc private func doneTapped(_ sender: UIButton) {
    guard !isAddingElement, !doneWasTapped else { return }
    doneWasTapped = true

    textOverlays.forEach { $0.exitEditMode(animated: false) }
    guard let composition: AVMutableComposition = composition else { return }

    let outputURL: URL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("mp4")

    let renderSize: CGSize = CGSize(width: 1080, height: 1920)

    // Base layers
    let parentLayer: CALayer = CALayer()
    parentLayer.frame = CGRect(origin: .zero, size: renderSize)
    parentLayer.isGeometryFlipped = true

    let videoLayer: CALayer = CALayer()
    videoLayer.frame = parentLayer.bounds
    parentLayer.addSublayer(videoLayer)

    // Ratio between export pixels and preview points
    let scaleFactor = renderSize.width / view.bounds.width

    // Reuse each overlay's CATextLayer
    for overlay in textOverlays {
      let source = overlay.displayLayer

      let textLayer: CATextLayer = CATextLayer()
      textLayer.string = source.string
      textLayer.font = source.font
      textLayer.fontSize = source.fontSize * scaleFactor  // ← your fix
      textLayer.foregroundColor = source.foregroundColor
      textLayer.alignmentMode = source.alignmentMode
      textLayer.isWrapped = source.isWrapped
      textLayer.truncationMode = source.truncationMode
      textLayer.contentsScale = max(UIScreen.main.scale, 3)
      textLayer.shadowOpacity = source.shadowOpacity
      textLayer.shadowRadius = source.shadowRadius
      textLayer.shadowOffset = source.shadowOffset
      textLayer.shadowColor = source.shadowColor

      // Convert overlay frame from preview space to video export space
      let baseFrame: CGRect
      if let playerFrame: CGRect = playerLayer.videoRectIfAvailable() {
        let normalized = CGRect(
          x: (overlay.frame.minX - playerFrame.minX) / playerFrame.width,
          y: (overlay.frame.minY - playerFrame.minY) / playerFrame.height,
          width: overlay.frame.width / playerFrame.width,
          height: overlay.frame.height / playerFrame.height
        )

        baseFrame = CGRect(
          x: normalized.minX * renderSize.width,
          y: normalized.minY * renderSize.height,
          width: normalized.width * renderSize.width,
          height: normalized.height * renderSize.height
        )
      } else {
        baseFrame = CGRect(
          x: overlay.frame.origin.x / view.bounds.width * renderSize.width,
          y: overlay.frame.origin.y / view.bounds.height * renderSize.height,
          width: overlay.frame.width / view.bounds.width * renderSize.width,
          height: overlay.frame.height / view.bounds.height * renderSize.height
        )
      }

      textLayer.frame = baseFrame

      // Apply rotation and scale exactly as seen on-screen
      textLayer.setAffineTransform(overlay.transform)

      parentLayer.addSublayer(textLayer)
    }

    // Export setup
    guard let videoComposition: AVMutableVideoComposition = videoComposition else { return }
    let export: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)!
    export.outputURL = outputURL
    export.outputFileType = .mp4
    export.shouldOptimizeForNetworkUse = true

    let exportVideoComp: AVMutableVideoComposition = AVMutableVideoComposition()
    exportVideoComp.instructions = videoComposition.instructions
    exportVideoComp.frameDuration = videoComposition.frameDuration
    exportVideoComp.renderSize = renderSize
    exportVideoComp.animationTool = AVVideoCompositionCoreAnimationTool(
      postProcessingAsVideoLayer: videoLayer,
      in: parentLayer
    )
    export.videoComposition = exportVideoComp

    // Async export
    Task { @MainActor in
      do {
        try await export.export(to: outputURL, as: .mp4)
        print("✅ Export completed: \(outputURL.path)")
        self.presentingViewController?.presentingViewController?.dismiss(animated: true)
        self.flutterResult?(outputURL.path)
      } catch {
        print("❌ Export failed: \(error.localizedDescription)")
        self.doneWasTapped = false
      }
    }
  }

  private func dismissEditor() {
    queuePlayer?.pause()
    playerLayer.removeFromSuperlayer()
    queuePlayer = nil
    playerLooper = nil
    textOverlays.removeAll()
    DispatchQueue.main.async {
      self.dismiss(animated: true)
    }
  }

  @objc private func addTextTapped() {
    isAddingElement = true
    updateUIElements()
    let overlay = TextOverlayView(containerView: view, onExit: { [weak self] in
      self?.isAddingElement = false
      self?.updateUIElements()
      self?.filterEmptyTextOverlays()
    })
    overlay.dragDelegate = self
    self.appendTextOverlay(overlay)
  }

  private func appendTextOverlay(_ overlay: TextOverlayView) {
    for existingOverlay in textOverlays {
      if existingOverlay.text.isEmpty {
        existingOverlay.removeFromSuperview()
      }
    }
    // DEBUG: print overlay rect
    print("OVERLAY: \(overlay.frame)")
    textOverlays.append(overlay)
  }

  private func filterEmptyTextOverlays() {
    textOverlays.removeAll { $0.text.isEmpty }
  }

  func updateUIElements() {
    DispatchQueue.main.async {
      self.closeButton.isHidden = self.isAddingElement
      self.addTextButton.isHidden = self.isAddingElement
    }
  }

  deinit {
    queuePlayer?.pause()
    playerLayer.removeFromSuperlayer()
    queuePlayer = nil
    playerLooper = nil
    textOverlays.removeAll()
  }
}

extension VideoReviewViewController: TextOverlayDragDelegate {
  func textOverlay(_ overlay: TextOverlayView, didStartDragging gesture: UIPanGestureRecognizer) {
    UIView.animate(withDuration: 0.2) {
      self.deleteBinView.alpha = 1
      self.deleteBinView.transform = .identity
    }
  }

  func textOverlay(_ overlay: TextOverlayView, didContinueDragging gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: view)
    let binFrame = deleteBinView.frame.insetBy(dx: -20, dy: -20)

    if binFrame.contains(location) {
      UIView.animate(withDuration: 0.1) {
        self.deleteBinView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        self.deleteBinView.tintColor = .red
      }
    } else {
      UIView.animate(withDuration: 0.1) {
        self.deleteBinView.transform = .identity
        self.deleteBinView.tintColor = .white
      }
    }
  }

  func textOverlay(_ overlay: TextOverlayView, didEndDragging gesture: UIPanGestureRecognizer) {
    let location = gesture.location(in: view)
    let binFrame = deleteBinView.frame.insetBy(dx: -20, dy: -20)

    if binFrame.contains(location) {
      UIView.animate(withDuration: 0.2, animations: {
        overlay.alpha = 0
        overlay.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
      }, completion: { _ in
        overlay.removeFromSuperview()
        if let index = self.textOverlays.firstIndex(of: overlay) {
          self.textOverlays.remove(at: index)
        }
      })
    }

    UIView.animate(withDuration: 0.2) {
      self.deleteBinView.alpha = 0
      self.deleteBinView.transform = .identity
      self.deleteBinView.tintColor = .white
    }
  }
}

private extension AVPlayerLayer {
  func videoRectIfAvailable() -> CGRect? {
    if !self.videoRect.isEmpty && self.videoRect.width > 0 {
      return self.videoRect
    }
    return nil
  }
}
