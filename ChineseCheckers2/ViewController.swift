//
//  ViewController.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import UIKit

struct Constant {
    static let boardColor = #colorLiteral(red: 1, green: 0.9140625, blue: 0.5994323806, alpha: 1)
    static let player1Color = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let player2Color = #colorLiteral(red: 1, green: 0.5853449012, blue: 0.8847629183, alpha: 1)
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
    
    // panning
    var panInitialPosition = CGPoint.zero
    var panOffset = CGPoint.zero
    var targetPosition = CGPoint.zero
    var startRowCol = RowCol.zero
    var endRowCol = RowCol.zero

    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var messageLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = ""
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
                if let player = board.occupant(at: rowCol) {
                    let color = player == .player1 ? Constant.player1Color : Constant.player2Color
                    let marbleView = addMarbleView(at: rowCol, color: color)
                    marbleViews.append(marbleView)
                    
                    let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                    marbleView.addGestureRecognizer(pan)
                }
            }
        }
    }
    
    private func addMarbleView(at rowCol: RowCol, color: UIColor) -> MarbleView {
        addMarbleView(at: boardView.holePositions[rowCol]!, color: color)
    }
    
    private func addMarbleView(at position: CGPoint, color: UIColor) -> MarbleView {
        let marbleView = MarbleView(frame: Constant.marbleViewFrame)
        marbleView.color = color
        marbleView.center = position
        boardView.addSubview(marbleView)
        return marbleView
    }
    
    // set best pan offset for seeing marble around finger;
    // ex. larger offset needed for panning up, since the pan isn't detected until the finger is near the top of the marble
    private func setPanOffsetFromInitialTranslation(_ translation: CGPoint) {
        if translation.magnitude == 0 {
            // translation initially zero - use medium offset
            panOffset = CGPoint(x: 0, y: -40)
        } else {
            let panDirection = atan2(translation.y, translation.x)  // 0 to right, pos clockwise
            if abs(panDirection + .pi / 2) < 0.2 {  // within 0.2 radians (11 deg) of up
                // panning up - use larger offset
                panOffset = CGPoint(x: 0, y: -60)
            } else if abs(panDirection - .pi / 2) < 0.2 {
                // panning down - use small offset
                panOffset = CGPoint(x: 0, y: -20)
            } else {
                // panning across - use medium offset
                panOffset = CGPoint(x: 0, y: -30)
            }
        }
    }
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedView = recognizer.view as? MarbleView {
            let translation = recognizer.translation(in: boardView)
            switch recognizer.state {
            case .began:
                panInitialPosition = pannedView.center
                setPanOffsetFromInitialTranslation(translation)
                targetPosition = pannedView.center
                startRowCol = boardView.holeRowCol(near: targetPosition) ?? RowCol.zero
                endRowCol = startRowCol
                boardView.bringSubviewToFront(pannedView)
            case .changed:
                targetPosition = (panInitialPosition + translation + panOffset)
                    .limitedToCircle(withRadius: boardView.bounds.width / 2 - Constant.marbleRadius - BoardConst.lineWidth,
                                     centeredAt: CGPoint(x: boardView.bounds.midX, y: boardView.bounds.midY))
                let nearbyRowCol = boardView.holeRowCol(near: targetPosition)  // nil if none nearby
                
                if let nearbyRowCol, nearbyRowCol == endRowCol || board.isLegalMove(from: startRowCol, to: nearbyRowCol) {
                    // panning near last snapped hole or any legal move hole - snap position, set end point
                    pannedView.center = boardView.holePositions[nearbyRowCol]!
                    endRowCol = nearbyRowCol
                } else if nearbyRowCol != nil {
                    // panning near any other hole - keep panning
                    pannedView.center = targetPosition
                } else {
                    // panning away from all holes - reset end point
                    pannedView.center = targetPosition
                    endRowCol = startRowCol
                }
            case .ended:
                if endRowCol == startRowCol {
                    // marble left unsnapped - move it back to startPosition
                    moveView(pannedView, to: boardView.holePositions[startRowCol]!)
                } else {
                    // marble successfully moved
                    board.moveMarble(from: startRowCol, to: endRowCol)
//                    if board.isGameOver {
//                        messageLabel.text = "You did it!"
//                        boardView.bringSubviewToFront(messageLabel)
//                    } else if !board.isPlayAvailable {
//                        messageLabel.text = "Sorry, try again"
//                        boardView.bringSubviewToFront(messageLabel)
//                    }
                }
            default:
                break
            }
        }
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
    
    private func moveView(_ view: UIView, to position: CGPoint) {
        UIView.transition(with: view,
                          duration: 0.2,
                          animations: { view.center = position }
        )
    }
}
