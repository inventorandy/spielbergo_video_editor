import Flutter
import UIKit

extension FlutterError: Error {}

public class SpielbergoVideoEditorPlugin: NSObject, FlutterPlugin {
  private var result: FlutterResult?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "spielbergo_video_editor", binaryMessenger: registrar.messenger())
    let instance = SpielbergoVideoEditorPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "pickVideo":
      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Expected arguments to be a dictionary", details: nil))
        return
      }

      guard let rootVC = UIApplication.shared.delegate?.window??.rootViewController else {
        result(FlutterError(code: "NO_ROOT_VIEW_CONTROLLER", message: "No root view controller found", details: nil))
        return
      }

      // Present the view controller
      let vc = NewVideoViewController(
        recordTimes: args["recordTimes"] as? [Int] ?? [],
        flutterResult: result
      )
      vc.modalPresentationStyle = .fullScreen

      rootVC.present(vc, animated: true, completion: nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
