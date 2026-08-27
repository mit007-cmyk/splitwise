import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    application.registerForRemoteNotifications()

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.example.splitwise/settings",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        if call.method == "getSupportDeviceInfo" {
          var systemInfo = utsname()
          uname(&systemInfo)
          let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
              String(cString: $0)
            }
          }
          let device = UIDevice.current.model + " " + machine
          let operatingSystem =
            "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
          result([
            "device": device.trimmingCharacters(in: .whitespaces),
            "operatingSystem": operatingSystem,
          ])
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
