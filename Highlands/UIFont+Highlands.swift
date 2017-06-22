//
//  UIFont+Highlands.swift
//  Highlands
//
//  Created by Raiden Honda on 9/14/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    class func highlandsBold(size: CGFloat) -> UIFont {
        return UIFont(name: "GothamBold", size: size)!
    }
    
    class func highlandsMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "GothamMedium", size: size)!
    }
    
    class func highlandsMediumItalic(size: CGFloat) -> UIFont {
        return UIFont(name: "GothamMedium-Italic", size: size)!
    }
    
    class func highlandsBook(size: CGFloat) -> UIFont {
        return UIFont(name: "GothamBook", size: size)!
    }
}
