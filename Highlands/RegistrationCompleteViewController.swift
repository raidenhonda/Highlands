//
//  RegistrationCompleteViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 1/25/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

class RegistrationCompleteViewController : UIViewController {
    
    override func viewDidLoad() {
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    @IBAction func donePressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)

//        NSNotificationCenter.defaultCenter().postNotificationName("dismissSingleSignOnFlowNotification", object: nil)
    }
    
    
    // Keep only portrait orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
}
