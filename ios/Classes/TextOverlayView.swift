import UIKit

final class TextOverlayView: UIView, UITextViewDelegate {
  
  // MARK: - Subviews
  private let displayLabel = UILabel()
  private let editTextView = UITextView()
  private var dismissLayer: UIButton?
  
  // MARK: - State
  private var isEditingMode = true
  private let placeholder = "Tap to type"
  
  private var savedTransform: CGAffineTransform = .identity
  private var savedCenter: CGPoint = .zero
  private var isFirstEdit = true
  private var logicalTextWidth: CGFloat?
  
  // Character limit
  private let characterLimit = 200
  
  // Font scaling
  private let maxLinesBeforeScaling = 5
  private let minFontSize: CGFloat = 18
  private let defaultFontSize: CGFloat = 28
  
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
    
    logicalTextWidth = containerView.bounds.width - 40 // 20pt margin each side
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
    displayLabel.font = UIFont.systemFont(ofSize: defaultFontSize, weight: .bold)
    displayLabel.numberOfLines = 0
    displayLabel.lineBreakMode = .byWordWrapping
    displayLabel.isUserInteractionEnabled = true
    addSubview(displayLabel)
  }
  
  private func setupEditTextView() {
    editTextView.delegate = self
    editTextView.textAlignment = .center
    editTextView.font = UIFont.systemFont(ofSize: defaultFontSize, weight: .bold)
    editTextView.textColor = .lightGray
    editTextView.backgroundColor = .clear
    editTextView.isScrollEnabled = false
    editTextView.returnKeyType = .default
    editTextView.textContainer.lineBreakMode = .byWordWrapping
    editTextView.textContainerInset = .zero
    addSubview(editTextView)
  }
  
  private func setupGestures() {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
    let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate(_:)))
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2
    
    addGestureRecognizer(panGesture)
    addGestureRecognizer(pinchGesture)
    addGestureRecognizer(rotateGesture)
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
    // Middle of the top third
    return CGPoint(x: containerView.bounds.midX, y: containerView.bounds.height / 3)
  }
  
  private func adjustHeightForText(_ text: String) {
    // Measure text
    let maxSize = CGSize(width: frame.width, height: .greatestFiniteMagnitude)
    let boundingRect = (text as NSString).boundingRect(
      with: maxSize,
      options: .usesLineFragmentOrigin,
      attributes: [.font: displayLabel.font ?? UIFont.systemFont(ofSize: defaultFontSize)],
      context: nil
    )
    
    var newFrame = frame
    newFrame.size.height = boundingRect.height + 10
    frame = newFrame
    
    // Adjust font size if too many lines
    let lineHeight = displayLabel.font.lineHeight
    let lineCount = Int(ceil(boundingRect.height / lineHeight))
    
    if lineCount > maxLinesBeforeScaling {
      let scale = CGFloat(maxLinesBeforeScaling) / CGFloat(lineCount)
      let newFontSize = max(minFontSize, defaultFontSize * scale)
      displayLabel.font = UIFont.systemFont(ofSize: newFontSize, weight: .bold)
      editTextView.font = displayLabel.font
    } else {
      displayLabel.font = UIFont.systemFont(ofSize: defaultFontSize, weight: .bold)
      editTextView.font = displayLabel.font
    }
    
    // Keep vertically centered in top third
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
  
  @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
    guard !isEditingMode else { return }
    transform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
    gesture.scale = 1
    savedTransform = transform
  }
  
  @objc private func handleRotate(_ gesture: UIRotationGestureRecognizer) {
    guard !isEditingMode else { return }
    transform = transform.rotated(by: gesture.rotation)
    gesture.rotation = 0
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
    // Enforce character limit
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
