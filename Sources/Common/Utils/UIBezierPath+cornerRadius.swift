import UIKit

public extension UIBezierPath {
    static func pch_make(
        with rect: CGRect,
        topLeftRadius: CGFloat?,
        topRightRadius: CGFloat?,
        bottomLeftRadius: CGFloat?,
        bottomRightRadius: CGFloat?
    ) -> UIBezierPath {
        let path = UIBezierPath()

        let topLeft = CGPoint(x: rect.minX + (topLeftRadius ?? 0), y: rect.minY + (topLeftRadius ?? 0))
        let topRight = CGPoint(x: rect.maxX - (topRightRadius ?? 0), y: rect.minY + (topRightRadius ?? 0))
        let bottomLeft = CGPoint(x: rect.minX + (bottomLeftRadius ?? 0), y: rect.maxY - (bottomLeftRadius ?? 0))
        let bottomRight = CGPoint(x: rect.maxX - (bottomRightRadius ?? 0), y: rect.maxY - (bottomRightRadius ?? 0))

        let topMidpoint = CGPoint(x: rect.midX, y: rect.minY)

        path.move(to: topMidpoint)

        if let topRightRadius = topRightRadius {
            path.addLine(to: CGPoint(x: rect.maxX - topRightRadius, y: rect.minY))
            path.addArc(
                withCenter: topRight,
                radius: topRightRadius,
                startAngle: -CGFloat.pi / 2,
                endAngle: 0,
                clockwise: true
            )
        } else {
            path.addLine(to: topRight)
        }

        if let bottomRightRadius = bottomRightRadius {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottomRightRadius))
            path.addArc(
                withCenter: bottomRight,
                radius: bottomRightRadius,
                startAngle: 0,
                endAngle: CGFloat.pi / 2,
                clockwise: true
            )
        } else {
            path.addLine(to: bottomRight)
        }

        if let bottomLeftRadius = bottomLeftRadius {
            path.addLine(to: CGPoint(x: rect.minX + bottomLeftRadius, y: rect.maxY))
            path.addArc(
                withCenter: bottomLeft,
                radius: bottomLeftRadius,
                startAngle: CGFloat.pi / 2,
                endAngle: CGFloat.pi,
                clockwise: true
            )
        } else {
            path.addLine(to: bottomLeft)
        }

        if let topLeftRadius = topLeftRadius {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + topLeftRadius))
            path.addArc(
                withCenter: topLeft,
                radius: topLeftRadius,
                startAngle: CGFloat.pi,
                endAngle: -CGFloat.pi / 2,
                clockwise: true
            )
        } else {
            path.addLine(to: topLeft)
        }
        
        path.close()

        return path
    }
}
