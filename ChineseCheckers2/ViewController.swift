//
//  ViewController.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//
// To do...
// - make it a two-player game over WiFi (like Battleship)
//

import UIKit

struct Constant {
    static let boardColor = #colorLiteral(red: 1, green: 0.9140625, blue: 0.5994323806, alpha: 1)
    static let humanColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let computerColor = #colorLiteral(red: 1, green: 0.5853449012, blue: 0.8847629183, alpha: 1)
    static let searchDepth = 3  // only use odd numbers (5 is slow)
    static let boardSize = 7
    static let playerSize = 4  // starting triangle dimension
    static let marbleRadius: CGFloat = 12
    static let snapDistance: CGFloat = 12
    static let farMoveTime: TimeInterval = 0.7
    static let closeMoveTime: TimeInterval = 0.4
    static let marbleViewSize = CGSize(width: 2 * Constant.marbleRadius + MarbleConst.lineWidth,
                                       height: 2 * Constant.marbleRadius + MarbleConst.lineWidth)
    static let marbleViewFrame = CGRect(origin: .zero, size: Constant.marbleViewSize)
}

class ViewController: UIViewController {
    
    var board = Board()
    let computer = Computer()
    var marbleViews = [MarbleView]()
    var isGameOver = false
    var pastBounds = CGRect.zero
    var whoseTurn: Player! {
        didSet {
            turnView.player = whoseTurn
            if whoseTurn == .computer && !isGameOver {
                computerMove()
            }
        }
    }
    
    // panning
    var panInitialPosition = CGPoint.zero
    var panOffset = CGPoint.zero
    var targetPosition = CGPoint.zero
    var startRowCol = RowCol.zero
    var endRowCol = RowCol.zero

    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var turnView: TurnView!
    @IBOutlet weak var messageLabel: UILabel!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = ""
        createMarbleViews()
        whoseTurn = Player.random()
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
            marbleView.player = marble.player
            marbleView.tag = index
            marbleView.center = boardView.holePositions[marble.rowCol]!
            marbleViews.append(marbleView)
            boardView.addSubview(marbleView)
            
            if marble.player == .human {
                let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
                marbleView.addGestureRecognizer(pan)
            }
        }
    }

    private func updateViewFromModel() {
        for marbleView in marbleViews {
            let rowCol = board.marbles[marbleView.tag].rowCol
            marbleView.center = boardView.holePositions[rowCol]!
        }
    }
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        guard whoseTurn == .human, isGameOver == false else { return }  // must be human's turn to pan
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
                let nearbyRowCol = boardView.holeRowCol(near: targetPosition)  // nil if no holes nearby
                
                if let nearbyRowCol, nearbyRowCol == startRowCol || board.isLegalMove(Move(from: startRowCol, to: nearbyRowCol)) {
                    // panning near starting hole or any legal move hole - snap position, set end point
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
                    UIView.animate(withDuration: Constant.closeMoveTime) {
                        pannedMarbleView.center = self.boardView.holePositions[self.startRowCol]!
                    }
                } else {
                    // marble successfully moved
                    board.updateMarbleLocationForMove(Move(from: startRowCol, to: endRowCol))  // update model
                    checkProgress()
                    whoseTurn.next()
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
    
    private func bringMarbleViewToFrontAt(rowCol: RowCol) {
        if let marbleIndex = board.marbles.firstIndex(where: { $0.rowCol == rowCol }) {
            let marbleView = marbleViews[marbleIndex]
            boardView.bringSubviewToFront(marbleView)
        }
    }

    private func checkProgress() {
        if let winner = board.winner() {
            isGameOver = true
            messageLabel.text = winner == .human ? "You won!" : "Computer won!"
            turnView.isHidden = true
        } else {
            messageLabel.text = ""
        }
    }

    // MARK: - Button Actions
    
    // reset game
    @IBAction func restartPressed(_ sender: UIButton) {
        isGameOver = false
        messageLabel.text = ""
        turnView.isHidden = false
        // move all marbles back to their starting positions
        board.updateAllMarbleLocationsToStartingPositions()
        UIView.animate(withDuration: Constant.farMoveTime, delay: 0, animations: {
            self.updateViewFromModel()
        }, completion: { _ in
            if self.whoseTurn == .computer {
                self.computerMove()
            }
        }
        )
    }
    
    // MARK: - Computer
    
    private func computerMove() {
        DispatchQueue.global(qos: .userInitiated).async {
            let bestMove = self.computer.bestMoveOn(board: self.board)
            DispatchQueue.main.async {
                UIView.animate(withDuration: Constant.farMoveTime, delay: 0, animations: {
                    self.board.updateMarbleLocationForMove(bestMove)
                    self.bringMarbleViewToFrontAt(rowCol: bestMove.to)
                    self.updateViewFromModel()
                }, completion: { _ in
                    self.checkProgress()
                    self.whoseTurn.next()
                }
                )
            }
        }
    }
}
