//
//  Settings.swift
//  Sway Boat
//
//  Created by Juan Erenas on 9/17/18.
//  Copyright © 2018 Juan Erenas. All rights reserved.
//

import Foundation

enum PhysicsCategories {
    static let none: UInt32 = 0
    static let boatCategory: UInt32 = 0x1           // 01
    static let defenderCategory: UInt32 = 0x1 << 1   // 10
    static let paperMissileCategory: UInt32 = 0x1 << 2
    static let powerUpCategory: UInt32 = 0x1 << 3
}
