//
//  PlusButton.swift
//  OpenCollectionView
//
//  Created by Raiden Honda on 9/23/15.
//  Copyright © 2015 Beloved Robot. All rights reserved.
//

import UIKit
@IBDesignable
class PlusButton: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 0.937, green: 0.965, blue: 0.957, alpha: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func drawRect(rect: CGRect) {
        let color = UIColor(red:0.604, green: 0.604, blue: 0.604, alpha: 1.0)
        let textRect = CGRectMake(7, 2, 10, 18)
        let textContent: NSString = "+"
        let font: AnyObject = UIFont(name: "Avenir-Heavy", size: 15)!
        textContent.drawInRect(textRect, withAttributes:[NSFontAttributeName: font, NSForegroundColorAttributeName: color])
    }
}
