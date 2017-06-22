//
//  ViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 4/28/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

struct MyCollectionViewConstants{
    // iPad
    static let CELL_HEADER_SIZE_IPAD_HEIGHT = 480;
    static let CELL_COMPACT_SIZE_IPAD_HEIGHT = 264;
    static let CELL_COMPACT_SIZE_IPAD_HEIGHT_LANDSCAPE = 245;
    // iPhone 4&5
    static let CELL_HEADER_SIZE_IPHONE_HEIGHT_SMALLIPHONE = 235;
    static let CELL_COMPACT_SIZE_IPHONE_HEIGHT_SMALLIPHONE = 135;
    static let CELL_HEADER_SIZE_IPHONE_HEIGHT_SMALLIPHONE_LANDSCAPE = 230;
    static let CELL_COMPACT_SIZE_IPHONE_HEIGHT_SMALLIPHONE_LANDSCAPE = 155;
    // iPhone 6
    static let CELL_HEADER_SIZE_IPHONE_HEIGHT = 264;
    static let CELL_HEADER_SIZE_IPHONE_HEIGHT_COMPACT = 240;
    static let CELL_COMPACT_SIZE_IPHONE_HEIGHT = 155;
    static let CELL_COMPACT_SIZE_IPHONE_HEIGHT_COMPACT = 180;
    // iPhone 6+
    static let CELL_HEADER_SIZE_IPHONE_HEIGHT_6PLUS = 285;
    static let CELL_COMPACT_SIZE_IPHONE_HEIGHT_6PLUS = 165;
    static let CELL_COMPACT_SIZE_IPHONE_HEIGHT_6PLUS_LANDSCAPE = 190;
}

struct ScreenSize
{
    static let SCREEN_WIDTH         = UIScreen.mainScreen().bounds.size.width
    static let SCREEN_HEIGHT        = UIScreen.mainScreen().bounds.size.height
    static let SCREEN_MAX_LENGTH    = max(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
    static let SCREEN_MIN_LENGTH    = min(ScreenSize.SCREEN_WIDTH, ScreenSize.SCREEN_HEIGHT)
}

struct DeviceType
{
    static let IS_IPHONE_5_OR_LESS  = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH <= 568.0
    static let IS_IPHONE_6          = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 667.0
    static let IS_IPHONE_6P         = UIDevice.currentDevice().userInterfaceIdiom == .Phone && ScreenSize.SCREEN_MAX_LENGTH == 736.0
    static let IS_IPAD              = UIDevice.currentDevice().userInterfaceIdiom == .Pad && ScreenSize.SCREEN_MAX_LENGTH == 1024.0
}

protocol HomeViewWebDelegate {
    func goToWebView(url: String)
}

class HomeViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UIActionSheetDelegate {

    var delegate : HomeViewWebDelegate!
    var switcher : SwitcherViewController!
    
    @IBOutlet weak var collectionView: UICollectionView!
    var hasLoaded = false
    var cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT
    var compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT
    var cellWidth = 0
    
    var isNotesActive = false
    var note : Note?
    
    var responseObject = JSON("") // This json is used for the "latest" message feature
    var featuresObject = JSON("") // This is for the remaining features
    var featuredSeries = JSON("") // This is also for the "latest" message feature
    
    var avatarPressedObserver : NSObjectProtocol?
    var skippedSSOPressedObserver : NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // [JG] - There may be a more elegant way of doing this but if the tableview loads while the
        // animation is still in progress it will stutter
        delay(0.3, closure: { () -> () in
            // [JG] - Load the first message to set the big header
            request(.GET, "https://api.churchofthehighlands.com/v2/media", parameters: ["format": "json"])
                .responseJSON { (_, _, data) in
                    // json has returned nil before, therefore nil-check before proceeding
                    if (data.value != nil) {
                        self.responseObject = JSON(data.value!)
                        self.hasLoaded = true
                        self.collectionView.reloadData()
                        
                        // Load messages into spotlight
                        SpotlightProvider.loadMedia(self.responseObject)
                    }
            }
            
            // [JG] - Load Features for the rest of the collectionview
            request(.GET, "https://api.churchofthehighlands.com/features", parameters: ["platform": "ios", "format": "json"])
                .responseJSON { (_, _, json) in
                    // json has returned nil before, therefore nil-check before proceeding
                    if (json.value != nil) {
                        self.featuresObject = JSON(json.value!)
                        self.hasLoaded = true
                        self.collectionView.reloadData()
                    }
            }
            
            request(.GET, "https://api.churchofthehighlands.com/v2/media/series", parameters: ["format": "json"])
                .responseJSON { (_, _, json) in
                    // json has returned nil before, therefore nil-check before proceeding
                    if (json.value != nil) {
                        self.featuredSeries = JSON(json.value!)
                    }
            }
            
            request(.GET, "https://notes.highlandsapp.com/api/v2/notes/", parameters: ["format": "json"])
                .responseJSON { _, _, data in
                    if let availableData = data.value {
                        let notesList = JSON(availableData)
                        let messageIdentifier = notesList[0]["slug"].stringValue
                        
                        // Pull the top Notes object and get the date to compare with today's date.
                        let notesDateString = notesList[0]["date"].string
                        let notesDate = NSDate(fromString: notesDateString!, format: DateFormat.Custom("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"))
                        let isSunday = notesDate.isToday()
//                        let isSunday = true

                        // Next check and see if it's 8 AM yet
                        if isSunday {
                            // Get the time for right now
                            let time = NSDate()
                            // Get the hour of the time
                            let hour = time.hour()
                            // If it's after 8 AM so make Notes available
                            if hour > 7 {
                                request(.GET, "https://notes.highlandsapp.com/api/v2/notes/\(messageIdentifier)", parameters: ["format": "json"])
                                    .responseJSON { request, _, data in
                                        if let json = data.value {
                                            if let note : Note = NoteSerializer.deserialize(json) {
                                                self.note = note
                                            }
                                            
                                            self.isNotesActive = true
                                            self.collectionView.reloadData()
                                        } // End optional unwrapper on data.value
                                } // End notes with messageId request
                            } // End if hour > 7
                        } // End if Sunday
                    } // End optional unwrapper on data.value
                } // End notes request
        }) // End Delay/API Calls

        // Configure Device for iOS 8.0
        self.cellWidth = Int(self.view.frame.size.width / 2)
        if IOSVersion.SYSTEM_VERSION_LESS_THAN("8.0") {
            if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                // iPad Portrait
                cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPAD_HEIGHT
                compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPAD_HEIGHT
                cellWidth = Int(self.view.frame.size.width / 2)
            } else {
                // iPhone Portrait
                if (DeviceType.IS_IPHONE_5_OR_LESS) {
                    // iPhone 5 and 4
                    cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_SMALLIPHONE
                    compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_SMALLIPHONE
                } else if (DeviceType.IS_IPHONE_6P) {
                    // iPhone 6+
                    cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_6PLUS
                    compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_6PLUS
                } else {
                    // iPhone 6
                    cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT
                    compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT
                }
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        // Add observer to avatar pressed notification
        self.avatarPressedObserver = NSNotificationCenter.defaultCenter().addObserverForName("avatarPressedNotification", object: nil, queue: nil) { note in
            // If user is signed in show action sheet
            if (Globals.userIsSignedIn) {
                let user = Globals.currentUser
                let actionSheet = UIActionSheet(title: "HIGHLANDS ID\nSigned in as: \(user!)", delegate: nil, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Sign Out")
                actionSheet.actionSheetStyle = .Default
                actionSheet.delegate = self
                actionSheet.showInView(self.view)
            } else if (Globals.hasSignedInBefore) { // If the user has logged in previously then we shouldn't show them the BenefitsVC
                // If user is not signed in show the sign in process
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("SignInViewController") as! SignInViewController
                vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
                self.presentViewController(vc, animated: true, completion: nil)
            } else {
                // If user is not signed in show the sign in process
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("BenefitsViewController") as! BenefitsViewController
                vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
                self.presentViewController(vc, animated: true, completion: nil)
            }
        }
        
        // Add observer for "skip" clicked on Sign Up Workflow
        self.skippedSSOPressedObserver = NSNotificationCenter.defaultCenter().addObserverForName("dismissSingleSignOnFlowNotification", object: nil, queue: nil) { note in
            [self.switcher.switchToViewControllerWithSegue("Home")]
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Remove observers
        if let avatarObserver = self.avatarPressedObserver {
            NSNotificationCenter.defaultCenter().removeObserver(avatarObserver)
        }
        
        if let skippedSSOObserver = self.skippedSSOPressedObserver {
            NSNotificationCenter.defaultCenter().removeObserver(skippedSSOObserver)
        }
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.isNotesActive {
            return self.featuresObject.count + 2;
        } else {
            return self.featuresObject.count + 1;
        }
    }
    
    // The cell that is returned must be retrieved from a call to -dequeueReusableCellWithReuseIdentifier:forIndexPath:
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // If Notes are available add Notes navigation to the top of the Collection View
        if self.isNotesActive {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("NewNotesAvailableCell", forIndexPath: indexPath) as! NewNotesAvailableCell
                return cell
            } else if indexPath.item == 1 {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HomeCell", forIndexPath: indexPath) as! HomeCollectionViewCell
                cell.titleLabel.text = self.responseObject["Messages"][0]["Title"].string
                cell.subtitleLabel.text = self.responseObject["Messages"][0]["Speaker"].string
                
                let imageURL = self.responseObject["Messages"][0]["Images"][0]["URL"].string
                if (imageURL != nil) {
                    cell.artWorkImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SmallHomeCell", forIndexPath: indexPath) as! SmallHomeCollectionViewCell
                
                cell.titleLabel.text = self.featuresObject[indexPath.item - 2]["title"].string
                cell.subTitleLabel.text = self.featuresObject[indexPath.item - 2]["description"].string
                let imageURL = self.featuresObject[indexPath.item - 2]["one_wide_img"].string
                if (imageURL != nil) {
                    cell.artWorkImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
                }
                return cell
            }

        } else {
            // Business as usual without Notes
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("HomeCell", forIndexPath: indexPath) as! HomeCollectionViewCell
                cell.titleLabel.text = self.responseObject["Messages"][0]["Title"].string
                cell.subtitleLabel.text = self.responseObject["Messages"][0]["Speaker"].string
                
                let imageURL = self.responseObject["Messages"][0]["Images"][0]["URL"].string
                if (imageURL != nil) {
                    cell.artWorkImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
                }
                return cell
            } else {
                let cell = collectionView.dequeueReusableCellWithReuseIdentifier("SmallHomeCell", forIndexPath: indexPath) as! SmallHomeCollectionViewCell
                
                cell.titleLabel.text = self.featuresObject[indexPath.item - 1]["title"].string
                cell.subTitleLabel.text = self.featuresObject[indexPath.item - 1]["description"].string
                let imageURL = self.featuresObject[indexPath.item - 1]["one_wide_img"].string
                if (imageURL != nil) {
                    cell.artWorkImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
                }
                return cell
            }
 
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize{
            if self.isNotesActive {
                if indexPath.item == 0 {
                    // [JG] - Set first item to full width
                    return CGSize(width: self.view.frame.size.width, height: CGFloat(80))
                } else if indexPath.item == 1 {
                    return CGSize(width: self.view.frame.size.width, height: CGFloat(cellHeight))
                } else {
                    // [JG] - Set remaining items to half width
                    return CGSize(width: CGFloat(cellWidth) - 1, height: CGFloat(compactCellHeight))
                }
            } else {
                if indexPath.item == 0 {
                    // [JG] - Set first item to full width
                    return CGSize(width: self.view.frame.size.width, height: CGFloat(cellHeight))
                } else {
                    // [JG] - Set remaining items to half width
                    return CGSize(width: CGFloat(cellWidth) - 1, height: CGFloat(compactCellHeight))
                }
            }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if self.isNotesActive {
            if indexPath.item == 0 {
                //Pop Notes View for testing
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewControllerWithIdentifier("NotesViewController") as! NotesViewController
                if let callableNote = self.note {
                    vc.note = callableNote
                }
                vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
                presentViewController(vc, animated: true, completion: nil)
            } else if indexPath.item == 1 {
                let messageParams = MessagePlayerViewControllerParameters()
                messageParams.messageSeriesJson = self.featuredSeries[0]
                let messageIndex = self.featuredSeries[0]["MessageCount"].intValue
                messageParams.messageIndex = messageIndex - 1
                [switcher.goToMessagePlayerView(messageParams)]
            } else if indexPath.item == 2 {
                // Navigate to One Year Bible - hard-coded
                [switcher.switchToViewControllerWithSegue("Bible")]
            } else {
                if self.featuresObject[indexPath.item - 2]["title"].string == "Weekend Services" {
                    [switcher.switchToViewControllerWithSegue("Locations")]
                } else {
                    // Get URL
                    let url = self.featuresObject[indexPath.item - 2]["link"].string
                    // For Online Giving kick out to Safari
                    if self.featuresObject[indexPath.item - 2]["title"].string == "Give Online" {
                        UIApplication.sharedApplication().openURL(NSURL(string:url!)!)
                    } else {
                        // For everything else go to Webview
                        self.delegate.goToWebView(url!)
                    }
                }
            }
        } else {
            if indexPath.item == 0 {
                let messageParams = MessagePlayerViewControllerParameters()
                messageParams.messageSeriesJson = self.featuredSeries[0]
                let messageIndex = self.featuredSeries[0]["MessageCount"].intValue
                messageParams.messageIndex = messageIndex - 1
                [switcher.goToMessagePlayerView(messageParams)]
            } else if indexPath.item == 1 {
                // Navigate to One Year Bible - hard-coded
                [switcher.switchToViewControllerWithSegue("Bible")]
            } else {
                if self.featuresObject[indexPath.item - 1]["title"].string == "Weekend Services" {
                    [switcher.switchToViewControllerWithSegue("Locations")]
                } else {
                    // Get URL
                    let url = self.featuresObject[indexPath.item - 1]["link"].string
                    // For Online Giving kick out to Safari
                    if self.featuresObject[indexPath.item - 1]["title"].string == "Give Online" {
                        UIApplication.sharedApplication().openURL(NSURL(string:url!)!)
                    } else {
                        // For everything else go to Webview
                        self.delegate.goToWebView(url!)
                    }
                }
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        
        var reusableView : UICollectionReusableView = UICollectionReusableView()
        
        if kind == UICollectionElementKindSectionFooter {
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "AboutUsFooter", forIndexPath: indexPath) as! AboutUsFooter
            reusableView = footerView
            reusableView.hidden = self.hasLoaded ? false : true
        }
        
        return reusableView
    }
    
    @IBAction func selectedAboutUs(sender: AnyObject) {
        [switcher.switchToViewControllerWithSegue("AboutUs")]
    }
    
    @available(iOS 8.0, *)
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // [JG] - Set the Cell Size depending on the Size Class
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact
            && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Regular){
                if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                    // iPad Portrait
                    cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPAD_HEIGHT
                    compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPAD_HEIGHT
                    cellWidth = Int(self.view.frame.size.width / 2)
                } else {
                    // iPhone Portrait
                    if (DeviceType.IS_IPHONE_5_OR_LESS) {
                        // iPhone 5 and 4
                        cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_SMALLIPHONE
                        compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_SMALLIPHONE
                    } else if (DeviceType.IS_IPHONE_6P) {
                        // iPhone 6+
                        cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_6PLUS
                        compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_6PLUS
                    } else {
                        // iPhone 6
                        cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT
                        compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT
                    }
                    cellWidth = Int(self.view.frame.size.width / 2)
                }
        } else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact) {
            // iPhone Landscape
            if (DeviceType.IS_IPHONE_5_OR_LESS) {
                cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_SMALLIPHONE_LANDSCAPE
                compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_SMALLIPHONE_LANDSCAPE
            } else if (DeviceType.IS_IPHONE_6P) {
                // iPhone 6+
                cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_COMPACT
                compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_6PLUS_LANDSCAPE
            } else {
                cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPHONE_HEIGHT_COMPACT
                compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPHONE_HEIGHT_COMPACT
            }
            cellWidth = Int(self.view.frame.size.width / 3)
        } else {
            // iPad Landscape
            cellHeight = MyCollectionViewConstants.CELL_HEADER_SIZE_IPAD_HEIGHT
            compactCellHeight = MyCollectionViewConstants.CELL_COMPACT_SIZE_IPAD_HEIGHT_LANDSCAPE
            cellWidth = Int(self.view.frame.size.width / 3)
        }
        
        self.collectionView.reloadItemsAtIndexPaths(
            self.collectionView.indexPathsForVisibleItems())
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        // [JG] - reload collectionview to reset Cell sizes
        self.collectionView.reloadData()
    }
    
    // MARK: UIActionSheetDelegate
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if (actionSheet.buttonTitleAtIndex(buttonIndex) == "Sign Out") {
            // Clear out authentication
            Globals.clearCurrentUser()
            print("sign out!")
        } else {
            // Dismiss Action Sheet
            actionSheet.dismissWithClickedButtonIndex(0, animated: true)
        }
    }

    // MARK: Helpers
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}

