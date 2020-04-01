//
//  changePlayer.swift
//  Sway Boat
//
//  Created by Juan Erenas on 3/14/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

class ChangePlayer: SKScene {
    
    var swipeDown = UISwipeGestureRecognizer()
    
    override func didMove(to view: SKView) {
        backgroundColor = .red
        
        swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(swipedDown))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)
    }
    
    
    @objc func swipedDown() {
        let mainMenu = MenuScene(size: self.view!.bounds.size)
        let transition = SKTransition.moveIn(with: .up, duration: 0.3)
        self.view!.presentScene(mainMenu, transition: transition)
    }
    
    
    
    
}
