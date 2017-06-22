//
//  CAShapeLayer+drawLine.swift
//  AnimatedHamburgerTestApp
//
//  Created by CrazyTalk Entertainment on 2014-11-03.
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

extension CAShapeLayer
{
    
   //MARK: Class Methods
    
    class func bezierPathForLine(fromPoint: CGPoint, toPoint: CGPoint, controlPoint: CGPoint?) ->UIBezierPath
    {
        let path: UIBezierPath = UIBezierPath()
        path.moveToPoint(fromPoint)
        
        if (controlPoint != nil) {
            
            path.addQuadCurveToPoint(toPoint, controlPoint: controlPoint!)
        }
        else {
            
            path.addLineToPoint(toPoint)
        }
        
        return path;
    }
    
    class func bezierPathForLine(fromPoint: CGPoint, toPoint: CGPoint) ->UIBezierPath
    {
        return CAShapeLayer.bezierPathForLine(fromPoint, toPoint: toPoint, controlPoint: nil)
    }
    
    class func pointAlongQuadBezierPath(fromPoint: CGPoint, toPoint: CGPoint, controlPoint: CGPoint, percent: CGFloat) -> CGPoint {
        
        if percent <= 0.0 {
            
            return fromPoint
        }
        else if percent >= 1.0 {
            
            return toPoint
        }
        
        let x: CGFloat = CAShapeLayer.calculateCoordinateAlongPath(fromPoint.x, coord1: controlPoint.x, coord2: toPoint.x, t: percent)
        let y: CGFloat = CAShapeLayer.calculateCoordinateAlongPath(fromPoint.y, coord1: controlPoint.y, coord2: toPoint.y, t: percent)
        
        return CGPoint(x: x, y: y)
    }
    
    class func calculateCoordinateAlongPath(coord0: CGFloat, coord1: CGFloat, coord2: CGFloat, t:CGFloat) -> CGFloat
    {
        let partOne: CGFloat = (pow((1 - t), 2) * coord0)
        let partTwo: CGFloat = (2 * (1 - t) * t * coord1)
        let partThree: CGFloat = (pow(t, 2) * coord2)
        
        return  partOne + partTwo + partThree
    }
    
    class func controlPointsForDividedBezierPath(startPoint: CGPoint, endPoint: CGPoint, controlPoint: CGPoint, t: CGFloat) -> (controlPoint1: CGPoint, controlPoint2: CGPoint)
    {
        let controlPoint1: CGPoint = CAShapeLayer.pointAlongLine(startPoint, endPoint: controlPoint, t: t)
        let controlPoint2: CGPoint = CAShapeLayer.pointAlongLine(controlPoint, endPoint: endPoint, t: t)
        return (controlPoint1, controlPoint2)
    }
    
    class func pointAlongLine(startPoint: CGPoint, endPoint: CGPoint, t: CGFloat) -> CGPoint
    {
        if t <= 0.0 {
            
            return startPoint
        }
        else if t >= 1.0 {
            
            return endPoint
        }
        
        let x:  CGFloat = ((1 - t) * startPoint.x) + (t * endPoint.x)
        let y: CGFloat = ((1 - t) * startPoint.y) + (t * endPoint.y)
        
        return CGPoint(x: x, y: y)
    }
    
    
    //MARK: Instance Methods
    
    func drawLine(fromPoint: CGPoint, toPoint: CGPoint, thickness: CGFloat, color: UIColor, alpha: Float, capType: NSString!)
    {
        let path: UIBezierPath = CAShapeLayer.bezierPathForLine(fromPoint, toPoint: toPoint)
        
        self.path = path.CGPath
        self.strokeColor = color.CGColor
        self.lineWidth = thickness
        self.lineCap = capType as String
        self.fillColor = UIColor.clearColor().CGColor
        self.opacity = alpha
    }
    
    func drawLine(fromPoint: CGPoint, toPoint: CGPoint, thickness: CGFloat, color: UIColor, alpha: Float)
    {
        self.drawLine(fromPoint, toPoint: toPoint, thickness: thickness, color: color, alpha: alpha, capType: kCALineCapButt)
    }
    
    
    func angleDelta(angle: CGFloat) -> CGFloat
    {
        let currentAngle = self.valueForKeyPath("transform.rotation.z")?.doubleValue
        var angleDifference: CGFloat = CGFloat(currentAngle!) - angle
        angleDifference = -angleDifference
        
        let twoPi: CGFloat = CGFloat(2 * M_PI)
        if (angleDifference > twoPi) {
            
            angleDifference = (angleDifference - twoPi)
        }
        else if (angleDifference < -twoPi) {
            
            angleDifference = (angleDifference + twoPi)
        }
        return angleDifference
        
    }
    
}








