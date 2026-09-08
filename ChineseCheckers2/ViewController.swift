//
//  ViewController.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

struct Constant {
    static let boardColor = #colorLiteral(red: 0.9686274529, green: 0.78039217, blue: 0.3450980484, alpha: 1)
    static let marbleColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let marbleRadius: CGFloat = 12
    static let snapDistance: CGFloat = 10
    static let discardSpacing = 20.0
    static let marbleViewSize = CGSize(width: 2 * Constant.marbleRadius + MarbleConst.lineWidth,
                                       height: 2 * Constant.marbleRadius + MarbleConst.lineWidth)
    static let marbleViewFrame = CGRect(origin: .zero, size: Constant.marbleViewSize)
}

class ViewController: UIViewController {
    
    var board = Board()
    var marbleViews = [MarbleView]()
    var pastBounds = CGRect.zero

    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds != pastBounds {
            updateViewFromModel()
            pastBounds = view.bounds
        }
    }
    
    private func updateViewFromModel() {
        marbleViews.forEach { $0.removeFromSuperview() }
        marbleViews.removeAll()
        for row in 0..<7 {
            for col in 0..<7 {
                let rowCol = RowCol(row: row, col: col)
                if board.isOccupied[rowCol] == true {
                    let marbleView = addMarbleView(at: rowCol)
                    marbleViews.append(marbleView)
                    
//                    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
//                    marbleView.addGestureRecognizer(pan)
                }
            }
        }
    }
    
    private func addMarbleView(at rowCol: RowCol) -> MarbleView {
        addMarbleView(at: boardView.holePositions[rowCol]!)
    }
    
    private func addMarbleView(at position: CGPoint) -> MarbleView {
        let marbleView = MarbleView(frame: Constant.marbleViewFrame)
        marbleView.center = position
        boardView.addSubview(marbleView)
        return marbleView
    }
    
    // MARK: - Button Actions
    
    @IBAction func restartPressed(_ sender: UIButton) {
        messageLabel.text = ""
//        moveAllMarblesBackToBoard() {
//            self.board.reset()
//            self.collectionView.reset()
//            self.updateViewFromModel()
//        }
    }
}
