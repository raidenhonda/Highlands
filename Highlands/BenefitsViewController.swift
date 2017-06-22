//
//  BenefitsViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 1/13/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

class BenefitsViewController : UIViewController {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var logoTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var doYouHaveALabel: UILabel!
    @IBOutlet weak var highlandsIDLabel: UILabel!
    
    @IBOutlet weak var withYourHighlandsIDLabel: UILabel!
    
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
    }
    
    override func viewDidAppear(animated: Bool) {
        let height = self.view.frame.height
        
        // Fade in Big Logo
        UIView.animateWithDuration(0.5, delay: 0.2, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.logoImageView.layer.opacity = 1.0
            }, completion: nil)
        
        // Sliding Big Logo up a bit
        UIView.animateWithDuration(0.8, delay: 0.2, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            
            var topConstraintConstant = height * 0.10
            if DeviceType.IS_IPHONE_5_OR_LESS {
                topConstraintConstant = 10
            }            
            self.logoTopConstraint.constant = topConstraintConstant
            self.view.layoutIfNeeded()
            }, completion: nil)

        // Fade in "Do You Have a HIGHLANDS ID"
        UIView.animateWithDuration(0.6, delay: 0.8, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.doYouHaveALabel.layer.opacity = 1.0
            self.highlandsIDLabel.layer.opacity = 1.0
            }, completion: nil)
        
        // Fade in "With Your Highlands ID You Can"
        UIView.animateWithDuration(0.6, delay: 1.6, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.withYourHighlandsIDLabel.layer.opacity = 1.0
            }, completion: nil)
        
        // Fade in Button
        UIView.animateWithDuration(0.5, delay: 2.0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.button.layer.opacity = 1.0
            }, completion: nil)
        
    }
    
    override func didReceiveMemoryWarning() {
    }
    
    @IBAction func skipButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Sign Up Segue
        if (segue.identifier == "registerSegue") {
            self.addChildViewController(segue.destinationViewController as! SignInViewController)
            let destinationView = (segue.destinationViewController as! SignInViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        }
    }
    
    // Keep only portrait orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
}
