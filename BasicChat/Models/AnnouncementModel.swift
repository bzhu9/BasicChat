//
//  AnnouncementModel.swift
//  BasicChat
//
//  Created by Brian Zhu on 9/7/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation

/// Announcement Object
/// Parameters
/// - `authorName`: Name of author
/// - `authorEmail`:  Author's email
/// - `title`: Title of announcement
/// - `description`: Description of event / purpose of announcement
/// - `organisation`:  Club/organisation the announcement is about
/// - `photoURLS`: Optional photos
/// - `comments`: Array of comments
struct Announcement {
    let authorName: String
    let authorEmail: String
    let title: String
    let description: String
    let organisation: String
    let photoURLS: [String]
    let comments: [Comment]
}

/// Comment Object
/// Parameters
/// - `senderName`: Name of sender
/// - `senderEmail`:  Sender's email
/// - `commentText`:  Text of the comment
struct Comment {
    let senderName: String
    let senderEmail: String
    let commentText: String
}
