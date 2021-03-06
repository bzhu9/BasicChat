//
//  ConversationTableViewCell.swift
//  BasicChat
//
//  Created by Brian Zhu on 8/5/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identifier = "ConversationTableViewCell"
    
    private let unreadDot: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 42, weight: .semibold)
        label.textColor = .link
        label.text = "•"
        label.isHidden = true
        return label
    }()
    
    private let userImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 75/2 //Width and height divided by 2
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let userMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .regular)
        label.numberOfLines = 0
        
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(userMessageLabel)
        contentView.addSubview(unreadDot)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        unreadDot.frame = CGRect(x: 5,
                                 y: contentView.height/2-10,
                                 width: 20,
                                 height: 20)
        userImageView.frame = CGRect(x: 30,
                                     y: 20,
                                     width: 75,
                                     height: 75)
        userNameLabel.frame = CGRect(x: userImageView.right + 10,
                                     y: 10,
                                     width: contentView.width - 20 - userImageView.width,
                                     height: (contentView.height - 20)/4)
        userMessageLabel.frame = CGRect(x: userImageView.right + 10,
                                        y: userNameLabel.bottom + 10,
                                        width: contentView.width - 20 - userImageView.width,
                                        height: 3*(contentView.height - 20)/4)
    }
    public func configure (with model: Conversation) {
        var path: String
        if model.isGroupChat{
            userNameLabel.text = model.id
            path = "images/\(model.otherUsers[0].email)_profile_picture.png"
        }
        else {
            userNameLabel.text = model.otherUsers[0].name
            path = "images/\(model.otherUsers[0].email)_profile_picture.png"
        }
        if !model.latestMessage.read {
            unreadDot.isHidden = false
        }
        if model.latestMessage.kind == "text"{
            userMessageLabel.text = model.latestMessage.text
        }
        else if model.latestMessage.kind == "photo"{
            userMessageLabel.text = "Attachment: 1 Image"
        }
        else if model.latestMessage.kind == "video"{
            userMessageLabel.text = "Attachment: 1 Video"
        }
        else if model.latestMessage.kind == "location"{
            userMessageLabel.text = "Attachment: 1 Location"
        }
        
        
        StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
            switch result{
            case .success(let url):
                DispatchQueue.main.async {
                    self?.userImageView.sd_setImage(with: url, completed: nil)
                }
            case .failure(let error):
                print ("Failed to get image url: \(error)")
            }
        })
    }

}
