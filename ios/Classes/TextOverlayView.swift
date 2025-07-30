import UIKit

final class TextOverlayView: UIView, UITextViewDelegate {

  // MARK: - Subviews
  private let displayLabel = UILabel()
  private let editTextView = UITextView()
  private var dismissLayer: UIButton?
  private var fontSlider: UISlider?
  private var colorPicker: ColorPickerView?
  private var paintButton: UIButton?

  // MARK: - State
  private var isEditingMode = true
  private let placeholder = "Tap to type"

  private var savedCenter: CGPoint = .zero
  private var savedRotation: CGFloat = 0
  private var savedScale: CGFloat = 1

  // Font settings
  private let characterLimit = 200
  private let minFontSize: CGFloat = 16
  private let maxFontSize: CGFloat = 48
  private var currentFontSize: CGFloat = 28

  // MARK: - Init
  init(containerView: UIView, initialText: String? = nil) {
    let frameWidth = containerView.bounds.width - 40
    let frameHeight = containerView.bounds.height / 3
    let defaultFrame = CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight)

    super.init(frame: defaultFrame)
    setupDisplayLabel()
    setupEditTextView()
    setupGestures()

    center = containerView.center
    containerView.addSubview(self)
    enterEditMode(initialText: initialText, animated: false)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Setup
  private func setupDisplayLabel() {
    displayLabel.textAlignment = .center
    displayLabel.textColor = .white
    displayLabel.font = UIFont.systemFont(ofSize: currentFontSize, weight: .bold)
    displayLabel.numberOfLines = 0
    displayLabel.lineBreakMode = .byWordWrapping
    displayLabel.isUserInteractionEnabled = true
    addSubview(displayLabel)
  }

  private func setupEditTextView() {
    editTextView.delegate = self
    editTextView.textAlignment = .center
    editTextView.font = UIFont.systemFont(ofSize: currentFontSize, weight: .bold)
    editTextView.textColor = .lightGray
    editTextView.backgroundColor = .clear
    editTextView.isScrollEnabled = true
    editTextView.returnKeyType = .default
    editTextView.textContainer.lineBreakMode = .byWordWrapping
    editTextView.textContainerInset = .zero
    addSubview(editTextView)
  }

  // MARK: - Toolbar Button
  private func setupPaintButton(in containerView: UIView) {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "paintpalette.fill"), for: .normal)
    button.tintColor = .white
    button.frame = CGRect(x: 64, y: containerView.safeAreaInsets.top + 16, width: 32, height: 32)
    button.addTarget(self, action: #selector(toggleColorPicker), for: .touchUpInside)
    containerView.addSubview(button)
    paintButton = button
  }

  private func removePaintButton() {
    paintButton?.removeFromSuperview()
    paintButton = nil
  }

  @objc private func toggleColorPicker() {
    guard let containerView = superview else { return }
    if let picker = colorPicker {
      picker.hide()
      colorPicker = nil
      return
    }

    let picker = ColorPickerView()
    picker.onColorSelected = { [weak self] color in
      self?.displayLabel.textColor = color
      self?.editTextView.textColor = color
    }
    print("Container Height: \(containerView.bounds.height)")
    let yPosition = containerView.bounds.height - 400 // Position above keyboard (approx)
    print("Color Picker Y Position: \(yPosition)")
    picker.show(in: containerView, at: CGPoint(x: 20, y: yPosition), width: containerView.bounds.width - 40, height: 50)
    colorPicker = picker
  }

  // MARK: - Edit Mode
  func enterEditMode(initialText: String? = nil, animated: Bool = true) {
    guard let containerView = superview else { return }

    if !isEditingMode {
      savedCenter = center
    }

    isEditingMode = true
    editTextView.isHidden = false
    displayLabel.isHidden = true
    editTextView.text = initialText ?? displayLabel.text ?? placeholder
    editTextView.textColor = editTextView.text == placeholder ? .lightGray : .white

    // Reset transform for editing
    self.transform = .identity
    self.bounds = CGRect(x: 0, y: 0, width: containerView.bounds.width - 40, height: containerView.bounds.height / 3)
    self.center = containerView.center

    addDismissLayer(to: containerView)
    setupFontSlider(in: containerView)
    setupPaintButton(in: containerView)

    editTextView.font = displayLabel.font
    editTextView.becomeFirstResponder()
  }

  func exitEditMode(animated: Bool = true) {
    isEditingMode = false
    editTextView.resignFirstResponder()

    let finalText = editTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    displayLabel.text = finalText.isEmpty || finalText == placeholder ? "" : finalText

    dismissLayer?.removeFromSuperview()
    removeFontSlider()
    removePaintButton()
    colorPicker?.hide()
    colorPicker = nil

    if savedCenter == .zero, let superview = superview {
      savedCenter = superview.center
    }

    self.center = savedCenter
    self.transform = CGAffineTransform(rotationAngle: savedRotation).scaledBy(x: savedScale, y: savedScale)

    editTextView.isHidden = true
    displayLabel.isHidden = false
  }

  // MARK: - Helpers
  private func addDismissLayer(to containerView: UIView) {
    let dismissButton = UIButton(frame: containerView.bounds)
    dismissButton.backgroundColor = .clear
    dismissButton.addTarget(self, action: #selector(dismissEditing), for: .touchUpInside)
    containerView.insertSubview(dismissButton, belowSubview: self)
    self.dismissLayer = dismissButton
  }

  @objc private func dismissEditing() {
    exitEditMode(animated: true)
  }

  // MARK: - Font Slider
  private func setupFontSlider(in containerView: UIView) {
    let sliderHeight = containerView.bounds.height / 3
    let slider = UISlider(frame: CGRect(x: 0, y: 0, width: sliderHeight, height: 30))

    slider.minimumValue = Float(minFontSize)
    slider.maximumValue = Float(maxFontSize)
    slider.value = Float(currentFontSize)

    slider.transform = CGAffineTransform(rotationAngle: -.pi / 2)
    slider.center = CGPoint(x: 20, y: ((containerView.bounds.height / 4 ) + 48.0))

    let thumbSize: CGFloat = 18
    let thumbImage = UIGraphicsImageRenderer(size: CGSize(width: thumbSize, height: thumbSize)).image { ctx in
      UIColor.white.setFill()
      ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: thumbSize, height: thumbSize)))
    }
    slider.setThumbImage(thumbImage, for: .normal)

    slider.minimumTrackTintColor = .white
    slider.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)

    slider.addTarget(self, action: #selector(fontSliderChanged(_:)), for: .valueChanged)

    containerView.addSubview(slider)
    self.fontSlider = slider
  }

  private func removeFontSlider() {
    fontSlider?.removeFromSuperview()
    fontSlider = nil
  }

  @objc private func fontSliderChanged(_ sender: UISlider) {
    currentFontSize = CGFloat(sender.value)
    displayLabel.font = UIFont.systemFont(ofSize: currentFontSize, weight: .bold)
    editTextView.font = displayLabel.font
  }

  // MARK: - Gestures
  private func setupGestures() {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleScale(_:)))
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2

    addGestureRecognizer(panGesture)
    addGestureRecognizer(rotateGesture)
    addGestureRecognizer(pinchGesture)
    addGestureRecognizer(doubleTapGesture)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    displayLabel.frame = bounds
    editTextView.frame = bounds
  }

  // MARK: - Gesture Handlers
  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard !isEditingMode else { return }
    let translation = gesture.translation(in: superview)
    center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
    gesture.setTranslation(.zero, in: superview)
    savedCenter = center
  }

  @objc private func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard !isEditingMode else { return }
    savedRotation += gesture.rotation
    transform = CGAffineTransform(rotationAngle: savedRotation).scaledBy(x: savedScale, y: savedScale)
    gesture.rotation = 0
  }

  @objc private func handleScale(_ gesture: UIPinchGestureRecognizer) {
    guard !isEditingMode else { return }
    savedScale *= gesture.scale
    transform = CGAffineTransform(rotationAngle: savedRotation).scaledBy(x: savedScale, y: savedScale)
    gesture.scale = 1.0
  }

  @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
    if !isEditingMode {
      enterEditMode(initialText: displayLabel.text)
    }
  }

  // MARK: - UITextViewDelegate
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.text == placeholder {
      textView.text = ""
      textView.textColor = .white
    }
  }

  func textViewDidChange(_ textView: UITextView) {
    if textView.text.count > characterLimit {
      textView.text = String(textView.text.prefix(characterLimit))
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    exitEditMode()
  }

  func textView(_ textView: UITextView,
                shouldChangeTextIn range: NSRange,
                replacementText text: String) -> Bool {
    // Block enter key (new lines)
    if text == "\n" { return false }
    return true
  }
}
