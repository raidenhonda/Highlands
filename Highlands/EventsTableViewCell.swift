//
//  EventsTableViewCell.swift
//  Highlands
//
//  Created by Raiden Honda on 6/9/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class EventsTableViewCell: UITableViewCell {

    @IBOutlet weak var eventImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var learnMoreLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        // [JG] iPad Text Size Changes
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            self.learnMoreLabel.font = UIFont(name:self.learnMoreLabel.font.fontName , size: 16)
            self.titleLabel.font = UIFont(name:self.titleLabel.font.fontName , size: 22)
            self.dateLabel.font = UIFont(name:self.dateLabel.font.fontName , size: 13)
        }
    }

}
