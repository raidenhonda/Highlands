//
//  LocationsTableViewCell.swift
//  Highlands
//
//  Created by Raiden Honda on 6/17/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class LocationsTableViewCell: UITableViewCell {

    @IBOutlet weak var campusImageView: UIImageView!
    @IBOutlet weak var locationNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        // [JG] iPad Text Size Changes
        if (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad) {
            self.locationNameLabel.font = UIFont(name: self.locationNameLabel.font.fontName, size: 22);
        }
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
