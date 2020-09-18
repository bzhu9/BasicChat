//
//  AnnouncementTableViewCell.swift
//  BasicChat
//
//  Created by Kyle Xu on 8/30/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit

class AnnouncementTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    public func configure (with model: Announcement) {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
    }
}
