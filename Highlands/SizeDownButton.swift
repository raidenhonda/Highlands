//
//  SizeDownButton.swift
//  Highlands
//
//  Created by Raiden Honda on 6/24/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

@IBDesignable
class SizeDownButton: UIButton {
    
    var selectionState : Bool = false

    override func drawRect(rect: CGRect) {
        
        var backgroundColor = UIColor.clearColor()
        if selectionState {
            backgroundColor = UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1.0)
        }
        
        let roundedRectPath = UIBezierPath(roundedRect: CGRect(x: 1, y: 1, width: self.frame.width - 2, height: self.frame.height - 2), byRoundingCorners: [.TopRight, .BottomRight] , cornerRadii: CGSize(width: 6, height: 6))
        roundedRectPath.closePath()
        backgroundColor.setFill()
        roundedRectPath.fill()
        UIColor(red: 0.33, green: 0.33, blue: 0.33, alpha: 1.0).setStroke()
        roundedRectPath.lineWidth = 2
        roundedRectPath.stroke()

    }
    
    func setSelected() {
        selectionState = true
        self.setNeedsDisplay()
        self.delay(0.075, closure: {
            self.selectionState = false
            self.setNeedsDisplay()
        })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }

}
