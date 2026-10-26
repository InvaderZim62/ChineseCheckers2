//
//  MoveView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/30/26.
//

import UIKit

class MoveView: UIView {
    
    let globalData = GlobalData.shared
    
    private var moveSequence = [Move]() { didSet { setNeedsDisplay() } }
    private var color: UIColor!
    
    func drawPathThroughSequence(_ sequence: [Move], player: Player) {
        color = player == .human ? Constant.humanColor : Constant.computerColor
        moveSequence = sequence  // triggers draw(rect:)
    }
    
    func clearSequencePath() {
        moveSequence.removeAll()
    }

    override func draw(_ rect: CGRect) {
        guard !moveSequence.isEmpty else { return }
        let path = UIBezierPath()
        path.move(to: globalData.holePositions[moveSequence.first!.from]!)
        for move in moveSequence {
            path.addLine(to: globalData.holePositions[move.to]!)
            path.lineWidth = Constant.moveLineWidth
            color.setStroke()
            path.stroke()
        }
    }
}
