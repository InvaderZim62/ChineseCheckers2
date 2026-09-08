//
//  BoardView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

struct BoardConst {
    static let lineWidth: CGFloat = 2  // board outline
}

class BoardView: UIView {
    
    private(set) var holePositions = [RowCol: CGPoint]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        computeHolePositions()
    }
    
    func holeRowCol(near point: CGPoint) -> RowCol? {
        holePositions.first(where: { $0.value.distance(to: point) < Constant.snapDistance })?.key
    }
    
    private func computeHolePositions() {
        let boardCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let holeSpacing = Int(bounds.width / 7.5)
        for row in 0..<7 {
            let deltaRow = row - 3  // delta from center
            for col in 0..<7 {
                let isCenterCols = (col > 1 && col < 5)
                if (row < 2 && isCenterCols) || (row > 1 && row < 5) || (row > 4 && isCenterCols) {
                    let deltaCol = col - 3
                    let holePosition = boardCenter + CGPoint(x: CGFloat(deltaCol * holeSpacing),
                                                             y: CGFloat(deltaRow * holeSpacing))
                    holePositions[RowCol(row: row, col: col)] = holePosition
                }
            }
        }
    }
    
    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        drawBoard()
        holePositions.forEach { drawHole(center: $0.value) }
    }
    
    private func drawBoard() {
        let boardCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let circle = UIBezierPath(arcCenter: boardCenter,
                                  radius: (bounds.width - BoardConst.lineWidth) / 2,
                                  startAngle: 0,
                                  endAngle: 2 * .pi,
                                  clockwise: true)
        Constant.boardColor.setFill()
        circle.fill()
        UIColor.black.setStroke()
        circle.lineWidth = BoardConst.lineWidth
        circle.stroke()
    }
    
    private func drawHole(center: CGPoint) {
        let circle = UIBezierPath(arcCenter: center,
                                  radius: Constant.marbleRadius,
                                  startAngle: 0,
                                  endAngle: 2 * .pi,
                                  clockwise: true)
        UIColor.clear.setFill()
        circle.fill()
        UIColor.black.setStroke()
        circle.lineWidth = 1
        circle.stroke()
    }
}
