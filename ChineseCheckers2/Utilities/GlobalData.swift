//
//  HolePositions.swift
//  ChineseCheckers2
//
//  Created by Phil Stern on 9/30/26.
//
//  usage: let globalData = GlobalData.shared
//

import UIKit

class GlobalData: NSObject {
    
    static let shared = GlobalData()
    
    private override init() { }  // private to prevent: let globalData = GlobalData() (a non-shared instance)
    
    var holePositions = [RowCol: CGPoint]()
    var searchDepth = 3  // controlled by switch
}
