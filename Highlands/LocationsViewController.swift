//
//  LocationsViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 5/6/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

protocol LocationsViewDelegate {
    func goToLocationDetails(locationDetails : LocationDetailsViewControllerParameters)
}

class LocationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var delegate : LocationsViewDelegate!
    @IBOutlet weak var tableView: UITableView!
    var locations = JSON("")

    override func viewDidLoad() {
        super.viewDidLoad()

        // [JG] - There may be a more elegant way of doing this but if the tableview loads while the
        // animation is still in progress it will stutter
        delay(0.2, closure: { () -> () in
            request(.GET, "https://api.churchofthehighlands.com/campuses", parameters: ["format": "json"])
                .responseJSON { (_, _, json) in
                    self.locations = JSON(json.value!)
                    self.tableView.reloadData()
            }
        })
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.locations.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            return 150
        }
        return 70
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationsCell") as! LocationsTableViewCell
        
        var imageURL = self.locations[indexPath.item]["Image"].string
        // We need to add _large into the URL to get a specific image
        // Find the last slash
        let rangeOfLastSlashInUrlSlug = imageURL?.rangeOfString("/", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil)
        // stick _large into the URL
        imageURL?.replaceRange(rangeOfLastSlashInUrlSlug!, with: "/_large/")
        
        if (imageURL != nil) {
            cell.campusImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
        }
        cell.locationNameLabel.text = self.locations[indexPath.row]["Name"].stringValue.uppercaseString
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let subJson = self.locations[indexPath.item] as JSON
        let locationDetails = LocationDetailsViewControllerParameters()
        locationDetails.locationJson = subJson
        self.delegate.goToLocationDetails(locationDetails)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
