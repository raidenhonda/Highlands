//
//  SwiftyJSONExtensions.swift
//  Highlands
//
//  Created by Raiden Honda on 5/26/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import Foundation

extension JSON {
    
    //Optional universal date
    public var universalDate: NSDate? {
        get {
            switch self.type {
            case .String:
                let formatter = NSDateFormatter()
                let timeString = self.object as! String
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZ"
                _ = formatter.dateFromString(timeString)
                return formatter.dateFromString(timeString)
            default:
                return nil
            }
        }
    }
    
    //Optional "short-hand" date
    public var shortHandDate: NSDate? {
        get {
            switch self.type {
            case .String:
                let formatter = NSDateFormatter()
                let timeString = self.object as! String
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                _ = formatter.dateFromString(timeString)
                return formatter.dateFromString(timeString)
            default:
                return nil
            }
        }
    }
}

extension NSDate {
    public func toLocalString() -> String {
        let dateFormatter : NSDateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        return dateFormatter.stringFromDate(self);
    }
    
    public func toShortDateString() -> String {
        let dateFormatter : NSDateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        
        return dateFormatter.stringFromDate(self);
    }
}
