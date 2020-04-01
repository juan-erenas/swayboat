//
//  Enemy.swift
//  Sway Boat
//
//  Created by Juan Erenas on 1/24/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit
class Enemy : SKSpriteNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(type: EnemyType, size: CGSize) {
        var texture : SKTexture
        var colorValue : UIColor
        
        switch type {
        case .normal:
            texture = SKTexture(imageNamed: "water trail")
            colorValue = UIColor.white
        case .diver:
            texture = SKTexture(imageNamed: "water trail")
            colorValue = UIColor.red
        case .splitter:
            texture = SKTexture(imageNamed: "water trail")
            colorValue = UIColor.yellow
        case .splitterChild:
            texture = SKTexture(imageNamed: "water trail")
            colorValue = UIColor.yellow
        }
        
        self.init(texture: texture, color: colorValue, size: size, type: type)
    }
    
    init(texture: SKTexture?, color: UIColor, size: CGSize, type: EnemyType) {
        enemyType = type
        super.init(texture: texture, color: color, size: size)
        configureEnemy()
    }
    
    var enemyType : EnemyType
    var killValue = 1
    
    enum EnemyType {
        case normal
        case diver
        case splitter
        case splitterChild
    }
    
    func configureEnemy() {
        self.zPosition = 12
        self.size.width = 30
        self.size.height = 30
        self.colorBlendFactor = 1
        setEnemyType()
    }
    
    func setEnemyType() {
        switch enemyType {
        case .normal:
            self.killValue = 1
            self.name = "normal enemy"
        case .diver:
            self.killValue = 1
            self.name = "diver enemy"
            flashWhite(and: .red, forEnemy: self)
        case .splitter:
            self.killValue = 0
            self.name = "splitter enemy"
            flashWhite(and: .yellow, forEnemy: self)
        case .splitterChild:
            self.killValue = 1
            self.name = "splitter child enemy"
        }
    }
    
    private func flashWhite(and color: UIColor,forEnemy enemy: SKSpriteNode) {
        
        let colorPulse = SKAction.colorize(with: color, colorBlendFactor: 1.0, duration: 0.2)
        let whitePulse = SKAction.colorize(with: .white, colorBlendFactor: 1.0, duration: 0.2)
        let enlarge = SKAction.scale(to: 1.1, duration: 0.2)
        let shrink = SKAction.scale(to: 1.0, duration: 0.2)
        
        let enlargeAndColor = SKAction.group([colorPulse,enlarge])
        let shrinkAndColorWhite = SKAction.group([shrink,whitePulse])
        let sequence = SKAction.sequence([enlargeAndColor,shrinkAndColorWhite])
        
        enemy.run(SKAction.repeatForever(sequence))
    }
    
    
}
