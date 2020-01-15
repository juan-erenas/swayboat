
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
    
    var scoreText : SKLabelNode?
    var currentScore = 0
    var scoreLabel : SKLabelNode?
    var currentExp = 0
    var expLabel : SKLabelNode?
    var pointsToNextLevel = 10
    var beginningOfLevel = 0
    var progressBar : SKSpriteNode?
    
    var powerReady : Bool = true
    
    var boatHealth : Double = 100
    var boatShield : Double = 0
    
    var timer : Timer?
    var defendersCurrentPos : CGPoint?
    var firstTouch : CGPoint? = nil
    
    var missileSpawnRate = 0.4
    var objectPositionArray = Array<CGPoint>()
    var missileVariety = 60
    let missileNameArray = ["paper missile","red missile","yellow missile child","yellow missile"]
    var missilesDeployed = 0
    var level = 1
    
    var timerWasValid : Bool?
    var dimPanel : SKSpriteNode?
    
    var fightForLifeActive = false
    var fightForLifeAvailable = true
    let maxTaps : Double = 15
    var currentTaps : Double = 7
    var tapBar : SKSpriteNode?
    var tapTimer : Timer?
    var tapResistence : Double = 1
    
    var circularView : CircularProgressView?
    
    
    let boat = SKSpriteNode(texture: SKTexture(imageNamed: "square"), color: .white, size: CGSize(width: 80.0, height: 80.0))
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
        createExpLabel()
        createProgressBar()
        createHealthBar()
        
        //add music
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "wav") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
        
        //        UserDefaults.standard.set(0, forKey: "Highscore")
    }
    
    //MARK: - Setup Scene
    
    func configureDefender() {
        defender.colorBlendFactor = 0.1
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
    
    func animate() {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp,scaleDown])
        boat.run(SKAction.repeatForever(sequence))
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
        dimPanel = createDimPanel()
        worldNode.addChild(dimPanel!)
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
    
    func createPowerUpIndicator() {
        
        let pos = CGPoint(x: frame.minX + 40 , y: boat.position.y)
        
        let powerUpIcon = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 30, height: 30))
               powerUpIcon.colorBlendFactor = 1.0
        powerUpIcon.position = CGPoint(x: pos.x, y: pos.y)
               worldNode.addChild(powerUpIcon)
        
        //MAKE OWN CLASS THAT HOLDS THE VIEW, COOLDOWN AND WHAT ICON TO USE?
        let rect = CGRect(x: pos.x, y: pos.y, width: 40, height: 40)
        circularView = CircularProgressView(frame: rect)
        circularView?.layer.anchorPoint = CGPoint(x: 1, y: 1)
        circularView!.progressColor = UIColor.red
        circularView!.trackClr = UIColor.lightGray
        self.view!.addSubview(circularView!)
        circularView!.setProgressWithAnimation(duration: 10, fromValue: Float(0), toValue: Float(1))
        
       
    }
    
    func createScoreLabel() {
        scoreText = SKLabelNode(text: "Kills:")
        scoreText!.fontName = "AvenirNext-Bold"
        scoreText!.fontSize = 30.0
        scoreText?.horizontalAlignmentMode = .left
        scoreText!.fontColor = UIColor.white
        scoreText!.position = CGPoint(x: frame.minX + frame.width/20, y: frame.maxY - frame.height/15)
        scoreText?.zPosition = 11
        worldNode.addChild(scoreText!)
        
        scoreLabel = SKLabelNode(text: "\(currentScore)")
        scoreLabel!.fontName = "AvenirNext-Bold"
        scoreLabel!.fontSize = 50.0
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel!.fontColor = UIColor.white
        scoreLabel!.position = CGPoint(x: scoreText!.position.x + 100, y: scoreText!.position.y)
        scoreLabel!.zPosition = 11
        worldNode.addChild(scoreLabel!)
        
        
        let pos = scoreText!.position
        let scoreHUDTile = SKShapeNode(rect: CGRect(x: pos.x - 50, y: pos.y - 8, width: 240, height: 50), cornerRadius: 30)
        scoreHUDTile.fillColor = UIColor.lightGray
        scoreHUDTile.lineWidth = 0
        scoreHUDTile.alpha = 0.3
        scoreHUDTile.zPosition = 10
        worldNode.addChild(scoreHUDTile)
    }
    
    func createExpLabel() {
        currentExp = 0
        //currentExp = UserDefaults.standard.integer(forKey: "CurrentExp")
        
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        let formattedExp = numberFormatter.string(from: NSNumber(value:currentExp))
        expLabel = SKLabelNode(text: "+\(formattedExp! as String)xp")
        expLabel!.fontName = "AvenirNext-Bold"
        expLabel!.fontSize = 30.0
        expLabel?.horizontalAlignmentMode = .right
        expLabel!.fontColor = UIColor.white
        expLabel!.position = CGPoint(x: frame.maxX - frame.width/20, y: frame.maxY - frame.height/15)
        worldNode.addChild(expLabel!)
        
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
        
        if fightForLifeActive {
            tappedInFightForLife()
        }
        
        //        if worldNode.isPaused {
        //            //check if paused power up buttons are pressed
        //            let positionInScene = firstTouch!
        //            let touchedNode = self.atPoint(positionInScene)
        //            checkAndExecute(powerUpButton: touchedNode)
        //        }
    }
    
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchPos = touches.first!.location(in: self)
        defender.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        defender.zRotation = findAngle(of: touchPos, and: firstTouch!)
        let xDiff = touchPos.x - firstTouch!.x
        let yDiff = touchPos.y - firstTouch!.y
        
        let gameIsPaused = timerWasValid
        if gameIsPaused == nil && fightForLifeActive == false {
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
        
        addExp(ofAmount: addedAmount)
        updateProgressBar()
        
        //determine if it's time to go to the next level
        if currentScore == pointsToNextLevel {
            endLevel()
        }
    }
    
    func addExp(ofAmount amount: Int) {
        if expLabel != nil {
            currentExp += amount
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .decimal
            let formattedExp = numberFormatter.string(from: NSNumber(value:currentExp))
            self.expLabel?.text = "+\(formattedExp! as String)xp"
        }
    }
    
    func endLevel() {
        timer = nil
        let multiplier = missileSpawnRate/15
        missileSpawnRate -= multiplier
        beginningOfLevel = pointsToNextLevel
        
        if level <= 4 {
            pointsToNextLevel += 50 * (level)
        } else {
            pointsToNextLevel += 150
        }
        
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
//        raiseDifficulty()

    }
    
    
    //MARK: - Fight for Life
    
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
    
    
    func fightForLife(against enemy: SKNode) {
        if fightForLifeAvailable == false {
            endGame()
            return
        }
        
        fightForLifeAvailable = false
        
        haltEnemies(except: enemy)
        createTapLabel()
        
        fightForLifeActive = true
        enemy.removeAllActions()
        
        let xDif = enemy.position.x - boat.position.x
        let yDif = enemy.position.y - boat.position.y
        let newPos = CGPoint(x: enemy.position.x + xDif, y: enemy.position.y + yDif)
        
        let moveToFront = SKAction.move(to: newPos, duration: 0.2)
        enemy.run(moveToFront)
        
        //        let maxHeight = CGFloat(100)
        //        let position = CGPoint(x: boat.position.x - 70, y: boat.position.y - 60)
        
        let progress = CGFloat(currentTaps) / CGFloat(maxTaps)
        
        //creates a circular loading bar that fills as you tap. Subview of UIView!
        let point = CGPoint(x: frame.midX, y: frame.midY)
        let rect = CGRect(x: point.x, y: point.y, width: 200, height: 200)
        circularView = CircularProgressView(frame: rect)
        circularView?.layer.anchorPoint = CGPoint(x: 1, y: 1)
        circularView!.progressColor = UIColor.red
        circularView!.trackClr = UIColor.lightGray
        self.view!.addSubview(circularView!)
        circularView!.setProgressWithAnimation(duration: 0, fromValue: Float(progress), toValue: Float(progress))
        
        tapTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector:#selector(GameScene.addTapResistance), userInfo: nil, repeats: true)
        
    }
    
    @objc func addTapResistance() {
        currentTaps -= tapResistence
        
        let progress = CGFloat(currentTaps) / CGFloat(maxTaps)
        
        let strokeEnd = (circularView!.progressLayer.presentation()?.value(forKey: "strokeEnd") as! NSNumber).floatValue
        
        circularView!.setProgressWithAnimation(duration: 0.2, fromValue: strokeEnd, toValue: Float(progress))
        
        //        let maxHeight = CGFloat(100)
        //        tapBar?.size.height = maxHeight * progress
        
        if currentTaps <= 0 {
            endGame()
        }
    }
    
    func tappedInFightForLife() {
        
        currentTaps += 1
        
        let progress = CGFloat(currentTaps) / CGFloat(maxTaps)
        let strokeEnd = (circularView!.progressLayer.presentation()?.value(forKey: "strokeEnd") as! NSNumber).floatValue
        
        circularView!.setProgressWithAnimation(duration: 0.1, fromValue: strokeEnd, toValue: Float(progress))
        
        //        let maxHeight = CGFloat(100)
        //        tapBar?.size.height = maxHeight * progress
        //
        //        let scaleUp = SKAction.scaleX(by: 1, y: 1.1, duration: 0.05)
        //        let scaleDown = SKAction.scale(to: 1.0, duration: 0.05)
        //        let sequence = SKAction.sequence([scaleUp,scaleDown])
        //        tapBar?.run(sequence)
        
        //        if let child = worldNode.childNode(withName: "max bar") as? SKSpriteNode {
        //            child.run(sequence)
        //        }
        
        if currentTaps >= maxTaps {
            unhaltEnemies()
        }
    }
    
    func createTapLabel() {
        let fightForLifeLabel = SKLabelNode(text: "Fight For Your Life!")
        fightForLifeLabel.name = "fight for life label"
        fightForLifeLabel.numberOfLines = 2
        fightForLifeLabel.fontName = "AvenirNext-Bold"
        fightForLifeLabel.fontSize = 30.0
        fightForLifeLabel.fontColor = UIColor.white
        fightForLifeLabel.position = CGPoint(x: frame.midX, y: frame.midY + frame.height/4)
        worldNode.addChild(fightForLifeLabel)
        
        let tapLabel = SKLabelNode(text: "TAP")
        tapLabel.verticalAlignmentMode = .center
        tapLabel.name = "tap label"
        tapLabel.numberOfLines = 2
        tapLabel.fontName = "AvenirNext-Bold"
        tapLabel.fontSize = 60.0
        tapLabel.fontColor = UIColor.white
        tapLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        worldNode.addChild(tapLabel)
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.15)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
        let sequence = SKAction.sequence([scaleUp,scaleDown])
        tapLabel.run(SKAction.repeatForever(sequence))
        
    }
    
    func haltEnemies(except mainEnemy : SKNode) {
        
        //        timerWasValid = timer?.isValid ?? false
        //        timer?.invalidate()
        //        timer = nil
        
        for enemy in worldNode.children {
            guard let enemyName = enemy.name else {continue}
            let powerUpArray = ["destroy all objects", "slow time"]
            if missileNameArray.contains(enemyName) && enemy != mainEnemy {
                enemy.removeAllActions()
                
                let xDif = enemy.position.x - boat.position.x
                let yDif = enemy.position.y - boat.position.y
                let vector = CGVector(dx: xDif * 7, dy: yDif * 7)
                let move = SKAction.move(by: vector, duration: 0.5)
                enemy.run(move)
                //                enemy.isPaused = true
            }
            if powerUpArray.contains(enemyName) {
                enemy.removeFromParent()
            }
        }
    }
    
    func unhaltEnemies() {
        if tapTimer != nil {
            tapTimer?.invalidate()
            tapTimer = nil
        }
        
        boatHealth = 32
        updateHealth()
        
        currentTaps = 7
        tapResistence += 0.2
        
        fightForLifeActive = false
        worldNode.isPaused = false
        
        let removeChildArray = ["fight for life label","tap label"]
        for childName in removeChildArray {
            if let child = worldNode.childNode(withName: childName) {
                child.removeFromParent()
            }
            
        }
        
        //        if tapBar != nil {
        //            tapBar!.removeFromParent()
        //            tapBar = nil
        //        }
        circularView?.removeFromSuperview()
        circularView = nil
        
        destroyAllNodes()
        
        //        if missilesDeployed != pointsToNextLevel && timerWasValid ?? false {
        //            timerWasValid = nil
        //            beginSpawningPaperMissiles()
        //        } else {
        //            timerWasValid = nil
        //        }
    }
    
    //MARK: - End Game
    
    func endGame() {
        //this line ensures endGame() wasn't immediatly called before.
        //this happens when two missiles attack at the same time.
        guard let size = view?.bounds.size else {return}
        
        if tapTimer != nil {
            tapTimer?.invalidate()
            tapTimer = nil
        }
        
        //in case the circularView is showing
        circularView?.removeFromSuperview()
        circularView = nil
        
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        
        UserDefaults.standard.set(currentExp, forKey: "CurrentExp")
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
        
        if contacted(powerUpButton: contact.bodyA.node!) || contacted(powerUpButton: contact.bodyB.node!) {
            return
        }
        
        if missileNameArray.contains(bodyAName) || missileNameArray.contains(bodyBName) {
            if bodyBName == "defender" || bodyAName == "defender" {
                if contact.bodyA.node?.name == "defender" {
                    handleContactBetween(defender: contact.bodyA.node!, andMissile: contact.bodyB.node!)
                } else {
                    handleContactBetween(defender: contact.bodyB.node!, andMissile: contact.bodyA.node!)
                }
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                let impactSound = SKAction.playSoundFileNamed("impact.mp3", waitForCompletion: false)
                self.run(impactSound)
            }
            
            if fightForLifeActive {
                return
            }
            
            if contact.bodyA.node?.name == "boat" {
                decreaseHealth(andDestroy: contact.bodyB.node!)
                if boatHealth <= 0 {
                    fightForLife(against: contact.bodyB.node!)
                }
            } else if contact.bodyB.node?.name == "boat" {
                decreaseHealth(andDestroy: contact.bodyA.node!)
                if boatHealth <= 0 {
                    fightForLife(against: contact.bodyA.node!)
                }
            }
        }
    }
    
    func handleContactBetween(defender: SKNode, andMissile missile: SKNode) {
        
        if missile.name == "yellow missile" {
            breakApart(yellowMissile: missile)
            let pointsAdded = missileNameArray.firstIndex(of: missile.name!)!
            addPointToScore(andExpOfAmount: pointsAdded)
            return
        }
        
        missile.removeFromParent()
        let pointsAdded = missileNameArray.firstIndex(of: missile.name!)! + 1
        addPointToScore(andExpOfAmount: pointsAdded)
        
    }
    
}

// MARK: - Spawn Missiles
extension GameScene {
    
    func beginSpawningPaperMissiles() {
        guard timer == nil else { fatalError() }
        timer = Timer.scheduledTimer(timeInterval: missileSpawnRate, target: self, selector:#selector(GameScene.createRandomMissile), userInfo: nil, repeats: true)
    }
    
    @objc func createRandomMissile() {
        
        //ensures no missiles are spawned during fight for life.
        if fightForLifeActive {
            return
        }
        
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
            
            let paperMissile = createMissileNode(atPosition: CGPoint(x: frame.maxX, y: frame.maxY),withName: "red missile")
            worldNode.addChild(paperMissile)
            animateWithPulse(ofColor: .red, for: paperMissile)
            
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX + frame.width/5, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.8)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            
            paperMissile.run(sequence)
            
        //missile that comes from the left corner slowly, then attacks fast
        case 76...90:
            
            //            let randXPos = CGFloat(arc4random_uniform(UInt32(frame.minX - frame.maxX)))
            //            let paperMissile = createMissileNode(atPosition: CGPoint(x: randXPos, y: frame.maxY), withName: "red missile")
            let paperMissile = createMissileNode(atPosition: CGPoint(x: frame.minX, y: frame.maxY),withName: "red missile")
            worldNode.addChild(paperMissile)
            animateWithPulse(ofColor: .red, for: paperMissile)
            
            let moveToCenter = SKAction.move(to: CGPoint(x: frame.midX - frame.width/5, y: frame.midY + frame.height/4), duration: 2)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 0.8)
            let sequence = SKAction.sequence([moveToCenter,moveToBoat])
            
            paperMissile.run(sequence)
            
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
            let paperMissile = createMissileNode(atPosition: position,withName: "yellow missile")
            worldNode.addChild(paperMissile)
            animateWithPulse(ofColor: .yellow, for: paperMissile)
            let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 3.5)
            paperMissile.run(moveToBoat)
            
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
        let paperMissile = createMissileNode(atPosition: position,withName: "paper missile")
        worldNode.addChild(paperMissile)
        //            createMissileEmitter(for: paperMissile)
        let moveToBoat = SKAction.move(to: CGPoint(x: boat.position.x, y: boat.position.y), duration: 3.5)
        paperMissile.run(moveToBoat)
    }
    
    func breakApart(yellowMissile: SKNode) {
        
        let impactPos = yellowMissile.position
        yellowMissile.removeFromParent()
        
        let thirdOfWidth = frame.size.width / 3
        let leftPoint = CGPoint(x: impactPos.x - thirdOfWidth,y: impactPos.y)
        let rightPoint = CGPoint(x: impactPos.x + thirdOfWidth,y: impactPos.y)
        let abovePoint = CGPoint(x: impactPos.x,y: impactPos.y + thirdOfWidth)
        let newPositions = [leftPoint,rightPoint,abovePoint]
        
        for index in 0...2 {
            let position = impactPos
            let paperMissile = createMissileNode(atPosition: position,withName: "yellow missile child")
            paperMissile.physicsBody?.categoryBitMask = PhysicsCategories.none
            paperMissile.physicsBody?.contactTestBitMask = PhysicsCategories.none
            worldNode.addChild(paperMissile)
            
            let normalDistance = frame.maxY - boat.position.y
            let distanceToBoat = abs(impactPos.y - boat.position.y)
            let distanceMultiplier = Double(distanceToBoat/normalDistance)
            
            let makeYellow = SKAction.colorize(with: .yellow, colorBlendFactor: 1, duration: 0)
            let moveToPosition = SKAction.move(to: newPositions[index], duration: 0.1)
            let moveToBoat = SKAction.move(to: boat.position, duration: 6 * distanceMultiplier)
            let makeDestroyable = SKAction.customAction(withDuration: 0) { (paperMissile, _) in
                paperMissile.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
                paperMissile.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.defenderCategory
            }
            let sequence = SKAction.sequence([makeYellow,moveToPosition,makeDestroyable,moveToBoat])
            paperMissile.run(sequence)
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
    func createMissileNode(atPosition position: CGPoint,withName name: String) -> SKNode {
        let paperMissile = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 30, height: 30))
        paperMissile.colorBlendFactor = 1.0
        paperMissile.name = name
        paperMissile.zPosition = 12
        paperMissile.position = CGPoint(x: position.x, y: position.y)
        paperMissile.physicsBody = SKPhysicsBody(circleOfRadius: paperMissile.size.width/2)
        paperMissile.physicsBody?.categoryBitMask = PhysicsCategories.paperMissileCategory
        paperMissile.physicsBody?.contactTestBitMask = PhysicsCategories.boatCategory | PhysicsCategories.defenderCategory
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
        
        if powerReady == false {return}
        powerReady = false
        
        let size = defender.size
        let grow = SKAction.resize(toWidth: size.width * 3, height: size.height * 3, duration: 0.2)
        let wait = SKAction.wait(forDuration: 3)
        let shrink = SKAction.resize(toWidth: size.width, height: size.height, duration: 0.2)
        let cooldown = SKAction.wait(forDuration: 10)
        let activatePower = SKAction.customAction(withDuration: 0) { (_, _) in
            self.powerReady = true
        }
        let sequence = SKAction.sequence([grow,wait,shrink,cooldown,activatePower])
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
                if node.name == "yellow missile" {
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

