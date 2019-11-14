//
//  Achievements Handler.swift
//  Sway Boat
//
//  Created by Juan Erenas on 10/13/19.
//  Copyright © 2019 Juan Erenas. All rights reserved.
// 

import SpriteKit
import GameplayKit


extension GameScene {
    
    
    func showLevelRewards() {
        //create reusable label for achievements
        let nextLevelLabel = SKLabelNode(text: "")
        nextLevelLabel.fontName = "AvenirNext-Bold"
        nextLevelLabel.fontSize = 60.0
        nextLevelLabel.horizontalAlignmentMode = .center
        nextLevelLabel.fontColor = UIColor.white
        nextLevelLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        nextLevelLabel.alpha = 0
        worldNode.addChild(nextLevelLabel)
        
        //create action array for displaying all achievements
        var actionArray = [SKAction]()
        var totalPoints = 0
        
        //For each level achievement, display with amount earned
        
        levelAchievements.createAchievements()
        
        for achievement in levelAchievements.acheivementList {
            let text = achievement.displayText
            totalPoints += achievement.achievementValue
//            addMoney(ofAmount: achievement.achievementValue)
            actionArray.append(contentsOf: addAnimation(forLabel: nextLevelLabel, withText: text))
        }
        
        //Show the total earned from achievments
        let totalText = SKAction.customAction(withDuration: 0) { (_, _) in
            nextLevelLabel.text = "Total: \(totalPoints)"
        }
        let showTotalPoints = SKAction.fadeAlpha(to: 1.0, duration: 1)
        let expand = SKAction.scale(to: 0.5, duration: 0.3)
        let appearAndExpand = SKAction.group([totalText,showTotalPoints,expand])
        actionArray.append(appearAndExpand)
        
        
        for i in 0...totalPoints {
            
            let pointsLeft = totalPoints - i
            let wait = SKAction.wait(forDuration: 0.06)
            let transferMoney = SKAction.customAction(withDuration: 0) { (_,_) in
                nextLevelLabel.text = "Total: \(pointsLeft)"
                self.addMoney(ofAmount: 1)
            }
            actionArray.append(transferMoney)
            actionArray.append(wait)
        }
        let fadeOut = SKAction.fadeAlpha(to: 0, duration: 1)
        actionArray.append(fadeOut)
        
        
        
        //Show the next level number and begin spawning enemies
        let changeText = SKAction.customAction(withDuration: 0) { (_, _) in
            nextLevelLabel.text = "LEVEL \(self.level)"
        }
        let wait = SKAction.wait(forDuration: 1)
        let showNextLevel = SKAction.fadeAlpha(to: 1.0, duration: 1)
        let hideNextLevel = SKAction.fadeAlpha(to: 0, duration: 1)
        let removeNode = SKAction.removeFromParent()
        let startTimer = SKAction.customAction(withDuration: 0) { (_, _) in
            self.beginSpawningPaperMissiles()
        }
        
        //Put it all together and run
        let finalSequence = SKAction.sequence([changeText,wait,showNextLevel,wait,hideNextLevel,wait,startTimer,removeNode])
        
        actionArray.append(finalSequence)
        
        let sequence = SKAction.sequence(actionArray)
        nextLevelLabel.run(sequence)
        
    }
    
    func addAnimation(forLabel label: SKLabelNode, withText text: String) -> [SKAction] {
        let changeText = SKAction.customAction(withDuration: 0) { (node, _) in
            label.text = text
        }
        let appear = SKAction.fadeAlpha(to: 1, duration: 0.3)
        let expand = SKAction.scale(to: 0.5, duration: 0.3)
        let appearAndExpand = SKAction.group([appear,expand])
        
        let wait = SKAction.wait(forDuration: 0.7)
        let remove = SKAction.fadeAlpha(to: 0, duration: 0.1)
        let resetSize = SKAction.scale(to: 1, duration: 0)
        let actionArray = [changeText,appearAndExpand,wait,remove,resetSize]
        
        return actionArray
    }
}
