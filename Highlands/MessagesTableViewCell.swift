//
//  MessagesTableViewCell.swift
//  Highlands
//
//  Created by Raiden Honda on 5/12/15.
//  Copyright (c) 2015 Church of the Highlands. All rights reserved.
//

import UIKit

class MessagesTableViewCell: UITableViewCell {

    @IBOutlet weak var messageTitle: UILabel!
    @IBOutlet weak var speakerName: UILabel!
    @IBOutlet weak var imagePreview: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
