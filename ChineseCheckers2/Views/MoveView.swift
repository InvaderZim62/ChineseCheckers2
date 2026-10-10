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
    private var color = UIColor.black
    
    func drawPathThroughSequence(_ sequence: [Move], player: Player) {
        color = player == .human ? Constant.humanColor : Constant.computerColor
        moveSequence = sequence
    }
    
    func clearSequencePath() {
        moveSequence.removeAll()
    }

    override func draw(_ rect: CGRect) {
        guard !moveSequence.isEmpty else { return }
        let line = UIBezierPath()
        line.move(to: globalData.holePositions[moveSequence.first!.from]!)
        for move in moveSequence {
            line.addLine(to: globalData.holePositions[move.to]!)
            line.lineWidth = Constant.moveLineWidth
            color.setStroke()
            line.stroke()
        }
    }
}
