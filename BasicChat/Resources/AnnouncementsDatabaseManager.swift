//
//  AnnouncementsDatabaseManager.swift
//  BasicChat
//
//  Created by Brian Zhu on 9/7/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation
import FirebaseDatabase

/// Announcements manager object to read and write data to the real time firebase database
final class AnnouncementsDatabaseManager{
    /// Shared instance of class
    public static let shared = AnnouncementsDatabaseManager()
    
    private let database = Database.database().reference()
}

//MARK: - Creating / Editing Announcements
extension AnnouncementsDatabaseManager {

    public func createNewAnnouncement (with announcement: Announcement, completion: @escaping (Result<String, Error>) -> Void) {
        let safeEmail = DatabaseManager.safeEmail(emailAddress: announcement.authorEmail)
        database.child("announcements").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            
            guard let strongSelf = self else {
                return
            }
            
            // ANNOUNCEMENT ID
            let dateString = ChatViewController.dateFormatter.string(from: Date())
            let announcementID = "\(announcement.organization)_\(dateString)"
            
            var formattedComments = [[String: String]]()
            for comment in announcement.comments {
                let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: comment.senderEmail)
                formattedComments.append([
                    "sender_name": comment.senderName,
                    "sender_email": safeSenderEmail,
                    "text": comment.commentText
                ])
            }
            
            let newAnnouncement: [String: Any] = [
                "id": announcementID,
                "author_name": announcement.authorName,
                "author_email": safeEmail,
                "title": announcement.title,
                "description": announcement.description,
                "photoURLS": announcement.photoURLS,
                "comments": formattedComments
            ]
            
            // if announcements node exists
            if var allOrganizations = snapshot.value as? [String: [[String: Any]]] {
                //if specific organization exists
                if var organization = allOrganizations[announcement.organization] {
                    organization.append(newAnnouncement)
                    allOrganizations[announcement.organization] = organization
                }
                else {
                    //create organization node
                    allOrganizations["\(announcement.organization)"] = [newAnnouncement]
                }
                
                strongSelf.database.child("announcements").setValue(allOrganizations, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        completion (.failure(DatabaseManager.DatabaseError.failedToFetch))
                        return
                    }
                    completion (.success(announcementID))
                })
                
            }
            else {
                //create announcements node
                let organizationCollection: [String: [[String: Any]]] =
                    [
                        "\(announcement.organization)": [newAnnouncement]
                ]
                strongSelf.database.child("announcements").setValue(organizationCollection) { error, _ in
                    guard error == nil else {
                        completion (.failure(DatabaseManager.DatabaseError.failedToFetch))
                        return
                    }
                    completion (.success(announcementID))
                }
            }
        })
    }
}

extension AnnouncementsDatabaseManager {
    public func getAllAnouncements(_ completion: @escaping(Result<[Announcement], Error>) -> Void) {
        database.child("announcements").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [String:Any] else {
                completion(.failure(DatabaseManager.DatabaseError.failedToFetch))
                return
            }
            var announcements = [Announcement]()
            for organization in value {
                guard let announcementsArray = organization.value as? [[String:Any]] else {
                    return
                }
                let organizationAnnouncements: [Announcement] = announcementsArray.compactMap({ dictionary in
                    guard let name = dictionary["author_name"] as? String,
                        let email = dictionary["author_email"] as? String,
                        let description = dictionary["description"] as? String,
                        let title = dictionary["title"] as? String,
                        let photoURLS = dictionary["photoURLS"] as? [String],
                        let commentDict = dictionary["comments"] as? [[String: String]] else {
                            return nil
                    }
                    let comments: [Comment] = commentDict.compactMap({ dict in
                        guard let senderName = dict["sender_name"],
                            let senderEmail = dict["sender_email"],
                            let text = dict["text"] else {
                                return nil
                        }
                        return Comment(senderName: senderName, senderEmail: senderEmail, commentText: text)
                    })
                    return Announcement(authorName: name, authorEmail: email, title: title, description: description, organization: organization.key, photoURLS: photoURLS, comments: comments)
                })
                announcements.append(contentsOf: organizationAnnouncements)
            }
            completion(.success(announcements))
        })
    }
}
