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

struct Board {
    
    private(set) var isOccupied = [RowCol: Bool]()
    private var numberOfMarbles = 0
    
    init() {
        initializeBoard()
//        setUpQuickWin()  // debug
//        setUpQuickLoss()  // debug
    }
    
    mutating func reset() {
        numberOfMarbles = 0
        isOccupied.removeAll()
        initializeBoard()
    }
    
    private mutating func initializeBoard() {
        for row in 0..<7 {
            for col in 0..<7 {
                let isCenterCols = (col > 1 && col < 5)
                if (row < 2 && isCenterCols) || (row > 1 && row < 5) || (row > 4 && isCenterCols) {
                    // cross shape
                    isOccupied[RowCol(row: row, col: col)] = true
                    numberOfMarbles += 1
                }
            }
        }
        isOccupied[RowCol.center] = false  // leave center empty
    }
    
    mutating func setUpQuickWin() {
        isOccupied.keys.forEach { isOccupied[$0] = false }
        isOccupied[RowCol(row: 1, col: 3)] = true
        isOccupied[RowCol(row: 2, col: 1)] = true
        isOccupied[RowCol(row: 2, col: 2)] = true
        numberOfMarbles = 3
    }
    
    mutating func setUpQuickLoss() {
        isOccupied.keys.forEach { isOccupied[$0] = false }
        isOccupied[RowCol(row: 1, col: 3)] = true
        isOccupied[RowCol(row: 2, col: 3)] = true
        isOccupied[RowCol(row: 2, col: 0)] = true
        isOccupied[RowCol(row: 3, col: 0)] = true
        isOccupied[RowCol(row: 4, col: 0)] = true
        numberOfMarbles = 4
    }
    
    mutating func markOccupied(_ rowCol: RowCol, _ bool: Bool) {
        isOccupied[rowCol] = bool
    }
    
    func rowColBetween(_ rowColA: RowCol, and rowColB: RowCol) -> RowCol {
        RowCol(row: Int(Double(rowColA.row + rowColB.row) / 2),
               col: Int(Double(rowColA.col + rowColB.col) / 2))
    }
    
    var firstUnoccupiedRowCol: RowCol? {
        isOccupied.first(where: { !$0.value && $0.key != RowCol.center})?.key
    }
    
    var isCenterOccupied: Bool {
        isOccupied[RowCol.center] ?? false
    }
    
    func isLegalMove(from: RowCol, to: RowCol) -> Bool {
        let isDestinationUnoccupied = isOccupied[to] == false
        let isTwoPositionMove = sqrt(pow(Double(from.row - to.row), 2) + pow(Double(from.col - to.col), 2)) == 2
        let jumpedRowCol = rowColBetween(from, and: to)
        let isJumpedPositionOccupied = isOccupied[jumpedRowCol] == true
        return isDestinationUnoccupied && isTwoPositionMove && isJumpedPositionOccupied
    }
    
    var isGameOver: Bool {
        isOccupied.values.filter({ $0 }).count == 1
    }
    
    var isPlayAvailable: Bool {
        for rowCol in occupiedRowCols {
            if canMove(rowCol: rowCol) {
                return true
            }
        }
        return false
    }
    
    private var occupiedRowCols: [RowCol] {
        isOccupied.filter({ $0.value }).map({ $0.key })
    }
    
    private func canMove(rowCol: RowCol) -> Bool {
        let canMoveUp = canMoveInDirection(deltaRow: -1, deltaCol: 0, from: rowCol)
        let canMoveDown = canMoveInDirection(deltaRow: 1, deltaCol: 0, from: rowCol)
        let canMoveLeft = canMoveInDirection(deltaRow: 0, deltaCol: -1, from: rowCol)
        let canMoveRight = canMoveInDirection(deltaRow: 0, deltaCol: 1, from: rowCol)
        return canMoveUp || canMoveDown || canMoveLeft || canMoveRight
    }
    
    private func canMoveInDirection(deltaRow: Int, deltaCol: Int, from rowCol: RowCol) -> Bool {
        let nextRowCol = RowCol(row: rowCol.row + deltaRow, col: rowCol.col + deltaCol)
        let nextNextRowCol = RowCol(row: rowCol.row + 2 * deltaRow, col: rowCol.col + 2 * deltaCol)
        return isOccupied[nextRowCol] == true && isOccupied[nextNextRowCol] == false
    }
}
