//
//  TimeBubble.swift
//  Highlands
//
//  Created by Raiden Honda on 5/18/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class TimeBubble : UIView {
    
    var timeString : String
    var date : NSDate
    
    required init?(coder aDecoder: NSCoder) {
        timeString = ""
        date = NSDate()
        
        super.init(coder: aDecoder)
    }
    
    init (point : CGPoint, timeString : String, date : NSDate) {
        self.timeString = timeString;
        self.date = date
        
        // The circle has a default size set here
        let frame : CGRect = CGRectMake(point.x, point.y, 80, 80) // *** set the default size here ***
        
        // Super init and other properties
        super.init(frame : frame)
        self.frame = frame
        self.backgroundColor = UIColor.whiteColor()
    }
    
    override func drawRect(rect: CGRect) {
        
        // Draw the circle
        let lineWidth : CGFloat = 5.0 // *** Set the line width here ***
        let boundedRect : CGRect = CGRectMake(rect.origin.x + lineWidth, rect.origin.y + lineWidth, rect.width - (lineWidth*2), rect.height - (lineWidth*2))
        let outerRing : UIBezierPath = UIBezierPath(ovalInRect: boundedRect);
        outerRing.lineWidth = 5;
        let color : UIColor = UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0)
        color.setStroke()
        outerRing.stroke()
        
//        // Ensure text will fit
//        let textAttritubes = [NSFontAttributeName : UIFont.fontNamesForFamilyName("") UIFont.systemFontOfSize(15.0)]; // *** Set the font size here ***
//        let textSize : CGSize = timeString.sizeWithAttributes(textAttritubes)
//        if (rect.width < textSize.width || rect.height < textSize.height) {
//            fatalError("The time string is too big for the bubble size")
//        }
        
        // Draw the text
//        let x : CGFloat = (rect.width - textSize.width) / 2.0;
//        let y : CGFloat = (rect.height - textSize.height) / 2.0;
//        timeString.drawAtPoint(CGPointMake(x, y), withAttributes: textAttritubes);
    }
    
}
