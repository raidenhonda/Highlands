//
//  SignOnViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 1/13/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation

class SignInViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var errorLabel1: UILabel!
    @IBOutlet weak var errorBoxTopConstraint1: NSLayoutConstraint!
    @IBOutlet weak var errorBox1: UIView!
    @IBOutlet weak var signInButton: UIButton!
    var registrationCipher : String? = nil
    
    @IBOutlet weak var spinnerContainer: UIView!
    var baseUrl : String = ""
    var spinner : LLARingSpinnerView = LLARingSpinnerView()

    
    override func viewDidLoad() {
 
        email.attributedPlaceholder = NSAttributedString(string:email.placeholder!, attributes:[NSForegroundColorAttributeName: UIColor(white: 0.55, alpha: 1.0)])
        email.delegate = self
        email.tintColor = UIColor.highlandsBlue()
        
        password.attributedPlaceholder = NSAttributedString(string:password.placeholder!, attributes:[NSForegroundColorAttributeName: UIColor(white: 0.55, alpha: 1.0)])
        password.delegate = self
        password.tintColor = UIColor.highlandsBlue()

        self.errorBox1.hidden = true
        
        // If cipher is present decrypt and set values
        if let cipher = registrationCipher {
            let value = try! HighlandsAES().decrypt(cipher)
            email.text = value
        }
        
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
    
    @IBAction func signInPressed(sender: AnyObject) {
        // Resign Responders
        email.resignFirstResponder()
        password.resignFirstResponder()
        errorLabel1.hidden = true // Hide label in case of previous error
        
        // First disable button so form is not submitted twice
        signInButton.enabled = false
        signInButton.alpha = 0.4
        
        // Start Spinner
        spinner.startAnimating()
        spinnerContainer.hidden = false
        
        // Validate form fields
        if (email.text == nil || email.text == "" || password.text == nil || password.text == "") {
            errorLabel1.text = "Please provide email and password."
            self.popOutErrorBox()
            signInButton.enabled = true
            signInButton.alpha = 1.0
            return;
        }
        
        let secret = "\(email.text!) \(password.text!)"
//        let secret = "zane@belovedrobot.com WmjIR/5KS!5sLn1UQz<." // Test
        
        do {
            // Encrypt the username/password
            var cipher = try HighlandsAES().encrypt(secret)
        
            // URL encode the cipher
            cipher = cipher.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!

            // *** Debugging options
//            print("My cipher is \(cipher)")
//            let mySecret = try! HighlandsAES().decrypt(cipher.stringByRemovingPercentEncoding!)
//            print("My secret is \(mySecret)")
        
            // Now that we have cipher, retrieve token from SSO endpoint
            // Set the authorization header value
            let headerDict = [
                "Authorization" : "Token token=9b9b943e7e5f16937d864e70d580bf9e",
                "Content-Type" : "application/x-www-form-urlencoded"
            ]

            // Set the Url
            let ssoPostUrl = "https://sso.highlandsapp.com/api/v1/sessions?data=true"

            // Set the parameters
            let parameters = [
                "up" : cipher
            ]
            
            // Send the request
            request(.POST, ssoPostUrl, parameters: parameters, headers: headerDict)
                .responseJSON { request, response, data in
                    if response?.statusCode == 200 {
                        if let json = data.value {
                            // Set Auth Variables
                            let oauthToken = JSON(json)["oauth_token"].stringValue
                            Globals.oauthToken = oauthToken
                            Globals.currentUser = self.email.text!
                            Globals.currentUserF1Id = JSON(json)["id"].stringValue
                            
                            Globals.hasSignedInBefore = true
                            
                            // Notification will close dialogue
                            self.dismissViewControllerAnimated(true, completion: nil)
                            
//                            NSNotificationCenter.defaultCenter().postNotificationName("dismissSingleSignOnFlowNotification", object: nil)
//                            print("Sign In Successful, OAuth token is => \(oauthToken)")
                            
                            // Go ahead and sync notes in the background
                            NotesManager.syncNotesAsync()
                            
                            self.fadeOutSpinnerView()
                            
                        } else {
                            // Can't parse json so show error message
                            self.errorLabel1.text = "Sorry, but we're having trouble signing you in. Please try again in a few minutes."
                            
                            
                        }
                    } else if response!.statusCode == 401 {
                        self.errorLabel1.text = "Sorry, but we're having trouble signing you in. Please check your email and password."
                        self.popOutErrorBox()
                    } else {
                        self.errorLabel1.text = "Sorry, but we're having trouble signing you in. Please try again in a few minutes."
                        self.popOutErrorBox()
                    }
                    self.signInButton.enabled = true
                }
            } catch {
                errorLabel1.text = "Sorry, but we're having trouble signing you in. Please try again in a few minutes."
                self.popOutErrorBox()
                signInButton.enabled = true
                signInButton.alpha = 1.0
            }
    }
    
    func popOutErrorBox() {
        
        self.fadeOutSpinnerView()
        
        errorLabel1.hidden = false
        self.errorBox1.hidden = false
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
            self.errorBoxTopConstraint1.constant = -20
            self.view.layoutIfNeeded()
            }, completion: { (_) -> Void in
                UIView.animateWithDuration(0.4, delay: 2.7, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: { () -> Void in
                    self.errorBoxTopConstraint1.constant = -100
                    self.view.layoutIfNeeded()
                    }, completion: { (_) -> Void in
                        self.errorBox1.hidden = true
                })
                
        })
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
    
    @IBAction func skipButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func forgotPasswordPressed(sender: AnyObject) {
        let url = NSURL(string: "https://chbhmal.infellowship.com/UserLogin/ForgotPassword")
        UIApplication.sharedApplication().openURL(url!)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Sign Up Segue
        if (segue.identifier == "CreateAccount") {
            self.addChildViewController(segue.destinationViewController as! RegisterViewController)
            let destinationView = (segue.destinationViewController as! RegisterViewController).view
            destinationView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
            destinationView.frame =  CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
            self.view.addSubview(destinationView)
            segue.destinationViewController.didMoveToParentViewController(self)
        }
    }
    
    // Dismiss Keyboard if you tap off the keyboard
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }


    // MARK: UITextFieldDelegate Methods
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (textField == email) {
            password.becomeFirstResponder()
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        signInButton.enabled = true
        signInButton.alpha = 1.0
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if textField == self.email {
            textField.placeholder = "EMAIL"
        }
        
        if textField == self.password {
            textField.placeholder = "PASSWORD"
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
    
    // Keep only portrait orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
}
