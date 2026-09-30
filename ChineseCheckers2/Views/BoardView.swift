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
    
    let globalData = GlobalData.shared
    
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

    private func computeHolePositions() {
        globalData.holePositions.removeAll()
        let boardCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        let holeSpacing = bounds.width / Double(Constant.boardSize) * 0.77
        let halfSize = CGFloat(Constant.boardSize - 1) / 2.0
        for row in 0..<Constant.boardSize {
            for col in 0..<Constant.boardSize {
                let deltaX = holeSpacing * ((CGFloat(col) - halfSize) * cos(BoardConst.slantAngle) - (CGFloat(row) - halfSize) * cos(BoardConst.slantAngle))
                let deltaY = holeSpacing * ((CGFloat(col) - halfSize) * sin(BoardConst.slantAngle) + (CGFloat(row) - halfSize) * sin(BoardConst.slantAngle))
                let holePosition = boardCenter + CGPoint(x: deltaX, y: deltaY)
                globalData.holePositions[RowCol(row: row, col: col)] = holePosition
            }
        }
    }
    
    func holeRowCol(near point: CGPoint) -> RowCol? {
        globalData.holePositions.first(where: { $0.value.distance(to: point) < Constant.snapDistance })?.key
    }

    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        drawBoard()
        globalData.holePositions.forEach { drawHole(center: $0.value) }
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
