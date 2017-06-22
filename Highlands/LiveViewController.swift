//
//  LiveViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/6/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class LiveViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var countdownLbl: UILabel!
    @IBOutlet weak var minuteTimer: MinuteTimer!
    @IBOutlet weak var countdownContainer: UIView!
    @IBOutlet weak var eventDateLabel: UILabel!
    @IBOutlet weak var eventTitle: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var firstEventDate : NSDate = NSDate()
    var countdownTimer : NSTimer = NSTimer()
    var events : [(startTime: NSDate, title: String)] = []
    var times : [((startTime: NSDate, title: String))] = []
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // [JG] - There may be a more elegant way of doing this but if the tableview loads while the
        // animation is still in progress it will stutter
        delay(0.2, closure: { () -> () in
            self.loadApi()
        })
        
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            countdownLbl.font = UIFont(name: self.countdownLbl.font.fontName, size: 34)
        }
    }
    
    func loadApi() {
        // Get the live data
        var json = JSON("")
        request(.GET, "https://api.churchofthehighlands.com/live", parameters: ["format":"json"])
            .responseJSON { _, _, data in
                json = JSON(data.value!)
                
//                let timeTilNextEvent = json["TimeToNextEvent"].int
                let isLiveInteger = json["Live"].int
                let isLive : Bool = (isLiveInteger == 1) ? true : false
                
                // Iterate over all the events and add to list
                for (_, subJson):(String, JSON) in json["Times"] {
                    let startTime = subJson["Start"].universalDate
                    let title = subJson["Title"].stringValue
                    self.events.append((startTime: startTime!, title: title))
                }
                
                // Configure the Countdown Label
                if self.events.count > 0 {
                    self.firstEventDate = self.events[0].startTime // The events are ordered from API
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
                    let dateString = dateFormatter.stringFromDate(self.firstEventDate)
                    self.eventDateLabel.text = dateString
                    self.eventTitle.text = self.events[0].title != "" ? self.events[0].title : "Sunday Service"
                }
                
                // Configure the time bubbles and reload collectionView
                self.times = self.events.filter { (startTime, title) -> Bool in
                    self.areDatesOnSameDay(startTime, bDate: self.firstEventDate)
                }
                self.collectionView.reloadData()
                
                // Depending on live status display media player or countdown timer
                // isLive = true
                if (isLive) {
                    self.countdownContainer.hidden = true
                } else {
                    if self.events.count > 0 {
                        self.configureCountdownTimer()
                    }
                }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return times.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("TimeBubbleCell", forIndexPath: indexPath) as! TimeBubbleCell

        let dateFormatter : NSDateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "h:mma"
        let event = self.times[indexPath.item]
        cell.timeLabel.text = dateFormatter.stringFromDate(event.startTime).lowercaseString
        
        let timeBubble : TimeBubble = TimeBubble(point: CGPointMake(0, 0), timeString: "", date: event.startTime)
        timeBubble.backgroundColor = UIColor.clearColor()
        cell.addSubview(timeBubble)
        
        let touch = UITapGestureRecognizer(target: self, action: "timeBubblePressed:")
        timeBubble.addGestureRecognizer(touch)
        
        return cell
    }
    
    
    func timeBubblePressed(sender: UIGestureRecognizer) {
        // Check user notification settings
        guard #available(iOS 8.0, *) else {
            return
        }
        
        let userNotificationSettings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if let notificationSettings = userNotificationSettings {
            if notificationSettings.types == UIUserNotificationType.None {
                return;
            }
        } else {
            return;
        }
        
        // Add the reminder feature
        if let timeBubble : TimeBubble = sender.view as? TimeBubble {

            // Create the notification
            let userNotification = UILocalNotification()
            userNotification.timeZone = NSTimeZone.defaultTimeZone()
            userNotification.soundName = UILocalNotificationDefaultSoundName

            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "h:mm"
            let dateString = dateFormatter.stringFromDate(timeBubble.date)
            userNotification.alertBody = "Church of the Highlands: The service begins at \(dateString)"

            // Create the alert menu
            let alertMenu = UIAlertController(title: nil, message: "Would you like to be notified before the \(dateString) service starts?", preferredStyle: .ActionSheet)

            let tenMinuteAction = UIAlertAction(title: "10 minutes", style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                userNotification.fireDate = timeBubble.date.dateByAddingTimeInterval(-600)
                UIApplication.sharedApplication().scheduleLocalNotification(userNotification)
            })
            
            let oneHourAction = UIAlertAction(title: "1 hour", style: .Default, handler: { (alert: UIAlertAction!) -> Void in
                userNotification.fireDate = timeBubble.date.dateByAddingTimeInterval(-3600)
                UIApplication.sharedApplication().scheduleLocalNotification(userNotification)
            })
            
            let cancelAction = UIAlertAction(title: "Close", style: .Cancel, handler: nil)
            
            alertMenu.addAction(tenMinuteAction)
            alertMenu.addAction(oneHourAction)
            alertMenu.addAction(cancelAction)
            
            if let popoverPresentationController = alertMenu.popoverPresentationController {
                popoverPresentationController.sourceView = timeBubble
                let x = timeBubble.frame.origin.x + (timeBubble.frame.height / 2)
                let y = timeBubble.frame.maxY
                popoverPresentationController.sourceRect = CGRectMake(x, y, 1.0, 1.0)
                popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirection.Up
            }
            self.presentViewController(alertMenu, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func playLiveVideoTapped(sender: AnyObject) {
        self.configureMediaPlayer()
    }
    
    // MARK: Configuring Media Player
    func configureMediaPlayer() {

        // Create/Configure the media controller
        let liveUrl = NSURL(string: "http://live.churchofthehighlands.com/mobile/ios-app")

        let moviePlayerController = MPMoviePlayerViewController(contentURL: liveUrl)
        moviePlayerController.moviePlayer.controlStyle = MPMovieControlStyle.Fullscreen
        moviePlayerController.moviePlayer.scalingMode = MPMovieScalingMode.AspectFit
        moviePlayerController.moviePlayer.shouldAutoplay = false
        
        self.presentMoviePlayerViewControllerAnimated(moviePlayerController)
        
        // [JG] unhide status bar
        UIApplication.sharedApplication().statusBarHidden = false
    }
    
    // MARK: Minute Timer Methods
    func configureCountdownTimer() {
        self.countdownTimer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("updateTimeDisplay"), userInfo: nil, repeats: true)
        self.countdownTimer.fire()
        
        self.animateMinuteTimer(0)
    }
    
    func animateMinuteTimer(revolutions: Double) {
        let duration : Double = 6 // Using a minute per revolution is too slow (aka boring), speed up so it makes 10 a minute
        minuteTimer.animate(UIColor(red: 0.31, green: 0.62, blue: 0.72, alpha: 1.0), duration: duration) {
            self.minuteTimer.animate(UIColor(red: 0.82, green: 0.82, blue: 0.82, alpha: 1.0), duration: duration) {
                // We can't animate indefinitely, so stop animating after an hour
                let revPerMinute = 60 / duration
                let revPerHour = revPerMinute * 60
                if (revolutions < revPerHour) {
                    self.animateMinuteTimer(revolutions + 2)
                }
            }
        }
    }
    
    func updateTimeDisplay() {
        let calendar : NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        // Subtract 10 minutes from time
        let negativeTenMins = NSTimeInterval(10 * 60 * -1)
        let labelDate = self.firstEventDate.dateByAddingTimeInterval(negativeTenMins)
        let components = calendar.components([.Day, .Hour, .Minute, .Second], fromDate: NSDate(), toDate: labelDate, options: [])
        
        let timeString = "\(components.day)d \(components.hour)h \(components.minute)m \(components.second)s"
        
        // [JG] - This makes the switch to Live from ticking the timer
        if timeString == "0d 0h 0m 1s" {
            // Fade out Timer and show Watch Live Button
            
            UIView.animateWithDuration(1.5, delay: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: { () -> Void in
                self.countdownContainer.layer.opacity = 0
                }, completion: nil);
            
            // Hide Timer View after it's faded out.
            delay(2, closure: { () -> () in
                self.countdownContainer.hidden = true
            })
            
            self.countdownTimer.invalidate()
        }
        countdownLbl.text = timeString
    }
    
    // MARK: Helper Methods
    func areDatesOnSameDay(aDate : NSDate, bDate : NSDate) -> Bool {4
        let calendar : NSCalendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)!
        
        let components1 = calendar.components([.Year, .Month, .Day], fromDate: aDate)
        let components2 = calendar.components([.Year, .Month, .Day], fromDate: bDate)
        
        let compDate1 = calendar.dateFromComponents(components1)
        let compDate2 = calendar.dateFromComponents(components2)
        
        if compDate1!.compare(compDate2!) == NSComparisonResult.OrderedSame {
            return true
        }
        
        return false
    }
    
    func delay(delay:Double, closure:()->()) {
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
}
