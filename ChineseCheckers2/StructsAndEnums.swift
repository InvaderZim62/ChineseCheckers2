//
//  StructsAndEnums.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/15/26.
//

import Foundation

enum Player: CaseIterable {
    case player1, player2
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

struct Move {
    let fromRowCol: RowCol
    let toRowCol: RowCol
}
