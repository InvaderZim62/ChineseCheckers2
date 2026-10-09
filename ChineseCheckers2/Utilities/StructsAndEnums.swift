//
//  StructsAndEnums.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/15/26.
//

import Foundation

enum Player: String, CaseIterable {
    case human, computer
    
    var other: Player {
        self == .human ? .computer : .human
    }
}

nonisolated struct RowCol: Hashable, CustomStringConvertible {  // nonisolated allows CustomStringConvertible to work in background tasks
    let row: Int
    let col: Int
    
    var description: String {
        "(\(row), \(col))"
    }
    
    static let zero = RowCol(row: 0, col: 0)
    static let none = RowCol(row: -1, col: -1)
    static let center = RowCol(row: 3, col: 3)
    
    // number of moves to another position
    // usage: RowCol(row: 1, col: 1).numberOfMovesTo(RowCol(row: 0, col: 2))  // = 1
    //        RowCol(row: 1, col: 1).numberOfMovesTo(RowCol(row: 0, col: 0))  // = 2
    func numberOfMovesTo(_ rowCol: RowCol) -> Int {
        Int(self.distanceTo(rowCol).rounded(.up))
    }

    // straight-line distance on board (in multiples of one move distance)
    // usage: RowCol(row: 1, col: 1).distanceTo(RowCol(row: 0, col: 2))  // = 1.0
    //        RowCol(row: 1, col: 1).distanceTo(RowCol(row: 0, col: 0))  // = 1.7
    private func distanceTo(_ rowCol: RowCol) -> Double {
        let angle = Double.pi / 3  // angle between rows and columns on board (60 degrees)
        let deltaCol = Double(self.col - rowCol.col)
        let deltaRow = Double(self.row - rowCol.row)
        let deltaX = (deltaCol - deltaRow) * cos(angle)
        let deltaY = (deltaCol + deltaRow) * sin(angle)
        return Double(round(sqrt(pow(deltaX, 2) + pow(deltaY, 2)) * 100)) / 100  // round to two decimal places
    }
}

struct Marble {
    let player: Player
    var rowCol: RowCol
}

nonisolated struct Move: Equatable, CustomStringConvertible {
    let from: RowCol
    let to: RowCol

    var isOnePosition: Bool {
        from.numberOfMovesTo(to) == 1
    }

    var isTwoPosition: Bool {
        from.numberOfMovesTo(to) == 2
    }

    // only good for two-position moves
    var midpoint: RowCol {
        RowCol(row: Int(Double(from.row + to.row) / 2),
               col: Int(Double(from.col + to.col) / 2))
    }

    var description: String {
        "from: \(from), to: \(to)"
    }
}
