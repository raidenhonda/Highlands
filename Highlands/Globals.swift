//
//  Globals.swift
//  Highlands
//
//  Created by Raiden Honda on 1/21/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

public class Globals {
    
    static let notesSyncedNotification = "NotesSyncNotification"
    
    static var userIsSignedIn : Bool {
        get {
            return Globals.oauthToken != nil
        }
    }
    
    static var oauthToken : String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("OAuthToken")
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "OAuthToken")
        }
    }
    
    static var currentUser : String? {
        get {
            return NSUserDefaults.standardUserDefaults().stringForKey("OAuthToken")
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "OAuthToken")
        }
    }
    
    static var currentUserF1Id : String? {
        get {
        return NSUserDefaults.standardUserDefaults().stringForKey("F1UserId")
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: "F1UserId")
        }
    }
    
    static var hasSignedInBefore : Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey("hasSignedInBefore")
        }
        set {
            NSUserDefaults.standardUserDefaults().setObject(true, forKey: "hasSignedInBefore")
        }
    }
    
    
    static func clearCurrentUser() {
        self.oauthToken = nil
        self.currentUser = nil
        self.currentUserF1Id = nil
    }
}
