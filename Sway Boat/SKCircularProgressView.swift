//
//  SKCircularProgressView.swift
//  Sway Boat
//
//  Created by Juan Erenas on 1/12/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

class SKCircularProgressView: SKNode {
    
    var arcCenter = CGPoint(x: 0, y: 0)
    var radius = 100

    private func createProgressNode() {
        
        let square = SKSpriteNode(color: SKColor.red, size: CGSize(width: 20, height: 20))
        square.position = CGPointMake(self.size.width/2, self.size.height/2)
        addChild(square)
        
        let bezierPath = UIBezierPath(arcCenter: arcCenter, radius: 100, startAngle: -.pi / 2, endAngle: -.pi / 2, clockwise: true)

        let pathNode = SKShapeNode(path: bezierPath.cgPath)
        pathNode.strokeColor = SKColor.blue
        pathNode.lineWidth = 3
        pathNode.position = square.position
        addChild(pathNode)

        square.run(SKAction.follow(bezierPath.cgPath, asOffset: true, orientToPath: true, duration: 2))

    }

}

