    //
//  SwitcherViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/6/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
    
    protocol SwitcherViewDelegate {
        func webViewIsVisibleSoShowBackButton()
    }

class SwitcherViewController: UIViewController, HomeViewWebDelegate, MessagesViewDelegate, EventsViewDelegate, LocationsViewDelegate {

    var delegate : SwitcherViewDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // [JG] Load Home View when the app launches
        self.performSegueWithIdentifier("Home", sender: "")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func switchToViewControllerWithSegue(segueIdentifier: String) {
        self.performSegueWithIdentifier(segueIdentifier, sender: nil)
    }
    
    func goToWebView(url: String) {
        self.delegate.webViewIsVisibleSoShowBackButton()
        self.performSegueWithIdentifier("WebView", sender: url)
    }
    
    func goToMessagePlayerView(messageParams: MessagePlayerViewControllerParameters) {
        self.delegate.webViewIsVisibleSoShowBackButton()
        self.performSegueWithIdentifier("MessagePlayer", sender: messageParams)
        let navBarVC = self.parentViewController as! NavBarViewController
        navBarVC.shareButton.hidden = false
    }
    
    func goToEventDetails(eventDetails: EventDetailsViewControllerParameters) {
        self.delegate.webViewIsVisibleSoShowBackButton()
        self.performSegueWithIdentifier("EventDetails", sender: eventDetails)
    }
    
    func goToLocationDetails(locationDetails: LocationDetailsViewControllerParameters) {
        self.delegate.webViewIsVisibleSoShowBackButton()
        self.performSegueWithIdentifier("LocationDetails", sender: locationDetails)
    }
    
    func goToSignInView(registrationCipher: String?) {
        // Switch this to a Modal Presentation
        self.performSegueWithIdentifier("SignInFromRoot", sender: registrationCipher)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Remove/deallocate Child View Controllers
        for child in self.childViewControllers {
//            let childMirror = Mirror(reflecting: child)
//            print("Child is \(childMirror.subjectType)")
            
            child.willMoveToParentViewController(child.parentViewController)
            child.view.removeFromSuperview()
            child.didMoveToParentViewController(self)
            child.removeFromParentViewController()
        }
        
        // Hide Share/Avatar Buttons
        if let navBarVC = self.parentViewController as? NavBarViewController {
            navBarVC.shareButton.hidden = true
            navBarVC.avatarButton.hidden = true
        }
        
        if (segue.identifier == "Home") {
            self.addChildViewController(segue.destinationViewController as! HomeViewController)
            let destinationView = (segue.destinationViewController as! HomeViewController).view
            // [JG] Hold onto an instance of the switcher for the Home View Controller to use
            (segue.destinationViewController as! HomeViewController).switcher = self;
            (segue.destinationViewController as! HomeViewController).delegate = self;
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
            
            // Show Avatar Button
            if let navBarVC = self.parentViewController as? NavBarViewController {
                navBarVC.avatarButton.hidden = false
            }
        } else if (segue.identifier == "Messages") {
            self.addChildViewController(segue.destinationViewController as! MessagesViewController)
            let destinationView = (segue.destinationViewController as! MessagesViewController).view
            (segue.destinationViewController as! MessagesViewController).delegate = self;
            destinationView.autoresizingMask = [.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "Bible") {
            self.addChildViewController(segue.destinationViewController as! BibleViewController)
            let destinationView = (segue.destinationViewController as! BibleViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "Live") {
            self.addChildViewController(segue.destinationViewController as! LiveViewController)
            let destinationView = (segue.destinationViewController as! LiveViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "Events") {
            self.addChildViewController(segue.destinationViewController as! EventsViewController)
            let destinationView = (segue.destinationViewController as! EventsViewController).view
            (segue.destinationViewController as! EventsViewController).delegate = self;
            destinationView.autoresizingMask = [.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "Locations") {
            self.addChildViewController(segue.destinationViewController as! LocationsViewController)
            let destinationView = (segue.destinationViewController as! LocationsViewController).view
            (segue.destinationViewController as! LocationsViewController).delegate = self;
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "WebView") {
            self.addChildViewController(segue.destinationViewController as! WebViewController)
            let destinationView = (segue.destinationViewController as! WebViewController).view
            // [JG] - Set base url for webview
            (segue.destinationViewController as! WebViewController).baseUrl = sender as! String
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "MessagePlayer") {
            self.addChildViewController(segue.destinationViewController as! MessagePlayerViewController)
            (segue.destinationViewController as! MessagePlayerViewController).messagePlayerParameters = sender as! MessagePlayerViewControllerParameters
            let destinationView = (segue.destinationViewController as! MessagePlayerViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
            
            // Show Avatar Button
            if let navBarVC = self.parentViewController as? NavBarViewController {
                navBarVC.shareButton.hidden = false
            }
        } else if (segue.identifier == "EventDetails") {
            self.addChildViewController(segue.destinationViewController as! EventDetailsViewController)
            (segue.destinationViewController as! EventDetailsViewController).eventParameters = sender as! EventDetailsViewControllerParameters
            let destinationView = (segue.destinationViewController as! EventDetailsViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "LocationDetails") {
            self.addChildViewController(segue.destinationViewController as! LocationDetailsViewController)
            (segue.destinationViewController as! LocationDetailsViewController).locationParameters = sender as! LocationDetailsViewControllerParameters
            let destinationView = (segue.destinationViewController as! LocationDetailsViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "AboutUs") {
            self.addChildViewController(segue.destinationViewController as! AboutUsViewController)
            let destinationView = (segue.destinationViewController as! AboutUsViewController).view
            // [JG] - Set base url for webview
//            (segue.destinationViewController as! AboutUsViewController).baseUrl = sender as! String
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        } else if (segue.identifier == "SingleSignOn") {
            self.addChildViewController(segue.destinationViewController as! BenefitsViewController)
            let destinationView = (segue.destinationViewController as! BenefitsViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        }  else if (segue.identifier == "SignInFromRoot") {
            let signInVC = segue.destinationViewController as! SignInViewController
            signInVC.registrationCipher = sender as? String
            self.addChildViewController(signInVC)
            let destinationView = (signInVC).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        }
    }
}
