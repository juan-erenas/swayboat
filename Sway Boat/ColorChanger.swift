//
//  ColorChanger.swift
//  Sway Boat
//
//  Created by Juan Erenas on 2/5/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

protocol ColorChangerDelegate {
    func startCountDown(forColor color: UIColor)
}

class ColorChanger : SKSpriteNode {
    
    var activeColor : UIColor
    var delegate : ColorChangerDelegate?
    
    init(withstartingColor startingColor: UIColor) {
        activeColor = startingColor
        let texture = SKTexture(imageNamed: "color changer")
        let size = CGSize(width: 50, height: 50)
        super.init(texture: texture, color: UIColor.white, size: size)
        configureSelf()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureSelf(){
        self.colorBlendFactor = 0
        self.name = "color changer"
        self.zPosition = 0
        
//        //add pointer child node
//        let texture = SKTexture(imageNamed: "color changer pointer")
//        let pointer = SKSpriteNode(texture: texture, color: .white, size: CGSize(width: 10, height: 15))
//        pointer.physicsBody?.allowsRotation = false
//        pointer.colorBlendFactor = 1
//        pointer.position = self.position
//        self.addChild(pointer)
    }
    
    func changeActiveColor() {
        let newColor = randomColor()
        rotate(toColor: newColor)
    }
    
    private func randomColor() -> ColorChangerColor {
        let range = ColorChangerColor.cases.count
        let randNum = Int(arc4random_uniform(UInt32(range)))
        return ColorChangerColor(randNum)
    }
    
    private func rotate(toAngle angle: CGFloat) {
        
    }
    
    
    //rotates the color wheel to the selected ColorChangerColor
    private func rotate(toColor newColor: ColorChangerColor) {
        
        let angle = convertColorToRadians(forColor: newColor)
        
        var sequenceArray = [SKAction]()
        
        //prepare animation
        let prepare = SKAction.rotate(toAngle: .pi/4, duration: 0.4)
        sequenceArray.append(prepare)
        
        //begin spinning animation
        for _ in 1...5 {
            let rotate = SKAction.rotate(byAngle: 2 * .pi, duration: 0.3)
            sequenceArray.append(rotate)
        }
        //prepare to stop animation
        let prepareStop = SKAction.rotate(toAngle: angle + 1.25664, duration: 0.4)
        let stop = SKAction.rotate(toAngle: angle, duration: 0.5)
        
        let stopped = SKAction.customAction(withDuration: 0) { (_, _) in
            let color = self.convertToUIColor(forColor: newColor)
            self.delegate?.startCountDown(forColor: color)
        }
        
        sequenceArray.append(contentsOf: [prepareStop,stop,stopped])
        //run all the actions
        let sequence = SKAction.sequence(sequenceArray)
        self.run(sequence)
        
    }
    
    private func convertColorToRadians(forColor color: ColorChangerColor) -> CGFloat {
        
        switch color {
        case .white:
            return 0
        case .blue:
            return 1.25664
        case .green:
            return 2.51327
        case .red:
            return 3.76991
        case .yellow:
            return 5.02655
         }
    }
    
    private func convertToUIColor(forColor color: ColorChangerColor) -> UIColor {
        switch color {
        case .white:
            return UIColor.white
        case .blue:
            return UIColor.blue
        case .green:
            return UIColor.green
        case .red:
            return UIColor.red
        case .yellow:
            return UIColor.yellow
         }
    }
    
}
