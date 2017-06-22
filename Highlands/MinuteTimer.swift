//
//  MinuteTimer.swift
//  Highlands
//
//  Created by Raiden Honda on 5/18/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import Foundation

@IBDesignable class MinuteTimer : UIView {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init (frame : CGRect) {
        super.init(frame: frame)
    }
    
//    override func drawRect(rect: CGRect) {
//        // Draw the circle
//        let lineWidth : CGFloat = 5.0 // *** Set the line width here ***
//        let boundedRect : CGRect = CGRectMake(rect.origin.x + lineWidth, rect.origin.y + lineWidth, rect.width - (lineWidth*2), rect.height - (lineWidth*2))
//        var outerRing : UIBezierPath = UIBezierPath(ovalInRect: boundedRect);
//        outerRing.lineWidth = 5;
//        var color : UIColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
//        color.setStroke()
//        outerRing.stroke()
//    }

    func animate(strokeColor: UIColor, duration: Double, completion: (() -> ())?) {
        // Set up the circle
        let lineWidth : CGFloat = 5.0
        let startAngle = pointsToDegrees(0.0)
        let endAngle = pointsToDegrees(1.0)

        let boundedRect : CGRect = CGRectMake(self.frame.origin.x + lineWidth,
                                                self.frame.origin.y + lineWidth,
                                                self.frame.width - (lineWidth*2),
                                                self.frame.height - (lineWidth*2))
        
        let radius : CGFloat = boundedRect.width / 2
        let floatStartAngle : CGFloat = CGFloat(startAngle)
        let floatEndAngle : CGFloat = CGFloat(endAngle)
        
        let blueCircle : CAShapeLayer = CAShapeLayer()
        blueCircle.path = UIBezierPath(arcCenter: CGPointMake(self.frame.width / 2, self.frame.width / 2), radius: radius, startAngle: floatStartAngle, endAngle: floatEndAngle, clockwise: true).CGPath
        blueCircle.fillColor = UIColor.clearColor().CGColor
        blueCircle.strokeColor = strokeColor.CGColor
        blueCircle.lineWidth = lineWidth
        
        self.layer.addSublayer(blueCircle)
        
        // Set up the animation
        CATransaction.begin()
        let drawAnimation : CABasicAnimation = CABasicAnimation(keyPath: "strokeEnd")
        drawAnimation.duration = duration
        drawAnimation.removedOnCompletion = true
        drawAnimation.fromValue = 0.0
        drawAnimation.toValue = 1.0
        drawAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)

        if let completionClosure = completion {
            CATransaction.setCompletionBlock(completionClosure)
        }
        blueCircle.addAnimation(drawAnimation, forKey: nil)

        CATransaction.commit()
    }
    
    func pointsToDegrees(points : Double) -> Double {
        return 2.0 * M_PI * points - M_PI_2
    }
}
