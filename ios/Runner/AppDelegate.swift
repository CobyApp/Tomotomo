import Flutter
import UIKit

/// Legacy UIKit window path (no UIScene manifest). Maximizes compatibility on devices that crash
/// with `FlutterImplicitEngineDelegate` + scene storyboard. Revisit UIScene when Apple requires it.
@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
