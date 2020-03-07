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
    
    convenience init(type: EnemyType, size: CGSize, color: EnemyColor) {
        var texture : SKTexture
        var colorValue : UIColor
        
        switch color {
        case .blue:
            colorValue = UIColor.blue
        case .green:
            colorValue = UIColor.green
        case .red:
            colorValue = UIColor.red
        case .yellow:
            colorValue = UIColor.yellow
        case .random:
            let randNum = Int.random(in: 0 ... (EnemyColor.cases.count - 2))
            let colors = [UIColor.blue,UIColor.green,UIColor.red,UIColor.yellow]
            colorValue = colors[randNum]
        }
        
        switch type {
        case .normal:
            texture = SKTexture(imageNamed: "water trail")
        case .diver:
            texture = SKTexture(imageNamed: "water trail")
        case .splitter:
            texture = SKTexture(imageNamed: "water trail")
        case .splitterChild:
            texture = SKTexture(imageNamed: "water trail")
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
        case .splitter:
            self.killValue = 0
            self.name = "splitter enemy"
        case .splitterChild:
            self.killValue = 1
            self.name = "splitter child enemy"
        }
    }
    
    
}
