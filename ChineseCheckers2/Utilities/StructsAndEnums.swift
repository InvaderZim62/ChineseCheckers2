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

struct RowCol: Hashable, CustomStringConvertible {
    let row: Int
    let col: Int
    
    var description: String {
        "(\(row), \(col))"
    }
    
    static let zero = RowCol(row: 0, col: 0)
    static let center = RowCol(row: 3, col: 3)
    
    // straight-line distance
    // usage: RowCol(row: 0, col: 0).distance(to: RowCol(row: 3, col: 4))  // = 5.0
    func distance(to rowCol: RowCol) -> Double {
        sqrt(pow(Double(self.row - rowCol.row), 2) + pow(Double(self.col - rowCol.col), 2))
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

struct Move: Equatable, CustomStringConvertible {
    let fromRowCol: RowCol
    let toRowCol: RowCol

    var description: String {
        "from: \(fromRowCol), to: \(toRowCol)"
    }
}
