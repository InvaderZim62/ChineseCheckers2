//
//  TurnView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/15/26.
//
//  Indicates whose turn it is.
//

import UIKit

class TurnView: UIView {
    
    var player = Player.player1 { didSet { setNeedsDisplay() } }
    
    private var color: UIColor {
        player == .player1 ? Constant.player1Color : Constant.player2Color
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
