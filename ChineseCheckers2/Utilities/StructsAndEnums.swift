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
    
    // straight-line distance
    // usage: RowCol(row: 3, col: 0).distance(to: RowCol(row: 1, col: 2))  // = 2.0
    func distance(to rowCol: RowCol) -> Double {
        let angle = Double.pi / 3  // angle between rows and columns on board
        let deltaCol = Double(self.col - rowCol.col)
        let deltaRow = Double(self.row - rowCol.row)
        let deltaX = (deltaCol - deltaRow) * cos(angle)
        let deltaY = (deltaCol + deltaRow) * sin(angle)
        return sqrt(pow(deltaX, 2) + pow(deltaY, 2))
    }
    
    // hole-to-hole move distance
    // usage: RowCol(row: 0, col: 0).moveDistance(to: RowCol(row: 3, col: 4))  // = 7
    func numberOfMovesTo(_ rowCol: RowCol) -> Int {
        abs(self.row - rowCol.row) + abs(self.col - rowCol.col)
    }
}

struct Marble {
    let player: Player
    var rowCol: RowCol
}

nonisolated struct Move: Equatable, CustomStringConvertible {
    let from: RowCol
    let to: RowCol

    var description: String {
        "from: \(from), to: \(to)"
    }
}
