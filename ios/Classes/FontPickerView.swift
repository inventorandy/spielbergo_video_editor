import UIKit

final class FontPickerView: UIView {

  // Callback when a font is selected
  var onFontSelected: ((UIFont) -> Void)?

  // Available fonts with readable labels
  private let fonts: [(label: String, fontName: String)] = [
    ("Modern", "Helvetica"),
    ("Strong", "Helvetica-Bold"),
    ("Classic", "TimesNewRomanPS-BoldMT"),
    ("Elegant", "Georgia-Italic"),
    ("Script", "Papyrus"),
    ("Code", "Courier-Bold")
  ]

  private var previewFontSize: CGFloat = 16

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupView()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupView() {
    backgroundColor = .clear
    layer.cornerRadius = 8
    clipsToBounds = true

    let scrollView = UIScrollView()
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.translatesAutoresizingMaskIntoConstraints = false

    let stack = UIStackView()
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false

    for (index, fontInfo) in fonts.enumerated() {
      let font = UIFont(name: fontInfo.fontName, size: previewFontSize) ?? UIFont.systemFont(ofSize: previewFontSize)
      let button = UIButton(type: .system)
      button.setTitle(fontInfo.label, for: .normal)
      button.titleLabel?.font = font
      button.setTitleColor(.white, for: .normal)
      button.backgroundColor = UIColor.darkGray.withAlphaComponent(0.6)
      button.layer.cornerRadius = 8
      button.contentEdgeInsets = UIEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)
      button.tag = index
      button.addTarget(self, action: #selector(fontTapped(_:)), for: .touchUpInside)
      button.translatesAutoresizingMaskIntoConstraints = false
      button.heightAnchor.constraint(equalToConstant: 36).isActive = true // Fixed height
      stack.addArrangedSubview(button)
    }

    scrollView.addSubview(stack)
    addSubview(scrollView)

    NSLayoutConstraint.activate([
      scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
      scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
      scrollView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
      scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),

      stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
      stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      stack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
    ])
  }

  @objc private func fontTapped(_ sender: UIButton) {
    let index = sender.tag
    let fontName = fonts[index].fontName
    let font = UIFont(name: fontName, size: previewFontSize) ?? UIFont.systemFont(ofSize: previewFontSize)
    onFontSelected?(font)
  }

  func show(in containerView: UIView, at position: CGPoint, width: CGFloat = 300, height: CGFloat = 50) {
    self.frame = CGRect(x: position.x, y: position.y, width: width, height: height)
    containerView.addSubview(self)

    alpha = 0
    UIView.animate(withDuration: 0.25) { self.alpha = 1 }
  }

  func hide() {
    UIView.animate(withDuration: 0.25, animations: {
      self.alpha = 0
    }) { _ in
      self.removeFromSuperview()
    }
  }

  func setFontSize(_ size: CGFloat) {
    self.previewFontSize = size
  }
}
