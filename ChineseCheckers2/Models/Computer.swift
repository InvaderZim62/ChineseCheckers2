//
//  Computer.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/18/26.
//

import UIKit

class Computer {

    //======================================================================================================
    // best move algorithm
    // computer: loop through all computer first moves
    // player: loop through all player first moves
    // computer: loop through all computer second moves, storing lowest net score for each
    // pick highest of the lowest net score moves, assuming the human will seek to minimize computer's gains
    // note: use an odd searchDepth, so algorithm stops going deeper on computer's turn
    //======================================================================================================

    func bestMoveOn(board: Board) -> Move {
        var bestMove = Move(fromRowCol: RowCol.zero, toRowCol: RowCol.zero)
        //---------------------------------------------------------------------------------------
        _ = tryMoves(player: .computer, board: board, level: 1, bestMove: &bestMove, isMax: true)
        //---------------------------------------------------------------------------------------
        return bestMove
    }

    private func tryMoves(player: Player, board: Board, level: Int, bestMove: inout Move, isMax: Bool) -> Int {
        var bestScore = isMax ? -100 : 100
        let availableMoves = board.availableMoves(for: player)
        for move in availableMoves {
            var boardCopy = board  // use a fresh copy before making each move
            let preMoveScore = boardCopy.netScore(for: player)
            boardCopy.updateMarbleLocation(from: move.fromRowCol, to: move.toRowCol)
            let postMoveScore = boardCopy.netScore(for: player)
            if postMoveScore - preMoveScore < 0 && move != availableMoves.last {
                // don't move to a worse position, unless there are no other moves
                continue
            }
            var score: Int
            if level >= Constant.searchDepth || boardCopy.winner() != nil {
                // at search depth or game over - compute score at this level
                // assuming searchDepth is an odd number, this is computer's turn
                score = boardCopy.netScore(for: player)
            } else {
                // not at search depth - go to next level
                //-----------------------------------------------------------------------------------------------------------
                score = tryMoves(player: player.other, board: boardCopy, level: level + 1, bestMove: &bestMove, isMax: false)
                //-----------------------------------------------------------------------------------------------------------
            }
            if isMax {
                if score == bestScore {
                    if Bool.random() {  // don't always make same moves
                        bestScore = score
                        bestMove = move
                    }
                } else if score > bestScore {
                    bestScore = score
                    bestMove = move
                }
            } else {
                if score < bestScore {
                    bestScore = score
                }
            }
        }
        return bestScore
    }
}
