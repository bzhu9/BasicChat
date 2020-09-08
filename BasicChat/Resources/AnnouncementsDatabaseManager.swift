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
            let announcementID = "\(announcement.organisation)_\(dateString)"
            
            let newAnnouncement: [String: Any] = [
                "id": announcementID,
                "author_name": announcement.authorName,
                "author_email": announcement.authorEmail,
                "title": announcement.title,
                "description": announcement.description,
                "photoURLS": announcement.photoURLS,
                "comments": announcement.comments
            ]
            
            // if announcements node exists
            if var allOrganisations = snapshot.value as? [String: [[String: Any]]] {
                //if specific organisation exists
                if var organisation = allOrganisations[announcement.organisation] {
                    organisation.append(newAnnouncement)
                    allOrganisations[announcement.organisation] = organisation
                }
                else {
                    //create organisation node
                    allOrganisations["\(announcement.organisation)"] = [newAnnouncement]
                }
                
                strongSelf.database.child("announcements").setValue(allOrganisations, withCompletionBlock: {error, _ in
                    guard error == nil else {
                        completion (.failure(DatabaseManager.DatabaseError.failedToFetch))
                        return
                    }
                    completion (.success(announcementID))
                })
                
            }
            else {
                //create announcements node
                let organisationCollection: [String: [[String: Any]]] =
                [
                    "\(announcement.organisation)": [newAnnouncement]
                ]
                strongSelf.database.child("announcements").setValue(organisationCollection) { error, _ in
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
