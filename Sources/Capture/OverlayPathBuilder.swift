import CoreGraphics

enum OverlayPathBuilder {
    static func dimmingPath(bounds: CGRect, cutout: CGRect?) -> CGPath {
        let path = CGMutablePath()
        path.addRect(bounds)
        if let cutout {
            path.addRect(cutout)
        }
        return path
    }
}
