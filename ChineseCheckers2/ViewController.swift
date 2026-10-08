//
//  ViewController.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//
//  Two-player Chinese Checkers.
//
//  Goal is to move all your marbles from the starting side to the opposite side (home), before
//  the other player does the same
//
//  Rules:
//  - during your turn, you can move a marble one space, or jump another marble (yours or theirs)
//  - marbles are not removed from the board
//  - you can string multiple jumps together in the same turn, but you can't combine single moves
//    and jumps in the same turn
//  - once a marble is home, it cannot move back out of home (it can move around in home)
//  - player wins if all their marbles are home
//  - player can also win with just one of the other player's marbles in your home (to prevent the
//    other player from blocking your home, as a stalling tactic), as long as your home is completely
//    filled
//

import UIKit

struct Constant {
    static let boardColor = #colorLiteral(red: 1, green: 0.9140625, blue: 0.5994323806, alpha: 1)
    static let humanColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
    static let computerColor = #colorLiteral(red: 1, green: 0.5853449012, blue: 0.8847629183, alpha: 1)
    static let boardSize = 7
    static let playerSize = 4  // starting triangle dimension
    static let marbleRadius: CGFloat = 12
    static let snapDistance: CGFloat = 14
    static let moveLineWidth: CGFloat = 5
    static let farMoveTime: TimeInterval = 0.7  // used for computer's move and returning marbles during restart
    static let closeMoveTime: TimeInterval = 0.4  // used to return marble, if unmoved
}

class ViewController: UIViewController {
    
    let globalData = GlobalData.shared
    
    var board = Board()
    let computer = Computer()
    var marbleViews = [MarbleView]()
    var isGameOver = false
    var pastBounds = CGRect.zero
    var whoseTurn: Player! {
        didSet {
            turnIndicatorView.player = whoseTurn
            if whoseTurn == .computer && !isGameOver {
                computerMove()
            }
        }
    }
    var isHardPlay = true {
        didSet {
            globalData.searchDepth = isHardPlay ? 3 : 1  // only use odd numbers (5 is slow)
            saveDefaults()
        }
    }

    // panning vars
    var availableEndpoints = [RowCol]()
    var panInitialPosition = CGPoint.zero
    var panOffset = CGPoint.zero
    var targetPosition = CGPoint.zero
    var startRowCol = RowCol.zero
    var endRowCol = RowCol.zero

    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var turnIndicatorView: TurnIndicatorView!  // colored circle in upper left corner
    @IBOutlet weak var moveView: MoveView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var hardPlaySwitch: UISwitch!
    
    // MARK: -

    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = ""
        getDefaults()
        createMarbleViews()
        whoseTurn = Player.random()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if view.bounds != pastBounds {
            updateViewFromModel()
            hardPlaySwitch.isOn = isHardPlay
            pastBounds = view.bounds
        }
    }
    
    private func getDefaults() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isHardPlay") != nil {
            isHardPlay = defaults.bool(forKey: "isHardPlay")
        }
    }

    private func saveDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(isHardPlay, forKey: "isHardPlay")
    }
    
    private func createMarbleViews() {
        let marbleViewSize = CGSize(width: 2 * Constant.marbleRadius + MarbleConst.lineWidth,
                                    height: 2 * Constant.marbleRadius + MarbleConst.lineWidth)
        let marbleViewFrame = CGRect(origin: .zero, size: marbleViewSize)
        for (index, marble) in board.marbles.enumerated() {
            let marbleView = MarbleView(frame: marbleViewFrame)
            marbleView.player = marble.player
            marbleView.tag = index
            marbleView.center = globalData.holePositions[marble.rowCol]!
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
            marbleView.center = globalData.holePositions[rowCol]!
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
                availableEndpoints = board.availableEndpoints(from: startRowCol, forPlayer: .human)
                endRowCol = startRowCol
                boardView.bringSubviewToFront(pannedMarbleView)
                moveView.clearMoveSequence()
           case .changed:
                targetPosition = (panInitialPosition + translation + panOffset)
                let nearbyRowCol = boardView.holeRowCol(near: targetPosition)  // nil if no holes nearby
                
                if let nearbyRowCol, nearbyRowCol == startRowCol || availableEndpoints.contains(nearbyRowCol) {
                    // panning near starting hole or any legal move hole - snap position, set end point
                    pannedMarbleView.center = globalData.holePositions[nearbyRowCol]!
                    endRowCol = nearbyRowCol
                    let moveSequence = board.shortestSequence(from: startRowCol, to: endRowCol, forPlayer: .human)
                    moveView.showMoveSequence(moveSequence, player: .human)
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
                        pannedMarbleView.center = self.globalData.holePositions[self.startRowCol]!
                    }
                } else {
                    // marble successfully moved
                    board.updateMarbleLocationForMove(Move(from: startRowCol, to: endRowCol))  // update model
                    print(board)
                    print("Human move: from: \(startRowCol), to: \(endRowCol)")
                    checkProgress()
                    whoseTurn.next()
                }
                fadeOutMoveView()
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
            turnIndicatorView.isHidden = true
        } else {
            messageLabel.text = ""
        }
    }
    
    private func fadeOutMoveView() {
        UIView.animate(withDuration: 0.5, delay: 0, animations: {
            self.moveView.alpha = 0
        }, completion: { _ in
            self.moveView.clearMoveSequence()
            self.moveView.alpha = 1
        }
        )
    }

    // MARK: - IBActions
    
    // reset game
    @IBAction func restartPressed(_ sender: UIButton) {
        isGameOver = false
        messageLabel.text = ""
        turnIndicatorView.isHidden = false
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
    
    @IBAction func hardPlaySelected(_ sender: UISwitch) {
        isHardPlay = sender.isOn
    }
    
    // MARK: - Computer
    
    private func computerMove() {
        DispatchQueue.global(qos: .userInitiated).async {
            let bestMoveSequence = self.computer.bestMoveSequenceOn(board: self.board)
            DispatchQueue.main.async {
                self.moveView.showMoveSequence(bestMoveSequence, player: .computer)
                for (index, move) in bestMoveSequence.enumerated() {
                    let delay = Double(index) * Constant.farMoveTime
                    UIView.animate(withDuration: Constant.farMoveTime, delay: delay, animations: {
                        self.board.updateMarbleLocationForMove(move)
                        self.bringMarbleViewToFrontAt(rowCol: move.to)
                        self.updateViewFromModel()
                    }, completion: { _ in
                        if move == bestMoveSequence.last! {
                            self.fadeOutMoveView()
                            self.checkProgress()
                            self.whoseTurn.next()
                            print(self.board)
                            print("Computer Sequence: \(bestMoveSequence)")
                        }
                    }
                    )
                }
            }
        }
    }
}
