
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
    
    var colorChanger : ColorChanger?
    var colorChangeTimer : Timer?
    
    var specialPowerIcon : SpecialPowerIcon?
    var powerReady : Bool = true
    
    var boatHealth : Double = 100
    var boatShield : Double = 0
    
    var timer : Timer?
    var defendersCurrentPos : CGPoint?
    var firstTouch : CGPoint? = nil
    
    var missileSpawnRate = 0.4
    var objectPositionArray = Array<CGPoint>()
    var missileVariety = 60
    let missileNameArray = ["normal enemy","diver enemy","splitter enemy","splitter child enemy"]
//    let missileNameArray = ["paper missile","red missile","yellow missile child","yellow missile"]
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
    
    var tapLoadingBar : CircularProgressView?
    var powerLoadBar : CircularProgressView?
    
    let boat = SKSpriteNode(texture: SKTexture(imageNamed: "square"), color: .white, size: CGSize(width: 80.0, height: 80.0))
    let defender = SKSpriteNode(texture: SKTexture(imageNamed: "water trail"), color: .white, size: CGSize(width: 20, height: 20))
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
        beginSpawningPaperMissiles()
//        createBackground()
        configureDimPanel()
        createScoreLabel()
        createExpLabel()
        createProgressBar()
        createHealthBar()
        createPowerUpIndicator()
        createColorChanger()
        
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
        
        colorShield.colorBlendFactor = 1
        colorShield.name = "color-shield"
        colorShield.zPosition = 0
        colorShield.color = UIColor.white
        colorShield.position = boat.position
        colorShield.physicsBody = SKPhysicsBody(circleOfRadius: colorShield.size.width/2)
        colorShield.physicsBody?.categoryBitMask = PhysicsCategories.colorShieldCategory
        colorShield.physicsBody?.contactTestBitMask = PhysicsCategories.paperMissileCategory
        colorShield.physicsBody?.collisionBitMask = PhysicsCategories.paperMissileCategory
        colorShield.physicsBody?.allowsRotation = false
        colorShield.physicsBody?.isDynamic = false
        worldNode.addChild(colorShield)
        
    }
    
    func animate() {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp,scaleDown])
        boat.run(SKAction.repeatForever(sequence))
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
        
        //Makes cooldown circle around power up icon
        let rect = CGRect(x: pos.x, y: boat.position.y, width: 35, height: 35)
        powerLoadBar = CircularProgressView(frame: rect)
        powerLoadBar!.progressColor = UIColor.green
        powerLoadBar!.trackClr = UIColor.lightGray
        
        //invert the y since zero starts at the top of the frame for UIView
        powerLoadBar?.center = CGPoint(x: pos.x, y: frame.maxY - pos.y)
        powerLoadBar?.progressLayer.lineWidth = 5
        print("Position of loadBar: \(powerLoadBar!.center)")
        self.view!.addSubview(powerLoadBar!)
        
        //Start filling the cooldown circle according to the power's cooldown rate
        let cooldownRate = Double(specialPowerIcon!.coolDownRate)
        powerLoadBar!.setProgressWithAnimation(duration: cooldownRate, fromValue: Float(0), toValue: Float(1))
        
        waitForCooldown()
        
    }
    
    //wait the designated cool down time until the powerup can be used again
    func waitForCooldown() {
        
        let wait = SKAction.wait(forDuration: Double(specialPowerIcon!.coolDownRate))
        let becomeActive = SKAction.customAction(withDuration: 0) { (_, _) in
            self.specialPowerIcon?.makeActive()
        }
        let sequence = SKAction.sequence([wait,becomeActive])
        worldNode.run(sequence)
        
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
    
    //MARK: - Fight For Life
    
    func fightForLife(against enemy: SKNode) {
        if fightForLifeAvailable == false {
            endGame()
            return
        }
        
        print("Position of loadBar: \(powerLoadBar!.center)")
        
        fightForLifeAvailable = false
        
        haltEnemies(except: enemy)
        createTapLabel()
        
        specialPowerIcon?.fightForLifeActive = true
        fightForLifeActive = true
        enemy.removeAllActions()
        
        let xDif = enemy.position.x - boat.position.x
        let yDif = enemy.position.y - boat.position.y
        let newPos = CGPoint(x: enemy.position.x + xDif, y: enemy.position.y + yDif)
        
        let moveToFront = SKAction.move(to: newPos, duration: 0.2)
        enemy.run(moveToFront)
        
        let progress = CGFloat(currentTaps) / CGFloat(maxTaps)
        
        //creates a circular loading bar that fills as you tap. Subview of UIView!
        let point = CGPoint(x: frame.midX, y: frame.midY)
        let rect = CGRect(x: point.x, y: point.y, width: 200, height: 200)
        tapLoadingBar = CircularProgressView(frame: rect)
        tapLoadingBar?.layer.anchorPoint = CGPoint(x: 1, y: 1)
        tapLoadingBar!.progressColor = UIColor.red
        tapLoadingBar!.trackClr = UIColor.lightGray
        self.view!.addSubview(tapLoadingBar!)
        tapLoadingBar!.setProgressWithAnimation(duration: 0, fromValue: Float(progress), toValue: Float(progress))
        
        tapTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector:#selector(GameScene.addTapResistance), userInfo: nil, repeats: true)
        
    }
    
    @objc func addTapResistance() {
        currentTaps -= tapResistence
        
        let progress = CGFloat(currentTaps) / CGFloat(maxTaps)
        
        let strokeEnd = (tapLoadingBar!.progressLayer.presentation()?.value(forKey: "strokeEnd") as! NSNumber).floatValue
        
        tapLoadingBar!.setProgressWithAnimation(duration: 0.2, fromValue: strokeEnd, toValue: Float(progress))
        
        if currentTaps <= 0 {
            endGame()
        }
    }
    
    func tappedInFightForLife() {
        
        currentTaps += 1
        
        let progress = CGFloat(currentTaps) / CGFloat(maxTaps)
        let strokeEnd = (tapLoadingBar!.progressLayer.presentation()?.value(forKey: "strokeEnd") as! NSNumber).floatValue
        
        tapLoadingBar!.setProgressWithAnimation(duration: 0.1, fromValue: strokeEnd, toValue: Float(progress))
        
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
    
    //used after fight for life
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
        
        tapLoadingBar?.removeFromSuperview()
        tapLoadingBar = nil
        
        destroyAllNodes()
        
        //Prevents user from accidentally using power while tapping
        //immediately after fight for life
        let wait = SKAction.wait(forDuration: 1)
        let turnOffFightForLife = SKAction.customAction(withDuration: 0) { (_, _) in
            self.specialPowerIcon?.fightForLifeActive = false
        }
        
        let sequence = SKAction.sequence([wait,turnOffFightForLife])
        specialPowerIcon?.run(sequence)
        
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
        tapLoadingBar?.removeFromSuperview()
        tapLoadingBar = nil
        
        powerLoadBar?.removeFromSuperview()
        powerLoadBar = nil
        
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
        
        //handle contacts between defender and power up
        if contacted(powerUpButton: contact.bodyA.node!) || contacted(powerUpButton: contact.bodyB.node!) {
            return
        }
        
        //handle contacts betweent the defender and a missile
        if missileNameArray.contains(bodyAName) || missileNameArray.contains(bodyBName) {
            if bodyBName == "defender" || bodyAName == "defender" {
                if contact.bodyA.node?.name == "defender" {
                    handleContactBetween(defender: contact.bodyA.node!, andMissile: contact.bodyB.node!)
                } else {
                    handleContactBetween(defender: contact.bodyB.node!, andMissile: contact.bodyA.node!)
                }
                
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
//                let impactSound = SKAction.playSoundFileNamed("impact.mp3", waitForCompletion: false)
//                self.run(impactSound)
            }
            
            if fightForLifeActive {
                return
            }
            
            //handle contacts against the boat
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
            
            //handle contacts against the color-shield
            if contact.bodyA.node?.name == "color-shield" {
                handleContactsBetweenColorshield(andMissile: contact.bodyB.node as! SKSpriteNode)
            } else if contact.bodyB.node?.name == "color-shield" {
                handleContactsBetweenColorshield(andMissile: contact.bodyA.node as! SKSpriteNode)
            }
            
        }
    }
    
    func handleContactsBetweenColorshield(andMissile missile: SKSpriteNode) {
        //if it's white, all missiles go through
        if colorChanger?.activeColor == .white {
            return
        }
        
        //if it's not matching colors, the missile gets destroyed
        if missile.color != colorChanger?.activeColor {
            missile.removeFromParent()
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
    
}

