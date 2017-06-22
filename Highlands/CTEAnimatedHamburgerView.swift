//
//  CTEAnimatedHamburgerView.swift
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
import UIKit
import QuartzCore

protocol CTEAnimatedHamburgerDelegate {
    
    func didTapHamburgerView(view: CTEAnimatedHamburgerView, gesture: UITapGestureRecognizer)
}

class CTEAnimatedHamburgerView: UIView {
    
    enum CTEAnimatedHamburgerType
    {
        case CTEAnimatedHamburgerTypeClose
        case CTEAnimatedHamburgerTypeBack
    }

    let rotationBugHack = 0.001 //sometime the middle line rotates the wrong direction when the rotation is Pi
    let numberOfLinesInHamburgerView: CGFloat = 3.0
    var delegate: CTEAnimatedHamburgerDelegate?
    var buttonType: CTEAnimatedHamburgerType = .CTEAnimatedHamburgerTypeClose
    var fullTransitionDuration: CFTimeInterval = 0.4
    lazy var midXPosition: CGFloat = {(self.frame.width * 0.5)}()
    lazy var topPosition: CGPoint = {CGPoint(x: self.midXPosition, y: self.minYPosition())}()
    lazy var bottomPosition: CGPoint = {CGPoint(x: self.midXPosition, y: self.maxYPosition())}()
    lazy var midYPosition: CGFloat = {(self.frame.height * 0.5)}()
    lazy var insetFrame: CGRect = {CGRectInset(self.frame, self.frame.width*0.1, self.frame.height*0.1)}()
    lazy var totalLineLength: CGFloat = {(self.lineCapType.isEqualToString(kCALineCapButt)) ? self.lineLength : (self.lineLength + self.lineThickness)}()
    lazy var lineLength: CGFloat = {self.calculateLineLength()}()
    lazy var ratio: CGFloat = {(1.0 - self.rotationalCircleRadius() / (self.totalLineLength * 0.5)) * 0.5}()
    private var topLineLayer = CAShapeLayer()
    private var midLineLayer = CAShapeLayer()
    private var bottomLineLayer = CAShapeLayer()
    private(set) var forwardDirection: Bool = true
    private(set) var percentComplete: CGFloat = 0.0
    private(set) var backArrowAngleStrokeStart: CGFloat = 0.43
    private(set) var backArrowFlatStrokeStart: CGFloat = 0.1
    var lineCapType: NSString! = kCALineCapButt {
        
        didSet {
            
            if self.lineCapType != oldValue {
                
                lineLength = calculateLineLength()
                resetLines()
            }
        }
    }
    var color: UIColor = UIColor.blackColor() {
        
        didSet {
           
            if self.color != oldValue {
               
                resetLines()
            }
        }
    }
    var lineThickness: CGFloat = 3.0 {
        
        didSet {
            
            if self.lineThickness != oldValue {
                
                lineLength = calculateLineLength()
                resetLines()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit()
    {
        setUpLines()
        setupGestures()
    }
    
    func setupGestures()
    {
        let tapGesuture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "didTapView:")
        self.addGestureRecognizer(tapGesuture)
    }

    func resetLines()
    {
        topLineLayer.removeFromSuperlayer()
        topLineLayer = CAShapeLayer()
        midLineLayer.removeFromSuperlayer()
        midLineLayer = CAShapeLayer()
        bottomLineLayer.removeFromSuperlayer()
        bottomLineLayer = CAShapeLayer()
        
        setUpLines()
    }
    
    
    func calculateLineLength() -> CGFloat
    {
        var length: CGFloat = (self.insetFrame.height <= self.insetFrame.width) ? self.insetFrame.height : self.insetFrame.width
        if !lineCapType.isEqualToString(kCALineCapButt) {
           
            length -= lineThickness
        }
        return length
    }
    
    func setUpLines()
    {
        self.topLineLayer = createLineLayerWithPosition(CGPoint(x: midXPosition, y: minYPosition()), length: lineLength, lineColor:color)
        self.midLineLayer = createLineLayerWithPosition(CGPoint(x: midXPosition, y: midYPosition), length: lineLength, lineColor:color)
        self.bottomLineLayer = createLineLayerWithPosition(CGPoint(x: midXPosition, y: maxYPosition()), length: lineLength, lineColor:color)
        
        self.layer.addSublayer(self.topLineLayer)
        self.layer.addSublayer(self.midLineLayer)
        self.layer.addSublayer(self.bottomLineLayer)
        
    }
    
    func isTransitionComplete() -> (isComplete: Bool, percent: CGFloat)
    {
        if ((self.percentComplete == 1.0 || self.percentComplete == 0.0)) {
            
            return (true, self.percentComplete)
        }
        else {
            
            return (false, self.percentComplete)
        }
    }
    
    
    func createLineLayerWithPosition(position: CGPoint, length: CGFloat , lineColor: UIColor) -> CAShapeLayer
    {
        let layer: CAShapeLayer = CAShapeLayer()
        layer.drawLine(CGPointMake(0 , 0), toPoint: CGPointMake(length, 0), thickness: lineThickness, color: lineColor, alpha: 1.0, capType:lineCapType)
        layer.position = position
        layer.bounds = CGPathGetPathBoundingBox(layer.path)
        
        return layer
    }
    
    
    func setPercentComplete(percentComplete: CGFloat, animated: Bool)
    {
        var percent: CGFloat = percentComplete
        if percent > 1.0 {
            
            percent = 1.0
        }
        else if percent < 0.0 {
            
            percent = 0.0
        }
        
        if animated {
        
            forwardDirection = (self.percentComplete < percent) ? true : false;
            let multiplier: CGFloat = (forwardDirection) ? (1 - self.percentComplete) : self.percentComplete;
            let duration: CFTimeInterval = remainingDuration(multiplier)
            startAnimationToPercentComplete(percent, duration: duration)
        }
        else {
            
            updateLinesForPercentComplete(percent)
        }
        
        self.percentComplete = percent
    }
    
    func setPercentageComplete(percentageComplete: CGFloat)
    {
        setPercentComplete(percentageComplete, animated: false)
    }
    
    func minYPosition() -> CGFloat
    {
        _ = (lineCapType.isEqualToString(kCALineCapButt)) ?  (lineLength - lineThickness) : lineLength
        let lineSeperation: CGFloat = rotationalCircleRadius()
        
        return (midYPosition - lineSeperation)
    }
    
    
    func maxYPosition() -> CGFloat
    {
        return (self.frame.height - minYPosition())
    }
    
    
    func rotationalCircleRadius() -> CGFloat
    {
        let length: CGFloat = (lineCapType.isEqualToString(kCALineCapButt)) ?  (lineLength - lineThickness) : lineLength
        let midXPosition: CGFloat = (length * 0.5)
        let radius: CGFloat = sqrt((midXPosition * midXPosition) * 0.5)
        
        return radius
    }
    
    func setLayerActions(actions: [String : CAAction]?)
    {
        topLineLayer.actions = actions
        midLineLayer.actions = actions
        bottomLineLayer.actions = actions
    }
    
    
    func updateLinesForPercentComplete(percentComplete: CGFloat)
    {
        setLayerActions(nil)
        
        switch (buttonType) {
            
        case .CTEAnimatedHamburgerTypeClose:
            
            updateLinesForClose(percentComplete, animate: false)
            
        case .CTEAnimatedHamburgerTypeBack:
            
            updateLinesForBackArrow(percentComplete, animate: false)
            
        }
    }
    
    
    func remainingDuration(percentComplete: CGFloat) -> CFTimeInterval
    {
        let duration: CFTimeInterval = (fullTransitionDuration * CFTimeInterval(percentComplete))
        return duration
        
    }
    
    
    func startAnimationToPercentComplete(percent: CGFloat, duration: CFTimeInterval)
    {
        setLayerActions(["transform": NSNull(), "position": NSNull()])

        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut))
        
        switch (buttonType) {
            
        case .CTEAnimatedHamburgerTypeClose:
           
            updateLinesForClose(percent, animate: true)
            
        case .CTEAnimatedHamburgerTypeBack:
            
            updateLinesForBackArrow(percent, animate: true)
            
        }
        
        CATransaction.commit()
    }
    
    
    //MARK: interactions
    
    func didTapView(gesture: UITapGestureRecognizer)
    {
       delegate?.didTapHamburgerView(self, gesture: gesture)
    }
    
    //MARK: animations
    
    func updateLinesForClose(percentComplete: CGFloat, animate: Bool)
    {
        let rightControlPoint: CGPoint = CGPoint(x: (midXPosition + (totalLineLength * 0.5) - 5.0), y: midYPosition)
        let leftControlPoint: CGPoint = CGPoint(x: (midXPosition - (totalLineLength * 0.5)), y: midYPosition)
        let center: CGPoint = CGPoint(x: midXPosition, y: midYPosition)
        let midAngle: CGFloat = (CGFloat(M_PI - rotationBugHack) * percentComplete)
        
        topLineLayer.strokeStart = (0.05 * percentComplete)
        topLineLayer.strokeEnd = 1.0 - (0.05 * percentComplete)
        midLineLayer.strokeEnd = 1.0 - (0.5 * percentComplete)
        midLineLayer.strokeStart = (0.5 * percentComplete)
        bottomLineLayer.strokeStart = (0.05 * percentComplete)
        bottomLineLayer.strokeEnd = 1.0 - (0.05 * percentComplete)
        
        if animate {
           
        //animate top line
            let topEndRotation: CGFloat = (forwardDirection) ? CGFloat(M_PI + M_PI_4) : CGFloat(-2*M_PI)
             topLineLayer.addRotationalAnimation(topLineLayer.angleDelta(topEndRotation), calculationMode: kCAAnimationCubic, keyTimes: nil)
            
             let curvePoint: CGPoint = CAShapeLayer.pointAlongQuadBezierPath(topPosition, toPoint: center, controlPoint: rightControlPoint, percent: self.percentComplete)
            
            let partialCurveControlPoint: CGPoint = CAShapeLayer.pointAlongLine((forwardDirection) ? rightControlPoint : topPosition, endPoint: (forwardDirection) ? center : rightControlPoint, t: self.percentComplete)
            topLineLayer.addPositionAnimation(curvePoint, toPoint: (forwardDirection) ? center : topPosition, controlPoint: partialCurveControlPoint)
            
        //animate middle line
            midLineLayer.addRotationalAnimation(midLineLayer.angleDelta(midAngle), calculationMode: kCAAnimationCubic, keyTimes: nil)
            
        //animate bottom line
            let bottomEndRotation: CGFloat = (forwardDirection) ? CGFloat(M_PI_2 + M_PI_4) : CGFloat(-2*M_PI)
            bottomLineLayer.addRotationalAnimation(bottomLineLayer.angleDelta(bottomEndRotation), calculationMode: kCAAnimationCubic, keyTimes: nil)
            let bottomCurvePoint: CGPoint = CAShapeLayer.pointAlongQuadBezierPath(bottomPosition, toPoint: center, controlPoint: leftControlPoint, percent: self.percentComplete)
            let bottomPartialCurveControlPoint: CGPoint = CAShapeLayer.pointAlongLine((forwardDirection) ? leftControlPoint : bottomPosition, endPoint: (forwardDirection) ? center : leftControlPoint, t: self.percentComplete)
            
            bottomLineLayer.addPositionAnimation(bottomCurvePoint, toPoint: (forwardDirection) ? center : bottomPosition, controlPoint: bottomPartialCurveControlPoint)
        }
        else {
            
        //animate top line
            let topAngle: CGFloat = (CGFloat(M_PI + M_PI_4) * percentComplete)
            let topRotation = CATransform3DRotate(topLineLayer.transform, topLineLayer.angleDelta(topAngle), 0, 0, 1)
            topLineLayer.transform = topRotation
            topLineLayer.position = CAShapeLayer.pointAlongQuadBezierPath(topPosition, toPoint:center, controlPoint: rightControlPoint, percent: percentComplete)
            
        //animate middle line
            let rotation = CATransform3DRotate(midLineLayer.transform, midLineLayer.angleDelta(midAngle), 0, 0, 1)
            midLineLayer.transform = rotation
            
        //animate bottome line
            let bottomAngle: CGFloat = CGFloat(M_PI_2 + M_PI_4) * percentComplete
            let bottomRotation = CATransform3DRotate(bottomLineLayer.transform, bottomLineLayer.angleDelta(bottomAngle), 0, 0, 1)
            bottomLineLayer.transform = bottomRotation
            bottomLineLayer.position = CAShapeLayer.pointAlongQuadBezierPath(bottomPosition, toPoint:center, controlPoint: leftControlPoint, percent: percentComplete)
        }
    }
    
    func updateLinesForBackArrow(percentComplete: CGFloat, animate: Bool)
    {
        let rightControlPoint: CGPoint = CGPoint(x: (midXPosition + (totalLineLength * 0.5)), y: midYPosition)
        let leftControlPoint: CGPoint = CGPoint(x: (midXPosition - (totalLineLength * 0.5)), y: midYPosition)
        let midAngle: CGFloat = (CGFloat(M_PI - rotationBugHack) * percentComplete)
        let bottomAngle: CGFloat = (CGFloat(M_PI_2 + M_PI_4) * percentComplete)
        
        topLineLayer.strokeStart = (backArrowAngleStrokeStart * percentComplete)
        midLineLayer.strokeEnd = 1.0 - (ratio * percentComplete)
        midLineLayer.strokeStart = (backArrowFlatStrokeStart * percentComplete)
        bottomLineLayer.strokeStart = (backArrowAngleStrokeStart * percentComplete)
        
        if animate {
            
        //animate top line
            let topEndRotation: CGFloat = (forwardDirection) ? CGFloat(M_PI + M_PI_4) : CGFloat(-2*M_PI)
            topLineLayer.addRotationalAnimation(topLineLayer.angleDelta(topEndRotation), calculationMode: kCAAnimationCubic, keyTimes: (forwardDirection) ? [0.0, 0.33, 0.73, 1.0] : [0.0, 0.27, 0.63, 1.0])
            
        //find the current position of the layer along the curve
            let curvePoint: CGPoint = CAShapeLayer.pointAlongQuadBezierPath(topPosition, toPoint: bottomPosition, controlPoint: rightControlPoint, percent: self.percentComplete)
            
        //calculate where the control point for the remaining of the bezier curve is.  when moving forward we need the control point on the point1 to point2 line. when moving backward we need the control point along the point0 to point1 line
            let partialCurveControlPoint: CGPoint = CAShapeLayer.pointAlongLine((forwardDirection) ? rightControlPoint : topPosition, endPoint: (forwardDirection) ? bottomPosition : rightControlPoint, t: self.percentComplete)
            topLineLayer.addPositionAnimation(curvePoint, toPoint: (forwardDirection) ? bottomPosition : topPosition, controlPoint: partialCurveControlPoint)
            
            
        //animate middle line
            midLineLayer.addRotationalAnimation(midLineLayer.angleDelta(midAngle), calculationMode: kCAAnimationCubic, keyTimes: nil)
            
            
        //animate bottom line
            bottomLineLayer.addRotationalAnimation(bottomLineLayer.angleDelta(bottomAngle), calculationMode: kCAAnimationCubic, keyTimes: (forwardDirection) ? [0.0, 0.33, 0.6, 1.0] : [0.0, 0.43, 0.73, 1.0])
            let bottomCurvePoint: CGPoint = CAShapeLayer.pointAlongQuadBezierPath(bottomPosition, toPoint: topPosition, controlPoint: leftControlPoint, percent: self.percentComplete)
            let bottomPartialCurveControlPoint: CGPoint = CAShapeLayer.pointAlongLine((forwardDirection) ? leftControlPoint : bottomPosition, endPoint: (forwardDirection) ? topPosition : leftControlPoint, t: self.percentComplete)
            
            bottomLineLayer.addPositionAnimation(bottomCurvePoint, toPoint: (forwardDirection) ? topPosition : bottomPosition, controlPoint: bottomPartialCurveControlPoint)
            
        }
        else {
            
        //animate top line
            let topAngle: CGFloat = (CGFloat(M_PI + M_PI_4) * percentComplete)
            let topRotation = CATransform3DRotate(topLineLayer.transform, topLineLayer.angleDelta(topAngle), 0, 0, 1)
            topLineLayer.transform = topRotation
            topLineLayer.position = CAShapeLayer.pointAlongQuadBezierPath(topPosition, toPoint:bottomPosition, controlPoint: rightControlPoint, percent: percentComplete)
            
        //animate middle line
            let rotation = CATransform3DRotate(midLineLayer.transform, midLineLayer.angleDelta(midAngle), 0, 0, 1)
            midLineLayer.transform = rotation
            
        //animate bottome line
            let bottomRotation = CATransform3DRotate(bottomLineLayer.transform, bottomLineLayer.angleDelta(bottomAngle), 0, 0, 1)
            bottomLineLayer.transform = bottomRotation
            bottomLineLayer.position = CAShapeLayer.pointAlongQuadBezierPath(bottomPosition, toPoint:topPosition, controlPoint: leftControlPoint, percent: percentComplete)
        }
    }
    
}










