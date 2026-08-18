import UIKit

/// Best-effort system capture block for iOS.
/// Screenshots of a secure-layer window are typically black; screen recording
/// is covered with an opaque overlay.
enum CaptureGuard {
  private static var overlay: UIView?
  private static var installed = false

  static func install(on window: UIWindow?) {
    guard let window else { return }
    makeWindowSecure(window)
    if !installed {
      installed = true
      NotificationCenter.default.addObserver(
        forName: UIScreen.capturedDidChangeNotification,
        object: nil,
        queue: .main
      ) { _ in
        updateRecordingOverlay(on: window)
      }
    }
    updateRecordingOverlay(on: window)
  }

  /// UITextField secure-entry layer makes the window contents omitted from
  /// screenshots / the system screen-capture pipeline.
  private static func makeWindowSecure(_ window: UIWindow) {
    guard window.viewWithTag(71_071) == nil else { return }
    let field = UITextField()
    field.isSecureTextEntry = true
    field.isUserInteractionEnabled = false
    field.tag = 71_071
    field.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(field)
    NSLayoutConstraint.activate([
      field.centerXAnchor.constraint(equalTo: window.centerXAnchor),
      field.centerYAnchor.constraint(equalTo: window.centerYAnchor),
      field.widthAnchor.constraint(equalToConstant: 1),
      field.heightAnchor.constraint(equalToConstant: 1),
    ])
    if let host = window.layer.superlayer, let secure = field.layer.sublayers?.last {
      host.addSublayer(field.layer)
      secure.addSublayer(window.layer)
    }
  }

  private static func updateRecordingOverlay(on window: UIWindow) {
    let captured = UIScreen.main.isCaptured
    if captured {
      if overlay == nil {
        let view = UIView(frame: window.bounds)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.backgroundColor = .white
        view.tag = 71_072
        let label = UILabel()
        label.text = "화면 녹화가 감지되어 프로필을 가렸습니다."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
          label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
          label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
          label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
          label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
        overlay = view
      }
      if let overlay, overlay.superview == nil {
        window.addSubview(overlay)
      }
      overlay?.frame = window.bounds
    } else {
      overlay?.removeFromSuperview()
    }
  }
}
