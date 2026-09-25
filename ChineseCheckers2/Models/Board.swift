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
    
    var marbles = [Marble]()  // first half is computer's marbles, second half is humans's marbles

    private var marbleStartingPositions = [RowCol]()  // used for restart; one for each marble; first half is computer, second half is human

    init() {
        initializeBoard()
//        setUpForEndGame()  // debug
    }
    
    private mutating func initializeBoard() {
        for row in 0..<Constant.boardSize {
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                // top triangle (computer's side)
                if col < Constant.playerSize - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .computer, rowCol: rowCol))
                }
                // bottom triangle (human's side)
                if col > 2 * Constant.boardSize - Constant.playerSize - 2 - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .human, rowCol: rowCol))
                }
            }
        }
    }

    // only valid for boardSize = 7, playerSize = 4
    mutating func setUpForEndGame() {
        // reverse sides, then move two marbles out of position
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[($0 + marbles.count / 2) % marbles.count] }
        updateMarbleLocation(from: RowCol(row: 3, col: 0), to: RowCol(row: 4, col: 0))
        updateMarbleLocation(from: RowCol(row: 6, col: 3), to: RowCol(row: 2, col: 6))
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
    
    private func isOnBoard(_ rowCol: RowCol) -> Bool {
        rowCol.row >= 0 && rowCol.row < Constant.boardSize && rowCol.col >= 0 && rowCol.col < Constant.boardSize
    }
    
    private func startingPositions(for player: Player) -> [RowCol] {
        let computerStartingPositions = Array(marbleStartingPositions.prefix(marbles.count / 2))  // first half
        let humanStartingPositions = Array(marbleStartingPositions.suffix(marbles.count / 2))  // second half
        return player == .computer ? computerStartingPositions : humanStartingPositions
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
        let moveDistance = from.distance(to: to)
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
    
    private func indexOfClosestMarbleTo(target: RowCol, in marbles: [Marble]) -> Int {
        let distancesToTarget = marbles.map { $0.rowCol.numberOfMovesTo(target) }
        return distancesToTarget.firstIndex(of: distancesToTarget.min()!)!
    }

    // number of moves remaining to fill every open hole in the destination area
    func numberOfMovesRemaining(for player: Player) -> Int {
        var movesRemaining = 0
        let endingPositions = startingPositions(for: player.other)
        var outstandingMarbles = marbles(for: player).filter { !endingPositions.contains($0.rowCol) }  // marbles not yet finished moving
        let openEndingPositions = endingPositions.filter { !isOccupied($0) }
        for openEndingPosition in openEndingPositions {
            let closestMarbleIndex = indexOfClosestMarbleTo(target: openEndingPosition, in: outstandingMarbles)
            let closestMarble = outstandingMarbles[closestMarbleIndex]
            movesRemaining += closestMarble.rowCol.numberOfMovesTo(openEndingPosition)
            outstandingMarbles.remove(at: closestMarbleIndex)
        }
        return movesRemaining
    }
    
    // higher is better for computer
    func netScore(for player: Player) -> Int {
        numberOfMovesRemaining(for: player.other) - numberOfMovesRemaining(for: player)
    }
    
    // MARK: - CustomStringConvertible
    
    var description: String {
        var string = ""
        string += "\n  0 1 2 3 4 5 6"
        for row in 0..<Constant.boardSize {
            string += "\n\(row)"
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                if let marble = marbles.first(where: { $0.rowCol == rowCol }) {
                    string += marble.player == .human ? " h" : " c"
                } else {
                    string += " ."
                }
            }
        }
        return string
    }
}
