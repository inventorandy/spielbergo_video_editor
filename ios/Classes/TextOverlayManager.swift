import UIKit

final class TextOverlayManager: NSObject, UITextViewDelegate {
  private weak var parentView: UIView?
  private let placeholder = "Tap to type"
  private var lastTransform: CGAffineTransform = .identity
  private var lastCenter: CGPoint = .zero


  init(parentView: UIView) {
    self.parentView = parentView
  }

  /// Adds a new editable text overlay immediately in edit mode.
  func addTextOverlay() {
    guard let parentView = parentView else { return }

    let textView = createTextView(frame: CGRect(
      x: 50,
      y: parentView.bounds.midY - 25,
      width: parentView.bounds.width - 100,
      height: 50
    ))

    // Save initial transform and center
    lastTransform = .identity
    lastCenter = textView.center

    parentView.addSubview(textView)
    textView.becomeFirstResponder()
  }

  // MARK: - Gesture Handlers
  @objc private func handleTextPan(_ gesture: UIPanGestureRecognizer) {
    guard let view = gesture.view else { return }
    let translation = gesture.translation(in: parentView)
    view.center = CGPoint(x: view.center.x + translation.x, y: view.center.y + translation.y)
    gesture.setTranslation(.zero, in: parentView)

    lastCenter = view.center
  }

  @objc private func handleTextPinch(_ gesture: UIPinchGestureRecognizer) {
    guard let view = gesture.view else { return }
    view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
    gesture.scale = 1

    lastTransform = view.transform
  }

  @objc private func handleTextRotate(_ gesture: UIRotationGestureRecognizer) {
    guard let view = gesture.view else { return }
    view.transform = view.transform.rotated(by: gesture.rotation)
    gesture.rotation = 0

    lastTransform = view.transform
  }

  // Double tap: re-enter edit mode
  @objc private func handleTextDoubleTap(_ gesture: UITapGestureRecognizer) {
    guard let label = gesture.view as? UILabel,
          let parentView = parentView else { return }

    // Save the current transform & center
    lastTransform = label.transform
    lastCenter = label.center

    // Reset transform temporarily to extract the untransformed frame
    let originalTransform = label.transform
    label.transform = .identity
    let untransformedFrame = label.frame
    label.transform = originalTransform

    // Create UITextView with untransformed frame
    let textView = createTextView(frame: untransformedFrame)
    textView.text = label.text == " " ? placeholder : label.text
    textView.textColor = label.text == " " ? UIColor.lightGray : UIColor.white

    // Add to parent
    parentView.addSubview(textView)
    label.removeFromSuperview()

    // Reset transform (editing is always upright)
    textView.transform = .identity
    textView.center = lastCenter

    textView.becomeFirstResponder()
  }

  // MARK: - UITextViewDelegate
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.text == placeholder {
      textView.text = ""
      textView.textColor = .white
    }
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      textView.text = placeholder
      textView.textColor = .lightGray
    }
  }

  func textView(_ textView: UITextView,
                shouldChangeTextIn range: NSRange,
                replacementText text: String) -> Bool {
    if text == "\n" {
      textView.resignFirstResponder()
      convertTextViewToLabel(textView)
      return false
    }
    return true
  }

  // MARK: - Helpers
  private func convertTextViewToLabel(_ textView: UITextView) {
    guard let parentView = parentView else { return }

    let label = UILabel(frame: textView.frame)
    label.text = textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || textView.text == placeholder ? " " : textView.text
    label.font = textView.font
    label.textColor = .white
    label.textAlignment = textView.textAlignment
    label.isUserInteractionEnabled = true

    // If this is the first conversion, use textView's center
    if lastCenter == .zero {
      lastCenter = textView.center
    }

    // Apply transform & center
    label.transform = lastTransform
    label.center = lastCenter

    addGestures(to: label)
    textView.removeFromSuperview()
    parentView.addSubview(label)
  }

  private func addGestures(to view: UIView) {
    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleTextPan(_:)))
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handleTextPinch(_:)))
    let rotateGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleTextRotate(_:)))
    let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTextDoubleTap(_:)))
    doubleTapGesture.numberOfTapsRequired = 2

    view.addGestureRecognizer(panGesture)
    view.addGestureRecognizer(pinchGesture)
    view.addGestureRecognizer(rotateGesture)
    view.addGestureRecognizer(doubleTapGesture)
  }

  private func createTextView(frame: CGRect) -> UITextView {
    let textView = UITextView(frame: frame)
    textView.text = placeholder
    textView.textColor = .lightGray
    textView.font = UIFont.systemFont(ofSize: 28, weight: .bold)
    textView.textAlignment = .center
    textView.backgroundColor = .clear
    textView.returnKeyType = .done
    textView.delegate = self
    textView.isScrollEnabled = false
    addGestures(to: textView)
    return textView
  }
}
