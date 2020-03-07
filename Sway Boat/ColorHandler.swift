//
//  ColorHandler.swift
//  Sway Boat
//
//  Created by Juan Erenas on 2/23/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

extension GameScene : ColorChangerDelegate {
    
    func changeColorShieldColor(to newColor: UIColor) {
        let shrink = SKAction.scale(to: 0.7, duration: 0.2)
        let grow = SKAction.scale(to: 1, duration: 0.2)
        let changeColor = SKAction.customAction(withDuration: 0) { (_, _) in
            self.colorShield.color = newColor
        }
        let sequence = SKAction.sequence([shrink,changeColor,grow])
        colorShield.run(sequence)
    }
    
    func createColorChanger() {
        colorChanger = ColorChanger(withstartingColor: .red)
        colorChanger?.delegate = self
        colorChanger!.position = CGPoint(x: specialPowerIcon!.position.x, y: scoreLabel!.position.y - 50)
        worldNode.addChild(colorChanger!)
        colorChanger!.changeActiveColor()
        startColorChangeTimer()
    }
    
    func startColorChangeTimer() {
        colorChangeTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector:#selector(GameScene.rotateColorChanger), userInfo: nil, repeats: true)
    }
    
    @objc func rotateColorChanger() {
        colorChanger?.changeActiveColor()
    }
    
    func removeColorChangeTimer() {
        
    }
    
    func highlight(color: UIColor) {
        //make the active color highlighted
        //call this func after new color is active
        
        for enemy in worldNode.children {
            guard let enemyName = enemy.name else {continue}
            if !missileNameArray.contains(enemyName) {
                return
            }
            let enemySprite = enemy as! SKSpriteNode
            
            if enemySprite.color == color {
                enemySprite.colorBlendFactor = 1
                return
            } else {
                enemySprite.colorBlendFactor = 0.3
            }
            
       }
    }
    
    //called by colorChanger after spinning stops
    func startCountDown(forColor color: UIColor) {
        
        var count = 3
        
        let countText = SKLabelNode(text: "3")
        countText.fontName = "AvenirNext-Bold"
        countText.fontSize = 30.0
        countText.horizontalAlignmentMode = .center
        countText.verticalAlignmentMode = .center
        countText.fontColor = UIColor.white
        countText.position = CGPoint(x: colorChanger!.position.x, y: colorChanger!.position.y)
        countText.zPosition = 110
        self.addChild(countText)
        
        let wait = SKAction.wait(forDuration: 1)
        let changeText = SKAction.customAction(withDuration: 0) { (_, _) in
            count -= 1
            countText.text = "\(count)"
            if count == 0 {
                countText.removeFromParent()
                self.changeColorShieldColor(to: color)
                self.highlight(color: color)
            }
        }
        
        let sequence = SKAction.sequence([wait,changeText,wait,changeText,wait,changeText])
        countText.run(sequence)
    }
}
