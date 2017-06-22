//
//  MessagesHeader.swift
//  Highlands
//
//  Created by Raiden Honda on 5/12/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

protocol MessagesHeaderViewDelegate: class, NSObjectProtocol {
    func sectionHeaderView(sectionHeaderView: MessagesHeader, sectionOpened: Int)
    func sectionHeaderView(sectionHeaderView: MessagesHeader, sectionClosed: Int)
}

class MessagesHeader: UITableViewHeaderFooterView {

    @IBOutlet weak var artworkThumbnail: UIImageView!
    @IBOutlet weak var seriesTitleLabel: UILabel!
    @IBOutlet weak var seriesSubTitleLabel: UILabel!
    @IBOutlet weak var seriesTotalLabel: UILabel!
    
    var isOpen = false
    
    var delegate: MessagesHeaderViewDelegate!
    
    var section: Int = 0
    
    override func awakeFromNib() {
    }

    @IBAction func toggleOpen(sender: AnyObject) {
        toggleOpenWithUserAction(true)
    }
    
    func toggleOpenWithUserAction(userAction: Bool) {

        // If this was a user action, send the delegate the appropriate message
        if userAction {
            
            // We have to manually set this here if the tableview is being reloaded in order to rememeber scroll position
            if MessageViewHistory.sharedInstance.selectedIndex != nil && self.section == MessageViewHistory.sharedInstance.selectedIndex {
                isOpen = true
            }
            
            if !isOpen {
                if self.delegate.respondsToSelector("sectionHeaderView:sectionOpened:") {
                    self.delegate.sectionHeaderView(self, sectionOpened: self.section)
                    isOpen = true
                }
            }
            else {
                if self.delegate.respondsToSelector("sectionHeaderView:sectionClosed:") {
                    self.delegate.sectionHeaderView(self, sectionClosed: self.section)
                    isOpen = false
                }
            }
        }
    }

}
