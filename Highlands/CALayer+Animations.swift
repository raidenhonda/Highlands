//
//  CALayer+Animations.swift
//  AnimatedHamburgerTestApp
//
//  Created by CrazyTalk Entertainment on 2014-11-12.
//  Copyright (c) 2014 CrazyTalk Entertainment. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import QuartzCore
import UIKit

extension CALayer
{
    
    func rotationValuesFromTransform(endRotation: CGFloat, frames: Int) -> [NSValue]
    {
        var keyFrames = [NSValue]()
        
        for num in (0..<frames) {
            
            let value = NSValue(CATransform3D: CATransform3DRotate(self.transform, endRotation / CGFloat(frames - 1) * CGFloat(num), 0, 0, 1))
            keyFrames.insert(value, atIndex: num)
        }
        
        return keyFrames
    }
    
    func addRotationalAnimation(rotation: CGFloat, calculationMode: String?, keyTimes: [AnyObject]?)
    {
        let rotationAnimation = CAKeyframeAnimation(keyPath: "transform")
        rotationAnimation.values = self.rotationValuesFromTransform(rotation, frames: 4)
        
        if (calculationMode != nil) {
            
            rotationAnimation.calculationMode = calculationMode!
        }

        if (keyTimes != nil) {
            
            rotationAnimation.keyTimes = keyTimes as? [NSNumber]
        }
        
        self.addAnimation(rotationAnimation, forKey: rotationAnimation.keyPath)
        
        if let numOfValues : Int = rotationAnimation.values?.count {
            self.setValue(rotationAnimation.values![numOfValues - 1], forKey: rotationAnimation.keyPath!)
        }
    }
    
    func addPositionAnimation(path: UIBezierPath, finalPosition: CGPoint)
    {
        let positionAnimation = CAKeyframeAnimation(keyPath: "position")
        positionAnimation.path = path.CGPath
        
        self.addAnimation(positionAnimation, forKey: positionAnimation.keyPath)
        self.setValue(NSValue(CGPoint: finalPosition), forKeyPath: positionAnimation.keyPath!)
    }
    
    
    func addPositionAnimation(fromPoint: CGPoint, toPoint: CGPoint, controlPoint: CGPoint?)
    {
        let path = CAShapeLayer.bezierPathForLine(fromPoint, toPoint: toPoint, controlPoint: controlPoint)
        self.addPositionAnimation(path, finalPosition: toPoint)
    }
    
}
