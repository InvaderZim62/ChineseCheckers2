//
//  Board.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import Foundation

enum Player: CaseIterable {
    case player1, player2
    
    mutating func next() {
        self = self == .player1 ? .player2 : .player1
    }
}

struct RowCol: Hashable {
    let row: Int
    let col: Int
    
    static let zero = RowCol(row: 0, col: 0)
    static let center = RowCol(row: 3, col: 3)
}

struct Marble {
    let player: Player
    var rowCol: RowCol
}

struct Board {
    
    var marbles = [Marble]()
    var marbleStartingPositions = [RowCol]()

    init() {
        initializeBoard()
    }
    
    private mutating func initializeBoard() {
        for row in 0..<Constant.boardSize {
            for col in 0..<Constant.boardSize {
                let rowCol = RowCol(row: row, col: col)
                // top triangle
                if col < Constant.startingSize - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .player2, rowCol: rowCol))
                }
                // bottom triangle
                if col > 2 * Constant.boardSize - Constant.startingSize - 2 - row {
                    marbleStartingPositions.append(rowCol)
                    marbles.append(Marble(player: .player1, rowCol: rowCol))
                }
            }
        }
    }
    
    mutating func updateMarbleLocationFor(_ marbleNumber: Int, to rowCol: RowCol) {
        marbles[marbleNumber].rowCol = rowCol
    }
    
    mutating func updateAllMarbleLocationsToStartingPositions() {
        marbles.indices.forEach { marbles[$0].rowCol = marbleStartingPositions[$0] }
    }
    
    // only use for two-position move
    func rowColBetween(_ rowColA: RowCol, and rowColB: RowCol) -> RowCol {
        RowCol(row: Int(Double(rowColA.row + rowColB.row) / 2),
               col: Int(Double(rowColA.col + rowColB.col) / 2))
    }
    
    func isOccupied(_ rowCol: RowCol) -> Bool {
        marbles.contains { $0.rowCol == rowCol }
    }

    func isLegalMove(from: RowCol, to: RowCol) -> Bool {
        let isDestinationUnoccupied = !isOccupied(to)
        let moveDistance = sqrt(pow(Double(from.row - to.row), 2) + pow(Double(from.col - to.col), 2))
        let isOnePositionMove = moveDistance == 1
        let isTwoPositionMove = moveDistance == 2
        let jumpedRowCol = rowColBetween(from, and: to)
        let isJumpedPositionOccupied = isOccupied(jumpedRowCol)
        return isDestinationUnoccupied && (isOnePositionMove || (isTwoPositionMove && isJumpedPositionOccupied))
    }
}
