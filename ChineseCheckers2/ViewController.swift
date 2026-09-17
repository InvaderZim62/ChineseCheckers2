//
//  ViewController.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//
// To do...
// - make it a two-player game over WiFi (like Battleship)
// - create computer player logic
//

import UIKit

struct Constant {
    static let boardColor = #colorLiteral(red: 1, green: 0.9140625, blue: 0.5994323806, alpha: 1)
    static let player1Color = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let player2Color = #colorLiteral(red: 1, green: 0.5853449012, blue: 0.8847629183, alpha: 1)
    static let searchDepth = 3  // only use odd numbers
    static let boardSize = 7
    static let startingSize = 4  // player starting triangle size
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
    var marbleViews = [MarbleView]()
    var isGameOver = false
    var pastBounds = CGRect.zero
    var whoseTurn = Player.player1 {
        didSet {
            turnView.player = whoseTurn
            if whoseTurn == .player2 {
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
    
    @objc private func handlePan(recognizer: UIPanGestureRecognizer) {
        guard isGameOver == false else { return }
        if let pannedMarbleView = recognizer.view as? MarbleView {
            guard board.marbles[pannedMarbleView.tag].player == whoseTurn else { return }
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
                    UIView.animate(withDuration: Constant.closeMoveTime) {
                        pannedMarbleView.center = self.boardView.holePositions[self.startRowCol]!
                    }
                } else {
                    // marble successfully moved
                    board.updateMarbleLocation(from: startRowCol, to: endRowCol)  // update model
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
    
    private func marbleViewsForPlayer(_ player: Player) -> [MarbleView] {
        marbleViews.filter( { $0.player == player })
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
            messageLabel.text = winner == .player1 ? "Player 1 wins!" : "Player 2 wins!"
            turnView.isHidden = true
        } else {
            messageLabel.text = ""
        }
    }

    // MARK: - Button Actions
    
    // reset game
    @IBAction func restartPressed(_ sender: UIButton) {
        messageLabel.text = ""
        turnView.isHidden = false
        // move all marbles back to their starting positions
        board.updateAllMarbleLocationsToStartingPositions()
        UIView.animate(withDuration: Constant.farMoveTime) {
            self.updateViewFromModel()
        }
    }
    
    // MARK: - Computer
    
    // best move algorithm
    // computer: loop through all computer first moves
    // player: loop through all player first moves
    // computer: loop through all computer second moves, storing score for each
    // assuming the player will seek to minimize computer's gains
    
    private func computerMove() {
        let bestMove = bestMove()
        board.updateMarbleLocation(from: bestMove.fromRowCol, to: bestMove.toRowCol)
        bringMarbleViewToFrontAt(rowCol: bestMove.toRowCol)
        UIView.animate(withDuration: Constant.farMoveTime) {
            self.updateViewFromModel()
        }
        checkProgress()
        whoseTurn.next()
    }
    
    private func bestMove() -> Move {
        var bestMove = Move(fromRowCol: RowCol.zero, toRowCol: RowCol.zero)
        var highScore = 0
        let availableMoves = board.availableMoves(for: .player2)
        for move in availableMoves {
            var boardCopy = board
            let preMoveScore = boardCopy.score(for: .player2)
            boardCopy.updateMarbleLocation(from: move.fromRowCol, to: move.toRowCol)
            let postMoveScore = boardCopy.score(for: .player2)
            if postMoveScore < preMoveScore && move != availableMoves.last {
                // don't move to a worse position, unless there are no other moves
                continue
            }
            print(boardCopy)
            print("level: 1")
            let score = tryMove(player: .player1, board: boardCopy, level: 2)
            if score > highScore {
                highScore = score
                bestMove = move
            }
        }
        print("==========================")
        print(bestMove)
        print("==========================")
        return bestMove
    }
    
    private func tryMove(player: Player, board: Board, level: Int) -> Int {
        var lowScore = 1000
        let availableMoves = board.availableMoves(for: player)
        for move in availableMoves {
            var boardCopy = board
            let preMoveScore = boardCopy.score(for: player)
            boardCopy.updateMarbleLocation(from: move.fromRowCol, to: move.toRowCol)
            let postMoveScore = boardCopy.score(for: player)
            if postMoveScore < preMoveScore && move != availableMoves.last {
                // don't move to a worse position, unless there are no other moves
                continue
            }
            print(boardCopy)
            print("level: \(level)")
            var score: Int
            if level >= Constant.searchDepth || boardCopy.winner() != nil {
                // assuming searchDepth is an odd number, this is player2's turn
                score = boardCopy.score(for: player)
                print("score: \(score)")
            } else {
                score = tryMove(player: player.other, board: boardCopy, level: level + 1)
            }
            if score < lowScore {
                lowScore = score
            }
        }
        print("lowScore: \(lowScore)")
        return lowScore
    }
}
