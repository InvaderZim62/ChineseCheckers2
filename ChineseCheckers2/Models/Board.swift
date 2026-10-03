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
//        setUpForEndGame()
//        setupTestBoard1()
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

    // use with boardSize = 7, playerSize = 4
    mutating func setUpForEndGame() {
        // reverse sides, then move marbles out of position
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[($0 + marbles.count / 2) % marbles.count] }
        updateMarbleLocationForMove(Move(from: RowCol(row: 3, col: 0), to: RowCol(row: 4, col: 2)))
        updateMarbleLocationForMove(Move(from: RowCol(row: 5, col: 5), to: RowCol(row: 3, col: 5)))
    }
    
    // use with boardSize = 5, playerSize = 2, computer moves first
    mutating func setupTestBoard1() {
        marbles.removeAll()
        marbles.append(Marble(player: .human, rowCol: RowCol(row: 1, col: 0)))
        marbles.append(Marble(player: .human, rowCol: RowCol(row: 3, col: 3)))
        marbles.append(Marble(player: .human, rowCol: RowCol(row: 4, col: 1)))
        marbles.append(Marble(player: .computer, rowCol: RowCol(row: 2, col: 2)))
        marbles.append(Marble(player: .computer, rowCol: RowCol(row: 3, col: 0)))
        marbles.append(Marble(player: .computer, rowCol: RowCol(row: 4, col: 3)))
    }
    
    // use with boardSize = 5, playerSize = 2, computer moves first
    mutating func setupTestBoard2() {
        marbles.removeAll()
        marbles.append(Marble(player: .human, rowCol: RowCol(row: 1, col: 0)))
        marbles.append(Marble(player: .human, rowCol: RowCol(row: 2, col: 3)))
        marbles.append(Marble(player: .human, rowCol: RowCol(row: 4, col: 1)))
        marbles.append(Marble(player: .computer, rowCol: RowCol(row: 2, col: 2)))
        marbles.append(Marble(player: .computer, rowCol: RowCol(row: 4, col: 0)))
        marbles.append(Marble(player: .computer, rowCol: RowCol(row: 4, col: 3)))
    }

    private func printMoveSequences(_ sequences: [[Move]]) {
        for sequence in sequences {
            print(sequence)
        }
    }

    mutating func updateMarbleLocationForMove(_ move: Move) {
        if let marbleIndex = marbles.firstIndex(where: { $0.rowCol == move.from }) {
            marbles[marbleIndex].rowCol = move.to
        }
    }
    
    mutating func updateAllMarbleLocationsToStartingPositions() {
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[$0] }
    }
    
    // only meaningful for two-position moves
    func rowColBetween(move: Move) -> RowCol {
        RowCol(row: Int(Double(move.from.row + move.to.row) / 2),
               col: Int(Double(move.from.col + move.to.col) / 2))
    }
    
    func isOccupied(_ rowCol: RowCol) -> Bool {
        marbles.contains { $0.rowCol == rowCol }
    }
    
    func isOccupied(_ rowCol: RowCol, byPlayer player: Player) -> Bool {
        marbles(for: player).contains { $0.rowCol == rowCol }
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

    func isLegalMove(_ move: Move) -> Bool {
        guard isOnBoard(move.to) else { return false }
        let isDestinationUnoccupied = !isOccupied(move.to)
        let moveDistance = move.from.distance(to: move.to)
        let isOnePositionMove = moveDistance == 1
        let isTwoPositionMove = moveDistance == 2
        let jumpedRowCol = rowColBetween(move: move)
        let isJumpedPositionOccupied = isOccupied(jumpedRowCol)
        return isDestinationUnoccupied && (isOnePositionMove || (isTwoPositionMove && isJumpedPositionOccupied))
    }

    // MARK: - Computer
    
    func availableSequences(for player: Player) -> [[Move]] {
        var sequences = [[Move]]()
        for marble in marbles where marble.player == player {
            sequences += availableSequences(from: marble.rowCol)
        }
        return sequences
    }

    // this version returns sequences from beginning to end with all intermediate sequences
    // note: this is susceptible to infinite an loop (jumping in a circle)
    func availableSequences(from fromRowCol: RowCol, currentSequence: [Move] = []) -> [[Move]] {
        var allSequences = [[Move]]()
        var directions = [(Int, Int)]()
        if currentSequence.isEmpty {
            directions = [(0, 1), (1, 0), (0, -1), (-1, 0), (0, 2), (2, 0), (0, -2), (-2, 0)]
        } else {
            directions = [(0, 2), (2, 0), (0, -2), (-2, 0)]  // only jumps after first move
        }
        for (deltaRow, deltaCol) in directions {
            if let toRowCol = checkForMoveAtPosition(deltaRow: deltaRow, deltaCol: deltaCol, from: fromRowCol) {
                let move = Move(from: fromRowCol, to: toRowCol)
                if currentSequence.contains(where: { $0.from == toRowCol }) { continue }  // don't allow move to prior position in current sequence
                allSequences.append([move])
                let isJump = abs(deltaRow + deltaCol) == 2
                if isJump {
                    var sequences = availableSequences(from: toRowCol, currentSequence: currentSequence + [move])
                    if !sequences.isEmpty {
                        // add move to front of each returned sequence, before adding to allSequences
                        sequences.indices.forEach { sequences[$0].insert(contentsOf: [move], at: 0) }
                    }
                    allSequences.append(contentsOf: sequences)
                }
            }
        }
        return allSequences
    }
    
    func availableEndpoints(from fromRowCol: RowCol) -> [RowCol] {
        let sequences = availableSequences(from: fromRowCol)
        return sequences.map { $0.last!.to }
    }
    
    func moveSequence(fromRowCol: RowCol, toRowCol: RowCol) -> [Move] {
        let allSequences = availableSequences(from: fromRowCol)
        let sequences = allSequences.filter { $0.last!.to == toRowCol }  // may be more than one path
        return sequences.min(by: { $0.count < $1.count }) ?? []  // pick shortest path
    }

    // start to end positions of the move sequences
    func availableMoves(for player: Player) -> [Move] {
        let availableMoveSequences = availableSequences(for: player)
        return availableMoveSequences.map { Move(from: $0.first!.from, to: $0.last!.to) }
    }
    
    
    private func checkForMoveAtPosition(deltaRow: Int, deltaCol: Int, from fromRowCol: RowCol) -> RowCol? {
        let toRowCol = RowCol(row: fromRowCol.row + deltaRow, col: fromRowCol.col + deltaCol)
        if isLegalMove(Move(from: fromRowCol, to: toRowCol)) {
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
        let openEndingPositions = endingPositions.filter { !isOccupied($0, byPlayer: player) }
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
