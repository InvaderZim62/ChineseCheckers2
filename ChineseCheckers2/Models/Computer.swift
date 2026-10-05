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
    // deepest computer pass returns highest computer score; human pass returns lowest of
    // highest computer scores, assuming player will seek to minimize computer's gains; final
    // pass returns move giving highest of lowest computer scores
    // note: use an odd searchDepth, so algorithm stops going deeper on computer's turn
    //=======================================================================================

    func bestMoveSequenceOn(board: Board) -> [Move] {
        var bestMove = Move(from: RowCol.zero, to: RowCol.zero)
        //---------------------------------------------------------------------------------------
        _ = tryMoves(player: .computer, board: board, level: 1, bestMove: &bestMove)
        //---------------------------------------------------------------------------------------
        // best sequence is the one that starts with bestMove.from and ends in bestMove.to
        let bestSequence = board.shortestSequence(from: bestMove.from, to: bestMove.to, forPlayer: .computer)
        return bestSequence
    }
    
    private func tryMoves(player: Player, board: Board, level: Int, bestMove: inout Move) -> Int {
        var bestScore = player == .computer ? -100 : 100  // computer wants max deep score, player wants min deep score
        let availableMoves = board.availableBeginningToEndMoves(for: player)
        var thisLevelScores = [Int]()
        var deeperLevelScores = [Int]()
        for move in availableMoves {
            var boardCopy = board  // use a fresh copy before making each move
            boardCopy.updateMarbleLocationForMove(move)
            // save scores at this level for tie-breaker, in case all deeper-levels return same score
            var score = boardCopy.netScore(for: player)
            thisLevelScores.append(score)

            if boardCopy.winner() != nil {
                // game winning move - set score to extreme
                score = player == .computer ? 100 : -100
                thisLevelScores[thisLevelScores.endIndex - 1] = score  // replace this level score
            } else if level < Constant.searchDepth {
                // not at search depth - go to next level (else keep this level score)
                //---------------------------------------------------------------------------------------------
                score = tryMoves(player: player.other, board: boardCopy, level: level + 1, bestMove: &bestMove)
                //---------------------------------------------------------------------------------------------
                deeperLevelScores.append(score)
            }
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
}
