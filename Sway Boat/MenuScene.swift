//
//  MainMenu.swift
//  Sway Boat
//
//  Created by Juan Erenas on 9/23/18.
//  Copyright © 2018 Juan Erenas. All rights reserved.
//

import SpriteKit

class MenuScene: SKScene {
    
    override func didMove(to view: SKView) {
        backgroundColor = UIColor(red: 44/255, green: 62/255, blue: 80/255, alpha: 1.0)
//        addLogo()
        addLabels()
    }
    
//    func addLogo() {
//        let logo = SKSpriteNode(imageNamed: "logo")
//        logo.size = CGSize(width: frame.size.width/4, height: frame.size.width/4)
//        logo.position = CGPoint(x: frame.midX, y: frame.midY + frame.size.height/4)
//        addChild(logo)
//    }
//
    func addLabels() {
        let titleLabel1 = SKLabelNode(text: "PAPER")
        titleLabel1.numberOfLines = 2
        titleLabel1.fontName = "AvenirNext-Bold"
        titleLabel1.fontSize = 90.0
        titleLabel1.fontColor = UIColor.white
        titleLabel1.position = CGPoint(x: frame.midX, y: frame.midY + frame.height/4)
        addChild(titleLabel1)
        
        let titleLabel2 = SKLabelNode(text: "BOAT")
        titleLabel2.numberOfLines = 2
        titleLabel2.fontName = "AvenirNext-Bold"
        titleLabel2.fontSize = 90.0
        titleLabel2.fontColor = UIColor.white
        titleLabel2.position = CGPoint(x: frame.midX, y: titleLabel1.position.y - 110)
        addChild(titleLabel2)
        
        let playLabel = SKLabelNode(text: "Tap to Play!")
        playLabel.fontName = "AvenirNext-Bold"
        playLabel.fontSize = 50.0
        playLabel.fontColor = UIColor.white
        playLabel.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(playLabel)
        animate(label: playLabel)
        
        let highscoreLabel = SKLabelNode(text: "Highscore: " + "\(UserDefaults.standard.integer(forKey: "Highscore"))")
        highscoreLabel.fontName = "AvenirNext-Bold"
        highscoreLabel.fontSize = 40.0
        highscoreLabel.fontColor = UIColor.white
        highscoreLabel.position = CGPoint(x: frame.midX, y: frame.midY - highscoreLabel.frame.size.height*4)
        addChild(highscoreLabel)
        
        let recentScoreLabel = SKLabelNode(text: "Recent Score: " + "\(UserDefaults.standard.integer(forKey: "RecentScore"))")
        recentScoreLabel.fontName = "AvenirNext-Bold"
        recentScoreLabel.fontSize = 40.0
        recentScoreLabel.fontColor = UIColor.white
        recentScoreLabel.position = CGPoint(x: frame.midX, y: highscoreLabel.position.y - recentScoreLabel.frame.size.height*2)
        addChild(recentScoreLabel)
    }
    
    func animate(label: SKLabelNode) {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp,scaleDown])
        label.run(SKAction.repeatForever(sequence))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let gameScene = GameScene(size: view!.bounds.size)
        view!.presentScene(gameScene)
    }
    
}

