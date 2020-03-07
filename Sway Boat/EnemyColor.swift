//
//  Color.swift
//  Sway Boat
//
//  Created by Juan Erenas on 2/10/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import Foundation

enum EnemyColor : String {
    
    case blue
    case red
    case yellow
    case green
    case random
    
    static var cases : [EnemyColor] = [.blue, .red, .yellow, .green]
    init(_ ix:Int) {
        let number = ix % EnemyColor.cases.count
        self = EnemyColor.cases[number]
    }
}
