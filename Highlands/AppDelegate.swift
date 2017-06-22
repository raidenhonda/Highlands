//
//  AppDelegate.swift
//  Highlands
//
//  Created by Raiden Honda on 4/28/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
import MediaPlayer
import Parse
import AVFoundation
import HockeySDK
import CoreSpotlight

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        // Setup Parse, NewRelic, and HockeyApp
        Parse.setApplicationId("HjPp2t4hw6kOI61j0urNP06C7Ma6oCghj2KtWDtS", clientKey: "t9V2twq1VRYO2wPRyiR6pVnj2pEidKTeP4ETEiA2")
        
        NewRelicAgent.startWithApplicationToken("AA87619fa4e89be5ebcad29ca9a9dadfa7c7d12726")
        
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier("b9556da6c4851da4faa268bee5c22746")
        BITHockeyManager.sharedHockeyManager().startManager()
        
        // Register for Push Notitications
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: { (success, error) -> Void in
                    if !success {
                        print("Parse Error: \(error)")
                    }
                })
            }
        }
        
        if application.respondsToSelector("registerUserNotificationSettings:") {
            
            // Register for notifications
            if #available(iOS 8.0, *) {
                let notificationSettings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Sound, UIUserNotificationType.Alert], categories: nil)
                UIApplication.sharedApplication().registerUserNotificationSettings(notificationSettings)
                
                let settings = UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Sound], categories: nil)
                application.registerUserNotificationSettings(settings)
                application.registerForRemoteNotifications()
            } else {
                application.registerForRemoteNotificationTypes([UIRemoteNotificationType.Alert, UIRemoteNotificationType.Sound])
            }
        }
  
        // Setup Airplay - This sets allows Airplay to run while phone is asleep
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
 
        // Set up URL Cache
        let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
        NSURLCache.setSharedURLCache(URLCache)
        
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackgroundWithBlock(nil)
    }

    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        }
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {

        // Sync Notes if there's a user
        if (Globals.userIsSignedIn) {
            NotesManager.syncNotes()
        }
        completionHandler(.NoData)
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        print("Host is -> \(url.host)")
        print("Path is -> \(url.path)")
        print("Query is -> \(url.query)")

        // Parse Query String
        let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)
        
        // If SSO registration callback
        if url.host == "sso" && url.path == "/registrationCallback" {
            // Push to Sign In Controller
            let navBarController = self.window?.rootViewController as? NavBarViewController
            if let navBar = navBarController {
                let userCipher : String? = urlComponents?.queryItems?.filter({ (item) in item.name == "up" }).first?.value
                navBar.switcher.goToSignInView(userCipher)
            }
        }
        
        return true
    }
    
    func application(application: UIApplication, continueUserActivity userActivity: NSUserActivity, restorationHandler: [AnyObject]? -> Void) -> Bool {
        if #available(iOS 9.0, *) {
            if userActivity.activityType == CSSearchableItemActionType {
                
                // If the identifier is returned then map the identifiers
                if let uniqueIdentifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String {
                    
                    // Split the string into it's parts, original form is "message-id^series-id"
                    let idArray = uniqueIdentifier.characters.split{$0 == "^" }.map(String.init)
                    // Both need to be returned so check for two pieces
                    if (idArray.count == 2) {
                        let messageId = idArray[0]
                        let seriesId = idArray[1]
                        
                        let params = MessagePlayerViewControllerParameters()
                        params.messageIdentifier = messageId
                        params.seriesIdentifier = seriesId
                        
                        // Push to Message Player View Controller
                        let navBarController = self.window?.rootViewController as? NavBarViewController
                        if let navBar = navBarController {
                            navBar.switcher.goToMessagePlayerView(params)
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    @available(iOS 9.0, *)
    func application(application: UIApplication, performActionForShortcutItem shortcutItem: UIApplicationShortcutItem, completionHandler: (Bool) -> Void) {
        print("Quick action is \(shortcutItem.type)")
        
        let quickAction = shortcutItem.type
        if quickAction == "OneYearBibleQuickAction" {
            // Push to One Year Bible
            let navBarController = self.window?.rootViewController as? NavBarViewController
            if let navBar = navBarController {
                navBar.switcher.switchToViewControllerWithSegue("Bible")
            }
        } else if quickAction == "LiveQuickAction" {
            // Push to Live
            let navBarController = self.window?.rootViewController as? NavBarViewController
            if let navBar = navBarController {
                navBar.switcher.switchToViewControllerWithSegue("Live")
            }
        }
        
        completionHandler(true)
    }
//    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> Int {
//        
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad) {
//            return Int(UIInterfaceOrientationMask.All.rawValue)
//        } else {
//            return Int(UIInterfaceOrientationMask.Portrait.rawValue)
//        }
//
//    }

}

