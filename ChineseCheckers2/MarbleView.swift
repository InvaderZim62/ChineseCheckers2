//
//  MarbleView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

struct MarbleConst {
    static let lineWidth: CGFloat = 1
}

class MarbleView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circle = UIBezierPath(arcCenter: center,
                                  radius: Constant.marbleRadius,
                                  startAngle: 0,
                                  endAngle: 2 * .pi,
                                  clockwise: true)
        Constant.marbleColor.setFill()
        circle.fill()
        UIColor.black.setStroke()
        circle.lineWidth = MarbleConst.lineWidth
        circle.stroke()
    }
}
