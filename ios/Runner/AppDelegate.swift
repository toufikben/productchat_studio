import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        if let controller = window?.rootViewController as? FlutterViewController {
            SeikaChannel.register(with: controller.registrar(forPlugin: "SeikaChannel")!)
            ShareReceiver.register(with: controller.registrar(forPlugin: "ShareReceiver")!)
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        if url.isFileURL { ShareReceiver.setPendingImage(url.path) }
        return super.application(app, open: url, options: options)
    }
}
