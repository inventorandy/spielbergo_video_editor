import UIKit

protocol TextOverlayDragDelegate: AnyObject {
  func textOverlay(_ overlay: TextOverlayView, didStartDragging gesture: UIPanGestureRecognizer)
  func textOverlay(_ overlay: TextOverlayView, didContinueDragging gesture: UIPanGestureRecognizer)
  func textOverlay(_ overlay: TextOverlayView, didEndDragging gesture: UIPanGestureRecognizer)
}

final class TextOverlayView: UIView, UITextViewDelegate {
  // MARK: - Callbacks
  var onExit: (() -> Void)?
  weak var dragDelegate: TextOverlayDragDelegate?

  // MARK: - Subviews
  private let displayLabel = UILabel()
  private let editTextView = UITextView()
  private var dismissLayer: UIButton?
  private var fontSlider: UISlider?
  private var colorPicker: ColorPickerView?
  private var fontPicker: FontPickerView?
  private var paintButton: UIButton?
  private var fontPickerButton: UIButton?

  // MARK: - State
  private var isEditingMode = true
  private let placeholder = "Enter text here..."

  private var savedCenter: CGPoint = .zero
  private var savedRotation: CGFloat = 0
  private var savedScale: CGFloat = 1

  // Font settings
  private let characterLimit = 200
  private let minFontSize: CGFloat = 16
  private let maxFontSize: CGFloat = 48
  private var currentFontSize: CGFloat = 28

  // Available fonts with readable labels
  private let fontOptions: [(label: String, fontName: String)] = [
    ("Modern", "Helvetica"),
    ("Strong", "Helvetica-Bold"),
    ("Classic", "TimesNewRomanPS-BoldMT"),
    ("Elegant", "Georgia-Italic"),
    ("Script", "Papyrus"),
    ("Code", "Courier-Bold")
  ]
  private var selectedFontIndex = 0

  // MARK: - Init
  init(containerView: UIView, initialText: String? = nil, onExit: (() -> Void)? = nil) {
    let frameWidth = containerView.bounds.width - 40
    let frameHeight = containerView.bounds.height / 3
    let defaultFrame = CGRect(x: 0, y: 0, width: frameWidth, height: frameHeight)

    super.init(frame: defaultFrame)
    setupDisplayLabel()
    setupEditTextView()
    setupGestures()

    self.onExit = onExit

    center = containerView.center
    containerView.addSubview(self)
    enterEditMode(initialText: initialText, animated: false)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func applyCurrentFont() {
    let fontName = fontOptions[selectedFontIndex].fontName
    let font = UIFont(name: fontName, size: currentFontSize) ?? UIFont.systemFont(ofSize: currentFontSize)
    displayLabel.font = font
    editTextView.font = font
  }

  // MARK: - Setup
  private func setupDisplayLabel() {
    displayLabel.textAlignment = .center
    displayLabel.textColor = .white
    // displayLabel.font = UIFont.systemFont(ofSize: currentFontSize, weight: .bold)
    displayLabel.font = UIFont(name: fontOptions[selectedFontIndex].fontName, size: currentFontSize) ?? UIFont.systemFont(ofSize: currentFontSize)
    displayLabel.numberOfLines = 0
    displayLabel.lineBreakMode = .byWordWrapping
    displayLabel.isUserInteractionEnabled = true
    addSubview(displayLabel)
  }

  private func setupEditTextView() {
    editTextView.delegate = self
    editTextView.textAlignment = .center
    // editTextView.font = UIFont.systemFont(ofSize: currentFontSize, weight: .bold)
    editTextView.font = UIFont(name: fontOptions[selectedFontIndex].fontName, size: currentFontSize) ?? UIFont.systemFont(ofSize: currentFontSize)
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

  private func setupFontPickerButton(in containerView: UIView) {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "textformat.size"), for: .normal)
    button.tintColor = .white
    button.frame = CGRect(x: 112, y: containerView.safeAreaInsets.top + 16, width: 32, height: 32)
    button.addTarget(self, action: #selector(toggleFontPicker), for: .touchUpInside)
    containerView.addSubview(button)
    fontPickerButton = button
  }

  private func removeFontPickerButton() {
    fontPickerButton?.removeFromSuperview()
    fontPickerButton = nil
  }

  // MARK: - Toggle Pickers
  @objc private func toggleColorPicker() {
    guard let containerView = superview else { return }
    fontPicker?.hide()
    fontPicker = nil

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
    let yPosition = containerView.bounds.height - 400 // Position above keyboard (approx)
    picker.show(in: containerView, at: CGPoint(x: 20, y: yPosition), width: containerView.bounds.width - 40, height: 64)
    colorPicker = picker
  }

  @objc private func toggleFontPicker() {
    guard let containerView = superview else { return }
    colorPicker?.hide()
    colorPicker = nil

    if let picker = fontPicker {
      picker.hide()
      fontPicker = nil
      return
    }

    let picker = FontPickerView()
    picker.setFonts(fontOptions, selectedIndex: selectedFontIndex)
    picker.onFontSelected = { [weak self] index in
      self?.selectedFontIndex = index
      self?.applyCurrentFont()
    }
    let yPosition = containerView.bounds.height - 400 // Position above keyboard (approx)
    picker.show(in: containerView, at: CGPoint(x: 20, y: yPosition), width: containerView.bounds.width - 40, height: 64)
    fontPicker = picker
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
    displayLabel.text = initialText ?? placeholder

    if displayLabel.textColor != .clear {
      editTextView.textColor = displayLabel.textColor
    } else {
      editTextView.textColor = .white
    }

    self.transform = .identity
    self.bounds = CGRect(x: 0, y: 0, width: containerView.bounds.width - 40, height: containerView.bounds.height / 3)
    self.center = containerView.center

    addDismissLayer(to: containerView)
    setupFontSlider(in: containerView)
    setupPaintButton(in: containerView)
    setupFontPickerButton(in: containerView)

    editTextView.font = displayLabel.font
    editTextView.becomeFirstResponder()
  }

  func exitEditMode(animated: Bool = true) {
    isEditingMode = false
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.editTextView.resignFirstResponder()

      let finalText = self.editTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
      self.displayLabel.text = finalText.isEmpty ? placeholder : finalText

      self.dismissLayer?.removeFromSuperview()
      self.removeFontSlider()
      self.removePaintButton()
      self.removeFontPickerButton()
      self.colorPicker?.hide()
      self.colorPicker = nil
      self.fontPicker?.hide()
      self.fontPicker = nil

      if self.savedCenter == .zero, let superview = self.superview {
      self.savedCenter = superview.center
      }

      self.center = self.savedCenter
      self.transform = CGAffineTransform(rotationAngle: self.savedRotation).scaledBy(x: self.savedScale, y: self.savedScale)

      self.editTextView.isHidden = true
      self.displayLabel.isHidden = false

      self.onExit?()
    }
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
    applyCurrentFont()
  }

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

    switch gesture.state {
    case .began:
      dragDelegate?.textOverlay(self, didStartDragging: gesture)
    case .changed:
      let translation = gesture.translation(in: superview)
      center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
      gesture.setTranslation(.zero, in: superview)
      savedCenter = center
      dragDelegate?.textOverlay(self, didContinueDragging: gesture)
    case .ended, .cancelled:
      dragDelegate?.textOverlay(self, didEndDragging: gesture)
    default:
      break
    }
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
  // func textViewDidBeginEditing(_ textView: UITextView) {
  //   // if textView.text == placeholder {
  //   //   textView.text = ""
  //   //   textView.textColor = .white
  //   // }
  // }

  func textViewDidChange(_ textView: UITextView) {
    if textView.text.count > characterLimit {
      textView.text = String(textView.text.prefix(characterLimit))
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    exitEditMode()
  }

  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    return text != "\n"
  }

  var text: String {
    return displayLabel.text ?? ""
  }
}
