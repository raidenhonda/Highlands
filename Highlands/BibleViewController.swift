//
//  BibleViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/6/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

struct SelectedTabConstants{
    static let DEVO = "Devotional"
    static let OLD = "OldTestament"
    static let NEW = "NewTestament"
    static let PROVERBS = "Proverbs"
    static let PSALMS = "Psalm"
}

class BibleViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var readingWebView: UIWebView!
    var bible = JSON("")
    var baseHTML : String = ""
    var dateOfReading = NSDate()
    var spinner : LLARingSpinnerView = LLARingSpinnerView()
    @IBOutlet weak var spinnerContainer: UIView!
    @IBOutlet weak var spinnerBackground: UIView!

    // Top Toolbar
    @IBOutlet weak var selection_Proverbs: UIView!
    @IBOutlet weak var label_Proverbs: UILabel!
    @IBOutlet weak var selection_Psalm: UIView!
    @IBOutlet weak var label_Psalm: UILabel!
    @IBOutlet weak var selection_New: UIView!
    @IBOutlet weak var label_New: UILabel!
    @IBOutlet weak var selection_Old: UIView!
    @IBOutlet weak var label_Old: UILabel!
    @IBOutlet weak var selection_Devo: UIView!
    @IBOutlet weak var label_Devo: UILabel!
    var currentlySelectedTab : String = SelectedTabConstants.DEVO
    
    // Text Widget
    @IBOutlet weak var fontSizeWidgetHeight: NSLayoutConstraint!
    @IBOutlet weak var translationPickerWidth: NSLayoutConstraint!
    var isTextWidgetOpen : Bool = false
    var selectedTranslation : String = ""
    @IBOutlet weak var translationPickerView: UISegmentedControl!
    var currentTextSize = 100.0
    var currentTextZoom = 1.0
    @IBOutlet weak var sizeUpBlockerView: UIView!
    @IBOutlet weak var sizeDownBlockerView: UIView!
    @IBOutlet weak var translationBlockerView: UIView!
    
    // Date Switcher
    @IBOutlet weak var dayForwardButton: UIButton!
    @IBOutlet weak var dayBackButton: UIButton!
    @IBOutlet weak var dateSwitcherLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readingWebView.delegate = self;
        
        dateOfReading = NSDate()

        self.setSwitcherDate()

        // Show spinner for loading
        spinner = LLARingSpinnerView.init(frame:CGRectMake(0.0, 0.0, 45.0, 45.0))
        spinner.lineWidth = 3.0
        spinner.tintColor = UIColor(red: 77/255, green:157/255 , blue: 183/255, alpha: 1.0)
        spinnerContainer.addSubview(spinner)
        spinner.startAnimating()
        
        let path = NSBundle.mainBundle().pathForResource("Bible", ofType: "html")
        self.baseHTML = try! String(contentsOfFile: path!, encoding: NSUTF8StringEncoding)
        
        let formattedDate = self.getDateString()
        request(.GET, "https://api.churchofthehighlands.com/v2/bible/\(formattedDate)/?key=ZFFjKkvwZc187WWDijQMR6FsONTTxg383pMc4dCn6CuOdsINPVUu4szjjskXzlH", parameters: ["format": "json"])
            .responseJSON { _, _, json in
                self.bible = JSON(json.value!)
                var html = self.bible["Devotional"].stringValue
                html = "<article id='Devotions' class='bible-mode active'> <div class='sixteen columns txtalign-center'><div class='bible-title'>Daily Devotional</div><div class='bible-author'>By Pastor Larry Stockstill</div></div><div class='sixteen columns nomarginside'><div class='bible-content'>\(html)</div></div></article>"
                let formattedHTML = self.baseHTML.stringByReplacingOccurrencesOfString("{{BIBLETEXT}}", withString: html)
                self.readingWebView.loadHTMLString(formattedHTML, baseURL: NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath))
                // Fade Out Spinner
                self.fadeOutSpinnerView()
        }
        
        // Set selection of Top Bar
        self.selection_Devo.hidden = false
        self.selection_Proverbs.hidden = true
        self.selection_Psalm.hidden = true
        self.selection_New.hidden = true
        self.selection_Old.hidden = true
        
        // Abbreviate for smaller devices
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
            self.label_Devo.text = "DEVO"
            self.label_Proverbs.text = "PROV"
            self.label_Devo.font = UIFont(name: "GothamMedium", size: 12)
            self.label_New.font = UIFont(name: "GothamMedium", size: 12)
            self.label_Old.font = UIFont(name: "GothamMedium", size: 12)
            self.label_Proverbs.font = UIFont(name: "GothamMedium", size: 12)
            self.label_Psalm.font = UIFont(name: "GothamMedium", size: 12)
            self.translationPickerWidth.constant = 150
            
            // Truncate text even more on tiny iPhones
            if DeviceType.IS_IPHONE_5_OR_LESS {
                self.label_Devo.text = "DV"
                self.label_Proverbs.text = "PV"
                self.label_New.text = "NT"
                self.label_Old.text = "OT"
                self.label_Psalm.text = "PS"
            }
        } else if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            self.currentTextSize = 120.0
            self.currentTextZoom = 1.2
            self.translationPickerWidth.constant = 250
        }
        
        let defaults = NSUserDefaults.standardUserDefaults()
        let textSize = defaults.doubleForKey("textSize")
        if (textSize > 0) {
            currentTextSize = textSize
        } else {
            defaults.setDouble(100.0, forKey: "textSize")
        }
        
        let textZoom = defaults.doubleForKey("textZoom")
        if (textZoom > 0) {
            currentTextZoom = textZoom
        } else {
            defaults.setDouble(1.0, forKey: "textZoom")
        }
        self.setTextSize()
        
        // Set Text Widget to Closed
        self.fontSizeWidgetHeight.constant = 0

        self.sizeDownBlockerView.hidden = self.currentTextSize >= 90.0 ? true : false
        self.sizeUpBlockerView.hidden = self.currentTextSize >= 140.0 ? false : true
        
        let trans = defaults.integerForKey("translation")
        if (trans == 0) {
            self.translationPickerView.selectedSegmentIndex = 0
            self.selectedTranslation = "niv"
        } else if (trans == 1) {
            self.translationPickerView.selectedSegmentIndex = 1
            self.selectedTranslation = "nlt"
        } else if (trans == 2) {
            self.translationPickerView.selectedSegmentIndex = 2
            self.selectedTranslation = "kjv"
        }
    }
    
    @IBAction func didSelectProverbs(sender: AnyObject) {
        let translation = getCurrentTranslation()
        let title = self.bible[SelectedTabConstants.PROVERBS]["Verses"].stringValue
        var html = self.bible[SelectedTabConstants.PROVERBS]["text"][self.selectedTranslation].stringValue
        html = "<article id='Proverbs' class='bible-mode verses'><div class='sixteen columns txtalign-center'><div class='bible-title'>\(title)</div><div class='bible-author marginbottom40'>\(translation)</div></div><div class='sixteen columns nomarginside'><div class='bible-content'>\(html)</div></div></article>"
        let formattedHtml = self.baseHTML.stringByReplacingOccurrencesOfString("{{BIBLETEXT}}", withString: html)
//        print(formattedHtml)
        self.readingWebView.loadHTMLString(formattedHtml, baseURL: NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath))

        // Set selection of Top Bar
        self.selection_Devo.hidden = true
        self.selection_Proverbs.hidden = false
        self.selection_Psalm.hidden = true
        self.selection_New.hidden = true
        self.selection_Old.hidden = true
        currentlySelectedTab = SelectedTabConstants.PROVERBS
        
        // Re-enable Translation Switcher
        self.translationBlockerView.hidden = true
    }
    
    @IBAction func didSelectPsalms(sender: AnyObject) {
        let translation = getCurrentTranslation()
        let title = self.bible[SelectedTabConstants.PSALMS]["Verses"].stringValue
        var html = self.bible[SelectedTabConstants.PSALMS]["text"][self.selectedTranslation].stringValue
        html = "<article id='Psalm' class='bible-mode verses'><div class='sixteen columns txtalign-center'><div class='bible-title'>\(title)</div><div class='bible-author marginbottom40'>\(translation)</div></div><div class='sixteen columns nomarginside'><div class='bible-content'>\(html)</div></div></article>"
        let formattedHtml = self.baseHTML.stringByReplacingOccurrencesOfString("{{BIBLETEXT}}", withString: html)
//        print(formattedHtml)
        self.readingWebView.loadHTMLString(formattedHtml, baseURL: NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath))

        // Set selection of Top Bar
        self.selection_Devo.hidden = true
        self.selection_Proverbs.hidden = true
        self.selection_Psalm.hidden = false
        self.selection_New.hidden = true
        self.selection_Old.hidden = true
        currentlySelectedTab = SelectedTabConstants.PSALMS
        
        // Re-enable Translation Switcher
        self.translationBlockerView.hidden = true
    }
    
    @IBAction func didSelectNew(sender: AnyObject) {
        let translation = getCurrentTranslation()
        let title = self.bible[SelectedTabConstants.NEW]["Verses"].stringValue
        var newHtml = self.bible[SelectedTabConstants.NEW]["text"][self.selectedTranslation].stringValue
        newHtml = "<article id='NewTestament' class='bible-mode verses'><div class='sixteen columns txtalign-center'><div class='bible-title'>\(title)</div><div class='bible-author marginbottom40'>\(translation)</div></div><div class='sixteen columns nomarginside'><div class='bible-content'>\(newHtml)</div></div></article>"
        let formattedNewHtml = self.baseHTML.stringByReplacingOccurrencesOfString("{{BIBLETEXT}}", withString: newHtml)
        self.readingWebView.loadHTMLString(formattedNewHtml, baseURL: NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath))

        // Set selection of Top Bar
        self.selection_Devo.hidden = true
        self.selection_Proverbs.hidden = true
        self.selection_Psalm.hidden = true
        self.selection_New.hidden = false
        self.selection_Old.hidden = true
        currentlySelectedTab = SelectedTabConstants.NEW
        
        // Re-enable Translation Switcher
        self.translationBlockerView.hidden = true
    }
    
    @IBAction func didSelectOld(sender: AnyObject) {
        let translation = getCurrentTranslation()
        let title = self.bible[SelectedTabConstants.OLD]["Verses"].stringValue
        var html = self.bible[SelectedTabConstants.OLD]["text"][self.selectedTranslation].stringValue
        html = "<article id='OldTestament' class='bible-mode verses'><div class='sixteen columns txtalign-center'><div class='bible-title'>\(title)</div><div class='bible-author marginbottom40'>\(translation)</div></div><div class='sixteen columns nomarginside'><div class='bible-content'>\(html)</div></div></article>"
        let formattedHtml = self.baseHTML.stringByReplacingOccurrencesOfString("{{BIBLETEXT}}", withString: html)
        self.readingWebView.loadHTMLString(formattedHtml, baseURL: NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath))
        // Set selection of Top Bar
        self.selection_Devo.hidden = true
        self.selection_Proverbs.hidden = true
        self.selection_Psalm.hidden = true
        self.selection_New.hidden = true
        self.selection_Old.hidden = false
        currentlySelectedTab = SelectedTabConstants.OLD
        
        // Re-enable Translation Switcher
        self.translationBlockerView.hidden = true
    }
    
    @IBAction func didSelectDevo(sender: AnyObject) {
        var html = self.bible[SelectedTabConstants.DEVO].stringValue
        html = "<article id='Devotions' class='bible-mode active'> <div class='sixteen columns txtalign-center'><div class='bible-title'>Daily Devotional</div><div class='bible-author'>By Pastor Larry Stockstill</div></div><div class='sixteen columns nomarginside'><div class='bible-content'>\(html)</div></div></article>"
        let formattedHtml = self.baseHTML.stringByReplacingOccurrencesOfString("{{BIBLETEXT}}", withString: html)
        self.readingWebView.loadHTMLString(formattedHtml, baseURL: NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath))

        // Set selection of Top Bar
        self.selection_Devo.hidden = false
        self.selection_Proverbs.hidden = true
        self.selection_Psalm.hidden = true
        self.selection_New.hidden = true
        self.selection_Old.hidden = true
        currentlySelectedTab = SelectedTabConstants.DEVO
        
        // Re-enable Translation Switcher
        self.translationBlockerView.hidden = false
    }
    
    @IBAction func changeTextSize(sender: AnyObject) {
        if isTextWidgetOpen {
            UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.fontSizeWidgetHeight.constant = 0;
                self.view.layoutIfNeeded();
                }, completion: nil);
            isTextWidgetOpen = false
        } else {
            UIView.animateWithDuration(0.4, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.fontSizeWidgetHeight.constant = 50;
                self.view.layoutIfNeeded();
                }, completion: nil);
            isTextWidgetOpen = true
        }
    }
    
    @IBAction func sizeTextUp(sender: AnyObject) {
        self.currentTextSize = self.currentTextSize + 20.0
        self.currentTextZoom = self.currentTextZoom + 0.2
        self.setTextSize()
        
        // Set Button selected
        let button = sender as! SizeDownButton
        button.setSelected()
        
        // Disable Sizing buttons depending on value
        self.sizeUpBlockerView.hidden = self.currentTextSize >= 140.0 ? false : true
        self.sizeDownBlockerView.hidden = self.currentTextSize > 90 ? true : false
    }
    
    @IBAction func sizeTextDown(sender: AnyObject) {
        self.currentTextSize = self.currentTextSize - 20.0
        self.currentTextZoom = self.currentTextZoom - 0.2
        self.setTextSize()
        
        // Set Button selected
        let button = sender as! SizeUpButton
        button.setSelected()
        
        // Disable Sizing buttons depending on value
        self.sizeDownBlockerView.hidden = self.currentTextSize <= 90.0 ? false : true
        self.sizeUpBlockerView.hidden = self.currentTextSize < 140.0 ? true : false
    }
    
    func setTextSize() {
        // Store Defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setDouble(currentTextZoom, forKey: "textZoom")
        defaults.setDouble(currentTextSize, forKey: "textSize")
        
        self.readingWebView.stringByEvaluatingJavaScriptFromString("document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '\(self.currentTextSize)'")
        self.readingWebView.stringByEvaluatingJavaScriptFromString("document.getElementsByTagName('body')[0].style.zoom= '\(self.currentTextZoom)'")
        // Specifically resize headers
//        self.readingWebView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('bible-title')[0].style.webkitTextSizeAdjust= '\(self.currentTextSize)'")
//        self.readingWebView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('bible-title')[0].style.zoom= '\(self.currentTextZoom)'")
//        self.readingWebView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('bible-author')[0].style.webkitTextSizeAdjust= '\(self.currentTextSize)'")
//        self.readingWebView.stringByEvaluatingJavaScriptFromString("document.getElementsByClassName('bible-author')[0].style.zoom= '\(self.currentTextZoom)'")
        
    }
    
    // MARK: WebView Delegate
    func webViewDidFinishLoad(webView: UIWebView) {
        self.setTextSize()
    }
    
    @IBAction func changedTranslation(sender: UISegmentedControl) {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.selectedTranslation = "niv"
            defaults.setInteger(0, forKey: "translation")
        case 1:
            self.selectedTranslation = "nlt"
            defaults.setInteger(1, forKey: "translation")
        case 2:
            self.selectedTranslation = "kjv"
            defaults.setInteger(2, forKey: "translation")
        default:
            break
        }
        
        self.updateSelectedTab()
    }
    
    @IBAction func oneDayBackAction(sender: AnyObject) {
        // 86,400 seconds in a day
        self.dateOfReading = dateOfReading.dateByAddingTimeInterval(-86400)
        self.setSwitcherDate()
        let formattedDate = self.getDateString()
        
        self.spinner.startAnimating()
        self.spinnerBackground.hidden = false
        self.spinnerContainer.hidden = false
        
        request(.GET, "https://api.churchofthehighlands.com/v2/bible/\(formattedDate)/?key=ZFFjKkvwZc187WWDijQMR6FsONTTxg383pMc4dCn6CuOdsINPVUu4szjjskXzlH", parameters: ["format": "json"])
            .responseJSON { _, _, json in
                self.bible = JSON(json.value!)
                self.updateSelectedTab()
                // Fade Out Spinner
                self.fadeOutSpinnerView()
        }
    }
    
    @IBAction func oneDayForwardAction(sender: AnyObject) {
        // 86,400 seconds in a day
        // There's no needed logic for not traversing into the future that should be available
        self.dateOfReading = dateOfReading.dateByAddingTimeInterval(86400)
        self.setSwitcherDate()
        let formattedDate = self.getDateString()
        
        self.spinner.startAnimating()
        self.spinnerBackground.hidden = false
        self.spinnerContainer.hidden = false
        
        request(.GET, "https://api.churchofthehighlands.com/v2/bible/\(formattedDate)/?key=ZFFjKkvwZc187WWDijQMR6FsONTTxg383pMc4dCn6CuOdsINPVUu4szjjskXzlH", parameters: ["format": "json"])
            .responseJSON { _, _, json in
                self.bible = JSON(json.value!)
                self.updateSelectedTab()
                // Fade Out Spinner
                self.fadeOutSpinnerView()
        }
    }
    
    // Get Date String for API call
    func getDateString() -> String {
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy/MM/dd"
        let string = dateFormat.stringFromDate(dateOfReading)
        return string
    }
    
    // Long style date for Switcher
    func setSwitcherDate() {
        let newDateFormat = NSDateFormatter()
        newDateFormat.dateStyle = NSDateFormatterStyle.LongStyle
        self.dateSwitcherLabel.text = newDateFormat.stringFromDate(self.dateOfReading)
    }
    
    func updateSelectedTab() {
        if currentlySelectedTab == SelectedTabConstants.DEVO {
            self.didSelectDevo("")
        } else if currentlySelectedTab == SelectedTabConstants.NEW {
            self.didSelectNew("")
        } else if currentlySelectedTab == SelectedTabConstants.OLD {
            self.didSelectOld("")
        } else if currentlySelectedTab == SelectedTabConstants.PSALMS {
            self.didSelectPsalms("")
        } else if currentlySelectedTab == SelectedTabConstants.PROVERBS {
            self.didSelectProverbs("")
        }
    }
    
    func getCurrentTranslation() -> String {
        if self.selectedTranslation == "niv" {
            return "New International Version"
        } else if self.selectedTranslation == "kjv" {
            return "King James Version"
        } else if self.selectedTranslation == "nlt" {
            return "New Living Translation"
        } else {
            return ""
        }
    }
    
    func fadeOutSpinnerView() {
//        let fadeOut = POPBasicAnimation(propertyNamed: kPOPViewAlpha)
//        fadeOut.toValue = 0.0
//        fadeOut.duration = 0.3
//        spinnerContainer.pop_addAnimation(fadeOut, forKey: "FadeOutSpinner")
        
        self.delay(0.35, closure: {
            self.spinner.stopAnimating()
            self.spinnerContainer.hidden = true
            self.spinnerBackground.hidden = true
            self.spinnerContainer.layer.opacity = 1.0
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
