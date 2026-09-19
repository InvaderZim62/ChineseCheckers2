//
//  Computer.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/18/26.
//

import UIKit

struct ComputerConst {
    static let isDebugging = true
}

class Computer {
    
    private func dPrint<T>(_ object: T) where T: CustomStringConvertible {
        guard ComputerConst.isDebugging else { return }
        print(object.description)
    }

    //======================================================================================================
    // best move algorithm
    // computer: loop through all computer first moves
    // player: loop through all player first moves
    // computer: loop through all computer second moves, storing lowest net score for each
    // pick highest of the lowest net score moves, assuming the human will seek to minimize computer's gains
    // note: use an odd searchDepth, so algorithm stops going deeper on computer's turn
    //======================================================================================================

    func bestMoveOn(board: Board) -> Move {
        dPrint(board)
        dPrint("level: 0")
        var bestMove = Move(fromRowCol: RowCol.zero, toRowCol: RowCol.zero)
        var highScore = -100
        //----------------------------------------------------------------------------------------------------------
        tryMoves(player: .computer, board: board, level: 1, bestScore: &highScore, bestMove: &bestMove, isMax: true)
        //----------------------------------------------------------------------------------------------------------
        dPrint("level: 1, highest low score: \(highScore)")
        dPrint("==========================")
        dPrint(bestMove)
        dPrint("==========================")
        return bestMove
    }

    private func tryMoves(player: Player, board: Board, level: Int, bestScore: inout Int, bestMove: inout Move, isMax: Bool) {
        let availableMoves = board.availableMoves(for: player)
        for (index, move) in availableMoves.enumerated() {
            var boardCopy = board  // use a fresh copy before making each move
            let preMoveScore = boardCopy.netScore()
            boardCopy.updateMarbleLocation(from: move.fromRowCol, to: move.toRowCol)
            dPrint(boardCopy)
            dPrint("level: \(level), move: \(index + 1)/\(availableMoves.count)")
            let postMoveScore = boardCopy.netScore()
            let netScore = player == .computer ? postMoveScore - preMoveScore : preMoveScore - postMoveScore
            if netScore < 0 && move != availableMoves.last {
                // don't move to a worse position, unless there are no other moves
                dPrint("worse position")
                continue
            }
            var score: Int
            if level >= Constant.searchDepth || boardCopy.winner() != nil {
                // at search depth or game over - compute score at this level
                // assuming searchDepth is an odd number, this is computer's turn
                score = boardCopy.netScore()
                dPrint("score: \(score)")
            } else {
                // not at search depth - go to next level
                score = 100
                //----------------------------------------------------------------------------------------------------------------------
                tryMoves(player: player.other, board: boardCopy, level: level + 1, bestScore: &score, bestMove: &bestMove, isMax: false)
                //----------------------------------------------------------------------------------------------------------------------
            }
            if isMax {
                if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            } else {
                if score < bestScore {
                    bestScore = score
                }
            }
        }
        dPrint("level: \(level), lowScore: \(bestScore)")
    }
}
