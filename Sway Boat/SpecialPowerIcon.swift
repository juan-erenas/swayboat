//
//  SpecialPowerIcon.swift
//  Sway Boat
//
//  Created by Juan Erenas on 1/18/20.
//  Copyright © 2020 Juan Erenas. All rights reserved.
//

import SpriteKit

class SpecialPowerIcon : SKSpriteNode {
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(size: CGSize, powerType: PowerType) {
        let initTexture = SKTexture(imageNamed: "water trail")
        self.init(texture: initTexture, color: .gray, size: size, powerType: powerType)
    }
    
    init(texture: SKTexture?, color: UIColor, size: CGSize, powerType: PowerType) {
        self.powerType = powerType
        super.init(texture: texture, color: color, size: size)
        configureIcon()
    }
    
    var powerType : PowerType
    var isActive = false
    var coolDownRate = 0
    
    //add to this enum as new powers are made
    enum PowerType : String {
        case growBig = "grow big"
    }
    
    private func configureIcon() {
        self.colorBlendFactor = 1.0
        self.name = "special power icon"
        self.texture = SKTexture(imageNamed: grabTextureName())
        self.coolDownRate = getCoolDownRate()
    }
    
    //use this func to choose what icon is being used
    private func grabTextureName() -> String {
        return "water trail"
    }
    
    //use this func to decide what the cool down rate is according to the power
    private func getCoolDownRate() -> Int {
        return 10
    }
    
    func makeActive() {
        isActive = true
        //purple color
        self.color = UIColor(red: 73/255, green: 0, blue: 172/255, alpha: 1)
    }
    
    func makeInactive() {
        isActive = false
        self.color = .gray
    }
}
