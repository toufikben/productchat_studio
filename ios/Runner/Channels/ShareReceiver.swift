import UIKit

class ShareReceiver {
    static let channelName = "com.productchat/share"
    private static var pendingImage: String?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "getPendingImage":
                result(pendingImage)
                pendingImage = nil
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    static func setPendingImage(_ path: String) {
        pendingImage = path
    }
}
