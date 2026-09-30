//
//  HolePositions.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/30/26.
//

import UIKit

class GlobalData: NSObject {
    static let shared = GlobalData()
    private override init() { }
    
    var holePositions = [RowCol: CGPoint]()
}
