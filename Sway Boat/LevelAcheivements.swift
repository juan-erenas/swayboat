//
//  LevelAcheivements.swift
//  Sway Boat
//
//  Created by Juan Erenas on 8/15/19.
//  Copyright © 2019 Juan Erenas. All rights reserved.
//

import SpriteKit
class LevelAchievements {
    
    var damaged = false
    
    var acheivementList = [Achievement]()
    
    func createAchievements() {
        if damaged == false {
            acheivementList.append(Achievement(text: "ZERO DAMAGE", andValue: 30))
        }
        acheivementList.append(Achievement(text: "LEVEL COMPLETE", andValue: 10))
    }
}

struct Achievement {
    
    let achievementText : String
    let achievementValue : Int
    let displayText: String
    
    init(text: String, andValue value: Int) {
        achievementText = text
        achievementValue = value
        
        displayText = achievementText + ": +\(achievementValue)"
    }
}
