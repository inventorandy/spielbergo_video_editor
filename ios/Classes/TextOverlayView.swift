import UIKit

final class TextOverlayView: UIView, UITextViewDelegate {
  
  // MARK: - Subviews
  private let displayLabel = UILabel()
  private let editTextView = UITextView()
  private var dismissLayer: UIButton?
  private var fontSlider: UISlider?
  
  // MARK: - State
  private var isEditingMode = true
  private let placeholder = "Tap to type"
  
  private var savedTransform: CGAffineTransform = .identity
  private var savedCenter: CGPoint = .zero
  private var isFirstEdit = true
  private var logicalTextWidth: CGFloat?
  
  // Character and font settings
  private let characterLimit = 200
  private let minFontSize: CGFloat = 16
  private let maxFontSize: CGFloat = 48
  private var currentFontSize: CGFloat = 28
  
  // MARK: - Init
  init(containerView: UIView, initialText: String? = nil) {
    let defaultFrame = CGRect(
      x: 0,
      y: 0,
      width: containerView.bounds.width * 0.8,
      height: 50
    )
    super.init(frame: defaultFrame)
    
    setupDisplayLabel()
    setupEditTextView()
    setupGestures()
    
    logicalTextWidth = containerView.bounds.width - 40
    center = editingPosition(in: containerView)
    
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
    editTextView.isScrollEnabled = false
    editTextView.returnKeyType = .default
    editTextView.textContainer.lineBreakMode = .byWordWrapping
    editTextView.textContainerInset = .zero
    addSubview(editTextView)
  }
  
  private func setupFontSlider(in containerView: UIView) {
    let sliderLength = containerView.bounds.height / 3  // Adjust length for top half
    let slider = UISlider(frame: CGRect(x: 0, y: 0, width: sliderLength, height: 30))

    slider.minimumValue = Float(minFontSize)
    slider.maximumValue = Float(maxFontSize)
    slider.value = Float(currentFontSize)
    
    // Rotate 90 degrees counterclockwise
    slider.transform = CGAffineTransform(rotationAngle: -.pi / 2)

    // Position with transform translation
    let xPosition: CGFloat = 20 // flush left with padding
    let yPosition: CGFloat = (containerView.bounds.height / 4) + 40 // center of top half + 40 padding
    slider.center = CGPoint(x: xPosition, y: yPosition)
    
    // Customize thumb
    let thumbSize: CGFloat = 18
    let thumbImage = UIGraphicsImageRenderer(size: CGSize(width: thumbSize, height: thumbSize)).image { ctx in
      UIColor.white.setFill()
      ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: CGSize(width: thumbSize, height: thumbSize)))
    }
    slider.setThumbImage(thumbImage, for: .normal)
    
    // Track colors
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
  
  // MARK: - Font Size Change
  @objc private func fontSliderChanged(_ sender: UISlider) {
    currentFontSize = CGFloat(sender.value)
    displayLabel.font = UIFont.systemFont(ofSize: currentFontSize, weight: .bold)
    editTextView.font = displayLabel.font
    adjustHeightForText(editTextView.text)
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
  
  // MARK: - Editing Modes
  func enterEditMode(initialText: String? = nil, animated: Bool = true) {
    guard let containerView = superview else { return }
    
    if !isEditingMode {
      savedTransform = transform
      savedCenter = center
    }
    
    isEditingMode = true
    editTextView.isHidden = false
    displayLabel.isHidden = true
    editTextView.text = initialText ?? displayLabel.text ?? placeholder
    editTextView.textColor = editTextView.text == placeholder ? .lightGray : .white
    
    addDismissLayer(to: containerView)
    setupFontSlider(in: containerView)
    
    let editWidth = logicalTextWidth ?? (containerView.bounds.width - 40)
    frame.size.width = editWidth
    adjustHeightForText(editTextView.text)
    
    let animations = {
      self.transform = .identity
      self.center = self.editingPosition(in: containerView)
    }
    
    if animated && !isFirstEdit {
      UIView.animate(withDuration: 0.25, animations: animations) { _ in
        self.editTextView.becomeFirstResponder()
      }
    } else {
      animations()
      editTextView.becomeFirstResponder()
      isFirstEdit = false
    }
  }
  
  func exitEditMode(animated: Bool = true) {
    isEditingMode = false
    editTextView.resignFirstResponder()
    
    let finalText = editTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    displayLabel.text = finalText.isEmpty || finalText == placeholder ? "" : finalText
    
    dismissLayer?.removeFromSuperview()
    removeFontSlider()
    
    if savedCenter == .zero {
      savedCenter = superview?.center ?? .zero
    }
    
    let animations = {
      self.transform = self.savedTransform
      self.center = self.savedCenter
    }
    let completion = {
      self.editTextView.isHidden = true
      self.displayLabel.isHidden = false
    }
    
    if animated {
      UIView.animate(withDuration: 0.25, animations: animations) { _ in completion() }
    } else {
      animations()
      completion()
    }
  }
  
  // MARK: - Helpers
  private func editingPosition(in containerView: UIView) -> CGPoint {
    return CGPoint(x: containerView.bounds.midX, y: containerView.bounds.height / 3)
  }
  
  private func adjustHeightForText(_ text: String) {
    let maxSize = CGSize(width: frame.width, height: .greatestFiniteMagnitude)
    let boundingRect = (text as NSString).boundingRect(
      with: maxSize,
      options: .usesLineFragmentOrigin,
      attributes: [.font: displayLabel.font ?? UIFont.systemFont(ofSize: currentFontSize)],
      context: nil
    )
    
    var newFrame = frame
    newFrame.size.height = boundingRect.height + 10
    frame = newFrame
    
    if let containerView = superview {
      center = editingPosition(in: containerView)
    }
  }
  
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
  
  // MARK: - Gestures
  @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
    guard !isEditingMode else { return }
    let translation = gesture.translation(in: superview)
    center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
    gesture.setTranslation(.zero, in: superview)
    savedCenter = center
  }
  
  @objc private func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard !isEditingMode else { return }
    transform = transform.rotated(by: gesture.rotation)
    gesture.rotation = 0
    savedTransform = transform
  }

  @objc private func handleScale(_ gesture: UIPinchGestureRecognizer) {
    guard !isEditingMode else { return }
    let scale = gesture.scale
    transform = transform.scaledBy(x: scale, y: scale)
    gesture.scale = 1.0
    savedTransform = transform
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
    adjustHeightForText(textView.text)
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    exitEditMode()
  }
  
  func textView(_ textView: UITextView,
                shouldChangeTextIn range: NSRange,
                replacementText text: String) -> Bool {
    return true
  }
}
