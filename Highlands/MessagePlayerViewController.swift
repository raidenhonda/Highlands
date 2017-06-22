//
//  MessagePlayerViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/26/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class MessagePlayerViewControllerParameters {
    var messageSeriesJson: JSON? // Used if Series Json is already provided (used by Messages table view)
    var messageIndex: Int = 0 // Used if Series Json and known index is provided (only used from Messages table view)
    var isMidWeekMessage: Bool = false // Used to load Mid-Week Messages
    var messageIdentifier: String? // Used by deep-links (AppDelegate) to link directly to message
    var seriesIdentifier: String? // Used by deep-links (AppDelegate) to link directly to message
}

class MessagePlayerViewController: UIViewController {
    
    var note : Note = Note()
    
    var willTransitionToPortrait : Bool = true;
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    
    @IBOutlet weak var messageCoverImage: UIImageView!
    @IBOutlet weak var partLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var speakerLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var dateToggleBarLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var shareSheetSourceView: UIView!
    
    // For hide/show when message isn't available
    @IBOutlet weak var watchWorhipHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var watchWorshipView: UIView!
    @IBOutlet weak var watchWorshipButton: UIButton!
    @IBOutlet weak var worshipUnderline: UIView!
    
    @IBOutlet weak var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var watchMessageView: UIView!
    @IBOutlet weak var watchMessageButton: UIButton!
    @IBOutlet weak var messageUnderline: UIView!
    
    @IBOutlet weak var listenHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var listenVew: UIView!
    @IBOutlet weak var listenButton: UIButton!
    @IBOutlet weak var listenUnderline: UIView!
    
    @IBOutlet weak var notesHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var notesView: UIView!
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var notesUnderline: UIView!
    
    private var seriesIdentifier = ""
    private var messageIdentifier = ""
    var messagePlayerParameters : MessagePlayerViewControllerParameters = MessagePlayerViewControllerParameters()
    private var messageUrl = ""
    private var worshipAndMessageUrl = ""
    private var audioUrl = ""
    var moviePlayerController : MPMoviePlayerViewController = MPMoviePlayerViewController()
    
    var messageJson = JSON("")
    
    // This is so that the same observer doesn't get added twice
    var observer: AnyObject = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set local parameters if set by calling params in Switcher
        if let seriesId = messagePlayerParameters.seriesIdentifier {
            self.seriesIdentifier = seriesId
        }
        if let messageId = messagePlayerParameters.messageIdentifier {
            self.messageIdentifier = messageId
        }
        
        if self.messagePlayerParameters.isMidWeekMessage {
            self.loadMidWeekMessage()
            self.loadNotes()
        } else {
            // If json is nil call API to load series
            if self.messagePlayerParameters.messageSeriesJson == nil {
                self.loadApi()
            } else {
                self.loadMessage()
            }
        }
        
        // Setup UI
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
        
        self.observer = NSNotificationCenter.defaultCenter().addObserverForName("shareMessageNotification", object:nil , queue: NSOperationQueue.mainQueue()) { notification in
            self.shareCurrentMessage()
        }
        
        
        
        let notifCenter = NSNotificationCenter.defaultCenter()
        notifCenter.addObserverForName("removeMessageObserver", object:nil , queue: NSOperationQueue.mainQueue()) { notification in
            self.removeMessageObserver()
        }
        
        notifCenter.addObserverForName(MPMoviePlayerPlaybackDidFinishNotification, object: nil, queue: NSOperationQueue.mainQueue()) { notification in
            let reason = notification.userInfo?[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey]
            print("Playback failed: \(reason?.intValue)")
        }
        
        self.setUpReferenceSizeClasses()
    }
    
    func removeMessageObserver() {
        NSNotificationCenter.defaultCenter().removeObserver(self.observer)
    }
    
    func loadApi() {
        if (self.seriesIdentifier == "") {
            print("Message Player: The series identifier should not be nil/empty")
            return
        }
        
        request(.GET, "https://api.churchofthehighlands.com/v2/media/series/\(seriesIdentifier)", parameters: ["format": "json"])
            .responseJSON { _, _, data in
                let json = JSON(data.value!)

                self.messagePlayerParameters.messageSeriesJson = json
                self.loadMessage()
        }
    }
    
    func loadMessage() {
        let json = self.messagePlayerParameters.messageSeriesJson!
        self.seriesIdentifier = json["Id"].stringValue
        
        // Message Id may already be set
        if self.messageIdentifier == "" {
            self.messageIdentifier = json["Messages"][self.messagePlayerParameters.messageIndex]["Id"].stringValue // MessageIndex is only set from Message Table View Controller
        }
        
        // [JG] Switched from an || statement to an && 
        // You don't want it to return if either are nil only if both are nil
        if self.seriesIdentifier == "" && self.messageIdentifier == "" {
            print("Message Player: The series identifier should not be nil/empty")
            return;
        }
        
        // Instantiate an array of tuples
        var messages : [JSON] = []
        
        // Iterate over all the events and add to list
        for (_,subJson):(String, JSON) in json["Messages"] {
            messages.append(subJson)
        }
        
        // Load message
        self.messageJson = JSON("")
        
        // Check if message identifier is provided, if not return first message
        if self.messageIdentifier == "" {
            // [JG] - If messageIdentifier is nil we need to load the series
            self.loadApi()
            return
        } else {
            let messagesFiltered = messages.filter({ (json: JSON) -> Bool in
                json["Id"].string == self.messageIdentifier
            })
            self.messageJson = messagesFiltered[0]
        }

        // Load Notes
        self.loadNotes()
        
        // Pull out the data
        let seriesTitle = json["Title"].stringValue
        let title = self.messageJson["Title"].stringValue
        let date = self.messageJson["Date"]["date"].shortHandDate
        let speaker = self.messageJson["Speaker"].stringValue
        let speakerString = "Speaker \(speaker)"
        let part = self.messageJson["Number"].stringValue
        let partString = "PART \(part) - \(seriesTitle)"
        let description = self.messageJson["Description"].stringValue
        let imageUrl = NSURL(string: "https://www.churchofthehighlands.com/images/content/series/_series_mobile/\(self.seriesIdentifier).jpg")!
        
        // [JG]- Sometimes the Video/Message may not be available yet. 
        // When that is the case the app crashes, hence checking the array size
        let messageVideoJson = self.messageJson["Videos"].arrayValue.filter({ (json: JSON) -> Bool in
            json["Type"].stringValue == "Adaptive"
        }) as [JSON]
        self.messageUrl = messageVideoJson.count > 0 ? messageVideoJson[0]["URL"].stringValue : ""
        
        // TODO: Figure out why these Adaptive videos don't play
        self.messageUrl = ""

        // If there's no HD version check for SD
        if self.messageUrl.isEmpty {
            let messageVideoJson = self.messageJson["Videos"].arrayValue.filter({ (json: JSON) -> Bool in
                json["Type"].stringValue == "Static"
            }) as [JSON]
            self.messageUrl = messageVideoJson.count > 0 ? messageVideoJson[0]["URL"].stringValue : ""
        }
        // If neither exists hide the button
        if self.messageUrl.isEmpty {
            self.hideMessageButton()
        }
        
        let worshipAndMessageVideoJson = self.messageJson["Worship"].arrayValue.filter({ (json: JSON) -> Bool in
            json["Type"].stringValue == "Adaptive"
        }) as [JSON]
        self.worshipAndMessageUrl = worshipAndMessageVideoJson.count > 0 ? worshipAndMessageVideoJson[0]["URL"].stringValue : ""
        
        // TODO: Figure out why these Adaptive videos don't play
        self.worshipAndMessageUrl = ""
        
        // If there's no HD version check for SD
        if self.worshipAndMessageUrl.isEmpty {
            let worshipAndMessageVideoJson = self.messageJson["Worship"].arrayValue.filter({ (json: JSON) -> Bool in
                json["Type"].stringValue == "Static"
            }) as [JSON]
            self.worshipAndMessageUrl = worshipAndMessageVideoJson.count > 0 ? worshipAndMessageVideoJson[0]["URL"].stringValue : ""
        }
        // If neither exists hide the button
        if self.worshipAndMessageUrl.isEmpty {
            self.hideWorshipButton()
        }
        
        let audioJson = self.messageJson["Audio"].arrayValue.filter({ (json: JSON) -> Bool in
            json["Bitrate"].stringValue == "192k"
        }) as [JSON]
        self.audioUrl =  audioJson.count > 0 ? audioJson[0]["URL"].stringValue : ""
        if self.audioUrl.isEmpty {
            self.hideListenButton()
        }
        
        // Set the UI elements
        self.messageCoverImage.sd_setImageWithURL(imageUrl)
        self.partLabel.text = partString
        self.messageLabel.text = title
        self.speakerLabel.text = speakerString
        
        let newDateFormat = NSDateFormatter()
        newDateFormat.dateStyle = NSDateFormatterStyle.LongStyle
        
        self.dateLabel.text = newDateFormat.stringFromDate(date!)
        self.dateToggleBarLabel.text = newDateFormat.stringFromDate(date!)
        self.descriptionLabel.text = description
        self.showHideToggleButtons()
    }
    
    func loadMidWeekMessage() {
        // Pull out the data
        let title = self.messagePlayerParameters.messageSeriesJson!["Title"].stringValue
        let date = self.messagePlayerParameters.messageSeriesJson!["Date"]["date"].shortHandDate
        let speaker = self.messagePlayerParameters.messageSeriesJson!["Speaker"].stringValue
        let speakerString = "Speaker \(speaker)"
        let imageUrl = NSURL(string:self.messagePlayerParameters.messageSeriesJson!["Images"][0]["URL"].string!)!
        let description = self.messagePlayerParameters.messageSeriesJson!["Description"].stringValue

        // [JG]- Sometimes the Video/Message may not be available yet.
        // When that is the case the app crashes, hence checking the array size
        let messageVideoJson = self.messagePlayerParameters.messageSeriesJson!["Videos"].arrayValue.filter({ (json: JSON) -> Bool in
            json["Type"].stringValue == "Adaptive"
        }) as [JSON]
        self.messageUrl = messageVideoJson.count > 0 ? messageVideoJson[0]["URL"].stringValue : ""
        
        // TODO: Figure out why these Adaptive videos don't play
        self.messageUrl = ""
        
        // If there's no HD version check for SD
        if self.messageUrl.isEmpty {
            let messageVideoJson = self.messagePlayerParameters.messageSeriesJson!["Videos"].arrayValue.filter({ (json: JSON) -> Bool in
                json["Type"].stringValue == "Static"
            }) as [JSON]
            self.messageUrl = messageVideoJson.count > 0 ? messageVideoJson[0]["URL"].stringValue : ""
        }
        // If neither exists hide the button
        if self.messageUrl.isEmpty {
            self.hideMessageButton()
        }
        
        let worshipAndMessageVideoJson = self.messagePlayerParameters.messageSeriesJson!["Worship"].arrayValue.filter({ (json: JSON) -> Bool in
            json["Type"].stringValue == "Adaptive"
        }) as [JSON]
        self.worshipAndMessageUrl = worshipAndMessageVideoJson.count > 0 ? worshipAndMessageVideoJson[0]["URL"].stringValue : ""
        
        // TODO: Figure out why these Adaptive videos don't play
        self.worshipAndMessageUrl = ""
        
        // If there's no HD version check for SD
        if self.worshipAndMessageUrl.isEmpty {
            let worshipAndMessageVideoJson = self.messagePlayerParameters.messageSeriesJson!["Worship"].arrayValue.filter({ (json: JSON) -> Bool in
                json["Type"].stringValue == "Static"
            }) as [JSON]
            self.worshipAndMessageUrl = worshipAndMessageVideoJson.count > 0 ? worshipAndMessageVideoJson[0]["URL"].stringValue : ""
        }
        // If neither exists hide the button
        if self.worshipAndMessageUrl.isEmpty {
            self.hideWorshipButton()
        }
        
        let audioJson = self.messagePlayerParameters.messageSeriesJson!["Audio"].arrayValue.filter({ (json: JSON) -> Bool in
            json["Bitrate"].stringValue == "192k"
        }) as [JSON]
        self.audioUrl =  audioJson.count > 0 ? audioJson[0]["URL"].stringValue : ""
        if self.audioUrl.isEmpty {
            self.hideListenButton()
        }
        
        // Set the UI elements
        self.messageCoverImage.sd_setImageWithURL(imageUrl)
        self.partLabel.text = ""
        self.messageLabel.text = title
        self.speakerLabel.text = speakerString

        let newDateFormat = NSDateFormatter()
        newDateFormat.dateStyle = NSDateFormatterStyle.LongStyle
        
        self.dateLabel.text = newDateFormat.stringFromDate(date!)
        self.dateToggleBarLabel.text = newDateFormat.stringFromDate(date!)
        self.descriptionLabel.text = description
        self.showHideToggleButtons()
    }
    
    // MARK: Button Actions
    @IBAction func watchFullServiceAction(sender: AnyObject) {
        // If message isn't avaiable pop alert
        if (self.worshipAndMessageUrl.isEmpty) {
            let alertController = UIAlertController(title: "Message Not Avialable Yet", message: "We are hard at work preparing the video. Check back soon.", preferredStyle: .Alert)
            let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(OKAction)
                
            self.presentViewController(alertController, animated: true, completion: nil)
        } else {
            self.playWithMediaPlayer(self.worshipAndMessageUrl)
        }
    }
    
    @IBAction func watchMessageAction(sender: AnyObject) {
        // If message isn't avaiable pop alert
        if (self.messageUrl.isEmpty) {
            
            let alertController = UIAlertController(title: "Message Not Avialable Yet", message: "We are hard at work preparing the video. Check back soon.", preferredStyle: .Alert)
            let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(OKAction)

            self.presentViewController(alertController, animated: true, completion: nil)

        } else {
            self.playWithMediaPlayer(self.messageUrl)
        }
    }
    
    @IBAction func listenAction(sender: AnyObject) {
        self.playWithMediaPlayer(self.audioUrl)
    }
    
    @IBAction func notesAction(sender: AnyObject) {
        //Pop Notes View for testing
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewControllerWithIdentifier("NotesViewController") as! NotesViewController
        vc.note = self.note
        vc.modalTransitionStyle = UIModalTransitionStyle.CoverVertical
        presentViewController(vc, animated: true, completion: nil)
    }

    @IBAction func seriesBackAction(sender: AnyObject) {
        if (self.messagePlayerParameters.messageSeriesJson == nil || self.messagePlayerParameters.messageSeriesJson == "") {
            return
        }
        
        // Update message index
        --self.messagePlayerParameters.messageIndex;
        
        // Update message id
        self.messageIdentifier = self.messagePlayerParameters.messageSeriesJson!["Messages"][self.messagePlayerParameters.messageIndex]["Id"].stringValue
        
        self.loadMessage()
    }
    
    @IBAction func seriesForwardAction(sender: AnyObject) {
        if (self.messagePlayerParameters.messageSeriesJson == nil || self.messagePlayerParameters.messageSeriesJson == "") {
            return
        }

        // Update message index
        ++self.messagePlayerParameters.messageIndex;
        
        // Update message id
        self.messageIdentifier = self.messagePlayerParameters.messageSeriesJson!["Messages"][self.messagePlayerParameters.messageIndex]["Id"].stringValue
        
        self.loadMessage()
    }
    
    func showHideToggleButtons() {
        backButton.hidden = false
        forwardButton.hidden = false
        
        if (self.messagePlayerParameters.messageIndex == 0) {
            backButton.hidden = true
        }
        
        let messagesInSeries = self.messagePlayerParameters.messageSeriesJson!["Messages"].arrayValue.count
        if (self.messagePlayerParameters.messageIndex >= (messagesInSeries - 1)) {
            forwardButton.hidden = true
        }
    }
    
    // MARK: Configure Media Player
    func playWithMediaPlayer(url: String) {

        // Create/Configure the media controller
        let liveUrl = NSURL(string: url)

        self.performSegueWithIdentifier("PlayVideo", sender: liveUrl)
        
//        let player = AVPlayer(URL: liveUrl!)
//        
//        let controller = AVPlayerViewController()
//        controller.player = player
//        self.addChildViewController(controller)
//        self.view.addSubview(controller.view)
//        controller.view.frame = self.view.frame
//        
//        player.play()
        
//        self.moviePlayerController = MPMoviePlayerViewController(contentURL: liveUrl)
//        self.moviePlayerController.moviePlayer.controlStyle = MPMovieControlStyle.Fullscreen
//        self.moviePlayerController.moviePlayer.scalingMode = MPMovieScalingMode.AspectFit
//        self.moviePlayerController.moviePlayer.shouldAutoplay = true
//        
//        self.presentMoviePlayerViewControllerAnimated(moviePlayerController)
        
        NSNotificationCenter.defaultCenter().postNotificationName("reformatNavBarWhenVideoIsPlayedNotification", object: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "PlayVideo" {
            let destination = segue.destinationViewController as! AVPlayerViewController
            destination.player = AVPlayer(URL: sender as! NSURL)
            destination.player?.play()
        }
    }
    
    func shareCurrentMessage() {
        
        let speaker = self.messageJson["Speaker"].stringValue
        let title = self.messageJson["Title"].stringValue
        let messageId = self.messageJson["Id"].stringValue

        let firstActivityItem = "\(title) by: \(speaker) | Church of the Highlands http://www.churchofthehighlands.com/media/message/\(messageId)"
        
        let secondActivityItem : NSURL = NSURL(fileURLWithPath: "https://www.churchofthehighlands.com/media/message/\(messageId)")
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [firstActivityItem, secondActivityItem], applicationActivities: nil)
        
        activityViewController.excludedActivityTypes = [
            UIActivityTypePostToWeibo,
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo,
            UIActivityTypePostToTencentWeibo
        ]
        
        activityViewController.popoverPresentationController?.sourceView = self.shareSheetSourceView
        self.presentViewController(activityViewController, animated: true, completion: nil)

    }
    
    func hideMessageButton() {
        self.messageHeightConstraint.constant = 0
        self.watchMessageView.hidden = true
        self.messageUnderline.hidden = true
    }
    
    func hideWorshipButton() {
        self.watchWorhipHeightConstraint.constant = 0
        self.watchWorshipView.hidden = true
//        self.worshipUnderline.hidden = true
    }
    
    func hideListenButton() {
        self.listenHeightConstraint.constant = 0
        self.listenVew.hidden = true
        self.listenUnderline.hidden = true
    }
    
    func loadNotes() {
        request(.GET, "https://notes.highlandsapp.com/api/v2/notes/\(messageIdentifier)", parameters: ["format": "json"])
            .responseJSON { request, _, data in
                guard let json = data.value
                    else { return }

                // Deserialize Note Data
                if let note : Note = NoteSerializer.deserialize(json) {
                    self.note = note
                    
                    // Hide notes if noteId is 0
                    if note.id == 0 {
                        self.notesHeightConstraint.constant = 0
                        self.notesView.hidden = true
                        self.notesUnderline.hidden = true
                    }
                }
            }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Setting up using different Size Classes for iPad portrait and landscape
    func setUpReferenceSizeClasses() {
    }
    
    override func viewDidAppear(animated: Bool) {
        // hide status bar in landscape when leaving a video only on iPhone
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone) {
            if self.view.frame.width > self.view.frame.height {
                UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Fade)
            }
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        willTransitionToPortrait = self.view.frame.size.height > self.view.frame.size.width
        
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        willTransitionToPortrait = size.height > size.width
    }
    
    @available(iOS 8.0, *)
    override func overrideTraitCollectionForChildViewController(childViewController: UIViewController) -> (UITraitCollection!) {
        let traitCollection_hRegular : UITraitCollection = UITraitCollection(verticalSizeClass: .Regular)
        let traitCollection_wRegular : UITraitCollection = UITraitCollection(horizontalSizeClass: .Regular)
        let traitCollection_hAny : UITraitCollection = UITraitCollection(verticalSizeClass: .Unspecified)
        
        // iPad Landscape
        let traitCollectionRegular_Any = UITraitCollection(traitsFromCollections: [traitCollection_hAny, traitCollection_wRegular])
        // iPad Portrait
        let traitCollectionRegular_Regular = UITraitCollection(traitsFromCollections: [traitCollection_hRegular, traitCollection_wRegular])
        
        let traitCollection = (willTransitionToPortrait) ? traitCollectionRegular_Regular : traitCollectionRegular_Any
        
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            return traitCollection
        } else {
            return self.traitCollection
        }
    }

}
