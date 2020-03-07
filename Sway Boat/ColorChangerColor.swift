//
//  ColorChangerColor.swift
//  Sway Boat
//
//  Created by Juan Erenas on 2/21/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import Foundation

enum ColorChangerColor : String {
    
    case blue
    case red
    case yellow
    case green
    case white
    
    static var cases : [ColorChangerColor] = [.blue, .red, .yellow, .green, .white]
    init(_ ix:Int) {
        let number = ix % ColorChangerColor.cases.count
        self = ColorChangerColor.cases[number]
    }
}
