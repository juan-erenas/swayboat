//
//  SpawnEnemies.swift
//  Sway Boat
//
//  Created by Juan Erenas on 1/27/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

// MARK: - Spawn Missiles
extension GameScene {
    
    func beginSpawningPaperMissiles() {
        guard timer == nil else { fatalError() }
        timer = Timer.scheduledTimer(timeInterval: missileSpawnRate, target: self, selector:#selector(GameScene.createRandomMissile), userInfo: nil, repeats: true)
    }
    
    @objc func createRandomMissile() {
        
        let randomNumber = Int(arc4random_uniform(UInt32(missileVariety)))
        
        if randomNumber <= 1 {
            createPowerUpMissile()
        }
        
        switch randomNumber {
        //        missile that moves slowly directly towards the boat
        case 0...60:
            spawnNormalMissile()
            
        //missile that comes out from the right corner slowly, then attacks fast
        case 61...75:
            
            let enemy = createEnemy(atPosition: CGPoint(x: frame.maxX, y: frame.maxY), ofType: .diver)
            
            worldNode.addChild(enemy)
            
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX + frame.width/5, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.8)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            
            enemy.run(sequence)
            
        //missile that comes from the left corner slowly, then attacks fast
        case 76...90:
            
            let enemy = createEnemy(atPosition: CGPoint(x: frame.minX, y: frame.maxY), ofType: .diver)
            
            worldNode.addChild(enemy)
            
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX - frame.width/5, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.8)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            
            enemy.run(sequence)
            
        case 90...100:
            
            if missilesDeployed > pointsToNextLevel - 4 {
                spawnNormalMissile()
                missilesDeployed += 1
                
                if missilesDeployed == pointsToNextLevel {
                    timer?.invalidate()
                }
                
                return
            }
            
            missilesDeployed += 3
            let position = CGPoint(x: frame.midX, y: frame.maxY + 30)
            let enemy = createEnemy(atPosition: position, ofType: .splitter)
//            let paperMissile = createMissileNode(atPosition: position,withName: "yellow missile")
            worldNode.addChild(enemy)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 3.5)
            enemy.run(moveToBoat)
            
        default:
            return
        }
        
        //Determines if it needs to stop spawning missiles because the level is ending
        missilesDeployed += 1
        if missilesDeployed == pointsToNextLevel {
            timer?.invalidate()
        }
    }
    
    func spawnNormalMissile() {
        let position = randomPosition()
        let enemy = createEnemy(atPosition: position, ofType: .normal)
//        let paperMissile = createMissileNode(atPosition: position,withName: "paper missile")
        worldNode.addChild(enemy)
        //            createMissileEmitter(for: paperMissile)
        let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 3.5)
        enemy.run(moveToBoat)
    }
    
    func breakApart(splitterEnemy: SKNode) {
        
        let impactPos = splitterEnemy.position
        splitterEnemy.removeFromParent()
        
        let thirdOfWidth = frame.size.width / 3
        let leftPoint = CGPoint(x: impactPos.x - thirdOfWidth,y: impactPos.y)
        let rightPoint = CGPoint(x: impactPos.x + thirdOfWidth,y: impactPos.y)
        let abovePoint = CGPoint(x: impactPos.x,y: impactPos.y + thirdOfWidth)
        let newPositions = [leftPoint,rightPoint,abovePoint]
        
        for index in 0...2 {
            let position = impactPos
            let enemy = createEnemy(atPosition: position, ofType: .splitterChild)
//            let paperMissile = createMissileNode(atPosition: position,withName: "yellow missile child")
            enemy.physicsBody?.categoryBitMask = PhysicsCategories.none
            enemy.physicsBody?.contactTestBitMask = PhysicsCategories.none
            worldNode.addChild(enemy)
            
            let normalDistance = frame.maxY - boat.position.y
            let distanceToBoat = abs(impactPos.y - boat.position.y)
            let distanceMultiplier = Double(distanceToBoat/normalDistance)
            
            let makeYellow = SKAction.colorize(with: .yellow, colorBlendFactor: 1, duration: 0)
            let moveToPosition = SKAction.move(to: newPositions[index], duration: 0.1)
            let moveToBoat = SKAction.move(to: boat.position, duration: 6 * distanceMultiplier)
            let makeDestroyable = SKAction.customAction(withDuration: 0) { (enemy, _) in
                enemy.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
                enemy.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.defenderCategory
            }
            let sequence = SKAction.sequence([makeYellow,moveToPosition,makeDestroyable,moveToBoat])
            enemy.run(sequence)
        }
        
    }
    
    //call this function to get a random position for spawning points
    func randomPosition() -> CGPoint {
        let randomNumber = Int(arc4random_uniform(UInt32(7)))
        var position : CGPoint?
        
        switch randomNumber {
        case 0:
            position = CGPoint(x: frame.minX, y: frame.midY)
        case 1:
            position = CGPoint(x: frame.maxX, y: frame.maxY)
        case 2:
            position = CGPoint(x: frame.minX, y: frame.maxY)
        case 3:
            position = CGPoint(x: frame.maxX, y: frame.midY)
        case 4:
            position = CGPoint(x: frame.minX, y: frame.midY + frame.height/4)
        case 5:
            position = CGPoint(x: frame.maxX, y: frame.midY + frame.height/4)
        case 6:
            position = CGPoint(x: frame.midX, y: frame.maxY)
        case 7:
            position = CGPoint(x: frame.midX - frame.width/4, y: frame.maxY)
        case 8:
            position = CGPoint(x: frame.midX + frame.width/4, y: frame.maxY)
        default:
            position = CGPoint(x: frame.midX, y: frame.maxY)
        }
        return position!
    }
    
    //Call this function to create a paper missile node
    func createEnemy(atPosition position: CGPoint,ofType type: Enemy.EnemyType) -> SKNode {
        
        let enemy = Enemy(type: type, size: CGSize(width: 30, height: 30))
        enemy.position = CGPoint(x: position.x, y: position.y)
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: enemy.size.width/2)
        enemy.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
        enemy.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.defenderCategory
        enemy.physicsBody?.collisionBitMask = PhysicsCategories.none
        enemy.physicsBody?.allowsRotation = false
        return enemy
        
        
//        let paperMissile = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 30, height: 30))
//        paperMissile.colorBlendFactor = 1.0
//        paperMissile.name = name
//        paperMissile.zPosition = 12
//        paperMissile.position = CGPoint(x: position.x, y: position.y)
//        paperMissile.physicsBody = SKPhysicsBody(circleOfRadius: paperMissile.size.width/2)
//        paperMissile.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
//        paperMissile.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.defenderCategory
//        paperMissile.physicsBody?.collisionBitMask = PhysicsCategories.none
//        paperMissile.physicsBody?.allowsRotation = false
//        return paperMissile
    }
    
    func createMissileEmitter(for missile: SKNode) {
        guard let emitter = SKEmitterNode(fileNamed: "MissileEmitter.sks") else { return }
        emitter.zPosition = -1
        emitter.name = "missile smoke"
        emitter.targetNode = self.scene
        missile.addChild(emitter)
    }
    
    //Added this func to Enemy class instead
    
//    func animateWithPulse(ofColor color: UIColor,for node: SKNode) {
//        let colorPulse = SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: 0.2)
//        let whitePulse = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.2)
//        let enlarge = SKAction.scale(to: 1.1, duration: 0.2)
//        let shrink = SKAction.scale(to: 1.0, duration: 0.2)
//
//        let enlargeAndColor = SKAction.group([colorPulse,enlarge])
//        let shrinkAndColorWhite = SKAction.group([shrink,whitePulse])
//        let sequence = SKAction.sequence([enlargeAndColor,shrinkAndColorWhite])
//
//        node.run(SKAction.repeatForever(sequence))
//    }
    
    
}

