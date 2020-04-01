
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
    
    var backgroundMusic: SKAudioNode!
    
    let worldNode = SKNode()
    let pauseNode = SKNode()
    
//    var scoreText : SKLabelNode?
    var currentScore = 0
    var scoreLabel : SKLabelNode?
    var pointsToNextLevel = 50
    var beginningOfLevel = 0
    var progressBar : SKSpriteNode?
    
    var specialPowerIcon : SpecialPowerIcon?
    var specialPowerCircle = SKShapeNode()
    var powerReady : Bool = true
    
    var boatHealth : Double = 100
    var boatShield : Double = 0
    
    var timer : Timer?
    var defendersCurrentPos : CGPoint?
    var firstTouch : CGPoint? = nil
    
    var missileSpawnRate = 0.46
    var objectPositionArray = Array<CGPoint>()
    var missileVariety = 60
    let missileNameArray = ["normal enemy","diver enemy","splitter enemy","splitter child enemy"]
//    let missileNameArray = ["paper missile","red missile","yellow missile child","yellow missile"]
    var missilesDeployed = 0
    var level = 1
    
    var timerWasValid : Bool?
    var dimPanel : SKSpriteNode?
    
    var powerLoadBar : SKSpriteNode?
    
//    var powerLoadBar : CircularProgressView?
    
    let boat = SKSpriteNode(texture: SKTexture(imageNamed: "square"), color: .white, size: CGSize(width: 80.0, height: 80.0))
    let defender = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 30, height: 30))
    let colorShield = SKSpriteNode(texture: SKTexture(imageNamed: "color-shield"), color: .white, size: CGSize(width: 100.0, height: 100.0))
    
    override func didMove(to view: SKView) {
        addChild(pauseNode)
        addChild(worldNode)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
        
        configureBoat()
        configureDefender()
        setupPhysics()
//        createBackground()
        configureDimPanel()
        createScoreLabel()
        createProgressBar()
        createHealthBar()
        createPowerUpIndicator()
        
        performIntroAnimation()
        
        //add music
        if let musicURL = Bundle.main.url(forResource: "CreoSphere", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        //        UserDefaults.standard.set(0, forKey: "Highscore")
    }
    
    //MARK: - Setup Scene
    
    func configureDefender() {
        defender.colorBlendFactor = 1
        defender.color = UIColor.yellow
        defender.name = "defender"
        defender.zPosition = 0
        
        defender.position = CGPoint(x: boat.position.x, y: boat.position.y + frame.height/8)
        defender.physicsBody = SKPhysicsBody(circleOfRadius: defender.size.width/2)
        defender.physicsBody?.categoryBitMask    = PhysicsCategories.defenderCategory
        defender.physicsBody?.contactTestBitMask = PhysicsCategories.paperMissileCategory | PhysicsCategories.powerUpCategory
        defender.physicsBody?.collisionBitMask   = PhysicsCategories.boatCategory
        worldNode.addChild(defender)
        
        guard let emitter = SKEmitterNode(fileNamed: "DefenderEmitter.sks") else { return }
        emitter.zPosition = -1
        emitter.targetNode = self.scene
        defender.addChild(emitter)
        
        let xRange = SKRange(lowerLimit: frame.minX, upperLimit: frame.maxX)
        let yRange = SKRange(lowerLimit: frame.minY, upperLimit: frame.maxY)
        let lockInsideFrame = SKConstraint.positionX(xRange, y: yRange)
        
        defender.constraints = [ lockInsideFrame ]
        
    }
    
    func configureBoat() {
        boat.colorBlendFactor = 0.1
        boat.name = "boat"
        boat.zPosition = 0
        boat.position = CGPoint(x: frame.midX, y: frame.midY - (frame.midY/4)*3)
        boat.physicsBody = SKPhysicsBody(circleOfRadius: boat.size.width/2)
        boat.physicsBody?.categoryBitMask = PhysicsCategories.boatCategory
        boat.physicsBody?.contactTestBitMask = PhysicsCategories.paperMissileCategory
        boat.physicsBody?.collisionBitMask = PhysicsCategories.paperMissileCategory
        boat.physicsBody?.allowsRotation = false
        boat.physicsBody?.isDynamic = false
        worldNode.addChild(boat)
        
    }
    
    //Remove once you create individual dim panels
    func configureDimPanel() {
        dimPanel = createDimPanel()
        worldNode.addChild(dimPanel!)
    }
    
    func createBackground() {
        //creates moving background for a parallax effect
        createMovingBackground(withImageNamed: "mid ground", height: frame.height, duration: 20,zPosition: -30)
        createMovingBackground(withImageNamed: "foreground", height: frame.height, duration: 10, zPosition: -20)
        
        let background = SKSpriteNode(texture: SKTexture(imageNamed: "background"))
        background.size = CGSize(width: frame.width, height: frame.height)
        background.zPosition = -40
        background.position = CGPoint(x: frame.midX, y: frame.midY)
        worldNode.addChild(background)
        
        //this is the node that dims everything when the game is paused.
        
    }
    
    func createDimPanel() -> SKSpriteNode {
        let panel = SKSpriteNode(color: UIColor.black, size: self.size)
        panel.alpha = 0
        panel.zPosition = 100
        panel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        return panel
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
    
    //MARK: - Setup HUD
    
    func createPowerUpIndicator() {
        
        let pos = CGPoint(x: frame.minX + 40 , y: boat.position.y)
        
        specialPowerIcon = SpecialPowerIcon(size: CGSize(width: 30, height: 30), powerType: .growBig)
        specialPowerIcon!.position = CGPoint(x: pos.x, y: pos.y)
        specialPowerIcon!.zPosition = 1
        worldNode.addChild(specialPowerIcon!)
        
        let cropNode = SKCropNode()
        
        specialPowerCircle = SKShapeNode(circleOfRadius: 30 ) // Size of Circle
        specialPowerCircle.position = pos
        specialPowerCircle.lineWidth = 5
        specialPowerCircle.strokeColor = .gray
        specialPowerCircle.zPosition = 1
        addChild(specialPowerCircle)
        
        let cropCircle = SKShapeNode(circleOfRadius: 30 ) // Size of Circle
        cropCircle.position = pos
        cropCircle.fillColor = SKColor.white
        cropNode.maskNode = cropCircle
        
        let circleDiameter = cropCircle.path?.boundingBox.width ?? 0
        
        let size = CGSize(width: circleDiameter, height: 0)
        powerLoadBar = SKSpriteNode(color: UIColor.lightGray, size: size)
        powerLoadBar!.anchorPoint = CGPoint(x: 0.5, y: 0)
        powerLoadBar!.name = "power load bar"
        powerLoadBar!.position = CGPoint(x: pos.x, y: pos.y - (circleDiameter / 2))
        powerLoadBar!.zPosition = 0
        cropNode.addChild(powerLoadBar!)

        
        addChild(cropNode)
    
        
//        //Makes cooldown circle around power up icon
//        let rect = CGRect(x: pos.x, y: boat.position.y, width: 35, height: 35)
//        powerLoadBar = CircularProgressView(frame: rect)
//        powerLoadBar!.progressColor = UIColor.green
//        powerLoadBar!.trackClr = UIColor.lightGray
//
//        //invert the y since zero starts at the top of the frame for UIView
//        powerLoadBar?.center = CGPoint(x: pos.x, y: frame.maxY - pos.y)
//        powerLoadBar?.progressLayer.lineWidth = 5
//        print("Position of loadBar: \(powerLoadBar!.center)")
//        self.view!.addSubview(powerLoadBar!)
//
//        //Start filling the cooldown circle according to the power's cooldown rate
//        let cooldownRate = Double(specialPowerIcon!.coolDownRate)
//        powerLoadBar!.setProgressWithAnimation(duration: cooldownRate, fromValue: Float(0), toValue: Float(1))
        
        waitForCooldown()
        
    }
    
    func inactivateSpecialPower() {
        powerLoadBar?.size.height = 0
        specialPowerCircle.fillColor = .clear
        specialPowerCircle.strokeColor = .gray
    }
    
    //wait the designated cool down time until the powerup can be used again
    func waitForCooldown() {
        
        let coolDownRate = Double(specialPowerIcon!.coolDownRate)
        
        
        let fill = SKAction.resize(toHeight: 60, duration: coolDownRate)
        powerLoadBar?.run(fill)
        
//        let wait = SKAction.wait(forDuration: coolDownRate)
        let becomeActive = SKAction.customAction(withDuration: 0) { (_, _) in
            self.activateSpecialPower()
        }
//        let sequence = SKAction.sequence([wait,becomeActive])
        let sequence = SKAction.sequence([fill,becomeActive])
        powerLoadBar?.run(sequence)
        
    }
    
    func activateSpecialPower() {
        self.specialPowerIcon?.makeActive()
        self.specialPowerCircle.fillColor = UIColor(red: 137/255, green: 55/255, blue: 196/255, alpha: 1)
        specialPowerCircle.strokeColor = UIColor(red: 73/255, green: 0, blue: 172/255, alpha: 1)
    }
    
    
    func createScoreLabel() {
//        scoreText = SKLabelNode(text: "")
//        scoreText!.fontName = "AvenirNext-Bold"
//        scoreText!.fontSize = 30.0
//        scoreText?.horizontalAlignmentMode = .left
//        scoreText!.fontColor = UIColor.white
//        scoreText!.position = CGPoint(x: frame.minX + frame.width/20, y: frame.maxY - frame.height/15)
//        scoreText?.zPosition = 11
//        worldNode.addChild(scoreText!)
        
        scoreLabel = SKLabelNode(text: "\(currentScore)")
        scoreLabel!.fontName = "AvenirNext-Bold"
        scoreLabel!.fontSize = 50.0
        scoreLabel?.horizontalAlignmentMode = .center
        scoreLabel?.verticalAlignmentMode = .center
        scoreLabel!.fontColor = UIColor.white
        scoreLabel!.position = CGPoint(x: frame.midX, y: frame.maxY - frame.height/15)
        scoreLabel!.zPosition = 11
        worldNode.addChild(scoreLabel!)
        
//        let pos = scoreLabel!.position
//        let scoreHUDTile = SKShapeNode(rect: CGRect(x: pos.x - 50, y: pos.y - 8, width: 240, height: 50), cornerRadius: 30)
//        scoreHUDTile.fillColor = UIColor.lightGray
//        scoreHUDTile.lineWidth = 0
//        scoreHUDTile.alpha = 0.3
//        scoreHUDTile.zPosition = 10
//        worldNode.addChild(scoreHUDTile)
    }
    
    
    func createProgressBar() {
        
        let maxWidth = frame.width
        let progress = CGFloat(currentScore - beginningOfLevel) / CGFloat(pointsToNextLevel)
        let position = CGPoint(x: frame.minX, y: frame.maxY - 5)
        let size = CGSize(width: (maxWidth * progress), height: 5)
        progressBar = SKSpriteNode(color: UIColor.red, size: size)
        progressBar?.anchorPoint = CGPoint(x: 0, y: 0)
        progressBar!.name = "progress bar"
        progressBar!.position = position
        progressBar?.zPosition = 10
        worldNode.addChild(progressBar!)
        
    }
    
    func updateProgressBar() {
        if progressBar != nil {
            let maxWidth = frame.width
            let progress = CGFloat(currentScore - beginningOfLevel) / CGFloat(pointsToNextLevel - beginningOfLevel)
            progressBar?.size = CGSize(width: (maxWidth * progress), height: 5)
        }
    }
    
    func createHealthBar() {
        
        let position = CGPoint(x: boat.position.x - 50, y: boat.position.y - 60)
        
        let maxWidth = CGFloat(100)
        let maxHealthBar = SKSpriteNode(color: UIColor.white, size: CGSize(width: maxWidth, height: 5))
        maxHealthBar.anchorPoint = CGPoint(x: 0, y: 0)
        maxHealthBar.name = "max health bar"
        maxHealthBar.position = position
        maxHealthBar.zPosition = 9
        
        let progress = CGFloat(boatHealth) / CGFloat(100)
        
        let size = CGSize(width: (maxWidth * progress), height: 5)
        let currentHealthBar = SKSpriteNode(color: UIColor.red, size: size)
        currentHealthBar.anchorPoint = CGPoint(x: 0, y: 0)
        currentHealthBar.name = "current health bar"
        currentHealthBar.position = position
        currentHealthBar.zPosition = 11
        
        
        let shieldPosition = CGPoint(x: position.x, y: position.y + 5)
        let shieldSize = CGSize(width: 0, height: 5)
        let currentShieldBar = SKSpriteNode(color: UIColor.blue, size: shieldSize)
        currentShieldBar.anchorPoint = CGPoint(x: 0, y: 0)
        currentShieldBar.name = "current shield bar"
        currentShieldBar.position = shieldPosition
        currentShieldBar.zPosition = 10
        
        worldNode.addChild(currentHealthBar)
        worldNode.addChild(maxHealthBar)
        worldNode.addChild(currentShieldBar)
    }
    
    
    //MARK: - Touch Handler
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        firstTouch = touches.first!.location(in: self)
        defendersCurrentPos = defender.position
        
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
            defender.position = CGPoint(x: defendersCurrentPos!.x + (xDiff * 2.5), y: defendersCurrentPos!.y + (yDiff * 2.5))
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
    
    func destroy(node: SKNode) {
        if let nodeName = node.name {
            node.removeFromParent()
            let addedAmount = missileNameArray.firstIndex(of: nodeName)! + 1
            addPointToScore(andExpOfAmount: addedAmount)
            //Handles yellow missiles which would usually have children for more points
            if node.name == "yellow missile" {
                for _ in 0...2 {
                    addPointToScore(andExpOfAmount: addedAmount - 1)
                }
            }
        }
    }
    
    func addPointToScore(andExpOfAmount addedAmount: Int) {
        currentScore += 1
        if let label = scoreLabel {
            let scaleUp = SKAction.scale(to: 1.4, duration: 0.1)
            let changeText = SKAction.customAction(withDuration: 0) { (_,_) in self.scoreLabel!.text = "\(self.currentScore)" }
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
            let sequence = SKAction.sequence([scaleUp,changeText,scaleDown])
            label.run(sequence)
        }
        
        updateProgressBar()
        
        //determine if it's time to go to the next level
        if currentScore == pointsToNextLevel {
            endLevel()
        }
    }
    
    func endLevel() {
        timer = nil
        let multiplier = missileSpawnRate/15
        missileSpawnRate -= multiplier
        beginningOfLevel = pointsToNextLevel
        
        pointsToNextLevel += 50 * (level)
        
//        if level <= 4 {
//            pointsToNextLevel += 50 * (level)
//        } else {
//            pointsToNextLevel += 150
//        }
        
        scoreLabel?.text = "\(currentScore)"
        updateProgressBar()
        //UserDefaults.standard.set(currentExp, forKey: "CurrentExp")
        level += 1
        if level == 2 {
            missileVariety = 90
        }
        else if level >= 3 {
            missileVariety = 100 + 1
        }
        beginNextLevel()
    }
    
    func beginNextLevel() {
        self.beginSpawningPaperMissiles()
    }
    
    
    //MARK: - Health Handler
    
    func decreaseHealth(andDestroy node: SKNode) {
        
        if boatShield > 0 {
            boatShield -= 34
            //resets to zero if it happens to go negative
            if boatShield < 0 {boatShield = 0}
        } else {
            boatHealth -= 34
            //resets to zero if it happens to go negative
            if boatHealth < 0 {boatHealth = 0}
        }
        
        if boatHealth > 0 {
            destroy(node: node)
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        }
        
        let panel = createDimPanel()
        panel.color = .red
        panel.alpha = 0.75
        worldNode.addChild(panel)
        
        let dim = SKAction.fadeAlpha(to: 0, duration: 0.5)
        let removeNode = SKAction.removeFromParent()
        let sequence = SKAction.sequence([dim,removeNode])
        panel.run(sequence)
        
        updateHealth()
    }
    
    func updateHealth() {
        if let healthBar = worldNode.childNode(withName: "current health bar") {
            let progress = CGFloat(boatHealth) / CGFloat(100)
            let width = 100 * progress
            let changeSize = SKAction.resize(toWidth: width, duration: 0.2)
            healthBar.run(changeSize)
        }
        
        if let shieldBar = worldNode.childNode(withName: "current shield bar") {
            let progress = CGFloat(boatShield) / CGFloat(100)
            let shieldWidth = 100 * progress
            let changeSize = SKAction.resize(toWidth: shieldWidth, duration: 0.2)
            shieldBar.run(changeSize)
        }
    }
    
//    func createTapLabel() {
//        let fightForLifeLabel = SKLabelNode(text: "Fight For Your Life!")
//        fightForLifeLabel.name = "fight for life label"
//        fightForLifeLabel.numberOfLines = 2
//        fightForLifeLabel.fontName = "AvenirNext-Bold"
//        fightForLifeLabel.fontSize = 30.0
//        fightForLifeLabel.fontColor = UIColor.white
//        fightForLifeLabel.position = CGPoint(x: frame.midX, y: frame.midY + frame.height/4)
//        worldNode.addChild(fightForLifeLabel)
//
//        let tapLabel = SKLabelNode(text: "TAP")
//        tapLabel.verticalAlignmentMode = .center
//        tapLabel.name = "tap label"
//        tapLabel.numberOfLines = 2
//        tapLabel.fontName = "AvenirNext-Bold"
//        tapLabel.fontSize = 60.0
//        tapLabel.fontColor = UIColor.white
//        tapLabel.position = CGPoint(x: frame.midX, y: frame.midY)
//        worldNode.addChild(tapLabel)
//
//        let scaleUp = SKAction.scale(to: 1.5, duration: 0.15)
//        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
//        let sequence = SKAction.sequence([scaleUp,scaleDown])
//        tapLabel.run(SKAction.repeatForever(sequence))
//
//    }
    
//    func haltEnemies(except mainEnemy : SKNode) {
//
//        //        timerWasValid = timer?.isValid ?? false
//        //        timer?.invalidate()
//        //        timer = nil
//
//        for enemy in worldNode.children {
//            guard let enemyName = enemy.name else {continue}
//            let powerUpArray = ["destroy all objects", "slow time"]
//            if missileNameArray.contains(enemyName) && enemy != mainEnemy {
//                enemy.removeAllActions()
//
//                let xDif = enemy.position.x - boat.position.x
//                let yDif = enemy.position.y - boat.position.y
//                let vector = CGVector(dx: xDif * 7, dy: yDif * 7)
//                let move = SKAction.move(by: vector, duration: 0.5)
//                enemy.run(move)
//                //                enemy.isPaused = true
//            }
//            if powerUpArray.contains(enemyName) {
//                enemy.removeFromParent()
//            }
//        }
//    }
    
    
    //MARK: - End Game
    
    func endGame() {
        //this line ensures endGame() wasn't immediatly called before.
        //this happens when two missiles attack at the same time.
        guard let size = view?.bounds.size else {return}
        
//        powerLoadBar?.removeFromSuperview()
//        powerLoadBar = nil
        
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        UserDefaults.standard.set(currentScore, forKey: "RecentScore")
        if currentScore > UserDefaults.standard.integer(forKey: "Highscore") {
            UserDefaults.standard.set(currentScore, forKey: "Highscore")
        }
        
        let gameScene = MenuScene(size: size)
        view!.presentScene(gameScene)
        
    }
}

// MARK: - Handle Contacts

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard let bodyAName = contact.bodyA.node?.name else {return}
        guard let bodyBName = contact.bodyB.node?.name else {return}
        
        //handle contacts between defender and power up
        if contacted(powerUpButton: contact.bodyA.node!) || contacted(powerUpButton: contact.bodyB.node!) {
            return
        }
        
        //handle contacts betweent the defender and a missile
        if missileNameArray.contains(bodyAName) || missileNameArray.contains(bodyBName) {
            if bodyBName == "defender" || bodyAName == "defender" {
                if contact.bodyA.node?.name == "defender" {
                    handleContactBetween(defender: contact.bodyA.node!, andMissile: contact.bodyB.node!)
                    addBlast(atPoint: contact.contactPoint)
                } else {
                    handleContactBetween(defender: contact.bodyB.node!, andMissile: contact.bodyA.node!)
                    addBlast(atPoint: contact.contactPoint)
                }
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
//                let impactSound = SKAction.playSoundFileNamed("impact.mp3", waitForCompletion: false)
//                self.run(impactSound)
            }
            
            //handle contacts against the boat
            if contact.bodyA.node?.name == "boat" {
                decreaseHealth(andDestroy: contact.bodyB.node!)
                if boatHealth <= 0 {
                    endGame()
                }
            } else if contact.bodyB.node?.name == "boat" {
                decreaseHealth(andDestroy: contact.bodyA.node!)
                if boatHealth <= 0 {
                    endGame()
                }
            }
            
            
        }
    }
    
    
    func handleContactBetween(defender: SKNode, andMissile missile: SKNode) {
        
        if missile.name == "splitter enemy" {
            breakApart(splitterEnemy: missile)
            let pointsAdded = missileNameArray.firstIndex(of: missile.name!)!
            addPointToScore(andExpOfAmount: pointsAdded)
            return
        }
        
        missile.removeFromParent()
        let pointsAdded = missileNameArray.firstIndex(of: missile.name!)! + 1
        addPointToScore(andExpOfAmount: pointsAdded)
        
    }
    
    
    // MARK: - Game Effects
    
    func addBlast(atPoint point: CGPoint) {
        
        let blast = SKSpriteNode(texture: SKTexture(imageNamed: "blast"), color: .white, size: CGSize(width: 40.0, height: 40.0))
        blast.alpha = 0.6
        blast.colorBlendFactor = 0.1
        blast.name = "blast"
        blast.zPosition = 100
        blast.position = point
        worldNode.addChild(blast)
        
        let grow = SKAction.resize(byWidth: blast.size.width * 30, height: blast.size.width * 30, duration: 0.8)
        let fade = SKAction.fadeAlpha(to: 0, duration: 0.8)
        fade.timingMode = SKActionTimingMode.easeOut
        let remove = SKAction.removeFromParent()
        
        let growAndFade = SKAction.group([grow,fade])
        let sequence = SKAction.sequence([growAndFade, remove])
        blast.run(sequence)
        
        shakeCamera(layer: worldNode, duration: 0.1)
        addImpactParticles(atLocation: point)
    }
    
    func shakeCamera(layer:SKNode, duration:Float) {

        let amplitudeX:Float = 6;
        let amplitudeY:Float = 6;
        let numberOfShakes = duration / 0.04;
        var actionsArray:[SKAction] = [];
        for _ in 1...Int(numberOfShakes) {
            let moveX = Float(arc4random_uniform(UInt32(amplitudeX))) - amplitudeX / 2;
            let moveY = Float(arc4random_uniform(UInt32(amplitudeY))) - amplitudeY / 2;
            let shakeAction = SKAction.moveBy(x: CGFloat(moveX), y: CGFloat(moveY), duration: 0.02);
            shakeAction.timingMode = SKActionTimingMode.easeOut;
            actionsArray.append(shakeAction);
            actionsArray.append(shakeAction.reversed());
        }

        let actionSeq = SKAction.sequence(actionsArray);
        layer.run(actionSeq);
    }
    
    
    func addImpactParticles(atLocation location: CGPoint) {
        if let emitter = SKEmitterNode(fileNamed: "impact") {
            emitter.position = location
            emitter.numParticlesToEmit = 15
            worldNode.addChild(emitter)
            
            let wait = SKAction.wait(forDuration: 0.5)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([wait,remove])
            emitter.run(sequence)
        }
    }
    
    func performIntroAnimation() {
        createFlash(andFade: true)
        
        let posY = self.position.y
        let aboveViewY = self.frame.height * 2
        let moveUp = SKAction.moveTo(y: aboveViewY, duration: 0)
        let resetPos = SKAction.moveTo(y: posY, duration: 0.5)
        let spawnMissiles = SKAction.customAction(withDuration: 0) { (_, _) in
            self.beginSpawningPaperMissiles()
        }
        resetPos.timingMode = SKActionTimingMode.easeOut
        
        let sequence = SKAction.sequence([moveUp,resetPos,spawnMissiles])
        worldNode.run(sequence)
    }
    
//    func performExitAnimation() {
//        createFlash(andFade: false)
//
//        let posY = self.position.y
//        let belowViewY = -self.frame.height
//        let moveDown = SKAction.moveTo(y: belowViewY, duration: 0.1)
//        let moveUp = SKAction.moveTo(y: posY + 100, duration: 0.3)
//        let presentScene = SKAction.customAction(withDuration: 0) { (_, _) in
//            let gameScene = GameScene(size: self.view!.bounds.size)
//            self.view!.presentScene(gameScene)
//        }
//
//        let sequence = SKAction.sequence([moveUp,moveDown,presentScene])
//        menuNode.run(sequence)
//    }
    
    func createFlash(andFade fade: Bool) {
        let panel = SKSpriteNode(color: UIColor.white, size: self.size)
        
        if fade {
            panel.alpha = 1
        } else {
            panel.alpha = 0
        }
        
        panel.zPosition = 100
        panel.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        self.addChild(panel)
        
        let raiseAlpha = SKAction.fadeAlpha(to: 1, duration: 0.4)
        let lowerAlpha = SKAction.fadeAlpha(to: 0, duration: 1)
        let remove = SKAction.removeFromParent()
        
        var sequence : SKAction?
        if fade {
            sequence = SKAction.sequence([lowerAlpha,remove])
        } else {
            sequence = SKAction.sequence([raiseAlpha])
        }
        
        panel.run(sequence!)
    }
    
}

