//
//  MoveView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/30/26.
//

import UIKit

class MoveView: UIView {
    
    let globalData = GlobalData.shared
    
    var moveSequence = [Move]() { didSet { setNeedsDisplay() } }

    override func draw(_ rect: CGRect) {
        guard !moveSequence.isEmpty else { return }
        let line = UIBezierPath()
        line.move(to: globalData.holePositions[moveSequence.first!.from]!)
        for move in moveSequence {
            line.addLine(to: globalData.holePositions[move.to]!)
            line.lineWidth = Constant.moveLineWidth
            UIColor.black.setStroke()
            line.stroke()
        }
    }
}
