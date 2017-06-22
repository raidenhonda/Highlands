//
//  SpotlightProvider.swift
//  Highlands
//
//  Created by Raiden Honda on 1/27/16.
//  Copyright © 2016 Church of the Highlands. All rights reserved.
//

import Foundation
import CoreSpotlight
import MobileCoreServices

public class SpotlightProvider {
    
    static func loadMedia(json : JSON) {

        // iOS 9 Check
        guard #available(iOS 9.0, *) else {
            return
        }
        
        // Execute in background
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            
            // Valid Data Check
            if let messages = json["Messages"].array {
                
                // Create index for each message
                for message in messages {

                    // Create the attribute set
                    let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeApplicationBundle as String)

                    // Pull attributes
                    let messageId = message["Id"].stringValue
                    
                    // Set title
                    let messageTitle = message["Title"].stringValue
                    attributeSet.title = messageTitle
                    
                    // Set Description
                    let messageDateString = message["Date"]["date"].stringValue
                    let dateFormatter = NSDateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let messageDate = dateFormatter.dateFromString(messageDateString)!
                    // If there's a series title include it in the description
                    var description = ""
                    let seriesTitle = message["SeriesTitle"].stringValue
                    if seriesTitle != "Standalone" {
                        description = "\(seriesTitle) - \(messageDate.toShortDateString())"
                    } else {
                        description = messageDate.toShortDateString()
                    }
                    attributeSet.contentDescription = description
                    
                    // Create custom ID of message-id::series-id
                    let seriesId = message["SeriesId"].stringValue
                    let spotlightId = "\(messageId)^\(seriesId)"
                    
                    // Create an item with a unique identifier, a domain identifier, and the attribute set you created earlier.
                    let item = CSSearchableItem(uniqueIdentifier: spotlightId, domainIdentifier: "highlandsMessages", attributeSet: attributeSet)
                    item.expirationDate = NSDate().dateByAddingDays(26 * 7) // Set items to expire after 6-months. This will renew everytime the index is updated (on homescreen load)
                    
                    // NOTE: We add the item to the index after image is downloaded, if there's no image data then we immediately add it

                    // Set image
                    // Get the image set with width equal to 215
                    if let imageJson = message["Images"].array?.filter({ $0["Width"].stringValue == "215" }).first {
                        let imageUrl = imageJson["URL"].stringValue
                        // Download image with SD Cache
                        SDWebImageManager.sharedManager()
                            .downloadImageWithURL(NSURL(string: imageUrl), options:[], progress: nil, completed: { (image, _, _, _, _) -> Void in
                                if let actualImage = image {
                                    item.attributeSet.thumbnailData = UIImageJPEGRepresentation(actualImage, 1.0)
                                }
                                
                                // Add the item to the on-device index.
                                CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
                            })
                    } else {
                        // Add the item to the on-device index.
                        CSSearchableIndex.defaultSearchableIndex().indexSearchableItems([item], completionHandler: nil)
                    } // End if/else image data
                    
                } // End for each message
            }
        }
    }
}
