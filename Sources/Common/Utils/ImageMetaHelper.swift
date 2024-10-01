import UIKit
import Accelerate

final class ImageMetaHelper {
    private static let blurPreviewSize = CGSize(width: 10, height: 10)

    // Update this constant when preview data algo changes
    private static let previewVersion: UInt8 = 1

    static let shared = ImageMetaHelper()

    func size(from image: UIImage) -> CGSize {
        return image.size
    }

    func blurPreview(from data: Data) -> UIImage? {
        guard data[0] == Self.previewVersion else {
            return nil
        }

        let pixelsCount = (data.count - 1) / 2

        let root = sqrt(Double(pixelsCount))
        guard abs(root - floor(root)) < 0.001 else {
            return nil
        }

        let dim = Int(root)
        if dim * dim != pixelsCount {
            assertionFailure("Invalid dimension")
            return nil
        }

        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<UInt16>.stride * pixelsCount,
            alignment: MemoryLayout<UInt16>.alignment
        )
        buffer.initializeMemory(as: UInt16.self, repeating: 0, count: pixelsCount)

        defer {
            buffer.deallocate()
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            assertionFailure("Unable to get color space")
            return nil
        }

        guard let context = CGContext(
            data: buffer,
            width: dim,
            height: dim,
            bitsPerComponent: 5,
            bytesPerRow: 2 * dim,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        ) else {
            assertionFailure("Invalid context creation")
            return nil
        }

        let uint8Array = [UInt8](data)
        let pixels: [UInt16] = zip(uint8Array + [0], [0] + uint8Array)
            .dropFirst()
            .dropLast()
            .enumerated()
            .compactMap { (idx, pair) in
                if !idx.isMultiple(of: 2) {
                    return nil
                }

                let (x, y) = pair
                let pxl: UInt16 = (UInt16(y) << 8) | UInt16(x)
                return RGB565(value: pxl).toARGB1555
            }

        if pixels.count != pixelsCount {
            assertionFailure("Invalid extracted buffer")
            return nil
        }

        buffer.copyMemory(from: pixels, byteCount: MemoryLayout<UInt16>.stride * pixels.count)

        return context.makeImage().flatMap { UIImage(cgImage: $0) }
    }

    func blurPreviewData(from image: UIImage) -> Data? {
        guard let blurredPreviews = Self.blurPreview(from: image),
              let preview = blurredPreviews.cgImage else {
            return nil
        }

        guard preview.width == Int(Self.blurPreviewSize.width),
              preview.height == Int(Self.blurPreviewSize.height) else {
            assertionFailure("Invalid preview size")
            return nil
        }

        let byteSize = preview.width * preview.height * 4
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: byteSize, alignment: 1)

        defer {
            buffer.deallocate()
        }

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            assertionFailure("Unable to get color space")
            return nil
        }

        guard let context = CGContext(
            data: buffer,
            width: preview.width,
            height: preview.height,
            bitsPerComponent: 5,
            bytesPerRow: 2 * preview.width,
            space: preview.colorSpace ?? colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder16Little.rawValue
        ) else {
            assertionFailure("Invalid context creation")
            return nil
        }

        context.draw(preview, in: CGRect(origin: .zero, size: Self.blurPreviewSize))

        var i = 0
        var pixels: [UInt16] = []

        while i < preview.width * preview.height {
            let pxl = buffer.load(fromByteOffset: MemoryLayout<UInt16>.size * i, as: UInt16.self)
            pixels.append(ARGB1555(value: pxl).toRGB565)

            i += 1
        }

        return pixels.withUnsafeBufferPointer {
            var data = Data(buffer: $0)
            data.insert(Self.previewVersion, at: 0)
            return data
        }
    }

    private static func blurPreview(from image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(Self.blurPreviewSize, false, 1.0)
        defer {
            UIGraphicsEndImageContext()
        }

        image.draw(in: CGRect(origin: .zero, size: Self.blurPreviewSize))

        guard let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
            return nil
        }

        return newImage
    }

    private struct ARGB1555: Equatable {
        // Each color = 5 bits, 16 bits total, most significant bit is always zero (ignored alpha bit)
        private let red: UInt16
        private let green: UInt16
        private let blue: UInt16

        init(value: UInt16) {
            self.blue = value & 0x1f
            self.green = (value >> 5) & 0x1f
            self.red = (value >> 10) & 0x1f
        }

        var toRGB565: UInt16 {
            let red5 = self.red << 11
            let green6 = UInt16(floor(63 / 31 * Double(self.green) + 0.5)) << 5
            let blue5 = self.blue

            return red5 | green6 | blue5
        }
    }

    private struct RGB565: Equatable {
        // Each color = 5 bits, except green - 6 bits
        private let red: UInt16
        private let green: UInt16
        private let blue: UInt16

        init(value: UInt16) {
            self.blue = value & 0x1f
            self.green = (value >> 5) & 0x3f
            self.red = (value >> 11) & 0x1f
        }

        var toARGB1555: UInt16 {
            let alpha = UInt16(0)
            let red5 = self.red << 10
            let green5 = UInt16(floor(31 / 63 * Double(self.green) + 0.5)) << 5
            let blue5 = self.blue

            return alpha | red5 | green5 | blue5
        }
    }
}
