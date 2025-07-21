import UIKit
import AVFoundation
import Flutter

private let recordCircleInitialSize: CGFloat = 32
private let recordCircleHasVideosSize: CGFloat = 24
private let progressCircleStartAngle: CGFloat = -.pi / 2
private let progressCircleEndAngle: CGFloat = (.pi * 2) - (.pi / 2)

class NewVideoViewController: UIViewController {
  var flutterResult: FlutterResult?

  // Plugin Parameters
  var recordTimes: [Int] = []
  var recordTime: Int = 0

  // Video Capture
  var captureSession: AVCaptureSession = AVCaptureSession()
  var currentInput: AVCaptureDeviceInput?
  var previewLayer: AVCaptureVideoPreviewLayer?
  var isRecording: Bool = false
  var doneWasTapped: Bool = false
  var currentOutput: AVCaptureMovieFileOutput?
  // TODO: add an array of recorded videos with metadata
  var recordedVideos: [AVURLAsset] = []

  // Video File
  var finalID: String = UUID().uuidString

  // Video Composition
  var composer: SpielbergoComposer = SpielbergoComposer()

  // Buttons
  var recordButton: UIButton!
  var deleteButton: UIButton!
  var switchCameraButton: UIButton!
  var closeButton: UIButton!
  var doneButton: UIButton!

  // Scroll view for time selection
  var timeSelectorScrollView: UIScrollView!
  var timeButtons: [UIButton] = []

  // Progress layers for recording
  var progressBaseLayer: CAShapeLayer!
  var progressLayer: CAShapeLayer!
  var progressTimer: Timer?
  var recordingStartTime: Date?

  // Record circle layer
  var recordCircleLayer: CAShapeLayer!
  // Record square layer
  var recordSquareLayer: CAShapeLayer!

  // Required initializer for using Storyboards
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // Initialize with parameters
  init(recordTimes: [Int], flutterResult: @escaping FlutterResult) {
    // Set the class parameters
    self.recordTimes = recordTimes
    self.flutterResult = flutterResult

    // Set the final video id
    self.finalID = UUID().uuidString

    // Set the buttons
    self.recordButton = UIButton(type: .custom)
    self.doneButton = UIButton(type: .custom)
    self.deleteButton = UIButton(type: .custom)
    self.switchCameraButton = UIButton(type: .custom)
    self.closeButton = UIButton(type: .close)

    // Set the default record time
    if !recordTimes.isEmpty {
      self.recordTime = recordTimes[0]
    }

    // Call the super initializer
    super.init(nibName: nil, bundle: nil)
  }

  // View Lifecycle
  override func viewDidLoad() {
    // Call the super method
    super.viewDidLoad()
    // Set the view background color
    view.backgroundColor = .black
    // Setup the camera preview
    setupCameraPreview()
    // Setup the Done Button
    setupDoneButton()
    // Setup the Close Button
    setupCloseButton()
    // Setup the Delete Button
    setupDeleteButton()
    // Setup the Time Selector
    setupTimeSelector()
    // Setup the Record Button
    setupRecordButton()
    // Setup the Switch Camera Button
    setupSwitchCameraButton()
    // TODO: set up buttons and their actions
  }

  // View Layout
  override func viewDidLayoutSubviews() {
    // Call the super method
    super.viewDidLayoutSubviews()

    // Layout the preview layer
    guard let previewLayer: AVCaptureVideoPreviewLayer = self.previewLayer else {
      return
    }

    // Set the frame of the preview layer to be 9:16 aspect ratio
    let screenWidth = view.bounds.width
    let height = screenWidth * (16.0 / 9.0)
    let yOrigin = view.safeAreaInsets.top

    // Set the frame of the preview layer
    previewLayer.frame = CGRect(x: 0, y: yOrigin, width: screenWidth, height: height)
  }
  /// Setup View Methods
  // Setup Camera Preview Layer
  func setupCameraPreview() {
    // Set the Capture Session Preset
    captureSession.sessionPreset = .high

    // Get the default video device
    guard let camera: AVCaptureDevice = AVCaptureDevice.default(
      .builtInWideAngleCamera,
      for: .video,
      position: .front
    ) else {
      flutterResult?(FlutterError(code: "NO_CAMERA", message: "No camera found", details: nil))
      return
    }

    // Create an input from the camera
    do {
      // Camera input
      let cameraInput = try AVCaptureDeviceInput(device: camera)
      if captureSession.canAddInput(cameraInput) {
        captureSession.addInput(cameraInput)
        self.currentInput = cameraInput
      } else {
        flutterResult?(FlutterError(code: "INPUT_ERROR", message: "Cannot add camera input", details: nil))
        return
      }

      // Microphone input
      if let mic: AVCaptureDevice = AVCaptureDevice.default(for: .audio) {
        let micInput = try AVCaptureDeviceInput(device: mic)
        if captureSession.canAddInput(micInput) {
          captureSession.addInput(micInput)
        } else {
          flutterResult?(FlutterError(code: "INPUT_ERROR", message: "Cannot add microphone input", details: nil))
          return
        }
      } else {
        flutterResult?(FlutterError(code: "NO_MICROPHONE", message: "No microphone found", details: nil))
        return
      }

      // Movie file output
      let output: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
      if captureSession.canAddOutput(output) {
        captureSession.addOutput(output)
        self.currentOutput = output
      } else {
        flutterResult?(FlutterError(code: "OUTPUT_ERROR", message: "Cannot add movie file output", details: nil))
        return
      }

      // Preview layer
      let layer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      layer.videoGravity = .resizeAspectFill
      layer.cornerRadius = 20.0
      layer.masksToBounds = true
      layer.frame = view.bounds
      view.layer.addSublayer(layer)
      self.previewLayer = layer

      // Start the capture session
      DispatchQueue.global(qos: .background).async {
        self.captureSession.startRunning()
      }
    } catch {
      flutterResult?(FlutterError(code: "INPUT_ERROR", message: "Error setting up camera input", details: error.localizedDescription))
      return
    }
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

    self.doneButton.isHidden = true // Hide by default
    // Add the target action for the Done Button
    self.doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
  }

  // Setup the Close Button
  private func setupCloseButton() {
    // Add the Close Button to the view
    self.closeButton.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(self.closeButton)

    // Position the Close Button 16 points from the leading edge
    // and 16 points from the top edge of the safe area
    NSLayoutConstraint.activate([
      self.closeButton.leadingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.leadingAnchor,
        constant: 16.0
      ),
      self.closeButton.topAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor,
        constant: 16.0
      ),
    ])

    // Add the target action for the Close Button
    self.closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
  }

  private func setupDeleteButton() {
    self.deleteButton.translatesAutoresizingMaskIntoConstraints = false

    let image = UIImage(
      systemName: "delete.left.fill",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    )

    self.deleteButton.setImage(image, for: .normal)
    self.deleteButton.tintColor = .white

    // Remove extra padding around image
    self.deleteButton.contentEdgeInsets = .zero
    self.deleteButton.imageEdgeInsets = .zero
    self.deleteButton.imageView?.contentMode = .scaleAspectFit

    // Optional: round background
    self.deleteButton.layer.cornerRadius = 8
    self.deleteButton.clipsToBounds = true

    self.view.addSubview(self.deleteButton)

    NSLayoutConstraint.activate([
      self.deleteButton.centerYAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.bottomAnchor,
        constant: -56.0
      ),
      self.deleteButton.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -96.0
      ),
      self.deleteButton.widthAnchor.constraint(equalToConstant: 48),
      self.deleteButton.heightAnchor.constraint(equalToConstant: 32)
    ])

    self.deleteButton.isHidden = true // Hide by default
    // Add the target action for the Delete Button
    self.deleteButton.addTarget(self, action: #selector(deleteLastClip), for: .touchUpInside)
  }

  // Setup the Time Selector
  private func setupTimeSelector() {
    // Check if recordTimes is empty
    if !recordTimes.isEmpty {
      timeSelectorScrollView = UIScrollView()
      timeSelectorScrollView.showsHorizontalScrollIndicator = false
      timeSelectorScrollView.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(timeSelectorScrollView)

      NSLayoutConstraint.activate([
        // Position the scroll view to just above the record button
        timeSelectorScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
        timeSelectorScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        timeSelectorScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110),
        timeSelectorScrollView.heightAnchor.constraint(equalToConstant: 40)
      ])

      var lastAnchor = timeSelectorScrollView.leadingAnchor
      for (index, time) in recordTimes.enumerated() {
          let button = UIButton(type: .system)
          button.setTitle("\(secondsToString(time))", for: .normal)
          button.setTitleColor(.white, for: .normal)
          button.titleLabel?.font = .systemFont(ofSize: 10, weight: .bold)
          button.backgroundColor = time == recordTime ? .darkGray : .black
          button.layer.cornerRadius = 16
          button.tag = index
          button.translatesAutoresizingMaskIntoConstraints = false
          button.addTarget(self, action: #selector(didSelectRecordTime(_:)), for: .touchUpInside)
          if index == 0 {
            button.backgroundColor = .darkGray
          }

          timeSelectorScrollView.addSubview(button)
          NSLayoutConstraint.activate([
              button.leadingAnchor.constraint(equalTo: lastAnchor, constant: index == 0 ? 0 : 12),
              button.centerYAnchor.constraint(equalTo: timeSelectorScrollView.centerYAnchor),
              button.heightAnchor.constraint(equalToConstant: 36),
              button.widthAnchor.constraint(equalToConstant: 40)
          ])

          lastAnchor = button.trailingAnchor
          timeButtons.append(button)
      }

      // Adjust content size
      timeSelectorScrollView.contentSize = CGSize(width: recordTimes.count * 72, height: 40)
    }
  }

  // Setup the Record Button
  private func setupRecordButton() {
    // Remove previous layers if any
    recordCircleLayer?.removeFromSuperlayer()
    recordSquareLayer?.removeFromSuperlayer()

    // Initialize the Record Button
    self.recordButton.backgroundColor = .clear
    self.recordButton.translatesAutoresizingMaskIntoConstraints = false
    self.view.addSubview(recordButton)
    NSLayoutConstraint.activate([
      self.recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      self.recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      self.recordButton.widthAnchor.constraint(equalToConstant: 70),
      self.recordButton.heightAnchor.constraint(equalToConstant: 70)
    ])
    // Add the target action for the Record Button
    self.recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)

    // Draw the red circle with white border
    let circleLayer = CAShapeLayer()
    let circlePath = UIBezierPath(
      arcCenter: CGPoint(x: 35, y: 35),
      radius: recordCircleInitialSize,
      startAngle: 0,
      endAngle: .pi * 2,
      clockwise: true
    )
    circleLayer.path = circlePath.cgPath
    circleLayer.fillColor = UIColor.red.cgColor
    circleLayer.strokeColor = UIColor.white.cgColor
    circleLayer.lineWidth = 4
    self.recordButton.layer.addSublayer(circleLayer)
    self.recordCircleLayer = circleLayer

    // Prepare the white square layer (hidden by default)
    let squareLayer = CAShapeLayer()
    let squareSize: CGFloat = 32
    let squarePath = UIBezierPath(
      roundedRect: CGRect(x: 35 - squareSize/2, y: 35 - squareSize/2, width: squareSize, height: squareSize),
      cornerRadius: 8
    )
    squareLayer.path = squarePath.cgPath
    squareLayer.fillColor = UIColor.white.cgColor
    squareLayer.isHidden = true
    self.recordButton.layer.addSublayer(squareLayer)
    self.recordSquareLayer = squareLayer

    // If we have recording times, add a white circle around the record button
    if !recordTimes.isEmpty {
      // Create the base progress layer
      progressBaseLayer = CAShapeLayer()
      let baseCirclePath = UIBezierPath(
        arcCenter: CGPoint(x: 35, y: 35),
        radius: 32,
        startAngle: progressCircleStartAngle,
        endAngle: progressCircleEndAngle,
        clockwise: true
      )
      progressBaseLayer.path = baseCirclePath.cgPath
      progressBaseLayer.fillColor = UIColor.clear.cgColor
      progressBaseLayer.strokeColor = UIColor.white.cgColor
      progressBaseLayer.lineWidth = 4
      self.recordButton.layer.addSublayer(progressBaseLayer)

      // Create the progress layer
      progressLayer = CAShapeLayer()
      progressLayer.path = baseCirclePath.cgPath
      progressLayer.fillColor = UIColor.clear.cgColor
      progressLayer.strokeColor = UIColor.red.cgColor
      progressLayer.lineWidth = 4
      progressLayer.strokeEnd = 0.0 // Start with no progress
      self.recordButton.layer.addSublayer(progressLayer)
    }
  }

  // Setup Switch Camera Button
  private func setupSwitchCameraButton() {
    self.switchCameraButton.translatesAutoresizingMaskIntoConstraints = false

    let image = UIImage(
      // systemName: "arrow.trianglehead.2.clockwise",
      systemName: "arrow.trianglehead.2.clockwise.rotate.90.camera.fill",
      withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    )

    self.switchCameraButton.setImage(image, for: .normal)
    self.switchCameraButton.tintColor = .white

    // Remove extra padding around image
    self.switchCameraButton.contentEdgeInsets = .zero
    self.switchCameraButton.imageEdgeInsets = .zero
    self.switchCameraButton.imageView?.contentMode = .scaleAspectFit

    // Optional: round background
    self.switchCameraButton.layer.cornerRadius = 8
    self.switchCameraButton.clipsToBounds = true

    self.view.addSubview(self.switchCameraButton)

    NSLayoutConstraint.activate([
      self.switchCameraButton.centerYAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.topAnchor,
        constant: 32.0
      ),
      self.switchCameraButton.trailingAnchor.constraint(
        equalTo: view.safeAreaLayoutGuide.trailingAnchor,
        constant: -16.0
      ),
      self.switchCameraButton.widthAnchor.constraint(equalToConstant: 32),
      self.switchCameraButton.heightAnchor.constraint(equalToConstant: 32)
    ])

    self.switchCameraButton.isHidden = false // Show by default
    // Add the target action for the Switch Camera Button
    self.switchCameraButton.addTarget(self, action: #selector(switchCameraTapped), for: .touchUpInside)
  }

  /// Button Handlers
  // Done Button
  @objc private func doneTapped(_ sender: UIButton) {
    print("Done button tapped")
    // If the done button was already tapped, return early
    if doneWasTapped {
      print("Done button was already tapped, returning early")
      return
    }
    // If there are no recorded videos, return early
    guard !recordedVideos.isEmpty else {
      print("No recorded videos to process")
      return
    }
    // Set the doneWasTapped flag to true
    doneWasTapped = true

    // Create the composition
    createComposition()
    // // Dismiss the view controller
    // dismiss(animated: true) {
    //   // Clear the recorded videos array
    //   self.recordedVideos.removeAll()
    //   // Clear the Flutter result
    //   self.flutterResult = nil
    // }
  }
  // Close Dialog
  @objc private func closeTapped(_ sender: UIButton) {
    if isRecording {
      currentOutput?.stopRecording()
      isRecording = false
    }
    for item in recordedVideos {
      try? FileManager.default.removeItem(at: item.url)
    }
    recordedVideos.removeAll()
    // Call the Flutter result with nil to indicate cancellation
    flutterResult?(nil)
    dismiss(animated: true)
  }

  // Select Record Time
  @objc private func didSelectRecordTime(_ sender: UIButton) {
    for (index, button) in timeButtons.enumerated() {
        button.backgroundColor = index == sender.tag ? .darkGray : .black
    }
    let selectedTime = recordTimes[sender.tag]
    self.recordTime = selectedTime
    print("⏱ Selected record time: \(recordTime)s")
  }

  // Toggle Recording
  @objc private func recordTapped(_ sender: UIButton) {
    if doneWasTapped {
      return
    }
    guard let output = currentOutput else {
      flutterResult?(FlutterError(code: "OUTPUT_ERROR", message: "Error setting up camera output", details: nil))
      return
    }
    if isRecording {
      // Invalidate the timer if recording is stopped
      progressTimer?.invalidate()
      progressTimer = nil

      // Stop recording
      output.stopRecording()

      isRecording = false
    } else {
      // Toggle the Progress Layer
      recordingStartTime = Date()

      progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
        guard let self = self, let start = self.recordingStartTime else { return }

        let currentElapsed = Date().timeIntervalSince(start)
        let totalElapsed = self.totalRecordedDuration() + currentElapsed
        let progress = min(CGFloat(totalElapsed) / CGFloat(self.recordTime), 1.0)

        self.progressLayer.strokeEnd = progress

        if progress >= 1.0 {
          self.recordTapped(self.recordButton) // auto-stop
        }

        self.toggleRecordButtonVisibility()
      }

      // Update the UI visibility based on the recording state
      self.updateUIVisibility()

      // Start recording
      let filename = UUID().uuidString + ".mov"
      let tempDir = FileManager.default.temporaryDirectory
      let fileURL = tempDir.appendingPathComponent(filename)
      output.startRecording(to: fileURL, recordingDelegate: self)
      isRecording = true
    }
  }

  // Delete Last Recorded Clip
  @objc private func deleteLastClip(_ sender: UIButton) {
    guard !recordedVideos.isEmpty else { return }
    let lastVideo = recordedVideos.removeLast()
    do {
      try FileManager.default.removeItem(at: lastVideo.url)
      print("Deleted last video: \(lastVideo.url)")
    } catch {
      print("Error deleting video: \(error.localizedDescription)")
    }

    // Update the UI visibility based on the recording state
    updateUIVisibility()
    // Update the progress layer angle
    updateProgressLayerAngle()
  }

  // Switch Camera
  @objc private func switchCameraTapped(_ sender: UIButton) {
    guard let currentInput = self.currentInput else { return }
    if !captureSession.isRunning {
      flutterResult?(FlutterError(code: "CAMERA_ERROR", message: "Cannot switch camera, the session isn't running", details: nil))
      return
    }
    if !isRecording {
      let newPosition: AVCaptureDevice.Position = currentInput.device.position == .front ? .back : .front
      print("Switching camera to: \(newPosition == .front ? "Front" : "Back")")

      guard let newCamera: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) else {
        flutterResult?(FlutterError(code: "CAMERA_ERROR", message: "Cannot add camera capture device", details: nil))
        return
      }

      do {
        let newInput = try AVCaptureDeviceInput(device: newCamera)
        captureSession.beginConfiguration()
        captureSession.removeInput(currentInput)
        if captureSession.canAddInput(newInput) {
          captureSession.addInput(newInput)
          self.currentInput = newInput
        } else {
          captureSession.addInput(currentInput)
        }
        captureSession.commitConfiguration()
      } catch {
        flutterResult?(FlutterError(code: "CAMERA_ERROR", message: "Cannot switch camera", details: error.localizedDescription))
        return
      }
    }
  }

  /// Composition Creation
  private func createComposition() {
    DispatchQueue.main.async {
      Task {
        await self.composer.createMutableComposition(
          assets: self.recordedVideos
        ) { [weak self] result in
          // NO async work here
          guard let self = self else { return }
          switch result {
            case .success(let composition, let videoComposition):
              Task { @MainActor in
                let videoReviewVC = VideoReviewViewController(
                  composition: composition,
                  videoComposition: videoComposition
                )
                self.present(videoReviewVC, animated: false)
              }
            case .failure(let message, let error):
              print("Error creating composition: \(message)")
              if let error = error {
                print("Error details: \(error.localizedDescription)")
              }
          }
        }
      }
    }
  }

  /// Visibility Handlers
  // Handle all visibility of UI elements based on recording state
  private func updateUIVisibility() {
    // Done Button
    toggleDoneButtonVisibility()
    // Record Button
    toggleRecordButtonVisibility()
    // Delete Button
    toggleDeleteButtonVisibility()
    // Switch Button
    toggleSwitchCameraButtonVisibility()
    // Time Selector
    toggleTimeSelectorVisibility()
  }

  // Handle angle of the progress layer based recorded duration
  private func updateProgressLayerAngle() {
    guard let progressLayer = self.progressLayer else { return }
    let totalDuration = totalRecordedDuration()
    let progress = totalDuration / Double(recordTime)
    // Ensure progress is between 0 and 1
    let clampedProgress = max(0, min(progress, 1.0))
    // Update the stroke end of the progress layer
    progressLayer.strokeEnd = progress
  }

  // Handle visibility of the record button based on recording state
  private func toggleRecordButtonVisibility() {
    if recordedVideos.isEmpty {
      recordCircleLayer.path = UIBezierPath(
        arcCenter: CGPoint(x: 35, y: 35),
        radius: recordCircleInitialSize,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
      ).cgPath
      recordCircleLayer.lineWidth = 4
    } else {
      recordCircleLayer.path = UIBezierPath(
        arcCenter: CGPoint(x: 35, y: 35),
        radius: recordCircleHasVideosSize,
        startAngle: 0,
        endAngle: .pi * 2,
        clockwise: true
      ).cgPath
      recordCircleLayer.lineWidth = 0
    }
    if isRecording {
      recordCircleLayer.isHidden = true
      recordSquareLayer.isHidden = false
    } else {
      recordCircleLayer.isHidden = false
      recordSquareLayer.isHidden = true
    }
  }

  // Handle visibility of the time selector scroll view
  private func toggleTimeSelectorVisibility() {
    timeSelectorScrollView?.isHidden = isRecording || !recordedVideos.isEmpty
  }

  // Handle visibility of the done button
  private func toggleDoneButtonVisibility() {
    doneButton.isHidden = recordedVideos.isEmpty || isRecording || doneWasTapped
  }

  // Handle visibility of the delete button
  private func toggleDeleteButtonVisibility() {
    deleteButton.isHidden = recordedVideos.isEmpty || isRecording
  }

  // Handle visibility of the switch camera button
  private func toggleSwitchCameraButtonVisibility() {
    switchCameraButton.isHidden = isRecording
  }

  /// Helper Functions
  // Convert seconds to a string in the format {x}m{y}s
  // where x is the number of minutes and y is the number of seconds
  // e.g. 90 seconds -> "1m30s"
  private func secondsToString(_ seconds: Int) -> String {
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    if minutes == 0 {
      return "\(remainingSeconds)s"
    }
    if remainingSeconds == 0 {
      return "\(minutes)m"
    }
    return "\(minutes)m\(remainingSeconds)s"
  }

  // Calculate the total recorded duration from all recorded videos
  private func totalRecordedDuration() -> TimeInterval {
    var duration: TimeInterval = 0
    for asset in recordedVideos {
      duration += CMTimeGetSeconds(asset.duration)
    }
    return duration
  }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension NewVideoViewController: AVCaptureFileOutputRecordingDelegate {
  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
    if let error = error {
      print("Error recording video: \(error.localizedDescription)")
      // Handle the error (e.g., show an alert to the user)
      return
    }
    // Successfully recorded video
    recordedVideos.append(AVURLAsset(url: outputFileURL))
    print("Video recorded successfully: \(outputFileURL)")

    // TODO: create the composition for the next screen
    if doneWasTapped {
      print("Creating composition for next screen")
      DispatchQueue.main.async {
        Task {
          await self.composer.createMutableComposition(
            assets: self.recordedVideos
          ) { [weak self] result in
            switch result {
              case .success(let composition, let videoComposition):
                // Handle the successful composition creation
                print("Composition created successfully")
              case .failure(let message, let error):
                // Handle the error
                print("Error creating composition: \(message)")
                if let error = error {
                  print("Error details: \(error.localizedDescription)")
                }
            }
          }
        }
      }
    }

    // Update the UI visibility
    self.updateUIVisibility()
  }
}
