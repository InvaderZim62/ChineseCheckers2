//
//  TurnView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/15/26.
//

import UIKit

class TurnIndicatorView: UIView {
    
    var player = Player.human { didSet { setNeedsDisplay() } }
    
    private var color: UIColor {
        player == .human ? Constant.humanColor : Constant.computerColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isOpaque = false
    }
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let circle = UIBezierPath(arcCenter: center,
                                  radius: Constant.marbleRadius,
                                  startAngle: 0,
                                  endAngle: 2 * .pi,
                                  clockwise: true)
        color.setFill()
        circle.fill()
        UIColor.black.setStroke()
        circle.lineWidth = MarbleConst.lineWidth
        circle.stroke()
    }
}
