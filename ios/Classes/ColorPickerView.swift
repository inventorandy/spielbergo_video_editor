import UIKit

final class ColorPickerView: UIView {
  
  // Callback when a color is selected
  var onColorSelected: ((UIColor) -> Void)?
  
  // Available colors
  private let colors: [UIColor]
  
  // MARK: - Init
  init(colors: [UIColor] = [.black, .white, .red, .blue, .green, .yellow, .orange, .purple, .cyan, .magenta]) {
    self.colors = colors
    super.init(frame: .zero)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: - Setup
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
    stack.distribution = .equalSpacing
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    
    // Add color buttons
    for color in colors {
      let button = UIButton(type: .custom)
      button.backgroundColor = color
      button.layer.cornerRadius = 16
      button.layer.borderWidth = 1
      button.layer.borderColor = UIColor.white.cgColor
      button.widthAnchor.constraint(equalToConstant: 32).isActive = true
      button.heightAnchor.constraint(equalToConstant: 32).isActive = true
      button.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
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
  
  // MARK: - Actions
  @objc private func colorTapped(_ sender: UIButton) {
    guard let color = sender.backgroundColor else { return }
    onColorSelected?(color)
  }
  
  // MARK: - Public API
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
}
