//
//  Board.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//
//  Board is the model.
//

import Foundation

struct Board: CustomStringConvertible {
    
    var description: String {
        var string = ""
        for row in 0..<Constant.boardSize {
            string += "\n"
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                if let marble = marbles.first(where: { $0.rowCol == rowCol }) {
                    string += marble.player == .human ? " p" : " c"
                } else {
                    string += " ."
                }
            }
        }
        return string
    }
    
    var marbles = [Marble]()  // first half is player 2's marbles, second half is player 1's marbles
    
    private var marbleStartingPositions = [RowCol]()  // one for each marble; first half is player 2's start, second half is player 1's start
    private var initialScore: Int!

    init() {
        initializeBoard()
        initialScore = marbles(for: .human).map({ $0.rowCol.moveDistance(to: RowCol.zero) }).reduce(0, +)
//        setUpForQuickGame()  // debug
//        setUpTestGame()
    }
    
    private mutating func initializeBoard() {
        for row in 0..<Constant.boardSize {
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                // top triangle (player 2's side)
                if col < Constant.playerSize - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .computer, rowCol: rowCol))
                }
                // bottom triangle (plater 1's side)
                if col > 2 * Constant.boardSize - Constant.playerSize - 2 - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .human, rowCol: rowCol))
                }
            }
        }
    }
    
    // only valid for boardSize = 5, playerSize = 2
    mutating func setUpTestGame() {
        marbles[0].rowCol = RowCol(row: 1, col: 4)
        marbles[3].rowCol = RowCol(row: 1, col: 3)
        marbles[4].rowCol = RowCol(row: 2, col: 4)
    }
    
    // only valid for boardSize = 7, playerSize = 4
    mutating func setUpForQuickGame() {
        // reverse sides, then move two marbles out of position
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[($0 + marbles.count / 2) % marbles.count] }
        marbles[3].rowCol = RowCol(row: 5, col: 3)
        marbles[13].rowCol = RowCol(row: 1, col: 3)
    }

    mutating func updateMarbleLocation(from: RowCol, to: RowCol) {
        if let marbleIndex = marbles.firstIndex(where: { $0.rowCol == from }) {
            marbles[marbleIndex].rowCol = to
        }
    }
    
    mutating func updateAllMarbleLocationsToStartingPositions() {
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[$0] }
    }
    
    // only use for two-position moves
    func rowColBetween(_ rowColA: RowCol, and rowColB: RowCol) -> RowCol {
        RowCol(row: Int(Double(rowColA.row + rowColB.row) / 2),
               col: Int(Double(rowColA.col + rowColB.col) / 2))
    }
    
    func isOccupied(_ rowCol: RowCol) -> Bool {
        marbles.contains { $0.rowCol == rowCol }
    }
    
    func indexForMarble(at rowCol: RowCol) -> Int? {
        marbles.firstIndex { $0.rowCol == rowCol }
    }
    
    private func isOnBoard(_ rowCol: RowCol) -> Bool {
        rowCol.row >= 0 && rowCol.row < Constant.boardSize && rowCol.col >= 0 && rowCol.col < Constant.boardSize
    }
    
    private func startingPositions(for player: Player) -> [RowCol] {
        let humanStartingPositions = Array(marbleStartingPositions.suffix(marbles.count / 2))  // second half
        let computerStartingPositions = Array(marbleStartingPositions.prefix(marbles.count / 2))  // first half
        return player == .human ? humanStartingPositions : computerStartingPositions
    }
    
    private func marbles(for player: Player) -> [Marble] {
        marbles.filter { $0.player == player }
    }
    
    private func isWinner(_ player: Player) -> Bool {
        // check if all player marbles are in other player's starting positions
        marbles(for: player).allSatisfy { startingPositions(for: player.other).contains($0.rowCol) }
    }
    
    func winner() -> Player? {
        let isHumanWinner = isWinner(.human)
        let isComputerWinner = isWinner(.computer)
        if !isHumanWinner && !isComputerWinner {
            return nil
        } else {
            return isHumanWinner ? .human : .computer
        }
    }

    func isLegalMove(from: RowCol, to: RowCol) -> Bool {
        guard isOnBoard(to) else { return false }
        let isDestinationUnoccupied = !isOccupied(to)
        let moveDistance = sqrt(pow(Double(from.row - to.row), 2) + pow(Double(from.col - to.col), 2))
        let isOnePositionMove = moveDistance == 1
        let isTwoPositionMove = moveDistance == 2
        let jumpedRowCol = rowColBetween(from, and: to)
        let isJumpedPositionOccupied = isOccupied(jumpedRowCol)
        return isDestinationUnoccupied && (isOnePositionMove || (isTwoPositionMove && isJumpedPositionOccupied))
    }

    // MARK: - Computer
    
    func availableMoves(for player: Player) -> [Move] {
        var moves: [Move] = []
        for marble in marbles where marble.player == player {
            // all potential one-hole and two-hole (jump) moves
            let directions: [(Int, Int)] = [(0, 1), (1, 0), (0, -1), (-1, 0), (0, 2), (2, 0), (0, -2), (-2, 0)]
            for (deltaRow, deltaCol) in directions {
                if let toRowCol = checkForMoveAtPosition(deltaRow: deltaRow, deltaCol: deltaCol, from: marble.rowCol) {
                    moves.append(Move(fromRowCol: marble.rowCol, toRowCol: toRowCol))
                }
            }
        }
        return moves
    }
    
    private func checkForMoveAtPosition(deltaRow: Int, deltaCol: Int, from fromRowCol: RowCol) -> RowCol? {
        let toRowCol = RowCol(row: fromRowCol.row + deltaRow, col: fromRowCol.col + deltaCol)
        if isLegalMove(from: fromRowCol, to: toRowCol) {
            return toRowCol
        } else {
            return nil
        }
    }
    
    // score is loosely based on how close you are to winning;
    // larger is better; score initially starts at zero
    func score(for player: Player) -> Int {
        let destinationCorner = player == .human ? RowCol.zero : RowCol(row: Constant.boardSize - 1, col: Constant.boardSize - 1)
        // initial score - sum of moves to corner (one hole at a time)
        return initialScore - marbles(for: player).map({ $0.rowCol.moveDistance(to: destinationCorner) }).reduce(0, +)
    }
    
    func netScore(for player: Player) -> Int {
        score(for: player) - score(for: player.other)
    }
}
