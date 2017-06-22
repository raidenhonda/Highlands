//
//  EventDetailsViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 6/9/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class EventDetailsViewControllerParameters {
    var eventJson: JSON!
}

class EventDetailsViewController: UIViewController, UIScrollViewDelegate , TTTAttributedLabelDelegate {

    var eventParameters : EventDetailsViewControllerParameters = EventDetailsViewControllerParameters()

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var eventDescriptionLabel: TTTAttributedLabel!
    @IBOutlet weak var eventDescLableHeight: NSLayoutConstraint!
    @IBOutlet weak var locationsList: UILabel!
    @IBOutlet weak var locationListHeight: NSLayoutConstraint!
    @IBOutlet weak var campusTitleLabel: UILabel!
    @IBOutlet weak var campusTitleLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var contentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftConstraint = NSLayoutConstraint(item: self.contentView!,
            attribute: NSLayoutAttribute.Leading,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.view!,
            attribute: NSLayoutAttribute.Leading,
            multiplier: 1.0,
            constant: 0.0)
        self.view.addConstraint(leftConstraint)
        
        let rightConstraint : NSLayoutConstraint = NSLayoutConstraint(item: self.contentView,
            attribute: NSLayoutAttribute.Trailing,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self.view,
            attribute: NSLayoutAttribute.Trailing,
            multiplier: 1.0,
            constant: 0)
        self.view.addConstraint(rightConstraint)
        
        let imageURL = self.eventParameters.eventJson["Image"].string
        if (imageURL != nil) {
            self.eventImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
        }
        
        print(self.eventParameters.eventJson["Description"].stringValue)
        self.setDetailsLabelWithHtml(self.eventParameters.eventJson["Description"].stringValue)
        
        // [JG] They use a different date format on the call specifically. :(
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        let date = dateFormat.dateFromString(self.eventParameters.eventJson["Date"].stringValue)
        let newDateFormat = NSDateFormatter()
        newDateFormat.dateStyle = NSDateFormatterStyle.LongStyle
        self.dateLabel.text = newDateFormat.stringFromDate(date!).uppercaseString
        
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad){
            self.dateLabel.font = UIFont(name: self.dateLabel.font.fontName, size: 25)
            self.campusTitleLabel.font = UIFont(name: self.campusTitleLabel.font.fontName, size: 25)
        }
        
        var timesString = ""
        for (_,timeJson):(String,JSON) in self.eventParameters.eventJson["Times"] {
            let campus = timeJson["Campus"].stringValue
            let serviceTime = timeJson["Time"].stringValue
            timesString = "\(timesString) \(campus) - \(serviceTime) \n"
        }
        
        self.locationsList.text = timesString
        
        if self.eventParameters.eventJson["Id"].string == "first-wednesday" {
            self.campusTitleLabel.hidden = true
        }
        
    }
    
    override func viewDidLayoutSubviews() {
//        self.dateLabel.font = UIFont(name: self.dateLabel.font.fontName, size: )
//        self.campusTitleLabel.font = UIFont(name: self.campusTitleLabel.font.fontName, size: 25)
    }
    
    func setDetailsLabelWithHtml(html: String) {
        
        // [JG] this is all sample code that I got from [GH]( https://github.com/alexshive/UILabelLinkReplace )
        let string = html as NSString
        
        // [JG] - REGEX to search for <a> tags
        let replacePattern = "<a href=\"[^\"]+\">([^<]+)</a>"
        let findPattern = "<a href=\"(.*?)\">(.*?)</a>"
        
        let replaceRegex = try! NSRegularExpression(pattern: replacePattern, options: [.DotMatchesLineSeparators])
        let findRegex = try! NSRegularExpression(pattern: findPattern, options: NSRegularExpressionOptions.DotMatchesLineSeparators)
        
        let findResult = replaceRegex.stringByReplacingMatchesInString(string as String, options: [], range: NSRange(location:0, length: string.length), withTemplate: "$1")
        let replaceString = NSString(string: findResult)
        let arrayOfAllMatches = findRegex.matchesInString(string as String, options: [], range: NSMakeRange(0, string.length)) 
        
        self.eventDescriptionLabel.delegate = self
        self.eventDescriptionLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.eventDescriptionLabel.setText(replaceString)
        
        for match in arrayOfAllMatches {
            let link = string.substringWithRange(match.rangeAtIndex(1)) // link
            let text = string.substringWithRange(match.rangeAtIndex(2)) // text
            
            let range:NSRange = replaceString.rangeOfString(text)
            let URL = NSURL(string: link)
            self.eventDescriptionLabel.addLinkToURL(URL, withRange: range)
        }
    }
    
    // MARK: TTTAttributedLabel Delegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        // [JG] - pop over to Safari, they may want to switch this to the in app web viewer
        UIApplication.sharedApplication().openURL(url)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
}
