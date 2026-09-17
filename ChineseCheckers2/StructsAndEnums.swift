//
//  StructsAndEnums.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/15/26.
//

import Foundation

enum Player: String, CaseIterable {
    case player1, player2
    
    var other: Player {
        self == .player1 ? .player2 : .player1
    }
}

struct RowCol: Hashable {
    let row: Int
    let col: Int
    
    static let zero = RowCol(row: 0, col: 0)
    static let center = RowCol(row: 3, col: 3)
    
    // straight-line distance
    // usage: RowCol(row: 0, col: 0).distance(to: RowCol(row: 3, col: 4))  // = 5.0
    func distance(to rowCol: RowCol) -> Double {
        sqrt(pow(Double(self.row - rowCol.row), 2) + pow(Double(self.col - rowCol.col), 2))
    }
    
    // hole-to-hole move distance
    // usage: RowCol(row: 0, col: 0).moveDistance(to: RowCol(row: 3, col: 4))  // = 7
    func moveDistance(to rowCol: RowCol) -> Int {
        abs(self.row - rowCol.row) + abs(self.col - rowCol.col)
    }
}

struct Marble {
    let player: Player
    var rowCol: RowCol
}

struct Move {
    let fromRowCol: RowCol
    let toRowCol: RowCol
}
