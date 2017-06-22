//
//  NavBarViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/4/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
import AVKit
import MediaPlayer

struct iPhoneType
{
    static let IS_IPHONE_6          = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P         = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
}

class NavBarViewController: UIViewController, CTEAnimatedHamburgerDelegate, SwitcherViewDelegate {
    
    var willTransitionToPortrait : Bool = true;
    
    @IBOutlet weak var navBarView: UIView!
    @IBOutlet weak var navBarBottomContraint: NSLayoutConstraint!

    @IBOutlet weak var hamburgerButton: CTEAnimatedHamburgerView!
    var forwardDirection: Bool = true
    
    @IBOutlet var leftButton1Contraint: NSLayoutConstraint!
    @IBOutlet var leftButton2Constraint: NSLayoutConstraint!
    @IBOutlet var leftButton3Contraint: NSLayoutConstraint!
    @IBOutlet var leftButton4Constraint: NSLayoutConstraint!
    @IBOutlet var leftButton5Constraint: NSLayoutConstraint!
    @IBOutlet var leftButton6Constraint: NSLayoutConstraint!

    @IBOutlet weak var homeBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var messagesBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bibleBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var liveBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var eventsBarWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var locationsBarWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var logoTopContraint: NSLayoutConstraint!
    @IBOutlet weak var hamburgerTopContraint: NSLayoutConstraint!
    @IBOutlet weak var shareButtonTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var homeView: UIView!
    @IBOutlet weak var messagesView: UIView!
    @IBOutlet weak var bibleView: UIView!
    @IBOutlet weak var liveView: UIView!
    @IBOutlet weak var eventsView: UIView!
    @IBOutlet weak var locationsView: UIView!
    
    @IBOutlet weak var container: UIView!
    
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var avatarButton: UIButton!
    
    var switcher: SwitcherViewController!
    var isArrow = false
    var navBarOpen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switcher.delegate = self
        
        // [JG] Init the Hamburger Button
        if (hamburgerButton != nil) {
            hamburgerButton.lineThickness = 2.0
            hamburgerButton.backgroundColor = UIColor.clearColor()
            hamburgerButton.color = UIColor.whiteColor()
            hamburgerButton.delegate = self
            hamburgerButton.lineCapType = kCALineCapRound
            hamburgerButton.buttonType = .CTEAnimatedHamburgerTypeClose
        }
        
        // [JG] Set the bottom contraint of the nav bar menu
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
            if (self.view.frame.height > self.view.frame.width) {
                navBarBottomContraint.constant = self.view.frame.height - 66
            } else {
                self.formatNavBarForLandscape()
            }
        } else {
            navBarBottomContraint.constant = self.view.frame.height - 66
        }
        
        // [JG] Slide the naviagtion menu buttons off screen to animate in later
        self.moveNavButtonsOffScreen()
        
        // Show/Hide the Share and Avatar Buttons
        shareButton.hidden = true
        avatarButton.hidden = true
        
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
            self.reformatNavBarWhenVideoIsPlayed()
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // Show the Avatar button
        let children = switcher.childViewControllers as NSArray
        let lastVC: AnyObject = children.lastObject!
        if (lastVC.isKindOfClass(HomeViewController)) {
            self.avatarButton.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func moveNavButtonsOffScreen() {
        
        var rightSideOfScreen = self.view.frame.width + 10
        if self.view.frame.width < self.view.frame.height {
            rightSideOfScreen = self.view.frame.height + 10
        }
        
        // [JG] - Move buttons off screen until ready to animate
        leftButton1Contraint.constant = rightSideOfScreen
        leftButton2Constraint.constant = rightSideOfScreen
        leftButton3Contraint.constant = rightSideOfScreen
        leftButton4Constraint.constant = rightSideOfScreen
        leftButton5Constraint.constant = rightSideOfScreen
        leftButton6Constraint.constant = rightSideOfScreen
        
        self.homeView.hidden = false
        self.bibleView.hidden = false
        self.liveView.hidden = false
        self.eventsView.hidden = false
        self.locationsView.hidden = false
        self.messagesView.hidden = false
    }
    
    //MARK: CTEAnimatedHamburgerDelegate
    func didTapHamburgerView(view: CTEAnimatedHamburgerView, gesture: UITapGestureRecognizer) {
        if !isArrow {
            self.animateHamburgerToXAndBack()
        } else {
            self.animateFromHamburgerToArrow()
        }
    }
    
    // [JG] - I added a larger tap target behind the hamburger
    @IBAction func almostTappedHamburger(sender: AnyObject) {
        if !isArrow {
            self.animateHamburgerToXAndBack()
        } else {
            self.animateFromHamburgerToArrow()
        }
    }
    
    func animateHamburgerToXAndBack() {
        var percent: CGFloat = 0.0;
        let transition = hamburgerButton.isTransitionComplete()
        
        if !transition.isComplete {
            
            if forwardDirection {
                
                percent = 1.0
            }
        }
        else {
            
            if transition.percent >= 1.0 {
                percent = 0.0
                self.close()
            }
            else {
                percent = 1.0
                self.open()
            }
        }
        
        
        hamburgerButton.setPercentComplete(percent, animated: true)
    }
    
    func animateFromHamburgerToArrow() {
        var percent: CGFloat = 0.0;
        let transition = hamburgerButton.isTransitionComplete()
        
        if !transition.isComplete {
            
            if forwardDirection {
                
                percent = 1.0
            }
        }
        else {
            
            if transition.percent >= 1.0 {
                percent = 0.0
                
                let children = switcher.childViewControllers as NSArray
                let lastVC: AnyObject = children.lastObject!
                if (lastVC.isKindOfClass(MessagePlayerViewController)) {
                    NSNotificationCenter.defaultCenter().postNotificationName("removeMessageObserver", object: nil)
                    [switcher.switchToViewControllerWithSegue("Messages")]
                    self.shareButton.hidden = true
                } else if (lastVC.isKindOfClass(EventDetailsViewController)) {
                    [switcher.switchToViewControllerWithSegue("Events")]
                } else if (lastVC.isKindOfClass(LocationDetailsViewController)) {
                    [switcher.switchToViewControllerWithSegue("Locations")]
                } else {
                    [switcher.switchToViewControllerWithSegue("Home")]
                }
                hamburgerButton.buttonType = .CTEAnimatedHamburgerTypeClose
                isArrow = false
            }
            else {
                percent = 1.0
                isArrow = true
            }
        }
        
        hamburgerButton.setPercentComplete(percent, animated: true)
    }
    
    func open() {
        
        UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.navBarBottomContraint.constant = 0;
            self.view.layoutIfNeeded();
            }, completion: nil);
       
        var constraints = [leftButton1Contraint, leftButton2Constraint, leftButton3Contraint, leftButton4Constraint, leftButton5Constraint, leftButton6Constraint]
        var toValue = (self.view.frame.size.width - homeBarWidthConstraint.constant) / 2
        
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact) {
            constraints = [leftButton1Contraint, leftButton2Constraint, leftButton3Contraint]
            let widthOfButtons = self.homeBarWidthConstraint.constant + self.liveBarWidthConstraint.constant
            toValue = ((self.view.frame.size.width - widthOfButtons) / 2)
            // [JG] For some reason this calculation never works out right. So I hard coded it. We need to refactor this.
            if (DeviceType.IS_IPHONE_6) {
                toValue = 50
            }
        }
        
        // [JG] Loop through contraints and stagger them as the slide into the view
        var interval = 0.15
        for constraint in constraints {
            UIView.animateWithDuration(0.4, delay: interval, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                    constraint.constant = toValue;
                    self.view.layoutIfNeeded();
                }, completion: nil);
            interval = interval + 0.03
        }
        
        navBarOpen = true
    }
    
    func close() {
        
        self.homeView.hidden = true
        self.bibleView.hidden = true
        self.liveView.hidden = true
        self.eventsView.hidden = true
        self.locationsView.hidden = true
        self.messagesView.hidden = true
        
        var toValue = self.view.frame.height - 66
        
        if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact) {
            toValue = self.view.frame.height - 46
        }
        
        UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.navBarBottomContraint.constant = toValue;
            self.view.layoutIfNeeded();
            }, completion: nil);
  
        // move after menu is closed
        delay(0.5, closure: { () -> () in
            self.moveNavButtonsOffScreen()
        })
        navBarOpen = false
    }
    
    @IBAction func shareMessageTapped(sender: AnyObject) {
        let children = switcher.childViewControllers as NSArray
        let lastVC: AnyObject = children.lastObject!
        if (lastVC.isKindOfClass(MessagePlayerViewController)) {
            NSNotificationCenter.defaultCenter().postNotificationName("shareMessageNotification", object: self)
        }
    }
    
    @IBAction func avatarMessageTapped(sender: AnyObject) {
        let children = switcher.childViewControllers as NSArray
        let lastVC: AnyObject = children.lastObject!
        if (lastVC.isKindOfClass(HomeViewController)) {
            NSNotificationCenter.defaultCenter().postNotificationName("avatarPressedNotification", object: self)
        }
    }
    
    // MARK: Switcher View Delegate
    func webViewIsVisibleSoShowBackButton() {
        // Swith from X in the menu to a BACK arrow
        hamburgerButton.buttonType = .CTEAnimatedHamburgerTypeBack
        self.animateFromHamburgerToArrow()
    }
    
    //MARK: Navigation Logic
    @IBAction func goToHome(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("Home")]
        self.animateHamburgerToXAndBack()
    }
    
    @IBAction func goToMessages(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("Messages")]
        self.animateHamburgerToXAndBack()
    }
    
    @IBAction func goToBible(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("Bible")]
        self.animateHamburgerToXAndBack()
    }

    @IBAction func goToLive(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("Live")]
        self.animateHamburgerToXAndBack()
    }
    
    @IBAction func goToEvents(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("Events")]
        self.animateHamburgerToXAndBack()
    }
    
    @IBAction func goToLocations(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("Locations")]
        self.animateHamburgerToXAndBack()
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "Switcher") {
            switcher = segue.destinationViewController as! SwitcherViewController;
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        willTransitionToPortrait = self.view.frame.size.height > self.view.frame.size.width
    }
    
    @available(iOS 8.0, *)
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        willTransitionToPortrait = size.height > size.width
        
        if !navBarOpen {
            self.navBarBottomContraint.constant = willTransitionToPortrait ? self.view.frame.width - 66 : self.view.frame.height - 66
        }
        
        // [JG] - This is all for the wierd navbar stuff that the landscape iPhone version does
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
            
            
            if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Regular) {
                
                // Manually hide the status bar here b/c of the Message Video issues
                UIApplication.sharedApplication().statusBarHidden = true
                
                // Transition to Landscape
                if !navBarOpen {
                    self.formatNavBarForLandscape()
                } else {
                    // [JG] - Animate centering the buttons
                    let constraints = [leftButton1Contraint, leftButton2Constraint, leftButton3Contraint]

                    // [JG] Loop through contraints and stagger them as the slide into the view
                    var interval = 0.15
                    
                    for constraint in constraints {
                        UIView.animateWithDuration(0.4, delay: interval, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                            constraint.constant = 50;
                            self.view.layoutIfNeeded();
                            }, completion: nil);
                        interval = interval + 0.03
                    }
                
                    // format for landscape without Status Bar
                    self.logoTopContraint.constant = self.logoTopContraint.constant - 15
                    self.hamburgerTopContraint.constant = self.hamburgerTopContraint.constant - 15
                    self.shareButtonTopConstraint.constant = self.shareButtonTopConstraint.constant - 15
                    
                }
            } else {
                // Portrait
                UIApplication.sharedApplication().statusBarHidden = false
                
                if navBarOpen {
                    if (DeviceType.IS_IPHONE_6P) {
                        // Reset the bottom 3 constraints when rotating from Landscape to Portrait with the menu open.
                        leftButton4Constraint.constant = leftButton1Contraint.constant
                        leftButton5Constraint.constant = leftButton1Contraint.constant
                        leftButton6Constraint.constant = leftButton1Contraint.constant
                    } else if (DeviceType.IS_IPHONE_6) {
                        let constraints = [leftButton1Contraint, leftButton2Constraint, leftButton3Contraint, leftButton4Constraint, leftButton5Constraint, leftButton6Constraint]
                        let toValue = (self.view.frame.size.height - homeBarWidthConstraint.constant) / 2
                        
                        for constraint in constraints {
                            constraint.constant = toValue;
                        }
                    }
                }
                
                // This is to work around a Navbar height bug when exiting a video
                // Can't wait to ditch this nav bar/ menu
                let children = switcher.childViewControllers as NSArray
                let lastVC: AnyObject = children.lastObject!
                if (lastVC.isKindOfClass(MessagePlayerViewController)) {
                    self.navBarBottomContraint.constant = self.view.frame.height - 66
                }
        
                // format for portrait with Status Bar
                if (logoTopContraint.constant != 26) {
                    self.logoTopContraint.constant = self.logoTopContraint.constant + 15
                    self.hamburgerTopContraint.constant = self.hamburgerTopContraint.constant + 15
                    self.shareButtonTopConstraint.constant = self.shareButtonTopConstraint.constant + 15
                }
            }
        } else {
            if !navBarOpen {
                // [JG] - This is a little hack to get around the issue where the navbar is too short on landscape.
                self.navBarBottomContraint.constant = willTransitionToPortrait ? self.navBarBottomContraint.constant : self.view.frame.width - 66
            } else {
                print(willTransitionToPortrait)
                if !willTransitionToPortrait {
                    let constraints = [leftButton1Contraint, leftButton2Constraint, leftButton3Contraint, leftButton4Constraint, leftButton5Constraint, leftButton6Constraint]
                    let toValue = (self.view.frame.size.height - homeBarWidthConstraint.constant) / 2
                    
                    for constraint in constraints {
                        constraint.constant = toValue;
                    }
                } else {
                    let constraints = [leftButton1Contraint, leftButton2Constraint, leftButton3Contraint, leftButton4Constraint, leftButton5Constraint, leftButton6Constraint]
                    let toValue = (self.view.frame.size.height - homeBarWidthConstraint.constant) / 2
                    
                    for constraint in constraints {
                        constraint.constant = toValue;
                    }
                }
            }
        }
    }
    
    @available(iOS 8.0, *)
    override func overrideTraitCollectionForChildViewController(childViewController: UIViewController) -> UITraitCollection? {
        let traitCollection_hRegular : UITraitCollection = UITraitCollection(verticalSizeClass: .Regular)
        let traitCollection_wRegular : UITraitCollection = UITraitCollection(horizontalSizeClass: .Regular)
        let traitCollection_wCompact : UITraitCollection = UITraitCollection(horizontalSizeClass: .Compact)
        
        // iPad Landscape
        let traitCollectionCompact_Regular = UITraitCollection(traitsFromCollections: [traitCollection_wCompact, traitCollection_hRegular])
        // iPad Portrait
        let traitCollectionRegular_Regular = UITraitCollection(traitsFromCollections: [traitCollection_hRegular, traitCollection_wRegular])

        let traitCollection = (willTransitionToPortrait) ? traitCollectionCompact_Regular : traitCollectionRegular_Regular
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            return traitCollection
        } else {
            return self.traitCollection
        }
    }
    
    func formatNavBarForLandscape() {
        if self.logoTopContraint.constant == 26 {
            self.navBarBottomContraint.constant = self.view.frame.height - 46
            self.logoTopContraint.constant = self.logoTopContraint.constant - 15
            self.hamburgerTopContraint.constant = self.hamburgerTopContraint.constant - 15
            self.shareButtonTopConstraint.constant = self.shareButtonTopConstraint.constant - 15
        }
        
        if self.navBarBottomContraint.constant == self.view.frame.height - 66 {
            self.navBarBottomContraint.constant = self.view.frame.height - 46
        }
    }
    
    // This is to fix all of the wierd orientation issues caused by the video.
    // This is triggered by the movie player when you tap done
    func reformatNavBarWhenVideoIsPlayed() {
        let toValue = self.view.frame.height - 66
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
                if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Regular) {
                    // iPhone Portrait
                    if (!navBarOpen && self.navBarBottomContraint.constant != toValue) {
                        self.navBarBottomContraint.constant = toValue
                        self.logoTopContraint.constant = 26
                        self.hamburgerTopContraint.constant = 26
                        self.shareButtonTopConstraint.constant = 26
                        
                        // Start video in landscape and rotate to portrait it would hide status bar
                        UIApplication.sharedApplication().statusBarHidden = false
                    }
                } else {
                    // iPhone Landscape
                    
                }
        } else {
            // iPad
            if (!navBarOpen && self.navBarBottomContraint.constant != toValue) {
                // I don't know why but it this fires normally it won't close the navbar. Super annoying.
                delay(0.20, closure: { () -> () in
                    self.navBarBottomContraint.constant = toValue
                })
            }
        }
        
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
