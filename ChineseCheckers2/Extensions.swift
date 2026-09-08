//
//  Extensions.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

extension CGPoint {
    // usage: CGPoint(x: 1, y: 2) + CGPoint(x: 3, y: 4)  // = CGPoint(x: 4, y: 6)
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    // usage: CGPoint(x: 1, y: 2) - CGPoint(x: 3, y: 4)  // = CGPoint(x: -2, y: -2)
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    // usage: CGPoint(x: 1, y: 2) += CGPoint(x: 3, y: 4)  // = CGPoint(x: 4, y: 6)
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }
    
    // usage: 3 * CGPoint(x: 1, y: 2)  // = CGPoint(x: 3, y: 6)
    static func *(lhs: Double, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
    }
    
    var magnitude: Double {
        sqrt(x * x + y * y)
    }
    
    // usage: CGPoint(x: 1, y: 2).offsetBy(dx: 3, dy: 4)  // = CGPoint(x: 4, y: 6)
    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        CGPoint(x: x + dx, y: y + dy)
    }
    
    // usage: CGPoint(x: 0, y: 0).distance(to: CGPoint(x: 3, y: 4))  // = 5
    func distance(to point: CGPoint) -> Double {
        sqrt(pow((self.x - point.x), 2) + pow((self.y - point.y), 2))
    }
    
    // return bearing from -pi to +pi, where 0 is to the right, positive is clockwise
    func bearing(to point: CGPoint) -> Double {
        atan2(Double(point.y - self.y), Double(point.x - self.x))
    }
    
    func limitedToRect(_ rect: CGRect) -> CGPoint {
        let limitedX = min(rect.maxX, max(rect.minX, x))
        let limitedY = min(rect.maxY, max(rect.minY, y))
        return CGPoint(x: limitedX, y: limitedY)
    }
    
    func limitedToRect(_ rect: CGRect, withHorizontalInset horizontalInset: CGFloat, andVerticalInset verticalInset: CGFloat) -> CGPoint {
        let limitedX = min(rect.maxX - horizontalInset, max(rect.minX + horizontalInset, x))
        let limitedY = min(rect.maxY - verticalInset, max(rect.minY + verticalInset, y))
        return CGPoint(x: limitedX, y: limitedY)
    }
    
    func limitedToCircle(withRadius radius: CGFloat, centeredAt center: CGPoint) -> CGPoint {
        let angle = center.bearing(to: self)
        let distance = distance(to: center)
        let newDistance = min(radius, distance)
        let newPoint = center.offsetBy(dx: Double(cos(angle) * newDistance),
                                       dy: Double(sin(angle) * newDistance))
        return newPoint
    }
}
