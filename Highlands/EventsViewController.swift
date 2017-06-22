//
//  EventsViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/6/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

protocol EventsViewDelegate {
    func goToEventDetails(eventDetails : EventDetailsViewControllerParameters)
}

class EventsViewController: UIViewController {

    var delegate : EventsViewDelegate!
    var events = JSON("")
    @IBOutlet weak var tableview: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // [JG] - There may be a more elegant way of doing this but if the tableview loads while the
        // animation is still in progress it will stutter
        delay(0.2, closure: { () -> () in
            request(.GET, "https://api.churchofthehighlands.com/events", parameters: ["format": "json"])
                .responseJSON { _, _, json  in
                    self.events = JSON(json.value!)
                    self.tableview.reloadData()
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UITableViewDataSource

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.events.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            return 150
        }
        return 100
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
        let cell = tableView.dequeueReusableCellWithIdentifier("EventsCell") as! EventsTableViewCell
        
        let imageURL = self.events[indexPath.item]["Image"].string
        if (imageURL != nil) {
            cell.eventImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
        }
        cell.titleLabel.text = self.events[indexPath.row]["Name"].stringValue

        // [JG] They use a different date format on the call specifically. :(
        let dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "yyyy-MM-dd"
        let date = dateFormat.dateFromString(self.events[indexPath.row]["Date"].stringValue)
        let newDateFormat = NSDateFormatter()
        newDateFormat.dateStyle = NSDateFormatterStyle.LongStyle
        cell.dateLabel.text = newDateFormat.stringFromDate(date!)
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let subJson = self.events[indexPath.item] as JSON
        let eventDetails = EventDetailsViewControllerParameters()
        eventDetails.eventJson = subJson
        self.delegate.goToEventDetails(eventDetails)
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
