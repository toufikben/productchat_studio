import Flutter
import UIKit

/// iOS Seika bridge compatible with the current Flutter contract.
///
/// This is the safe native baseline used until the iOS Runner target and
/// onnxruntime-objc pod are provisioned. It keeps the channel contract stable
/// and performs deterministic local bitmap operations.
final class SeikaChannel: NSObject, FlutterPlugin {
    static let channelName = "productchat/studio/seika"
    private let fileManager = FileManager.default

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(SeikaChannel(), channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "removeBackground":
                result(try removeBackground(call))
            case "inpaint":
                result(try inpaint(call))
            case "upscale":
                result(try upscale(call))
            case "addShadow":
                result(try addShadow(call))
            case "export":
                result(try export(call))
            case "loadModel":
                // The ONNX pod is intentionally not assumed until the iOS
                // Runner target is available. Keep this explicit and safe.
                result(FlutterError(code: "MODEL_RUNTIME_UNAVAILABLE",
                                    message: "iOS ONNX runtime is not provisioned yet.",
                                    details: nil))
            case "unloadModel":
                result(true)
            case "isLoaded":
                result(false)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let error as BridgeError {
            result(FlutterError(code: error.code, message: error.message, details: nil))
        } catch {
            result(FlutterError(code: "SEIKA_ERROR", message: error.localizedDescription, details: nil))
        }
    }

    private func removeBackground(_ call: FlutterMethodCall) throws -> String {
        let path = try string(call, "imagePath")
        guard let image = UIImage(contentsOfFile: path) else {
            throw BridgeError("DECODE_ERROR", "Cannot decode image")
        }
        // Preserve the current baseline behavior: copy the image until the
        // production segmentation/LaMa runtime is available on iOS.
        return try write(image, suffix: "remove_bg", format: .png)
    }

    private func inpaint(_ call: FlutterMethodCall) throws -> String {
        let path = try string(call, "imagePath")
        _ = try string(call, "maskPath")
        guard let image = UIImage(contentsOfFile: path) else {
            throw BridgeError("DECODE_ERROR", "Cannot decode image")
        }
        return try write(image, suffix: "inpaint", format: .png)
    }

    private func upscale(_ call: FlutterMethodCall) throws -> String {
        let path = try string(call, "imagePath")
        let factor = (call.arguments as? [String: Any])?["factor"] as? Int ?? 2
        guard (2...4).contains(factor), let image = UIImage(contentsOfFile: path),
              let cg = image.cgImage else {
            throw BridgeError("INVALID_ARGUMENT", "factor must be 2 or 4 and image must be valid")
        }
        let size = CGSize(width: cg.width * factor, height: cg.height * factor)
        let renderer = UIGraphicsImageRenderer(size: size)
        let output = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return try write(output, suffix: "upscale_\(factor)x", format: .png)
    }

    private func addShadow(_ call: FlutterMethodCall) throws -> String {
        let path = try string(call, "imagePath")
        guard let image = UIImage(contentsOfFile: path) else {
            throw BridgeError("DECODE_ERROR", "Cannot decode image")
        }
        return try write(image, suffix: "shadow", format: .png)
    }

    private func export(_ call: FlutterMethodCall) throws -> String {
        let path = try string(call, "imagePath")
        guard let image = UIImage(contentsOfFile: path) else {
            throw BridgeError("DECODE_ERROR", "Cannot decode image")
        }
        return try write(image, suffix: "export", format: .jpg)
    }

    private func string(_ call: FlutterMethodCall, _ key: String) throws -> String {
        guard let args = call.arguments as? [String: Any],
              let value = args[key] as? String, !value.isEmpty else {
            throw BridgeError("INVALID_ARGUMENT", "Missing \(key)")
        }
        return value
    }

    private func write(_ image: UIImage, suffix: String,
                       format: ImageFormat) throws -> String {
        guard let data = format == .png ? image.pngData() : image.jpegData(compressionQuality: 0.92) else {
            throw BridgeError("ENCODE_ERROR", "Cannot encode image")
        }
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let path = directory.appendingPathComponent("\(suffix)_\(Int(Date().timeIntervalSince1970 * 1000)).\(format.extension)")
        try data.write(to: path, options: .atomic)
        return path.path
    }

    private enum ImageFormat {
        case png, jpg
        var `extension`: String { self == .png ? "png" : "jpg" }
    }

    private struct BridgeError: Error {
        let code: String
        let message: String
        init(_ code: String, _ message: String) {
            self.code = code
            self.message = message
        }
    }
}
