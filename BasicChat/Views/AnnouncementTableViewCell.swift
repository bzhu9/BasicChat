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
    @IBOutlet weak var clubAuthorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var pictureView: UIImageView!
    
    public func configure (with model: Announcement) {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
        clubAuthorLabel.text = model.organization + " - " + model.authorName
        dateLabel.text = "Oct. 3, 2020 11:30 AM"
        StorageManager.shared.downloadURL(for: model.photoURLS[0], completion: { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.pictureView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print ("Failed to get image url: \(error)")
            }
        })
    }
}
