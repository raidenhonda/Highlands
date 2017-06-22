//
//  SignOnViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 1/7/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation
import UIKit

class RegisterViewController : UIViewController, UITextFieldDelegate {

    @IBOutlet weak var firstName: UITextField!
    @IBOutlet weak var lastName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var haveAnAccountButton: UIButton!
    @IBOutlet weak var errorBoxTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var createAccountButton: UIButton!
    @IBOutlet weak var errorBox: UIView!
    
    @IBOutlet weak var spinnerContainer: UIView!
    var spinner : LLARingSpinnerView = LLARingSpinnerView()
    
    override func viewDidLoad() {
        // *** UI ***
        firstName.attributedPlaceholder = NSAttributedString(string:firstName.placeholder!, attributes:[NSForegroundColorAttributeName: UIColor(white: 0.55, alpha: 1.0)])
        firstName.delegate = self
        firstName.tintColor = UIColor.highlandsBlue()
        
        lastName.attributedPlaceholder = NSAttributedString(string:lastName.placeholder!, attributes:[NSForegroundColorAttributeName: UIColor(white: 0.55, alpha: 1.0)])
        lastName.delegate = self
        lastName.tintColor = UIColor.highlandsBlue()
        
        email.attributedPlaceholder = NSAttributedString(string:email.placeholder!, attributes:[NSForegroundColorAttributeName: UIColor(white: 0.55, alpha: 1.0)])
        email.delegate = self
        email.tintColor = UIColor.highlandsBlue()
        
        self.errorBox.hidden = true

        spinnerContainer.hidden = true
        spinner = LLARingSpinnerView.init(frame:CGRectMake(0.0, 0.0, 45.0, 45.0))
        spinner.lineWidth = 3.0
        spinner.tintColor = UIColor(white: 1.0, alpha: 1.0)
        spinnerContainer.addSubview(spinner)
        
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
    }
    
    @IBAction func createAccountAction(sender: AnyObject) {
        // First disable button so form is not submitted twice
        createAccountButton.enabled = false
        createAccountButton.alpha = 0.4
        
        spinner.startAnimating()
        spinnerContainer.hidden = false
        
        // Validate form fields
        if (firstName.text == nil || firstName.text == "" || lastName.text == nil || lastName.text == "" ||
            email.text == nil || email.text == "") {
               
                errorLabel.text = "Please provide first name, last name, email, and password."
                self.popOutErrorBox()
                
                createAccountButton.enabled = true
                createAccountButton.alpha = 1.0
                return;
        }
        
        let json = "{ \"account\" : { \"firstName\" : \"\(firstName.text!)\", \"lastName\" : \"\(lastName.text!)\", \"email\" : \"\(email.text!)\" } }"

        do {
            // Encrypt the username/password
            var cipher = try HighlandsAES().encrypt(json)
            
            // URL encode the cipher
            cipher = cipher.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            
            // Encrypt email for return from registration
            var emailCipher = try HighlandsAES().encrypt(email.text!)
            emailCipher = emailCipher.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
            
            // Now that we have cipher, retrieve token from SSO endpoint
            // Set the authorization header value
            let headerDict = [
                "Authorization" : "Token token=9b9b943e7e5f16937d864e70d580bf9e",
                "Content-Type" : "application/x-www-form-urlencoded"
            ]
            
            // Set the Url
            let registrationPostUrl = "https://sso.highlandsapp.com/api/v1/registrations?redirect=highlands://sso/registrationCallback?up=\(emailCipher)"
            
            // Set the parameters
            let parameters = [
                "up" : cipher
            ]

            // Send the request
            request(.POST, registrationPostUrl, parameters: parameters, headers: headerDict)
                .responseJSON { request, response, data in
                    if response?.statusCode == 200 {
                        
                        // Set this user default so that they user won't see the benifits view again. 
                        Globals.hasSignedInBefore = true
                        
                        print("Registration successful")
                        self.performSegueWithIdentifier("registerCompleteSegue", sender: nil)
                        self.fadeOutSpinnerView()
                    } else {
                        self.errorLabel.text = "Sorry, but we're having trouble registering you. Please try again in a few minutes."
                        self.popOutErrorBox()
                        self.createAccountButton.enabled = true
                        self.createAccountButton.alpha = 1.0
                    }
                }
        } catch {
            errorLabel.text = "Sorry, but we're having trouble signing you in. Please try again in a few minutes."
            self.popOutErrorBox()
            createAccountButton.enabled = true
            createAccountButton.alpha = 1.0
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Sign In Segue
        if (segue.identifier == "signInSegue") {
            self.addChildViewController(segue.destinationViewController as! SignInViewController)
            let destinationView = (segue.destinationViewController as! SignInViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        }
        
        if (segue.identifier == "registerCompleteSegue") {
            self.addChildViewController(segue.destinationViewController as! RegistrationCompleteViewController)
            let destinationView = (segue.destinationViewController as! RegistrationCompleteViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        }
    }
    
    func popOutErrorBox() {
        
        self.fadeOutSpinnerView()
        
        self.errorBox.hidden = false
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.errorBoxTopConstraint.constant = -20
            self.view.layoutIfNeeded()
            }, completion: { (_) -> Void in
                UIView.animateWithDuration(0.4, delay: 2.7, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                    self.errorBoxTopConstraint.constant = -100
                    self.view.layoutIfNeeded()
                    }, completion: { (_) -> Void in
                        self.errorBox.hidden = true
                })
                
        })
    }
    
    @IBAction func skipButtonPressed(sender: AnyObject) {
        self.errorBox.hidden = true
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // Dismiss Keyboard if you tap off the keyboard
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // MARK: UITextFieldDelegate Methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == firstName) {
            lastName.becomeFirstResponder()
        }
        
        if (textField == lastName) {
            email.becomeFirstResponder()
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.placeholder = ""
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == self.firstName {
            textField.placeholder = "FIRST NAME"
        }
        
        if textField == self.lastName {
            textField.placeholder = "LAST NAME"
        }
        
        if textField == self.email {
            textField.placeholder = "EMAIL"
        }
    }
    
    func fadeOutSpinnerView() {
        
        UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
            self.spinnerContainer.layer.opacity = 0
            }, completion: nil);
        
        self.delay(0.35, closure: {
            self.spinner.stopAnimating()
            self.spinnerContainer.hidden = true
        })
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    // Keep only portrait orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
}
