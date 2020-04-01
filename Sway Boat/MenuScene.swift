//
//  MainMenu.swift
//  Sway Boat
//
//  Created by Juan Erenas on 9/23/18.
//  Copyright © 2018 Juan Erenas. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    var backgroundMusic: SKAudioNode!
    var menuNode = SKNode()
    var messageNode = SKNode()
    enum scenes {
        case gameScene
        case changePlayer
    }
    
    var swipeUp = UISwipeGestureRecognizer()
    var dimPanel : SKSpriteNode?
    
    override func didMove(to view: SKView) {
        
        messageNode.zPosition = 1
        
        swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(swipedUp))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)
            
        addChild(menuNode)
        addChild(messageNode)
        
        backgroundColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0)
//        addLogo()
        addLabels()
        performIntroAnimation()
        
        if let musicURL = Bundle.main.url(forResource: "CreoSphere", withExtension: "mp3") {
               backgroundMusic = SKAudioNode(url: musicURL)
               addChild(backgroundMusic)
           }
        
        checkForNewDay()
    }
    
//    func addLogo() {
//        let logo = SKSpriteNode(imageNamed: "logo")
//        logo.size = CGSize(width: frame.size.width/4, height: frame.size.width/4)
//        logo.position = CGPoint(x: frame.midX, y: frame.midY + frame.size.height/4)
//        addChild(logo)
//    }
//

    
    
    
    func addLabels() {
        let titleLabel1 = SKLabelNode(text: "SWAY")
        titleLabel1.numberOfLines = 2
        titleLabel1.fontName = "AvenirNext-Bold"
        titleLabel1.fontSize = 100.0
        titleLabel1.fontColor = UIColor.white
        titleLabel1.position = CGPoint(x: frame.midX, y: frame.midY + frame.height/4)
        menuNode.addChild(titleLabel1)
        
        let titleLabel2 = SKLabelNode(text: "BOAT")
        titleLabel2.numberOfLines = 2
        titleLabel2.fontName = "AvenirNext-Bold"
        titleLabel2.fontSize = 100.0
        titleLabel2.fontColor = UIColor.white
        titleLabel2.position = CGPoint(x: frame.midX, y: titleLabel1.position.y - 100)
        menuNode.addChild(titleLabel2)
        
        let highscoreLabel = SKLabelNode(text: "Highscore: " + "\(UserDefaults.standard.integer(forKey: "Highscore"))")
        highscoreLabel.name = "high score label"
        highscoreLabel.fontName = "AvenirNext-Bold"
        highscoreLabel.fontSize = 30.0
        highscoreLabel.fontColor = UIColor.white
        highscoreLabel.position = CGPoint(x: frame.midX, y: titleLabel2.position.y - 70)
        menuNode.addChild(highscoreLabel)
        
        let recentScoreLabel = SKLabelNode(text: "Recent Score: " + "\(UserDefaults.standard.integer(forKey: "RecentScore"))")
        recentScoreLabel.fontName = "AvenirNext-Bold"
        recentScoreLabel.fontSize = 30.0
        recentScoreLabel.fontColor = UIColor.white
        recentScoreLabel.position = CGPoint(x: frame.midX, y: highscoreLabel.position.y - recentScoreLabel.frame.size.height*2)
        menuNode.addChild(recentScoreLabel)
        
        
        let playLabel = SKLabelNode(text: "- tap to play -")
        playLabel.fontName = "AvenirNext-Bold"
        playLabel.fontSize = 30.0
        playLabel.fontColor = UIColor.white
        playLabel.position = CGPoint(x: frame.midX, y: self.frame.minY + 150)
        menuNode.addChild(playLabel)
        animate(label: playLabel)
        
        let changePlayerLabel = SKLabelNode(text: "change player")
        changePlayerLabel.fontName = "AvenirNext-Bold"
        changePlayerLabel.name = "change player"
        changePlayerLabel.fontSize = 20.0
        changePlayerLabel.fontColor = UIColor.white
        changePlayerLabel.position = CGPoint(x: frame.midX, y: self.frame.minY + 50)
        menuNode.addChild(changePlayerLabel)
        
        let arrowDown = SKSpriteNode(imageNamed: "arrow-down")
        arrowDown.name = "arrow-down"
        arrowDown.size = CGSize(width: 20.0, height: 10.0)
        arrowDown.color = UIColor.white
        arrowDown.colorBlendFactor = 1
        arrowDown.position = CGPoint(x: frame.midX, y: changePlayerLabel.position.y - 20)
        menuNode.addChild(arrowDown)
        animate(arrow: arrowDown)
        
        let settings = SKSpriteNode(imageNamed: "gear")
        settings.size = CGSize(width: 30.0, height: 30.0)
        settings.color = UIColor.white
        settings.colorBlendFactor = 1
        settings.position = CGPoint(x: frame.minX + 30, y: frame.maxY - 30)
        menuNode.addChild(settings)
        
    }
    func animate(arrow: SKSpriteNode) {
        let pos = arrow.position
        
        let moveDown = SKAction.moveTo(y: pos.y - 5, duration: 0.5)
        let moveUp = SKAction.move(to: pos, duration: 0.5)
        let sequence = SKAction.sequence([moveDown,moveUp])
        arrow.run(SKAction.repeatForever(sequence))
    }
    
    
    func animate(label: SKLabelNode) {
        let fade = SKAction.fadeAlpha(to: 0, duration: 0.5)
        let appear = SKAction.fadeAlpha(to: 1, duration: 0.5)
        let wait = SKAction.wait(forDuration: 1)
        
        let sequence = SKAction.sequence([fade,appear,wait])
        label.run(SKAction.repeatForever(sequence))
    }
    
    //MARK: - Exit Scene Animations
    
    @objc func swipedUp() {
        
        if !messageNode.children.isEmpty {return}
        
        goToCharacterSelect()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !messageNode.children.isEmpty {
            checkNotificationTouch(at: touches.first!)
            return
        }
        
        
        let touch = touches.first!
        let location = touch.location(in: self)
        
        let label = menuNode.childNode(withName: "change player")
        let arrow = menuNode.childNode(withName: "arrow-down")
        
        if label?.frame.contains(location) ?? false || arrow?.frame.contains(location) ?? false {
            goToCharacterSelect()
        } else {
            performExitAnimation(AndGoTo: .gameScene)
        }
        
    }
    
    func performIntroAnimation() {
        createFlash(andFade: true)
        
        let posY = self.position.y
        let belowViewY = -self.frame.height
        let moveDown = SKAction.moveTo(y: belowViewY, duration: 0.1)
        let moveUp = SKAction.moveTo(y: posY + 100, duration: 0.3)
        let resetPos = SKAction.moveTo(y: posY, duration: 0.3)
        
        let sequence = SKAction.sequence([moveDown,moveUp,resetPos])
        menuNode.run(sequence)
    }
    
    func performExitAnimation(AndGoTo scene: scenes) {
        print("perform exit called")
        createFlash(andFade: false)
        
        self.view?.removeGestureRecognizer(swipeUp)
        
        let posY = self.position.y
        let belowViewY = -self.frame.height
        let moveDown = SKAction.moveTo(y: belowViewY, duration: 0.1)
        let moveUp = SKAction.moveTo(y: posY + 100, duration: 0.3)
        let presentScene = SKAction.customAction(withDuration: 0) { (_, _) in
            if scene == .gameScene {
                self.goToGameScene()
            } else if scene == .changePlayer {
                self.goToCharacterSelect()
            }
        }
        
        let sequence = SKAction.sequence([moveUp,moveDown,presentScene])
        menuNode.run(sequence)
        
        
    }
    
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
        
        let wait = SKAction.wait(forDuration: 0.3)
        let raiseAlpha = SKAction.fadeAlpha(to: 1, duration: 0.1)
        let lowerAlpha = SKAction.fadeAlpha(to: 0, duration: 1)
        let remove = SKAction.removeFromParent()
        
        var sequence : SKAction?
        if fade {
            sequence = SKAction.sequence([lowerAlpha,remove])
        } else {
            sequence = SKAction.sequence([wait,raiseAlpha])
        }
        
        panel.run(sequence!)
    }
    
    func goToGameScene() {
        let gameScene = GameScene(size: self.view!.bounds.size)
        self.view!.presentScene(gameScene)
    }
    
    func goToCharacterSelect() {
        let characterSelect = ChangePlayer(size: self.view!.bounds.size)
        let transition = SKTransition.moveIn(with: .down, duration: 0.3)
        self.view!.presentScene(characterSelect, transition: transition)
    }
    
    
    
    //MARK: - Daily Score Handler
    func checkForNewDay() {
        
//        createNotification(withMessage: "Daily Hi Score Reset!")
//        return
        
        if UserDefaults.standard.object(forKey: "LastDateSaved") == nil {
            UserDefaults.standard.set(Date(), forKey: "LastDateSaved")
            return
        }
        
        let lastDate = UserDefaults.standard.object(forKey: "LastDateSaved") as! Date
        let todaysDate = Date()
        
        if !isSameDay(date1: lastDate, date2: todaysDate) {
            UserDefaults.standard.set(0, forKey: "Highscore")
            
            let highScoreLabel = menuNode.childNode(withName: "high score label") as? SKLabelNode
            highScoreLabel?.text = "Highscore: 0"
            
            UserDefaults.standard.set(Date(), forKey: "LastDateSaved")
            createNotification(withMessage: "New Day, New Hi Score!")
        }
    
    }
    
    func isSameDay(date1: Date, date2: Date) -> Bool {
        let diff = Calendar.current.dateComponents([.day], from: date1, to: date2)
        if diff.day == 0 {
            return true
        } else {
            return false
        }
    }
    
    func createNotification(withMessage message: String) {
        dimScreen()
        let frameSize = CGSize(width: self.frame.width * 0.8, height: self.frame.height * 0.5)
        let framePos = CGPoint(x: self.frame.midX - (frameSize.width/2), y: (self.frame.midY - (self.frame.midY * 0.2)) - (frameSize.height/2))
        let messageFrame = SKShapeNode(rect: CGRect(origin: framePos, size: frameSize), cornerRadius: 20)
        messageFrame.fillColor = self.backgroundColor
        messageFrame.alpha = 1
//        let messageFrame = SKSpriteNode(color: .blue, size: frameSize)
        messageFrame.name = "message frame"
        messageNode.addChild(messageFrame)
        
        let third = messageFrame.frame.size.height * 0.3
        
        //used to find the true center, not the lower left corner that the origin points to
        let messageFrameCenter = CGPoint(x: messageFrame.frame.origin.x + (messageFrame.frame.width/2), y: messageFrame.frame.origin.y + (messageFrame.frame.height/2))
        
        let titleMessage = SKLabelNode(text: message)
        titleMessage.position = CGPoint(x: messageFrameCenter.x, y: messageFrameCenter.y + third)
        titleMessage.fontName = "AvenirNext-Bold"
        titleMessage.fontSize = 30.0
        titleMessage.fontColor = UIColor.white
        titleMessage.numberOfLines = 0
        titleMessage.verticalAlignmentMode = .top
        titleMessage.horizontalAlignmentMode = .center
        titleMessage.lineBreakMode = .byWordWrapping
        titleMessage.preferredMaxLayoutWidth = messageFrame.frame.size.width - 70
        
        let attrString = NSMutableAttributedString(string: message)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let range = NSRange(location: 0, length: message.count)
        attrString.addAttribute(NSAttributedStringKey.paragraphStyle, value: paragraphStyle, range: range)
        attrString.addAttributes([NSAttributedStringKey.foregroundColor : UIColor.white, NSAttributedStringKey.font : UIFont.systemFont(ofSize: 30)], range: range)
        titleMessage.attributedText = attrString
        
        messageNode.addChild(titleMessage)
        
        let buttonWidth = messageFrame.frame.size.width * 0.5
        let button = SKShapeNode(rect: CGRect(x: messageFrameCenter.x - (buttonWidth/2), y: messageFrameCenter.y - third, width: buttonWidth, height: 50), cornerRadius: 30)
        button.fillColor = UIColor.red
        button.lineWidth = 0
        button.name = "notification button"
        messageNode.addChild(button)
        
        let buttonLabel = SKLabelNode(text: "OK")
        buttonLabel.name = "button label"
        buttonLabel.fontName = "AvenirNext"
        buttonLabel.fontSize = 20
        buttonLabel.color = UIColor.white
        buttonLabel.colorBlendFactor = 1
        buttonLabel.position = CGPoint(x: messageFrameCenter.x, y: (messageFrameCenter.y - third) + (button.frame.height / 2))
        buttonLabel.verticalAlignmentMode = .center
        messageNode.addChild(buttonLabel)
    }
    
    func dimScreen() {
        dimPanel = SKSpriteNode(color: UIColor.black, size: self.size)
        dimPanel!.alpha = 0.5
        dimPanel!.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        messageNode.addChild(dimPanel!)
    }
    
    func removeDimScreen() {
        dimPanel?.removeFromParent()
        dimPanel = nil
    }
    
    func checkNotificationTouch(at touch: UITouch) {
        
        let location = touch.location(in: self)
        
        let button = messageNode.childNode(withName: "notification button")
        let messageFrame = messageNode.childNode(withName: "message frame")
        
        if button?.frame.contains(location) ?? false {
            messageNode.removeAllChildren()
        } else if !(messageFrame?.frame.contains(location) ?? true) {
            messageNode.removeAllChildren()
        }
        
        
    }
    
}

