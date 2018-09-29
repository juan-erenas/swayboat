
//
//  GameScene.swift
//  Sway Boat
//
//  Created by Juan Erenas on 9/17/18.
//  Copyright © 2018 Juan Erenas. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    var currentScore = 0
    var scoreLabel : SKLabelNode?
    
    var timer : Timer?
    var firstTouch = CGPoint()
    var missileSpawnRate = 1.5
    var objectPositionArray = Array<CGPoint>()
    
    let boat = SKSpriteNode(texture: SKTexture(imageNamed: "Boat"), color: .red, size: CGSize(width: 30.0, height: 60.0))
    let arrow = SKSpriteNode(texture: SKTexture(imageNamed: "Arrow"), color: .white, size: CGSize(width: 25, height: 10))
    
    override func didMove(to view: SKView) {
        configureBoat()
        setupPhysics()
        beginSpawningPaperMissiles()
        createBackground()
        createScoreLabel()
    }
    
    func configureBoat() {
        boat.colorBlendFactor = 0.1
        boat.name = "boat"
        boat.zPosition = 0
        boat.position = CGPoint(x: frame.midX, y: frame.midY - frame.midY/2)
        boat.physicsBody = SKPhysicsBody(circleOfRadius: boat.size.width/2)
        boat.physicsBody?.categoryBitMask = PhysicsCategories.boatCategory
        boat.physicsBody?.contactTestBitMask = PhysicsCategories.paperMissileCategory
        boat.physicsBody?.collisionBitMask = PhysicsCategories.paperMissileCategory
        boat.physicsBody?.allowsRotation = false
        boat.physicsBody?.isDynamic = false
        addChild(boat)
        animate()
        
        guard let emitter = SKEmitterNode(fileNamed: "WaterTrail.sks") else { return }
        emitter.position = CGPoint(x: boat.position.x, y: boat.position.y)
        emitter.zPosition = -1
        emitter.name = "water trail"
        scene?.addChild(emitter)
    }
    
    func createScoreLabel() {
        scoreLabel = SKLabelNode(text: "\(currentScore)")
        scoreLabel!.fontName = "AvenirNext-Bold"
        scoreLabel!.fontSize = 50.0
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel!.fontColor = UIColor.white
        scoreLabel!.position = CGPoint(x: frame.minX + frame.width/20, y: frame.maxY - frame.height/15)
        addChild(scoreLabel!)
    }
    
    func addPointToScore() {
        currentScore += 1
        if let label = scoreLabel {
            let scaleUp = SKAction.scale(to: 1.4, duration: 0.1)
            let changeText = SKAction.customAction(withDuration: 0) { (_,_) in self.scoreLabel!.text = "\(self.currentScore)" }
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            let sequence = SKAction.sequence([scaleUp,changeText,scaleDown])
            label.run(sequence)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard arrow.parent == nil else { return }
        arrow.position = CGPoint(x: boat.position.x, y: boat.position.y)
        arrow.zPosition = 1
        arrow.anchorPoint = CGPoint(x: 0.5, y: 0)
        firstTouch = touches.first!.location(in: self)
        addChild(arrow)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentPosition = touches.first!.location(in: self)
        let distance = findDistance(of: currentPosition, and: firstTouch)
        arrow.zRotation = findAngle(of: currentPosition, and: firstTouch)
        if distance <= 75 {
            arrow.size = CGSize(width: 25, height: distance*2)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let missile = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .green, size: CGSize(width: 15, height: 15))
        missile.position = boat.position
        missile.zPosition = 1
        missile.name = "missile"
        missile.physicsBody = SKPhysicsBody(circleOfRadius: missile.size.width/2)
        missile.physicsBody?.categoryBitMask = PhysicsCategories.missileCategory
        missile.physicsBody?.contactTestBitMask = PhysicsCategories.paperMissileCategory
        missile.physicsBody?.collisionBitMask = PhysicsCategories.none
        missile.physicsBody?.fieldBitMask = PhysicsCategories.none
        let touchPos = touches.first!.location(in: self)
        let xDiff = firstTouch.x - touchPos.x
        let yDiff = firstTouch.y - touchPos.y
        let fire = SKAction.applyForce(CGVector(dx: xDiff/2, dy: yDiff/2), duration: 2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fire,remove])
        addChild(missile)
        missile.run(sequence)
        arrow.removeFromParent()
    }
    
    func findDistance(of firstPoint: CGPoint, and secondPoint: CGPoint) -> CGFloat {
        let xDist = firstPoint.x - secondPoint.x
        let yDist = firstPoint.y - secondPoint.y
        let distance = sqrt(xDist * xDist + yDist * yDist)
        return distance
    }
    
    func findAngle(of firstPoint: CGPoint, and secondPoint: CGPoint) -> CGFloat {
        let xDiff = secondPoint.x - firstPoint.x
        let yDiff = secondPoint.y - firstPoint.y
        return atan2(yDiff, xDiff) - .pi/2
    }
    
    func animate() {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp,scaleDown])
        boat.run(SKAction.repeatForever(sequence))
    }
    
    func createBackground() {
        createMovingBackground(withImageNamed: "River", height: frame.height, duration: 20,zPosition: -30)
        createMovingBackground(withImageNamed: "Middle River", height: frame.height, duration: 10, zPosition: -20)
    }
    
    func createMovingBackground(withImageNamed imageName: String,height: CGFloat,duration: Double, zPosition: CGFloat) {
        let backgroundTexture = SKTexture(imageNamed: imageName)
        
        for i in 0 ... 1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.size = CGSize(width: frame.width, height: height)
            background.zPosition = zPosition
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: 0, y: (height * CGFloat(i)) - CGFloat(1 * i))
            
            addChild(background)
            
            let moveDown = SKAction.moveBy(x: 0, y: -height, duration: duration)
            let moveReset = SKAction.moveBy(x: 0, y: height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            background.run(moveForever)
        }
    }
    
    func setupPhysics() {
        
        let upperLeft = CGPoint(x: frame.minX, y: frame.maxY)
        let lowerLeft = CGPoint(x: frame.minX, y: frame.minY)
        let upperRight = CGPoint(x: frame.maxX, y: frame.maxY)
        let lowerRight = CGPoint(x: frame.maxX, y: frame.minY)
        
        let leftWall = SKNode()
        leftWall.physicsBody = SKPhysicsBody(edgeFrom: upperLeft, to: lowerLeft)
        leftWall.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory
        
        let rightWall = SKNode()
        rightWall.physicsBody = SKPhysicsBody(edgeFrom: upperRight, to: lowerRight)
        rightWall.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory
        
        addChild(leftWall)
        addChild(rightWall)
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    func beginSpawningPaperMissiles() {
        guard timer == nil else { fatalError() }
        timer = Timer.scheduledTimer(timeInterval: missileSpawnRate, target: self, selector:#selector(GameScene.createRandomMissile), userInfo: nil, repeats: true)
    }
    
    @objc func spawnPaperMissiles() {
        let paperMissile = SKSpriteNode(texture: SKTexture(imageNamed: "Paper Missile"), color: .red, size: CGSize(width: 30, height: 30))
        paperMissile.colorBlendFactor = 1.0
        paperMissile.name = "paper missile"
        paperMissile.zPosition = 2
        paperMissile.position = CGPoint(x: frame.midX, y: frame.maxY)
        paperMissile.physicsBody = SKPhysicsBody(circleOfRadius: paperMissile.size.width/2)
        paperMissile.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
        paperMissile.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.missileCategory
        paperMissile.physicsBody?.collisionBitMask = PhysicsCategories.none
        paperMissile.physicsBody?.allowsRotation = false
        addChild(paperMissile)
    }
    
    func endGame() {
        guard timer != nil else { fatalError() }
        timer?.invalidate()
        timer = nil
        UserDefaults.standard.set(currentScore, forKey: "RecentScore")
        if currentScore > UserDefaults.standard.integer(forKey: "Highscore") {
            UserDefaults.standard.set(currentScore, forKey: "Highscore")
        }
        let gameScene = MenuScene(size: view!.bounds.size)
        view!.presentScene(gameScene)
    }
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "paper missile" || contact.bodyB.node?.name == "paper missile" {
            if contact.bodyA.node?.name == "missile" || contact.bodyB.node?.name == "missile" {
                contact.bodyA.node?.removeFromParent()
                contact.bodyB.node?.removeFromParent()
                addPointToScore()
            }
            if contact.bodyA.node?.name == "boat" || contact.bodyB.node?.name == "boat" {
                endGame()
            }
        }
    }
}

//extension for creating missiles
extension GameScene {
    @objc func createRandomMissile() {
        let randomNumber = Int(arc4random_uniform(UInt32(6)))
        
        switch randomNumber {
        //missile that comes from the left corner slowly, then attacks fast
        case 0:
            let paperMissile = createMissileNode(atPosition: CGPoint(x: frame.minX, y: frame.maxY))
            addChild(paperMissile)
            createMissileEmitter(for: paperMissile)
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.5)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            paperMissile.run(sequence)
            
        //missile that comes out from the right corner slowly, then attacks fast
        case 1:
            let paperMissile = createMissileNode(atPosition: CGPoint(x: frame.maxX, y: frame.maxY))
            addChild(paperMissile)
            createMissileEmitter(for: paperMissile)
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.5)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            paperMissile.run(sequence)
            
        //missile that moves slowly directly towards the boat
        case 2,3,4,5:
            let position = randomPosition()
            let paperMissile = createMissileNode(atPosition: position)
            addChild(paperMissile)
            createMissileEmitter(for: paperMissile)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 3)
            paperMissile.run(moveToBoat)
        default:
            print("Switch default has been triggered")
            return
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
    func createMissileNode(atPosition position: CGPoint) -> SKNode {
        let paperMissile = SKSpriteNode(texture: SKTexture(imageNamed: "Paper Missile"), color: .white, size: CGSize(width: 30, height: 30))
        paperMissile.colorBlendFactor = 1.0
        paperMissile.name = "paper missile"
        paperMissile.zPosition = 2
        paperMissile.position = CGPoint(x: position.x, y: position.y)
        paperMissile.physicsBody = SKPhysicsBody(circleOfRadius: paperMissile.size.width/2)
        paperMissile.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
        paperMissile.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.missileCategory
        paperMissile.physicsBody?.collisionBitMask = PhysicsCategories.none
        paperMissile.physicsBody?.allowsRotation = false
        return paperMissile
    }
    
    
    //work on this function. Emitter does not move with the missile.
    func createMissileEmitter(for missile: SKNode) {
        guard let emitter = SKEmitterNode(fileNamed: "MissileEmitter.sks") else { return }
        emitter.zPosition = -1
        emitter.name = "missile smoke"
        emitter.targetNode = self.scene
        missile.addChild(emitter)
    }
}


