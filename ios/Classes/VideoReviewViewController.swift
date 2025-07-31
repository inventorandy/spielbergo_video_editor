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

  // Flags
  private var isAddingElement: Bool = false

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
    setupDeleteBinView()
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    playerLayer.frame = view.bounds
  }

  /// UI Element Setup
  private func setupVideoPlayer() {
    guard let composition = composition else { return }

    let playerItem = AVPlayerItem(asset: composition)
    playerItem.videoComposition = videoComposition

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

    if textOverlays.isEmpty {
      dismissEditor()
    } else {
      let alert = UIAlertController(title: "Discard Changes?", message: "You have unsaved edits. Are you sure you want to discard them?", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      alert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
        self.dismissEditor()
      }))
      present(alert, animated: true)
    }
  }

  private func dismissEditor() {
    queuePlayer?.pause()
    playerLayer.removeFromSuperlayer()
    queuePlayer = nil
    playerLooper = nil
    textOverlays.removeAll()
    dismiss(animated: true)
  }

  @objc private func addTextTapped() {
    isAddingElement = true
    updateUIElements()
    let overlay = TextOverlayView(containerView: view, onExit: { [weak self] in
      self?.isAddingElement = false
      self?.updateUIElements()
    })
    overlay.dragDelegate = self
    textOverlays.append(overlay)
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
