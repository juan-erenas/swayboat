//
//  PowerUps.swift
//  Sway Boat
//
//  Created by Juan Erenas on 1/27/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

//MARK: - PowerUps
extension GameScene {
    
    func createPowerUpMissile() {
        let spawnXRange = self.frame.width - 100
        let randX = Int(arc4random_uniform(UInt32(spawnXRange)))
        
        let xPos = self.frame.minX + CGFloat(randX)
        let yPos = self.frame.minY - 50
        let position = CGPoint(x: xPos, y: yPos)
        
        let powerUpArray = ["slow time", "destroy all objects","health"]
        let randomNumber = Int(arc4random_uniform(UInt32(powerUpArray.count)))
        
        let powerUpMissile = createPowerUpButton(withName: powerUpArray[randomNumber])
        powerUpMissile.position = position
        worldNode.addChild(powerUpMissile)
        
        let newPos = CGPoint(x: position.x, y: frame.maxY + 100)
        let moveUpWard = SKAction.move(to: newPos, duration: 3)
        let destroyNode = SKAction.removeFromParent()
        let sequence = SKAction.sequence([moveUpWard,destroyNode])
        powerUpMissile.run(sequence)
        
    }
    
    @objc func doubleTapped() {
        
        if specialPowerIcon?.isActive == false {return}
        specialPowerIcon?.isActive = false
        
        specialPowerIcon?.makeInactive()
        
        
        inactivateSpecialPower()
        
//        let cooldownRate = Double(specialPowerIcon!.coolDownRate)
//        powerLoadBar?.setProgressWithAnimation(duration: cooldownRate, fromValue: 0, toValue: 1)
        
        //this region is specific to the GROW special power
        let size = defender.size
        let grow = SKAction.resize(toWidth: size.width * 3, height: size.height * 3, duration: 0.2)
        let changePhysicsBody = SKAction.customAction(withDuration: 0.2) { (_, _) in
            self.defender.physicsBody = SKPhysicsBody(circleOfRadius: self.defender.size.width/2)
        }
        let wait = SKAction.wait(forDuration: 3)
        let shrink = SKAction.resize(toWidth: size.width, height: size.height, duration: 0.2)
        let beginCooldown = SKAction.customAction(withDuration: 0) { (_, _) in
            self.waitForCooldown()
        }

        let sequence = SKAction.sequence([grow,changePhysicsBody,wait,shrink,changePhysicsBody,beginCooldown])
        self.defender.run(sequence)
        
    }
    
    func pauseGame() {
        if worldNode.isPaused == false {
            timerWasValid = timer?.isValid ?? false
            dimPanel?.alpha = 0.75
            worldNode.isPaused = true
            timer?.invalidate()
            timer = nil
            addPowerUpButtons()
        }
    }
    
    func unpauseGame() {
        pauseNode.removeAllChildren()
        worldNode.isPaused = false
        dimPanel?.alpha = 0
        if missilesDeployed != pointsToNextLevel && timerWasValid ?? false {
            timerWasValid = nil
            beginSpawningPaperMissiles()
        } else {
            timerWasValid = nil
        }
    }
    
    func addPowerUpButtons() {
        
        let pos1 = CGPoint(x: frame.midX, y: frame.midY + 100)
        let slowTimeBtn = createPowerUpButton(withName: "slow time")
        pauseNode.addChild(slowTimeBtn)
        move(powerUpBtn: slowTimeBtn, to: pos1, withCostAmount: "50")

        let Pos2 = CGPoint(x: frame.midX, y: frame.midY - 100)
        let destroyAllObjectsBtn = createPowerUpButton(withName: "destroy all objects")
        pauseNode.addChild(destroyAllObjectsBtn)
        move(powerUpBtn: destroyAllObjectsBtn, to: Pos2,withCostAmount: "100")
    }
    
    func contacted(powerUpButton: SKNode) -> Bool {
        guard let name = powerUpButton.name else {return false}
        
        if name == "destroy all objects" {
            destroyAllNodes()
            powerUpButton.removeFromParent()
            return true
        } else if name == "slow time" {
            worldNode.speed = 0.2
            defender.speed = 1
            
            dimPanel?.color = UIColor.blue
            dimPanel?.alpha = 1
            
            let lowerAlpha = SKAction.fadeAlpha(to: 0.3, duration: 0.1)
            dimPanel?.run(lowerAlpha)
            
            let wait = SKAction.wait(forDuration: 0.5)
            
            let increaseSpeed = SKAction.speed(to: 1, duration: 0.5)
            let worldNodeSequence = SKAction.sequence([wait,increaseSpeed])
            worldNode.run(worldNodeSequence)
            
            let removeColor = SKAction.fadeAlpha(to: 0, duration: 0.5)
            let revertColor = SKAction.colorize(with: UIColor.black, colorBlendFactor: 1, duration: 0)
            let dimPanelSequence = SKAction.sequence([wait,removeColor,revertColor])
            dimPanel?.run(dimPanelSequence)
            powerUpButton.removeFromParent()
            return true
            
        } else if name == "health"{
            if boatHealth <= 66 {
                boatHealth += 34
            }else if boatHealth > 66 && boatHealth < 100 {
                boatHealth = 100
            } else if boatHealth == 100 && boatShield <= 64 {
                boatShield += 34
            } else {
                boatShield = 100
            }
            
            let panel = createDimPanel()
            panel.color = .green
            panel.alpha = 0.75
            worldNode.addChild(panel)
            
            let dim = SKAction.fadeAlpha(to: 0, duration: 0.5)
            let removeNode = SKAction.removeFromParent()
            let sequence = SKAction.sequence([dim,removeNode])
            panel.run(sequence)
            
            updateHealth()
            powerUpButton.removeFromParent()
            return true
            
        } else {
            return false
        }
    }
    
    func destroyAllNodes() {
        //Create a flash
        dimPanel?.color = UIColor.white
        dimPanel?.alpha = 1.0
        let slowlyDim = SKAction.fadeAlpha(to: 0, duration: 2)
        let changeBacktoBlack = SKAction.customAction(withDuration: 0) {_,_ in
            self.dimPanel?.color = UIColor.black
        }
        let sequence = SKAction.sequence([slowlyDim,changeBacktoBlack])
        dimPanel?.run(sequence)
        
        //Destroy all nodes.
        for node in worldNode.children {
            guard let nodeName = node.name else {continue}
            if missileNameArray.contains(nodeName) {
                node.removeFromParent()
                let addedAmount = missileNameArray.firstIndex(of: nodeName)! + 1
                addPointToScore(andExpOfAmount: addedAmount)
                //Handles yellow missiles which would usually have children for more points
                if node.name == "splitter enemy" {
                    for _ in 0...2 {
                        addPointToScore(andExpOfAmount: addedAmount - 1)
                    }
                }
            } else if nodeName == "missile smoke" {
                node.removeFromParent()
            }
        }
    }
    
    func move(powerUpBtn: SKNode,to newLocation: CGPoint, withCostAmount cost: String) {
        let size = 70
        let newSize = CGSize(width: size, height: size)
        let exaggeratedSize = CGSize(width: size + 10, height: size + 10)
        let smallerSize = CGSize(width: size - 10, height: size - 10)
        let scaleUp = SKAction.scale(to: exaggeratedSize, duration: 0.1)
        let scaleDown = SKAction.scale(to: smallerSize, duration: 0.05)
        let scaleNormal = SKAction.scale(to: newSize, duration: 0.05)
        let scaleUpSequence = SKAction.sequence([scaleUp,scaleDown,scaleNormal])
        
        let move = SKAction.move(to: newLocation, duration: 0.1)
        
        //Also adds a label indicating the cost of power up button
        let wait = SKAction.wait(forDuration: 0.1)
        let addLabel = SKAction.customAction(withDuration: 0) {_,_ in
            let costLabel = self.createLabel(for: powerUpBtn, ofAmount: cost)
            self.pauseNode.addChild(costLabel)
            let scaleLabel = SKAction.scale(by: 2, duration: 0.1)
            let moveLabelDown = SKAction.moveTo(y: costLabel.position.y - 55, duration: 0.1)
            let sequence = SKAction.group([scaleLabel,moveLabelDown])
            costLabel.run(sequence)
        }
        
        let labelSequence = SKAction.sequence([wait,addLabel])
        let sequence = SKAction.group([scaleUpSequence,move,labelSequence])
        powerUpBtn.run(sequence)
    }
    
    func shake(node: SKNode) {
        let left = CGPoint(x: node.position.x - 10, y: node.position.y)
        let right = CGPoint(x: node.position.x + 10, y: node.position.y)
        
        let moveLeft = SKAction.move(to: left, duration: 0.1)
        let moveRight = SKAction.move(to: right, duration: 0.1)
        let returnToPos = SKAction.move(to: node.position, duration: 0.1)
        let sequence = SKAction.sequence([moveLeft,moveRight,moveLeft,returnToPos])
        node.run(sequence)
    }
    
    func createPowerUpButton(withName name: String) -> SKSpriteNode {
        let powerUpButton = SKSpriteNode(texture: SKTexture(imageNamed: name), color: .white, size: CGSize(width: 30, height: 30))
        powerUpButton.colorBlendFactor = 1.0
        powerUpButton.name = name
        powerUpButton.zPosition = 102
        powerUpButton.position = CGPoint(x: frame.midX, y: frame.midY)
        powerUpButton.physicsBody = SKPhysicsBody(circleOfRadius: powerUpButton.size.width/2)
        powerUpButton.physicsBody?.categoryBitMask    = PhysicsCategories.powerUpCategory
        powerUpButton.physicsBody?.contactTestBitMask = PhysicsCategories.defenderCategory
        powerUpButton.physicsBody?.collisionBitMask   = PhysicsCategories.none
        powerUpButton.physicsBody?.allowsRotation = false
        return powerUpButton
    }
    
    func createLabel(for button: SKNode, ofAmount cost: String) -> SKLabelNode {
        let buttonLabel = SKLabelNode(text: "$\(cost)")
        buttonLabel.fontName = "AvenirNext-Bold"
        buttonLabel.fontSize = 10.0
        buttonLabel.zPosition = 101
        buttonLabel.fontColor = UIColor.white
        buttonLabel.position = CGPoint(x: button.position.x, y: button.position.y)
        return buttonLabel
    }
    
}

