//
//  AnnouncementTableViewCell.swift
//  BasicChat
//
//  Created by Kyle Xu on 8/30/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit

class AnnouncementTableViewCell: UITableViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .bold)
//        label.text = "El Primo Title"
        label.textAlignment = .center
        return label
    }()
    private let descriptionLabel: UILabel = {
        let label = UILabel()
//        label.text = "ELLLLLLL PRIMOOOOOOOO ELLLLLLL PRIMOOOOOOOO ELLLLLLL PRIMOOOOOOOO ELLLLLLL PRIMOOOOOOOO ELLLLLLL PRIMOOOOOOOO"
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.textAlignment = .left
        label.numberOfLines = 0
        //label.lineBreakMode = NSLineBreakMode.byWordWrapping
        return label
    }()
    
    static let identifier = "AnnouncementTableViewCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 0, y: 10, width: contentView.width, height: 20)
        descriptionLabel.frame = CGRect(x: 10, y: titleLabel.bottom+10, width: contentView.width, height: (contentView.height-10)/2)
        
    }
    
    public func configure (with model: Announcement) {
        titleLabel.text = model.title
        descriptionLabel.text = model.description
    }
}
