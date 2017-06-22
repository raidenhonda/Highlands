//
//  MessagesViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/6/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class MessageViewHistory {
    static let sharedInstance = MessageViewHistory()
    var selectedIndex: Int!
}

struct MessagesViewConstants{
    static let CELL_SIZE_IPAD_HEIGHT = 100;
    static let CELL_SIZE_IPHONE_HEIGHT = 70;
    static let CELL_SIZE_IPHONE_HEIGHT_COMPACT = 60;
}

protocol MessagesViewDelegate {
    func goToMessagePlayerView(messageParams: MessagePlayerViewControllerParameters)
}

class MessagesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MessagesHeaderViewDelegate {

    @IBOutlet weak var tableview: UITableView!
    
    var delegate : MessagesViewDelegate!
    let SectionHeaderViewIdentifier = "MessagesHeader"
    var sectionInfoArray: NSMutableArray!
    var opensectionindex: Int! = 0
    
    var messageSeries : [JSON] = []
    var messageDetails = [String: JSON]()
    
    var sectionHeaderView: MessagesHeader!
    var cellHeight = MessagesViewConstants.CELL_SIZE_IPHONE_HEIGHT
    
    @IBOutlet weak var midweekSwitcher: UISegmentedControl!
    var hasSelectedMidWeekMessages = false
    var midWeekMessages: JSON = JSON("")

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.opensectionindex = NSNotFound
        
        let sectionHeaderNib: UINib = UINib(nibName: "MessagesHeader", bundle: nil)
        
        self.tableview.registerNib(sectionHeaderNib, forHeaderFooterViewReuseIdentifier: SectionHeaderViewIdentifier)
        
        if IOSVersion.SYSTEM_VERSION_LESS_THAN("8.0") {
            if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                self.tableview.sectionHeaderHeight = CGFloat(135)
                cellHeight = MessagesViewConstants.CELL_SIZE_IPAD_HEIGHT
            } else {
                self.tableview.sectionHeaderHeight = CGFloat(70)
                cellHeight = MessagesViewConstants.CELL_SIZE_IPHONE_HEIGHT
            }
        }
        
        // [JG] - There may be a more elegant way of doing this but if the tableview loads while the
        // animation is still in progress it will stutter
        delay(0.1, closure: { () -> () in
            
            request(.GET, "https://api.churchofthehighlands.com/v2/media/series", parameters: ["format": "json"])
                .responseJSON { _, _, data in
                    
                    guard let jsonRaw = data.value
                        else { return }

                    let json = JSON(jsonRaw)
                    for (_, subJson):(String, JSON) in json {
                        self.messageSeries.append(subJson)
                    }
                    self.setSectionInfo()
                    self.tableview.reloadData()
                    self.scrollToPosition()
                }
            
            request(.GET, "https://api.churchofthehighlands.com/v2/media/midweek", parameters: ["format": "json"])
                .responseJSON { _, _, data in
                    self.midWeekMessages = JSON(data.value!)
            }
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        // Forget index if they leave the view
        MessageViewHistory.sharedInstance.selectedIndex = nil
    }
    
    func scrollToPosition() {
        if MessageViewHistory.sharedInstance.selectedIndex != nil {
            let sectionRect = self.tableview.rectForHeaderInSection(MessageViewHistory.sharedInstance.selectedIndex)
            let setToTopRect = CGRectMake(sectionRect.origin.x, sectionRect.origin.y + (self.view.frame.height - 100), sectionRect.width, sectionRect.height)
            self.tableview.scrollRectToVisible(setToTopRect, animated: true)

            
            let sectionHeaderView: MessagesHeader = MessagesHeader()
            let sectionInfo: MessageSectionInfo = self.sectionInfoArray[MessageViewHistory.sharedInstance.selectedIndex] as! MessageSectionInfo
            sectionInfo.headerView = sectionHeaderView
            sectionHeaderView.section = MessageViewHistory.sharedInstance.selectedIndex
            sectionHeaderView.delegate = self
            
            // If there aren't any child messages we don't want to pre-select the section
            let countOfRowsToInsert = sectionInfo.seriesJson["MessageCount"].intValue
            if countOfRowsToInsert > 1 {
                self.sectionHeaderView(sectionHeaderView, sectionOpened:MessageViewHistory.sharedInstance.selectedIndex)
            }
            
        }
    }
    
    func setSectionInfo() {
        if self.sectionInfoArray == nil || self.sectionInfoArray.count != self.numberOfSectionsInTableView(self.tableview) {
            
            // For each play, set up a corresponding SectionInfo object to contain the default height for each row.
            let infoArray = NSMutableArray()
            
            for series in self.messageSeries {
                let sectionInfo = MessageSectionInfo()
                sectionInfo.seriesJson = series
                sectionInfo.open = false
                
                infoArray.addObject(sectionInfo)
            }
            
            self.sectionInfoArray = infoArray
        }
    }

    @IBAction func toggleSeriesAndMidWeekMessages(sender: AnyObject) {
        if self.midweekSwitcher.selectedSegmentIndex == 0 {
            // Selected Series Messages
            self.hasSelectedMidWeekMessages = false
        } else {
            // Selected Mid-Week Messages
            self.hasSelectedMidWeekMessages = true
        }
        self.tableview.reloadData()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        if self.hasSelectedMidWeekMessages {
            let countOfMessages = self.midWeekMessages["Messages"].count
            return countOfMessages
        } else {
            return self.messageSeries.count
        }
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if self.hasSelectedMidWeekMessages {
            return 1
        } else {
            let sectionInfo = self.sectionInfoArray[section] as! MessageSectionInfo
            let numStoriesInSection: Int = sectionInfo.seriesJson["MessageCount"].intValue
            
            // [JG] If section is open return message count else return 0
            return sectionInfo.open ? numStoriesInSection : 0
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if self.hasSelectedMidWeekMessages {
            let midweekMessage = self.midWeekMessages["Messages"][indexPath.section]
            
            let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as! MessagesTableViewCell
            
            cell.messageTitle.text = midweekMessage["Title"].string
                    
            let speaker = midweekMessage["Speaker"].stringValue
            cell.speakerName.text = "\(speaker)"
                    
            let imageURL = midweekMessage["Images"][2]["URL"].string

            cell.imagePreview.sd_setImageWithURL(NSURL(string: imageURL!)!)
            
            return cell
        } else {
            let sectionInfo = self.sectionInfoArray[indexPath.section] as! MessageSectionInfo
            
            let messageId : String = sectionInfo.seriesJson["Id"].stringValue
            var returned = JSON("")
            
            let cell = tableView.dequeueReusableCellWithIdentifier("MessageCell") as! MessagesTableViewCell
            
            request(.GET, "https://api.churchofthehighlands.com/v2/media/series/" + messageId, parameters: ["format": "json"])
                .responseJSON { (request, _, json) in
                    returned = JSON(json.value!)
                    sectionInfo.messageSeriesJson = returned // Save the message data back to the variable sectionInfoArray for the media player
                    cell.messageTitle.text = returned["Messages"][indexPath.row]["Title"].string
                    
                    let partNumber = returned["Messages"][indexPath.row]["Number"].stringValue
                    let speaker = returned["Messages"][indexPath.row]["Speaker"].stringValue
                    cell.speakerName.text = "Part \(partNumber) by \(speaker)"
                    
                    var imageURL = returned["Messages"][indexPath.row]["Image"].string
                    if imageURL == "" {
                        imageURL = sectionInfo.seriesJson["Images"][2]["URL"].string
                    }
                    cell.imagePreview.sd_setImageWithURL(NSURL(string: imageURL!)!)
            }
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CGFloat(self.cellHeight)
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.hasSelectedMidWeekMessages {
            return 0
        } else {
            return CGFloat(self.cellHeight)
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if self.hasSelectedMidWeekMessages {
            return nil
        } else {
            let sectionHeaderView: MessagesHeader = self.tableview.dequeueReusableHeaderFooterViewWithIdentifier(SectionHeaderViewIdentifier) as! MessagesHeader
            
            let sectionInfo: MessageSectionInfo = self.sectionInfoArray[section] as! MessageSectionInfo
            sectionInfo.headerView = sectionHeaderView
            
            let imageURL = sectionInfo.seriesJson["Images"][2]["URL"].string
            sectionHeaderView.artworkThumbnail.sd_setImageWithURL(NSURL(string: imageURL!)!)
            
            sectionHeaderView.seriesTitleLabel.text = sectionInfo.seriesJson["Title"].string?.uppercaseString
            
            let dateString = sectionInfo.seriesJson["LastMessageDate"]["date"].string
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date = dateFormatter.dateFromString(dateString!)
            dateFormatter.dateStyle = NSDateFormatterStyle.LongStyle
            sectionHeaderView.seriesSubTitleLabel.text = dateFormatter.stringFromDate(date!)
            
            let total = sectionInfo.seriesJson["MessageCount"].intValue
            
            sectionHeaderView.seriesTotalLabel.text = total > 1 ? String(format: "%i", total) : ""
            
            sectionHeaderView.section = section
            sectionHeaderView.delegate = self
            
            return sectionHeaderView
        }
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let messageParams = MessagePlayerViewControllerParameters()
        
        if self.hasSelectedMidWeekMessages {
            let midweekMessage = self.midWeekMessages["Messages"][indexPath.section]
            
            messageParams.messageSeriesJson = midweekMessage
            messageParams.messageIndex = indexPath.row
            messageParams.isMidWeekMessage = true
            // this is to prevent a crash if the API hasn't returned yet.
            if messageParams.messageSeriesJson != nil {
                self.delegate.goToMessagePlayerView(messageParams)
            }
        } else {
            let sectionInfo = self.sectionInfoArray[indexPath.section] as! MessageSectionInfo
            
            messageParams.messageSeriesJson = sectionInfo.messageSeriesJson
            messageParams.messageIndex = indexPath.row
            // this is to prevent a crash if the API hasn't returned yet.
            if messageParams.messageSeriesJson != nil {
                self.delegate.goToMessagePlayerView(messageParams)
            }
        }
    }
    
    // MARK: - SectionHeaderViewDelegate
    
    func sectionHeaderView(sectionHeaderView: MessagesHeader, sectionOpened: Int) {
        
        let sectionInfo: MessageSectionInfo = self.sectionInfoArray[sectionOpened] as! MessageSectionInfo
        sectionInfo.open = true
        
        MessageViewHistory.sharedInstance.selectedIndex = sectionOpened
        
        /*
        Create an array containing the index paths of the rows to insert: These correspond to the rows for each quotation in the current section.
        */
        let countOfRowsToInsert = sectionInfo.seriesJson["MessageCount"].intValue
        
        if countOfRowsToInsert < 2 {
            let messageParams = MessagePlayerViewControllerParameters()
            messageParams.messageSeriesJson = sectionInfo.seriesJson
            // [JG] - Hard code to the first message
            messageParams.messageIndex = 0
            self.delegate.goToMessagePlayerView(messageParams)
        } else {
            var indexPathsToInsert = [NSIndexPath]()
            for (var i = 0; i < countOfRowsToInsert; i++) {
                indexPathsToInsert.append(NSIndexPath(forRow: i, inSection: sectionOpened))
            }
            
            /*
            Create an array containing the index paths of the rows to delete: These correspond to the rows for each quotation in the previously-open section, if there was one.
            */
            var indexPathsToDelete = [NSIndexPath]()
            
            let previousOpenSectionIndex = self.opensectionindex
            if previousOpenSectionIndex != NSNotFound {
                
                let previousOpenSection: MessageSectionInfo = self.sectionInfoArray[previousOpenSectionIndex] as! MessageSectionInfo
                previousOpenSection.open = false
                previousOpenSection.headerView.toggleOpenWithUserAction(false)
                let countOfRowsToDelete = previousOpenSection.seriesJson["MessageCount"].intValue
                for (var i = 0; i < countOfRowsToDelete; i++) {
                    indexPathsToDelete.append(NSIndexPath(forRow: i, inSection: previousOpenSectionIndex))
                }
            }
            
            // Style the animation so that there's a smooth flow in either direction
            var insertAnimation: UITableViewRowAnimation
            var deleteAnimation: UITableViewRowAnimation
            if previousOpenSectionIndex == NSNotFound || sectionOpened < previousOpenSectionIndex {
                insertAnimation = UITableViewRowAnimation.Top
                deleteAnimation = UITableViewRowAnimation.Bottom
            }
            else {
                insertAnimation = UITableViewRowAnimation.Bottom
                deleteAnimation = UITableViewRowAnimation.Top
            }
            
            // Apply the updates
            self.tableview.beginUpdates()
            self.tableview.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: deleteAnimation)
            self.tableview.insertRowsAtIndexPaths(indexPathsToInsert, withRowAnimation: insertAnimation)
            self.tableview.endUpdates()
            
            self.opensectionindex = sectionOpened
        }
    }
    
    func sectionHeaderView(sectionHeaderView: MessagesHeader, sectionClosed: Int) {
        
        /*
        Create an array of the index paths of the rows in the section that was closed, then delete those rows from the table view.
        */
        let sectionInfo = self.sectionInfoArray[sectionClosed] as! MessageSectionInfo
        
        sectionInfo.open = false
        let countOfRowsToDelete = self.tableview.numberOfRowsInSection(sectionClosed)
        
        if countOfRowsToDelete > 0 {
            var indexPathsToDelete = [NSIndexPath]()
            for (var i = 0; i < countOfRowsToDelete; i++) {
                indexPathsToDelete.append(NSIndexPath(forRow: i, inSection: sectionClosed))
            }
            self.tableview.deleteRowsAtIndexPaths(indexPathsToDelete, withRowAnimation: UITableViewRowAnimation.Top)
        }
        // set to nil b/c if a section is closed we don't remember scroll position
        MessageViewHistory.sharedInstance.selectedIndex = nil
        self.opensectionindex = NSNotFound
    }
    
    @available(iOS 8.0, *)
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        // [JG] - Set the Cell Size depending on the Size Class
        if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact
            && self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Regular){
                if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
                    self.tableview.sectionHeaderHeight = CGFloat(135)
                    cellHeight = MessagesViewConstants.CELL_SIZE_IPAD_HEIGHT
                } else {
                    self.tableview.sectionHeaderHeight = CGFloat(70)
                    cellHeight = MessagesViewConstants.CELL_SIZE_IPHONE_HEIGHT
                }
            
        } else if (self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact) {
            self.tableview.sectionHeaderHeight = CGFloat(60)
            cellHeight = MessagesViewConstants.CELL_SIZE_IPHONE_HEIGHT_COMPACT
        } else {
            self.tableview.sectionHeaderHeight = CGFloat(125)
            cellHeight = MessagesViewConstants.CELL_SIZE_IPAD_HEIGHT
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
}
