//
//  CircularProgressView.swift
//  Sway Boat
//
//  Created by Juan Erenas on 12/15/19.
//  Copyright © 2019 Juan Erenas. All rights reserved.
//

import UIKit
class CircularProgressView: UIView {
    var progressLayer = CAShapeLayer()
    var trackLayer = CAShapeLayer()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        makeCircularPath()
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        makeCircularPath()
    }
    
    var progressColor = UIColor.white {
        didSet {
            progressLayer.strokeColor = progressColor.cgColor
        }
    }
    var trackClr = UIColor.white {
        didSet {
            trackLayer.strokeColor = trackClr.cgColor
        }
    }
    func makeCircularPath() {
        self.backgroundColor = UIColor.clear
        self.layer.cornerRadius = self.frame.size.width/2
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: frame.size.width/2, y: frame.size.height/2), radius: (frame.size.width - 1.5)/2, startAngle: CGFloat(-0.5 * .pi), endAngle: CGFloat(1.5 * .pi), clockwise: true)
        trackLayer.path = circlePath.cgPath
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = trackClr.cgColor
        trackLayer.lineWidth = 5.0
        trackLayer.strokeEnd = 1.0
        layer.addSublayer(trackLayer)
        progressLayer.path = circlePath.cgPath
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = 10.0
        progressLayer.strokeEnd = 0.0
        progressLayer.lineCap = kCALineCapRound
        layer.addSublayer(progressLayer)
    }
    func setProgressWithAnimation(duration: TimeInterval, fromValue: Float, toValue: Float) {
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = duration
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        progressLayer.strokeEnd = CGFloat(toValue)
        progressLayer.add(animation, forKey: "animateprogress")
    }
}
