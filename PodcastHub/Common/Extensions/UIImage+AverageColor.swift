import UIKit

extension UIImage {
    var averageColor: UIColor {
        guard let cgImage else { return .systemBackground }
        let size = CGSize(width: 1, height: 1)
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: Int(size.width) * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let ctx = context else { return .systemBackground }
        ctx.interpolationQuality = .medium
        ctx.draw(cgImage, in: CGRect(origin: .zero, size: size))
        guard let data = ctx.data else { return .systemBackground }
        let ptr = data.bindMemory(to: UInt8.self, capacity: 4)
        let r = CGFloat(ptr[0]) / 255.0
        let g = CGFloat(ptr[1]) / 255.0
        let b = CGFloat(ptr[2]) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}
