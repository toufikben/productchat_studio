import UIKit
import onnxruntime_objc

class SeikaChannel: NSObject {
    static let channelName = "com.productchat/seika"
    private var lamaSession: ORTSession?
    private var esrganSession: ORTSession?
    private var env: ORTEnv?
    private let lock = NSLock()

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: channelName,
            binaryMessenger: registrar.messenger()
        )
        let instance = SeikaChannel()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
}

extension SeikaChannel: FlutterPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "removeBg":    handleRemoveBg(call, result)
        case "inpaint":     handleInpaint(call, result)
        case "upscale":     handleUpscale(call, result)
        case "loadModel":   handleLoadModel(call, result)
        case "unloadModel": unload(); result(true)
        case "isLoaded":    result(isAnyLoaded())
        default:            result(FlutterMethodNotImplemented)
        }
    }

    private func handleRemoveBg(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "ARGS", message: "path required", details: nil))
            return
        }
        let quality = (args["quality"] as? String) ?? "fast"
        let outputPath = path.replacingOccurrences(
            of: "\\.[^.]+$", with: "_nobg.png", options: .regularExpression
        )

        guard let img = decodeImage(path) else {
            result(FlutterError(code: "DECODE", message: "cannot decode", details: nil))
            return
        }

        var output: UIImage
        if quality == "balanced" || quality == "best" {
            lock.lock()
            let lamaOut = lamaSession != nil ? runLaMa(img, mask: nil) : nil
            lock.unlock()
            output = lamaOut ?? PatchMatchRemover.removeBackground(img)
        } else {
            output = PatchMatchRemover.removeBackground(img)
        }

        guard let data = output.pngData() else {
            result(FlutterError(code: "ENCODE", message: "png failed", details: nil))
            return
        }
        do {
            try data.write(to: URL(fileURLWithPath: outputPath))
            result([
                "ok": true,
                "outputPath": outputPath,
                "width": Int(output.size.width),
                "height": Int(output.size.height),
                "quality": quality
            ])
        } catch {
            result(FlutterError(code: "WRITE", message: error.localizedDescription, details: nil))
        }
    }

    private func handleInpaint(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let maskPath = args["maskPath"] as? String else {
            result(FlutterError(code: "ARGS", message: "path and maskPath required", details: nil))
            return
        }
        let outputPath = path.replacingOccurrences(
            of: "\\.[^.]+$", with: "_inpaint.png", options: .regularExpression
        )

        guard let img = decodeImage(path),
              let mask = decodeImage(maskPath) else {
            result(FlutterError(code: "DECODE", message: "cannot decode", details: nil))
            return
        }

        lock.lock()
        let output = runLaMa(img, mask: mask) ?? img
        lock.unlock()

        guard let data = output.pngData() else {
            result(FlutterError(code: "ENCODE", message: "png failed", details: nil))
            return
        }
        do {
            try data.write(to: URL(fileURLWithPath: outputPath))
            result(["ok": true, "outputPath": outputPath])
        } catch {
            result(FlutterError(code: "WRITE", message: error.localizedDescription, details: nil))
        }
    }

    private func handleUpscale(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(FlutterError(code: "ARGS", message: "path required", details: nil))
            return
        }
        let factor = (args["factor"] as? Int) ?? 2
        let outputPath = path.replacingOccurrences(
            of: "\\.[^.]+$", with: "_\(factor)x.png", options: .regularExpression
        )

        guard let img = decodeImage(path) else {
            result(FlutterError(code: "DECODE", message: "cannot decode", details: nil))
            return
        }

        lock.lock()
        let output = runEsrgan(img, factor: factor) ?? img
        lock.unlock()

        guard let data = output.pngData() else {
            result(FlutterError(code: "ENCODE", message: "png failed", details: nil))
            return
        }
        do {
            try data.write(to: URL(fileURLWithPath: outputPath))
            result([
                "ok": true,
                "outputPath": outputPath,
                "width": Int(output.size.width),
                "height": Int(output.size.height),
                "factor": factor
            ])
        } catch {
            result(FlutterError(code: "WRITE", message: error.localizedDescription, details: nil))
        }
    }

    private func handleLoadModel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let modelType = args["modelType"] as? String,
              let modelPath = args["modelPath"] as? String else {
            result(FlutterError(code: "ARGS", message: "modelType and modelPath required", details: nil))
            return
        }

        do {
            let ortEnv = try ORTEnv(loggingLevel: .warning)
            let opts = try ORTSessionOptions()
            try opts.setIntraOpNumThreads(4)
            try opts.setInterOpNumThreads(1)
            try opts.setGraphOptimizationLevel(.all)
            try opts.addConfigEntry(withKey: "session.intra_op.allow_spinning", value: "0")

            let session = try ORTSession(env: ortEnv, modelPath: modelPath, sessionOptions: opts)

            lock.lock()
            switch modelType {
            case "lama":   lamaSession = session
            case "esrgan": esrganSession = session
            default:
                lock.unlock()
                result(FlutterError(code: "UNKNOWN_MODEL", message: "lama|esrgan only", details: nil))
                return
            }
            env = ortEnv
            lock.unlock()

            result(["ok": true, "modelType": modelType])
        } catch {
            result(FlutterError(code: "LOAD", message: error.localizedDescription, details: nil))
        }
    }

    private func unload() {
        lock.lock()
        lamaSession = nil
        esrganSession = nil
        env = nil
        lock.unlock()
    }

    private func isAnyLoaded() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return lamaSession != nil || esrganSession != nil
    }

    private func runLaMa(_ image: UIImage, mask: UIImage?) -> UIImage? {
        guard let session = lamaSession, let ortEnv = env else { return nil }
        let N = 512
        let plane = N * N

        let imgResized = safeResize(image, width: N, height: N)
        guard let imgCG = imgResized.cgImage else { return nil }

        let maskImage: UIImage
        if let m = mask {
            maskImage = safeResize(m, width: N, height: N)
        } else {
            maskImage = solidImage(width: N, height: N, color: .white)
        }
        guard let maskCG = maskImage.cgImage else { return nil }

        var imgArr = [Float](repeating: 0, count: 3 * plane)
        var maskArr = [Float](repeating: 0, count: plane)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        var imgPixels = [UInt8](repeating: 0, count: N * N * 4)
        var maskPixels = [UInt8](repeating: 0, count: N * N * 4)

        guard let imgCtx = CGContext(data: &imgPixels, width: N, height: N,
                                      bitsPerComponent: 8, bytesPerRow: N * 4,
                                      space: colorSpace, bitmapInfo: bitmapInfo),
              let maskCtx = CGContext(data: &maskPixels, width: N, height: N,
                                       bitsPerComponent: 8, bytesPerRow: N * 4,
                                       space: colorSpace, bitmapInfo: bitmapInfo)
        else { return nil }

        imgCtx.draw(imgCG, in: CGRect(x: 0, y: 0, width: N, height: N))
        maskCtx.draw(maskCG, in: CGRect(x: 0, y: 0, width: N, height: N))

        for i in 0..<plane {
            let src = i * 4
            imgArr[0 * plane + i] = Float(imgPixels[src + 0]) / 255.0
            imgArr[1 * plane + i] = Float(imgPixels[src + 1]) / 255.0
            imgArr[2 * plane + i] = Float(imgPixels[src + 2]) / 255.0

            let lum = (Int(maskPixels[src + 0]) + Int(maskPixels[src + 1]) + Int(maskPixels[src + 2])) / 3
            maskArr[i] = lum > 128 ? 1.0 : 0.0
        }

        do {
            let imgData = NSMutableData(bytes: imgArr, length: imgArr.count * MemoryLayout<Float>.size)
            let maskData = NSMutableData(bytes: maskArr, length: maskArr.count * MemoryLayout<Float>.size)

            let imgTensor = try ORTValue(
                tensorData: imgData, elementType: .float,
                shape: [1, 3, NSNumber(value: N), NSNumber(value: N)]
            )
            let maskTensor = try ORTValue(
                tensorData: maskData, elementType: .float,
                shape: [1, 1, NSNumber(value: N), NSNumber(value: N)]
            )

            let inputNames = try session.inputNames()
            var inputs: [String: ORTValue] = [:]
            inputs[inputNames[0]] = imgTensor
            if inputNames.count >= 2 { inputs[inputNames[1]] = maskTensor }

            let outputNames = Set(try session.outputNames())
            let outputs = try session.run(withInputs: inputs,
                                          outputNames: outputNames,
                                          runOptions: nil)

            guard let outputName = try session.outputNames().first,
                  let outputTensor = outputs[outputName] else { return nil }

            let outData = try outputTensor.tensorData() as Data
            let outFloats = outData.withUnsafeBytes { ptr -> [Float] in
                Array(ptr.bindMemory(to: Float.self))
            }

            var minV: Float = .greatestFiniteMagnitude
            for v in outFloats where v < minV { minV = v }
            let needsRescale = minV < -0.1

            let outShape = outputTensor.shape
            let outC = outShape[1].intValue
            let outH = outShape[2].intValue
            let outW = outShape[3].intValue
            let outPlane = outH * outW

            var outPixels = [UInt8](repeating: 0, count: outW * outH * 4)
            for i in 0..<outPlane {
                func ch(_ c: Int) -> UInt8 {
                    let raw = outFloats[c * outPlane + i]
                    let n = needsRescale ? (raw + 1.0) / 2.0 : raw
                    return UInt8(max(0, min(255, Int(n * 255.0))))
                }
                outPixels[i * 4 + 0] = ch(0)
                outPixels[i * 4 + 1] = ch(1)
                outPixels[i * 4 + 2] = ch(2)
                outPixels[i * 4 + 3] = outC >= 4 ? ch(3) : 255
            }

            guard let outImage = makeImage(from: outPixels, width: outW, height: outH) else {
                return nil
            }
            return safeResize(outImage, width: Int(image.size.width), height: Int(image.size.height))
        } catch {
            return nil
        }
    }

    private func runEsrgan(_ image: UIImage, factor: Int) -> UIImage? {
        guard let session = esrganSession, env != nil else { return nil }

        var w = Int(image.size.width)
        var h = Int(image.size.height)
        if w > 1024 || h > 1024 {
            let s = min(Float(1024) / Float(w), Float(1024) / Float(h))
            w = Int(Float(w) * s)
            h = Int(Float(h) * s)
        }
        w = max(32, (w / 32) * 32)
        h = max(32, (h / 32) * 32)

        let resized = safeResize(image, width: w, height: h)
        guard let cg = resized.cgImage else { return nil }

        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &pixels, width: w, height: h,
                                   bitsPerComponent: 8, bytesPerRow: w * 4,
                                   space: colorSpace,
                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        let plane = w * h
        var arr = [Float](repeating: 0, count: 3 * plane)
        for i in 0..<plane {
            let src = i * 4
            arr[0 * plane + i] = Float(pixels[src + 0]) / 255.0
            arr[1 * plane + i] = Float(pixels[src + 1]) / 255.0
            arr[2 * plane + i] = Float(pixels[src + 2]) / 255.0
        }

        do {
            let tensorData = NSMutableData(bytes: arr, length: arr.count * MemoryLayout<Float>.size)
            let inputTensor = try ORTValue(
                tensorData: tensorData, elementType: .float,
                shape: [1, 3, NSNumber(value: h), NSNumber(value: w)]
            )

            let inputName = try session.inputNames().first ?? "input"
            let outputNames = Set(try session.outputNames())
            let outputs = try session.run(withInputs: [inputName: inputTensor],
                                          outputNames: outputNames,
                                          runOptions: nil)

            guard let outName = try session.outputNames().first,
                  let outputTensor = outputs[outName] else { return nil }

            let outData = try outputTensor.tensorData() as Data
            let outFloats = outData.withUnsafeBytes { ptr -> [Float] in
                Array(ptr.bindMemory(to: Float.self))
            }

            var minV: Float = .greatestFiniteMagnitude
            for v in outFloats where v < minV { minV = v }
            let needsRescale = minV < -0.1

            let outShape = outputTensor.shape
            let outH = outShape[2].intValue
            let outW = outShape[3].intValue
            let outPlane = outH * outW

            var outPixels = [UInt8](repeating: 0, count: outW * outH * 4)
            for i in 0..<outPlane {
                func ch(_ c: Int) -> UInt8 {
                    let raw = outFloats[c * outPlane + i]
                    let n = needsRescale ? (raw + 1.0) / 2.0 : raw
                    return UInt8(max(0, min(255, Int(n * 255.0))))
                }
                outPixels[i * 4 + 0] = ch(0)
                outPixels[i * 4 + 1] = ch(1)
                outPixels[i * 4 + 2] = ch(2)
                outPixels[i * 4 + 3] = 255
            }

            return makeImage(from: outPixels, width: outW, height: outH)
        } catch {
            return nil
        }
    }

    private func decodeImage(_ path: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let img = UIImage(data: data) else { return nil }

        let maxSide = max(img.size.width, img.size.height)
        if maxSide <= 4096 { return img }

        let scale = 4096 / maxSide
        let newSize = CGSize(width: img.size.width * scale, height: img.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in img.draw(in: CGRect(origin: .zero, size: newSize)) }
    }

    private func safeResize(_ img: UIImage, width: Int, height: Int) -> UIImage {
        let target = CGSize(width: width, height: height)
        if img.size == target { return img }
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            img.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func solidImage(width: Int, height: Int, color: UIColor) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func makeImage(from rgba: [UInt8], width: Int, height: Int) -> UIImage? {
        guard let provider = CGDataProvider(data: Data(rgba) as CFData) else { return nil }
        guard let cg = CGImage(
            width: width, height: height,
            bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: provider, decode: nil,
            shouldInterpolate: false, intent: .defaultIntent
        ) else { return nil }
        return UIImage(cgImage: cg)
    }
}
