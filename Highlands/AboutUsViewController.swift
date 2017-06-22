//
//  AboutUsViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 6/30/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
import MessageUI

class AboutUsViewController: UIViewController, TTTAttributedLabelDelegate, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var aboutUsLabel: TTTAttributedLabel!
    @IBOutlet weak var versionLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let version : AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        versionLabel.text = "Version: \(version as! String)"
        
        let string = "Church of the Highlands is a life-giving, relational church led by Pastor Chris Hodges. Our church meets in multiple locations in Alabama. Highlands offers contemporary, biblically-driven worship services that are alive with energy and creativity, as well as excellent childcare, exciting children's and student ministries, and dynamic small groups.\n\nFor more information about our church, visit us online at <a href=\"http://www.churchofthehighlands.com\">churchofthehighlands.com</a>" as NSString
        
        // [JG] - REGEX to search for <a> tags
        let replacePattern = "<a href=\"[^\"]+\">([^<]+)</a>"
        let findPattern = "<a href=\"(.*?)\">(.*?)</a>"
        
        
        let replaceRegex = try! NSRegularExpression(pattern: replacePattern, options: NSRegularExpressionOptions.DotMatchesLineSeparators)
        let findRegex = try! NSRegularExpression(pattern: findPattern, options: NSRegularExpressionOptions.DotMatchesLineSeparators)
        
        let findResult = replaceRegex.stringByReplacingMatchesInString(string as String, options: NSMatchingOptions.ReportCompletion, range: NSRange(location:0, length: string.length), withTemplate: "$1")
        let replaceString = NSString(string: findResult)
        let arrayOfAllMatches = findRegex.matchesInString(string as String, options: NSMatchingOptions.ReportCompletion, range: NSMakeRange(0, string.length))
        
        self.aboutUsLabel.delegate = self
        self.aboutUsLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.aboutUsLabel.setText(replaceString)
        
        for match in arrayOfAllMatches {
            let link = string.substringWithRange(match.rangeAtIndex(1)) // link
            let text = string.substringWithRange(match.rangeAtIndex(2)) // text
            
            let range:NSRange = replaceString.rangeOfString(text)
            let URL = NSURL(string: link)
            self.aboutUsLabel.addLinkToURL(URL, withRange: range)
        }
    }

    @IBAction func problemReported(sender: AnyObject) {
        let iosVersion = UIDevice.currentDevice().systemVersion
        let model = UIDevice.currentDevice().model
        let version : AnyObject? = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"]
        
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = self
        composer.setToRecipients(["appsupport@churchofthehighlands.com"])
        composer.setSubject("Highlands iOS v:\(version as! String) Support Request")
        composer.setMessageBody("Device: \(model)\niOS Version: \(iosVersion)\n\nPlease describe your problem or question.", isHTML: false)
        
        self.presentViewController(composer, animated: true, completion: nil)
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        switch result.rawValue{
        case MFMailComposeResultCancelled.rawValue: print("Mail cancelled")
        case MFMailComposeResultSaved.rawValue: print("Mail saved")
        case MFMailComposeResultSent.rawValue: print("Mail sent")
        case MFMailComposeResultFailed.rawValue: print("Failed to send mail: \(error!.localizedDescription)")
            
        default:
            break
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: TTTAttributedLabel Delegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        // [JG] - pop over to Safari, they may want to switch this to the in app web viewer
        UIApplication.sharedApplication().openURL(url)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
