//
//  ViewController.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//
// To do...
// - update circular panning limit to oval limit
// - alternate player turns
// - create computer player logic
// - update winning logic
//

import UIKit

struct Constant {
    static let boardColor = #colorLiteral(red: 1, green: 0.9140625, blue: 0.5994323806, alpha: 1)
    static let player1Color = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let player2Color = #colorLiteral(red: 1, green: 0.5853449012, blue: 0.8847629183, alpha: 1)
    static let boardSize = 7
    static let startingSize = 4  // player starting triangle size
    static let marbleRadius: CGFloat = 12
    static let snapDistance: CGFloat = 12
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
        createMarbleViews()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds != pastBounds {
            updateViewFromModel()
            pastBounds = view.bounds
        }
    }
    
    private func createMarbleViews() {
        for (index, marble) in board.marbles.enumerated() {
            let marbleView = MarbleView(frame: Constant.marbleViewFrame)
            marbleView.color = marble.player == .player1 ? Constant.player1Color : Constant.player2Color
            marbleView.tag = index
            marbleView.center = boardView.holePositions[marble.rowCol]!
            marbleViews.append(marbleView)
            boardView.addSubview(marbleView)
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            marbleView.addGestureRecognizer(pan)
        }
    }

    private func updateViewFromModel() {
        for marbleView in marbleViews {
            let rowCol = board.marbles[marbleView.tag].rowCol
            marbleView.center = boardView.holePositions[rowCol]!
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
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedMarbleView = recognizer.view as? MarbleView {
            let translation = recognizer.translation(in: boardView)
            switch recognizer.state {
            case .began:
                panInitialPosition = pannedMarbleView.center
                panOffset = panOffsetBasedOnInitialTranslation(translation)
                targetPosition = pannedMarbleView.center
                startRowCol = boardView.holeRowCol(near: targetPosition) ?? RowCol.zero
                endRowCol = startRowCol
                boardView.bringSubviewToFront(pannedMarbleView)
            case .changed:
                targetPosition = (panInitialPosition + translation + panOffset)
                // pws: update to .limitedToOval
//                    .limitedToCircle(withRadius: boardView.bounds.width / 2 - Constant.marbleRadius - BoardConst.lineWidth,
//                                     centeredAt: CGPoint(x: boardView.bounds.midX, y: boardView.bounds.midY))
                let nearbyRowCol = boardView.holeRowCol(near: targetPosition)  // nil if none nearby
                
                if let nearbyRowCol, nearbyRowCol == endRowCol || board.isLegalMove(from: startRowCol, to: nearbyRowCol) {
                    // panning near last snapped hole or any legal move hole - snap position, set end point
                    pannedMarbleView.center = boardView.holePositions[nearbyRowCol]!
                    endRowCol = nearbyRowCol
                } else if nearbyRowCol != nil {
                    // panning near any other hole - keep panning
                    pannedMarbleView.center = targetPosition
                } else {
                    // panning away from all holes - reset end point
                    pannedMarbleView.center = targetPosition
                    endRowCol = startRowCol
                }
            case .ended:
                if endRowCol == startRowCol {
                    // marble left unsnapped - move it back to startPosition
                    UIView.animate(withDuration: 0.4) {
                        pannedMarbleView.center = self.boardView.holePositions[self.startRowCol]!
                    }
                } else {
                    // marble successfully moved
                    board.updateMarbleLocationFor(pannedMarbleView.tag, to: endRowCol)  // update model
                    checkProgress()
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Utilities

    // set best pan offset for seeing marble around finger;
    // ex. larger offset needed for panning up, since the pan isn't detected until the finger is near the top of the marble
    private func panOffsetBasedOnInitialTranslation(_ translation: CGPoint) -> CGPoint {
        if translation.magnitude == 0 {
            // translation initially zero - use medium offset
            return CGPoint(x: 0, y: -40)
        } else {
            let panDirection = atan2(translation.y, translation.x)  // 0 to right, pos clockwise
            if abs(panDirection + .pi / 2) < 0.2 {  // within 0.2 radians (11 deg) of up
                // panning up - use larger offset
                return CGPoint(x: 0, y: -60)
            } else if abs(panDirection - .pi / 2) < 0.2 {
                // panning down - use small offset
                return CGPoint(x: 0, y: -20)
            } else {
                // panning across - use medium offset
                return CGPoint(x: 0, y: -30)
            }
        }
    }

    private func checkProgress() {
//        if board.isGameOver {
//            messageLabel.text = "You did it!"
//            boardView.bringSubviewToFront(messageLabel)
//        } else if !board.isPlayAvailable {
//            messageLabel.text = "Sorry, try again"
//            boardView.bringSubviewToFront(messageLabel)
//        } else {
//            messageLabel.text = ""
//        }
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
