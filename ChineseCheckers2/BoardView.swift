//
//  BoardView.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

struct BoardConst {
    static let lineWidth: CGFloat = 2  // board outline
    static let slantAngle = 50 * .pi / 180.0
}

class BoardView: UIView {
    
    private(set) var holePositions = [RowCol: CGPoint]()
    
    override var bounds: CGRect {
        didSet {
            if bounds != oldValue {
                computeHolePositions()
                setNeedsDisplay()  // redraw
            }
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        computeHolePositions()
    }
    
    func holeRowCol(near point: CGPoint) -> RowCol? {
        holePositions.first(where: { $0.value.distance(to: point) < Constant.snapDistance })?.key
    }
    
    private func computeHolePositions() {
        let boardCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let holeSpacing = bounds.width / 7.5 / tan(BoardConst.slantAngle)
        for row in 0..<7 {
            let deltaRow = row - 3  // delta from center
            for col in 0..<7 {
                let deltaCol = col - 3
                let deltaX = holeSpacing * (CGFloat(deltaCol) * cos(BoardConst.slantAngle) - CGFloat(deltaRow) * cos(BoardConst.slantAngle))
                let deltaY = holeSpacing * (CGFloat(deltaCol) * sin(BoardConst.slantAngle) + CGFloat(deltaRow) * sin(BoardConst.slantAngle))
                let holePosition = boardCenter + CGPoint(x: deltaX, y: deltaY)
                holePositions[RowCol(row: row, col: col)] = holePosition
            }
        }
    }
    
    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        drawBoard()
        holePositions.forEach { drawHole(center: $0.value) }
    }
    
    private func drawBoard() {
        let oval = UIBezierPath(ovalIn: bounds.insetBy(dx: BoardConst.lineWidth, dy: BoardConst.lineWidth))
        Constant.boardColor.setFill()
        oval.fill()
        UIColor.black.setStroke()
        oval.lineWidth = BoardConst.lineWidth
        oval.stroke()
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
