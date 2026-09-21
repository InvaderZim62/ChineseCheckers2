//
//  Extensions.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

extension Array where Element: Equatable {
    // usage: [1, 2, 3, 1, 0].allIndices(of: 1)  // = [0, 3]
    func allIndices(of target: Element) -> [Int] {
        self.enumerated().filter { $0.element == target }.map { $0.offset }
    }
}

extension CGPoint {
    // usage: CGPoint(x: 1, y: 2) + CGPoint(x: 3, y: 4)  // = CGPoint(x: 4, y: 6)
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    // usage: 3 * CGPoint(x: 1, y: 2)  // = CGPoint(x: 3, y: 6)
    static func *(lhs: Double, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs * rhs.x, y: lhs * rhs.y)
    }

    // usage: CGPoint(x: 3, y: 4)  // = 5
    var magnitude: Double {
        sqrt(x * x + y * y)
    }
    
    // usage: CGPoint(x: 0, y: 0).distance(to: CGPoint(x: 3, y: 4))  // = 5
    func distance(to point: CGPoint) -> Double {
        sqrt(pow((self.x - point.x), 2) + pow((self.y - point.y), 2))
    }
    
    // return bearing from -pi to +pi, where 0 is to the right, positive is clockwise
    func bearing(to point: CGPoint) -> Double {
        atan2(Double(point.y - self.y), Double(point.x - self.x))
    }
    
    func limitedToCircle(withRadius radius: CGFloat, centeredAt center: CGPoint) -> CGPoint {
        let angle = center.bearing(to: self)
        let limitedRadius = min(radius, distance(to: center))
        let limitedPoint = center + limitedRadius * CGPoint(x: cos(angle), y: sin(angle))
        return limitedPoint
    }
}

extension CaseIterable where Self: Equatable {  // Equatable needed for firstIndex(of:)
    mutating func next() {
        let allCases = Self.allCases
        let thisIndex = allCases.firstIndex(of: self)!
        let nextIndex = allCases.index(after: thisIndex)
        self = allCases[nextIndex == allCases.endIndex ? allCases.startIndex : nextIndex]
    }

    static func random() -> AllCases.Element {
        .allCases.randomElement()!
    }
}
