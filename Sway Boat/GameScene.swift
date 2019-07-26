
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
    
    let worldNode = SKNode()
    let pauseNode = SKNode()
    
    var currentScore = 0
    var scoreLabel : SKLabelNode?
    var currentMoney = 0
    var moneyLabel : SKLabelNode?
    
    
    var timer : Timer?
    var defendersCurrentPos : CGPoint?
    var firstTouch : CGPoint? = nil
    
    var missileSpawnRate = 0.5
    var objectPositionArray = Array<CGPoint>()
    var missileVariety = 4
    var pointsToNextLevel = 10
    var missilesDeployed = 0
    var level = 1
    
    var timerWasValid : Bool?
    var dimPanel : SKSpriteNode?
    
    let boat = SKSpriteNode(texture: SKTexture(imageNamed: "Boat"), color: .red, size: CGSize(width: 30.0, height: 60.0))
    let defender = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 20, height: 20))
    
    override func didMove(to view: SKView) {
        addChild(pauseNode)
        addChild(worldNode)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
        configureBoat()
        configureDefender()
        setupPhysics()
        beginSpawningPaperMissiles()
        createBackground()
        createScoreLabel()
        createMoneyLabel()
    }
    

    
    //MARK: - Setup Scene
    
    func configureDefender() {
        defender.colorBlendFactor = 0.1
        defender.name = "defender"
        defender.zPosition = 0
        defender.position = CGPoint(x: boat.position.x, y: boat.position.y + frame.height/8)
        defender.physicsBody = SKPhysicsBody(circleOfRadius: defender.size.width/2)
        defender.physicsBody?.categoryBitMask = PhysicsCategories.boatCategory
        defender.physicsBody?.contactTestBitMask = PhysicsCategories.paperMissileCategory
        defender.physicsBody?.collisionBitMask = PhysicsCategories.boatCategory
        worldNode.addChild(defender)
        
        guard let emitter = SKEmitterNode(fileNamed: "DefenderEmitter.sks") else { return }
        emitter.zPosition = -1
        emitter.targetNode = self.scene
        defender.addChild(emitter)
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
        worldNode.addChild(boat)
        animate()
        
        guard let emitter = SKEmitterNode(fileNamed: "WaterTrail.sks") else { return }
        emitter.position = CGPoint(x: boat.position.x, y: boat.position.y)
        emitter.zPosition = -1
        emitter.name = "water trail"
        worldNode.addChild(emitter)
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
        
        //this is the node that dims everything when the game is paused.
        dimPanel = SKSpriteNode(color: UIColor.black, size: self.size)
        dimPanel!.alpha = 0
        dimPanel!.zPosition = 100
        dimPanel!.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        worldNode.addChild(dimPanel!)
    }
    
    func createMovingBackground(withImageNamed imageName: String,height: CGFloat,duration: Double, zPosition: CGFloat) {
        let backgroundTexture = SKTexture(imageNamed: imageName)
        
        for i in 0 ... 1 {
            let background = SKSpriteNode(texture: backgroundTexture)
            background.size = CGSize(width: frame.width, height: height)
            background.zPosition = zPosition
            background.anchorPoint = CGPoint.zero
            background.position = CGPoint(x: 0, y: (height * CGFloat(i)) - CGFloat(1 * i))
            
            worldNode.addChild(background)
            
            let moveDown = SKAction.moveBy(x: 0, y: -height, duration: duration)
            let moveReset = SKAction.moveBy(x: 0, y: height, duration: 0)
            let moveLoop = SKAction.sequence([moveDown, moveReset])
            let moveForever = SKAction.repeatForever(moveLoop)
            
            background.run(moveForever)
        }
    }
    
    func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    func createScoreLabel() {
        scoreLabel = SKLabelNode(text: "\(currentScore) / \(pointsToNextLevel)")
        scoreLabel!.fontName = "AvenirNext-Bold"
        scoreLabel!.fontSize = 50.0
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel!.fontColor = UIColor.white
        scoreLabel!.position = CGPoint(x: frame.minX + frame.width/20, y: frame.maxY - frame.height/15)
        worldNode.addChild(scoreLabel!)
    }
    
    func createMoneyLabel() {
        currentMoney = UserDefaults.standard.integer(forKey: "CurrentMoney")
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedMoney = numberFormatter.string(from: NSNumber(value:currentMoney))
        moneyLabel = SKLabelNode(text: "$\(formattedMoney! as String)")
        moneyLabel!.fontName = "AvenirNext-Bold"
        moneyLabel!.fontSize = 30.0
        moneyLabel?.horizontalAlignmentMode = .right
        moneyLabel!.fontColor = UIColor.white
        moneyLabel!.position = CGPoint(x: frame.maxX - frame.width/20, y: frame.maxY - frame.height/15)
        worldNode.addChild(moneyLabel!)
    }
    
    
    //MARK: - Touch Handler
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        firstTouch = touches.first!.location(in: self)
        defendersCurrentPos = defender.position
        
        if worldNode.isPaused {
            //check if paused power up buttons are pressed
            let positionInScene = firstTouch!
            let touchedNode = self.atPoint(positionInScene)
            checkAndExecute(powerUpButton: touchedNode)
        }
    }
    
  
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPos = touches.first!.location(in: self)
        defender.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        defender.zRotation = findAngle(of: touchPos, and: firstTouch!)
        let xDiff = touchPos.x - firstTouch!.x
        let yDiff = touchPos.y - firstTouch!.y
        
        let gameIsPaused = timerWasValid
        if gameIsPaused == nil {
            //Multiplied by 1.5 to add aditional reach, i.e. the user doesn't have to stretch their thunb out so much
            defender.position = CGPoint(x: defendersCurrentPos!.x + (xDiff * 1.5), y: defendersCurrentPos!.y + (yDiff * 1.5))
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        firstTouch = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        if timerWasValid != nil {
            worldNode.isPaused = true
        }
    }
  
    
    func findAngle(of firstPoint: CGPoint, and secondPoint: CGPoint) -> CGFloat {
        let xDiff = secondPoint.x - firstPoint.x
        let yDiff = secondPoint.y - firstPoint.y
        return atan2(yDiff, xDiff) - .pi/2
    }
    
    //MARK: - Game Levels Handler
    
    func addPointToScore() {
        currentScore += 1
        if let label = scoreLabel {
            let scaleUp = SKAction.scale(to: 1.4, duration: 0.1)
            let changeText = SKAction.customAction(withDuration: 0) { (_,_) in self.scoreLabel!.text = "\(self.currentScore) / \(self.pointsToNextLevel)" }
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            let sequence = SKAction.sequence([scaleUp,changeText,scaleDown])
            label.run(sequence)
        }
        
        if moneyLabel != nil {
            currentMoney += 1
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedMoney = numberFormatter.string(from: NSNumber(value:currentMoney))
            self.moneyLabel?.text = "$\(formattedMoney! as String)"
        }
        //determine if it's time to go to the next level
        if currentScore == pointsToNextLevel {
            endLevel()
        }
    }
    
    func endLevel() {
        timer = nil
        let multiplier = missileSpawnRate/10
        missileSpawnRate -= multiplier
        pointsToNextLevel *= 2
        scoreLabel?.text = "\(currentScore) / \(pointsToNextLevel)"
        UserDefaults.standard.set(currentMoney, forKey: "CurrentMoney")
         level += 1
        if level == 2 {
            missileVariety = 6
        } else {
            missileVariety = 6
        }
        
        beginNextLevel()
    }
    
    func beginNextLevel() {
        let nextLevelLabel = SKLabelNode(text: "LEVEL \(level)")
        nextLevelLabel.fontName = "AvenirNext-Bold"
        nextLevelLabel.fontSize = 50.0
        nextLevelLabel.horizontalAlignmentMode = .center
        nextLevelLabel.fontColor = UIColor.white
        nextLevelLabel.position = CGPoint(x: frame.midX, y: frame.midY + frame.height/4)
        nextLevelLabel.alpha = 0
        worldNode.addChild(nextLevelLabel)
        
        let wait = SKAction.wait(forDuration: 1)
        let showNextLevel = SKAction.fadeAlpha(to: 1.0, duration: 1)
        let hideNextLevel = SKAction.fadeAlpha(to: 0, duration: 1)
        let removeNode = SKAction.removeFromParent()
        let startTimer = SKAction.customAction(withDuration: 0) { (_, _) in
            self.beginSpawningPaperMissiles()
        }
        let sequence = SKAction.sequence([wait,showNextLevel,wait,hideNextLevel,wait,startTimer,removeNode])
        nextLevelLabel.run(sequence)
    }
    
    //MARK: - End Game
    
    func endGame() {
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        UserDefaults.standard.set(currentMoney, forKey: "CurrentMoney")
        UserDefaults.standard.set(currentScore, forKey: "RecentScore")
        if currentScore > UserDefaults.standard.integer(forKey: "Highscore") {
            UserDefaults.standard.set(currentScore, forKey: "Highscore")
        }
        let gameScene = MenuScene(size: view!.bounds.size)
        view!.presentScene(gameScene)
    }
}

// MARK: - Handle Contacts

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node?.name == "paper missile" || contact.bodyB.node?.name == "paper missile" {
            if contact.bodyA.node?.name == "defender" || contact.bodyB.node?.name == "defender" {
                if contact.bodyA.node?.name == "defender" {
                    contact.bodyB.node?.removeFromParent()
                } else {
                    contact.bodyA.node?.removeFromParent()
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                addPointToScore()
            }
            if contact.bodyA.node?.name == "boat" || contact.bodyB.node?.name == "boat" {
                endGame()
            }
        }
    }
}

// MARK: - Spawn Missiles
extension GameScene {
    
    func beginSpawningPaperMissiles() {
        guard timer == nil else { fatalError() }
        timer = Timer.scheduledTimer(timeInterval: missileSpawnRate, target: self, selector:#selector(GameScene.createRandomMissile), userInfo: nil, repeats: true)
    }
    
    @objc func createRandomMissile() {
        //Determines if it needs to stop spawning missiles because the level is ending
        missilesDeployed += 1
        if missilesDeployed == pointsToNextLevel {
            timer?.invalidate()
        }
        
        let randomNumber = Int(arc4random_uniform(UInt32(missileVariety)))
        
        switch randomNumber {
        //missile that comes from the left corner slowly, then attacks fast
        case 0,1,2,3:
            let position = randomPosition()
            let paperMissile = createMissileNode(atPosition: position)
            worldNode.addChild(paperMissile)
//            createMissileEmitter(for: paperMissile)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 3)
            paperMissile.run(moveToBoat)
            
        //missile that comes out from the right corner slowly, then attacks fast
        case 4:
            let paperMissile = createMissileNode(atPosition: CGPoint(x: frame.maxX, y: frame.maxY))
            worldNode.addChild(paperMissile)
            animateWithPulse(ofColor: .red, for: paperMissile)
//            createMissileEmitter(for: paperMissile)
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX + frame.width/5, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.5)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            paperMissile.run(sequence)
            
        //missile that moves slowly directly towards the boat
        case 5:
            let paperMissile = createMissileNode(atPosition: CGPoint(x: frame.minX, y: frame.maxY))
            worldNode.addChild(paperMissile)
            animateWithPulse(ofColor: .red, for: paperMissile)
//            createMissileEmitter(for: paperMissile)
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX - frame.width/5, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.5)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            paperMissile.run(sequence)
        case 6,7:
            let randInt = CGFloat(arc4random_uniform(UInt32(2)))
            let xCoordinate = frame.width/3 + (randInt * frame.width/3)
            let yCoordinate = frame.midY + (randInt * frame.height/4)
            let paperMissile = createMissileNode(atPosition: CGPoint(x: xCoordinate, y: yCoordinate))
            paperMissile.run(SKAction.scale(to: 0.1, duration: 0))
            worldNode.addChild(paperMissile)
            animateWithPulse(ofColor: .yellow, for: paperMissile)
//            createMissileEmitter(for: paperMissile)
            let scale = SKAction.scale(to: 1.0, duration: 2)
            let moveToEdge = SKAction.move(to: CGPoint(x: 30 + frame.minX + (randInt * frame.maxX) - (randInt * 60), y: paperMissile.position.y), duration: 0.5)
            let moveNextToBoat = SKAction.move(to: CGPoint(x: paperMissile.position.x, y: boat.position.y), duration: 0.5)
            let wait = SKAction.wait(forDuration: 1)
            let attack = SKAction.move(to: boat.position, duration: 0.5)
            let sequence = SKAction.sequence([scale,moveToEdge,wait,moveNextToBoat,wait,attack])
            paperMissile.run(sequence)
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
        let paperMissile = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 30, height: 30))
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
    
    func createMissileEmitter(for missile: SKNode) {
        guard let emitter = SKEmitterNode(fileNamed: "MissileEmitter.sks") else { return }
        emitter.zPosition = -1
        emitter.name = "missile smoke"
        emitter.targetNode = self.scene
        missile.addChild(emitter)
    }
    
    func animateWithPulse(ofColor color: UIColor,for node: SKNode) {
        let colorPulse = SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: 0.2)
        let whitePulse = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.2)
        let enlarge = SKAction.scale(to: 1.1, duration: 0.2)
        let shrink = SKAction.scale(to: 1.0, duration: 0.2)

        let enlargeAndColor = SKAction.group([colorPulse,enlarge])
        let shrinkAndColorWhite = SKAction.group([shrink,whitePulse])
        let sequence = SKAction.sequence([enlargeAndColor,shrinkAndColorWhite])
        
        node.run(SKAction.repeatForever(sequence))
    }
    
    
}
//MARK: - Pause Game
extension GameScene{
    
    @objc func doubleTapped() {
        if worldNode.isPaused == false {
            
            timerWasValid = timer?.isValid ?? false
            dimPanel?.alpha = 0.75
            worldNode.isPaused = true
            timer?.invalidate()
            timer = nil
            addPowerUpButtons()
        } else {
            unpauseGame()
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
        let Pos1 = CGPoint(x: frame.midX, y: frame.midY + 100)
        let destroyAllObjectsBtn = createPowerUpButton(withName: "destroy all objects")
        pauseNode.addChild(destroyAllObjectsBtn)
        move(powerUpBtn: destroyAllObjectsBtn, to: Pos1,withCostAmount: "100")
        
    }
    
    func checkAndExecute(powerUpButton: SKNode){
        guard let name = powerUpButton.name else {return}
        
        if name == "destroy all objects" {
            if currentMoney < 100 {
                shake(node: powerUpButton)
                return
            }else{
                currentMoney -= 100
            }
            unpauseGame()
            
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
                if (node.name == "paper missile" || node.name == "missile smoke") {
                    node.removeFromParent()
                    addPointToScore()
                }
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
        
        //also adds a label indicating the cost of power up button
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
        let powerUpButton = SKSpriteNode(texture: SKTexture(imageNamed: name), color: .white, size: CGSize(width: 10, height: 10))
        powerUpButton.colorBlendFactor = 1.0
        powerUpButton.name = name
        powerUpButton.zPosition = 102
        powerUpButton.position = CGPoint(x: frame.midX, y: frame.midY)
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

