//
//  Board.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/8/26.
//

import Foundation

struct RowCol: Hashable {
    let row: Int
    let col: Int
    
    static let zero = RowCol(row: 0, col: 0)
    static let center = RowCol(row: 3, col: 3)
}

enum Player {
    case player1, player2
}

struct Board {
    
    private var occupant: [[Player?]] = Array(repeating: Array(repeating: nil, count: 7), count: 7)
    
    init() {
        initializeBoard()
    }
    
    mutating func reset() {
        initializeBoard()
    }
    
    private mutating func initializeBoard() {
        for row in 0..<7 {
            for col in 0..<7 {
                // top triangle
                if col < 4 - row {
                    occupant[row][col] = .player2
                }
                // bottom triangle
                if col > 8 - row {
                    occupant[row][col] = .player1
                }
            }
        }
    }
    
    func occupant(at rowCol: RowCol) -> Player? {
        occupant[rowCol.row][rowCol.col]
    }
    
    mutating func moveMarble(from: RowCol, to: RowCol) {
        occupant[to.row][to.col] = occupant[from.row][from.col]
        occupant[from.row][from.col] = nil
    }
    
//    mutating func setOccupant(at rowCol: RowCol, to player: Player?) {
//        occupant[rowCol.row][rowCol.col] = player
//    }
    
    // only makes sense for two-position move
    func rowColBetween(_ rowColA: RowCol, and rowColB: RowCol) -> RowCol {
        RowCol(row: Int(Double(rowColA.row + rowColB.row) / 2),
               col: Int(Double(rowColA.col + rowColB.col) / 2))
    }

    func isLegalMove(from: RowCol, to: RowCol) -> Bool {
        let isDestinationUnoccupied = occupant(at: to) == nil
        let moveDistance = sqrt(pow(Double(from.row - to.row), 2) + pow(Double(from.col - to.col), 2))
        let isOnePositionMove = moveDistance == 1
        let isTwoPositionMove = moveDistance == 2
        let jumpedRowCol = rowColBetween(from, and: to)
        let isJumpedPositionOccupied = occupant(at: jumpedRowCol) != nil
        return isDestinationUnoccupied && (isOnePositionMove || (isTwoPositionMove && isJumpedPositionOccupied))
    }
}
