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
    // human: loop through all human first moves
    // computer: loop through all computer second moves, storing lowest net score for each
    // pick highest of the lowest net score moves, assuming the human will seek to minimize computer's gains
    // note: use an odd searchDepth, so algorithm stops going deeper on computer's turn
    //======================================================================================================

    func bestMoveOn(board: Board) -> Move {
        dPrint(board)
        dPrint("level: 0")
        var bestMove = Move(fromRowCol: RowCol.zero, toRowCol: RowCol.zero)
        //---------------------------------------------------------------------------------------------------
        let highScore = tryMoves(player: .computer, board: board, level: 1, bestMove: &bestMove, isMax: true)
        //---------------------------------------------------------------------------------------------------
        dPrint("level: 1, highest high score: \(highScore)")
        dPrint("==========================")
        dPrint(bestMove)
        dPrint("==========================")
        return bestMove
    }

    private func tryMoves(player: Player, board: Board, level: Int, bestMove: inout Move, isMax: Bool) -> Int {
        var bestScore = isMax ? -100 : 100
        let availableMoves = board.availableMoves(for: player)
        var thisLevelScores = [Int]()
        var deeperLevelScores = [Int]()
        for (index, move) in availableMoves.enumerated() {
            var boardCopy = board  // use a fresh copy before making each move
            boardCopy.updateMarbleLocation(from: move.fromRowCol, to: move.toRowCol)
            dPrint(boardCopy)
            dPrint("level: \(level), move: \(index + 1)/\(availableMoves.count)")
            // save scores at this level for tie-breaker, in case all deeper-levels return same score
            thisLevelScores.append(boardCopy.netScore(for: player))
            
            var score: Int
            // if this is a human winning move, set score to something bad for the computer
            // if this is a computer winning move, set score to something good for computer
            if boardCopy.winner() != nil {
                // winning move
                if player == .human {
                    bestScore = isMax ? -100 : 100
                } else {
                    bestScore = isMax ? 100 : -100
                }
                break  // don't try other moves
                
            } else if level >= Constant.searchDepth {
                // at search depth - compute score to send up
                // note: assuming searchDepth is an odd number, this is computer's turn
                score = boardCopy.netScore(for: player)
                dPrint("score: \(score)")
            } else {
                // not at search depth - go to next level
                //----------------------------------------------------------------------------------------------------------
                score = tryMoves(player: player.other, board: boardCopy, level: level + 1, bestMove: &bestMove, isMax: true)
                //----------------------------------------------------------------------------------------------------------
            }
            deeperLevelScores.append(score)
            if isMax {
                if level == 1 {
                    // save best move (as well as best score), if level 1
                    if score == bestScore {
                        if Bool.random() {  // don't always make same moves
                            bestMove = move
                        }
                    } else if score > bestScore {
                        bestScore = score
                        bestMove = move
                    }
                } else if score > bestScore {
                    bestScore = score
                }
            } else {
                if score < bestScore {
                    bestScore = score
                }
            }
        }
        // at level 1 (computer's move), if all deeper-level scores are the same, use computer's best first move
        if level == 1 && deeperLevelScores.allSatisfy({ $0 == deeperLevelScores.first }) {
            let maxScoreIndices = thisLevelScores.allIndices(of: thisLevelScores.max()!)
            let maxScoreIndex = maxScoreIndices.randomElement()!
            bestMove = availableMoves[maxScoreIndex]
        }
        dPrint("level: \(level), highScore: \(bestScore)")
        return bestScore
    }
}
