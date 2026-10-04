//
//  Computer.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/18/26.
//

import UIKit

class Computer {

    //=======================================================================================
    // best move algorithm
    // computer: loop through all computer first moves
    // human: loop through all human first moves
    // computer: loop through all computer second moves, returning highest net score for each
    // computer pass returns highest computer score, human pass return lowest computer score,
    // assuming player will seek to minimize computer's gains
    // note: use an odd searchDepth, so algorithm stops going deeper on computer's turn
    //=======================================================================================

    func bestMoveSequenceOn(board: Board) -> [Move] {
        var bestMove = Move(from: RowCol.zero, to: RowCol.zero)
        //---------------------------------------------------------------------------------------
        _ = tryMoves(player: .computer, board: board, level: 1, bestMove: &bestMove)
        //---------------------------------------------------------------------------------------
        let bestSequence = board.shortestSequence(from: bestMove.from, to: bestMove.to, forPlayer: .computer)
        return bestSequence
    }
    
    private func tryMoves(player: Player, board: Board, level: Int, bestMove: inout Move) -> Int {
        var bestScore = player == .computer ? -100 : 100  // computer wants max deep score, player wants min deep score
        let availableMoves = board.availableMoves(for: player)
        var thisLevelScores = [Int]()
        var deeperLevelScores = [Int]()
        for move in availableMoves {
            var boardCopy = board  // use a fresh copy before making each move
            boardCopy.updateMarbleLocationForMove(move)
            // save scores at this level for tie-breaker, in case all deeper-levels return same score
            thisLevelScores.append(boardCopy.netScore(for: player))

            var score: Int
            // if this is a human winning move, set score to something bad for the computer
            // if this is a computer winning move, set score to something good for computer
            if boardCopy.winner() != nil {
                // winning move
                bestScore = player == .computer ? 100 : -100
                bestMove = move
                break  // don't try other moves
                
            } else if level >= Constant.searchDepth {
                // at search depth - compute score to send up
                // note: assuming searchDepth is an odd number, this is computer's turn
                score = boardCopy.netScore(for: player)
            } else {
                // not at search depth - go to next level
                //---------------------------------------------------------------------------------------------
                score = tryMoves(player: player.other, board: boardCopy, level: level + 1, bestMove: &bestMove)
                //---------------------------------------------------------------------------------------------
            }
            deeperLevelScores.append(score)
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
            } else if player == .computer && score > bestScore {
                bestScore = score
            } else if player == .human && score < bestScore {
                bestScore = score
            }
        }
        // at level 1 (computer's move), if all deeper-level scores are the same, use computer's best first move
        if level == 1 && deeperLevelScores.allSatisfy({ $0 == deeperLevelScores.first }) {
            let maxScoreIndices = thisLevelScores.allIndices(of: thisLevelScores.max()!)
            let maxScoreIndex = maxScoreIndices.randomElement()!
            bestMove = availableMoves[maxScoreIndex]
        }
        return bestScore
    }

    private func printMoveSequences(_ sequences: [[Move]]) {
        for sequence in sequences {
            print(sequence)
        }
    }
}
