//
//  Computer.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/18/26.
//

import UIKit

struct ComputerConst {
    static let isDebugging = false
}

class Computer {
    
    private func dPrint(_ string: Any) {
        guard ComputerConst.isDebugging else { return }
        print(string)
    }

    // best move algorithm
    // computer: loop through all computer first moves
    // player: loop through all player first moves
    // computer: loop through all computer second moves, storing score for each
    // pick highest of the lowest score moves, assuming the player will seek to minimize computer's gains
    
    func bestMoveOn(board: Board) -> Move {
        var bestMove = Move(fromRowCol: RowCol.zero, toRowCol: RowCol.zero)
        var highScore = 0
        let availableMoves = board.availableMoves(for: .computer)
        for move in availableMoves {
            var boardCopy = board
            let preMoveScore = boardCopy.score(for: .computer)
            boardCopy.updateMarbleLocation(from: move.fromRowCol, to: move.toRowCol)
            let postMoveScore = boardCopy.score(for: .computer)
            if postMoveScore < preMoveScore && move != availableMoves.last {
                // don't move to a worse position, unless there are no other moves
                continue
            }
            dPrint(boardCopy)
            dPrint("level: 1")
            let score = tryMove(player: .human, board: boardCopy, level: 2)
            if score > highScore {
                highScore = score
                bestMove = move
            }
        }
        dPrint("==========================")
        dPrint(bestMove)
        dPrint("==========================")
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
            dPrint(boardCopy)
            dPrint("level: \(level)")
            var score: Int
            if level >= Constant.searchDepth || boardCopy.winner() != nil {
                // assuming searchDepth is an odd number, this is computer's turn
                score = boardCopy.score(for: player)
                dPrint("score: \(score)")
            } else {
                score = tryMove(player: player.other, board: boardCopy, level: level + 1)
            }
            if score < lowScore {
                lowScore = score
            }
        }
        dPrint("lowScore: \(lowScore)")
        return lowScore
    }
}
