//
//  LocationDetailsViewController.swift
//  Highlands
//
//  Created by Raiden Honda on 6/17/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit
import MapKit
import AddressBook

class LocationDetailsViewControllerParameters {
    var locationJson: JSON!
}

class LocationDetailsViewController: UIViewController, MKMapViewDelegate {

    var locationParameters : LocationDetailsViewControllerParameters = LocationDetailsViewControllerParameters()

    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var celebrationServicesLabel: UILabel!
    @IBOutlet weak var weekendAndMidweekServiceListLabel: UILabel!
    @IBOutlet weak var prayerServiceLabel: UILabel!
    @IBOutlet weak var prayerServiceLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var prayerServiceListLabel: UILabel!
    @IBOutlet weak var prayerServiceListLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var prayerServiceBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var campusPastorHeaderLabel: UILabel!
    @IBOutlet weak var campusPastorLabel: UILabel!
    @IBOutlet weak var campusMap: MKMapView!
    @IBOutlet weak var campusMapHeight: NSLayoutConstraint!

    @IBOutlet weak var scrollView: UIScrollView!
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
        
        // Image
        let imageURL = self.locationParameters.locationJson["Image"].string
        if (imageURL != nil) {
            self.locationImageView.sd_setImageWithURL(NSURL(string: imageURL!)!)
        }
        
        // Maps
        let zoomLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(self.locationParameters.locationJson["Latitude"].doubleValue , self.locationParameters.locationJson["Longitude"].doubleValue)
        let metersPerMile = 1609.344
        let viewRegions = MKCoordinateRegionMakeWithDistance(zoomLocation, metersPerMile, metersPerMile)
        self.campusMap.setRegion(viewRegions, animated: true)
        
        let pointAnnotation : MKPointAnnotation = MKPointAnnotation()
        pointAnnotation.coordinate = zoomLocation
        let name = self.locationParameters.locationJson["Name"].stringValue
        pointAnnotation.title = "Church of the Highlands \(name)"
        
        self.campusMap?.addAnnotation(pointAnnotation)
        self.campusMap?.centerCoordinate = zoomLocation
        
        if self.locationParameters.locationJson["Id"].string == "online" {
            let heightConstraint = NSLayoutConstraint(item: self.campusMap,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: nil,
                attribute: NSLayoutAttribute.NotAnAttribute,
                multiplier: 1,
                constant: 0)
            self.campusMap.addConstraint(heightConstraint)
        }
        
        // Service Times
        self.weekendAndMidweekServiceListLabel.text = self.populateServicesLabel()
        self.checkForAndPopulatePrayerServicesLabel()
        
        // Campus Pastor
        let pastorName = self.locationParameters.locationJson["Pastor"]["Name"].stringValue
        if pastorName.characters.count > 0 {
            self.campusPastorLabel.text = pastorName
        } else {
            self.campusPastorLabel.text = ""
            self.campusPastorHeaderLabel.hidden = true
        }
    }
    
    func populateServicesLabel() -> String {
        var serviceTimesString = "Sunday at "
        // Weekend Services
        for (_, services):(String, JSON) in self.locationParameters.locationJson["WeekendServices"] {
            let time = services["Time"].stringValue
            serviceTimesString = serviceTimesString.stringByAppendingString("\(time), ")
        }
        let stringLength = serviceTimesString.characters.count
        serviceTimesString = serviceTimesString.substringToIndex(serviceTimesString.startIndex.advancedBy(stringLength - 2))
        
        // Midweek Services
        let midWeekArray = self.locationParameters.locationJson["MidweekServices"]
        if midWeekArray.count > 0 {
            var midWeekServiesString = "First Wednesday "
            for (_, services):(String, JSON) in self.locationParameters.locationJson["MidweekServices"] {
                let time = services["Time"].stringValue
                midWeekServiesString = midWeekServiesString.stringByAppendingString(time)
            }
            serviceTimesString = "\(serviceTimesString)\n\(midWeekServiesString)"
        }
        
        return serviceTimesString
    }
    
    func checkForAndPopulatePrayerServicesLabel() {
        let prayerServices = self.locationParameters.locationJson["PrayerServices"]
        if prayerServices.count > 0 {
            var prayerServiceString = ""
            for (_, services):(String, JSON) in self.locationParameters.locationJson["PrayerServices"] {
                let time = services["Time"].stringValue
                let day = services["Day"].stringValue
                prayerServiceString = "\(day) at \(time)"
            }
            self.prayerServiceListLabel.text = prayerServiceString
        } else {
            // Set Labels to blank and resize the labels to 0
            self.prayerServiceLabel.text = ""
            self.prayerServiceLabelHeight.constant = 0
            self.prayerServiceListLabel.text = ""
            self.prayerServiceListLabelHeight.constant = 0
            self.prayerServiceBottomConstraint.constant = 0
        }
    }
    
    func mapView (mapView: MKMapView,
        viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
            
            let pinView:MKPinAnnotationView = MKPinAnnotationView()
            pinView.annotation = annotation
            pinView.pinColor = MKPinAnnotationColor.Red
            pinView.animatesDrop = true
            pinView.canShowCallout = true
            
            return pinView
    }
    
    func mapView(mapView: MKMapView,
        didSelectAnnotationView view: MKAnnotationView){
            
            let street = self.locationParameters.locationJson["StreetAddress"].stringValue
            let city = self.locationParameters.locationJson["City"].stringValue
            let state = self.locationParameters.locationJson["State"].stringValue
            let zip = self.locationParameters.locationJson["Zip"].stringValue
            
            let addressDict : [String : String] = [kABPersonAddressStreetKey as String : street,
                kABPersonAddressCityKey as String : city,
                kABPersonAddressStateKey as String : state,
                kABPersonAddressZIPKey as String : zip ]
            
            let placeMark = MKPlacemark(coordinate: view.annotation!.coordinate , addressDictionary: addressDict)
            let mapItem = MKMapItem(placemark: placeMark)
            mapItem.name = view.annotation!.title!
            MKMapItem.openMapsWithItems([mapItem], launchOptions: [:])
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
