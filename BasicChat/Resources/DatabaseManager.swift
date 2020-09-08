//
//  DatabaseManager.swift
//  BasicChat
//
//  Created by Brian Zhu on 7/4/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation
import FirebaseDatabase
import MessageKit
import CoreLocation

/// Group Chats manager object to read and write data to the real time firebase database
final class DatabaseManager{
    /// Shared instance of class
    public static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail (emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

extension DatabaseManager {
    /// Returns dictionary node at child path
    public func getData (path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        })
        
    }
}

//MARK: - Account Management
extension DatabaseManager {
    /// Checks if user exists for given email
    /// Parameters
    /// - `email`:                Target email to be checked
    /// - `completion`:     Async closure to return with result
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        })
    }
    
    
    /// Inserts New User to Database
    public func insertUser(with user: ChatAppUser, completion: @escaping (Bool) -> Void){
        database.child(user.safeEmail).setValue([
            "first_name": user.firstName,
            "last_name": user.lastName
            ], withCompletionBlock: { [weak self] error, _ in
                
                guard let strongSelf = self else {
                    return
                }
                
                guard error == nil else {
                    print ("Failed to write to database")
                    completion(false)
                    return
                }
                
                strongSelf.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        //append to user dictionary
                        let newElement = [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        strongSelf.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
                            guard error == nil else {
                                completion (false)
                                return
                            }
                            completion (true)
                        })
                    }
                    else {
                        //create that array
                        let viewCollection: [[String: String]] = [
                            [
                                    "name": user.firstName + " " + user.lastName,
                                    "email": user.safeEmail
                            ]
                        ]
                        
                        strongSelf.database.child("users").setValue(viewCollection, withCompletionBlock: {error, _ in
                            guard error == nil else {
                                completion (false)
                                return
                            }
                            completion (true)
                        })
                    }
                })
        })
    }
    
    /// Gets all users from database
    public func getAllUsers(completion: @escaping (Result<[[String:String]], Error>) -> Void) {
        database.child("users").observeSingleEvent(of: .value, with: { snapshot in
            guard let value = snapshot.value as? [[String:String]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
            
        })
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
        case userDoesNotExist
    }
}


// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    ///Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, name:String, firstMessage: Message, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": otherUserEmail,
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    "type": firstMessage.kind.messageKindString
                ],
            ]
            
            let recipientNewConversationData: [String: Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    "type": firstMessage.kind.messageKindString
                ],
            ]
            // Update recipient conversation entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    conversations.append(recipientNewConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else {
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipientNewConversationData])
                }
            })
            
            
            // Update current user conversation entry
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists for current user, append messages
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error==nil else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
            else {
                //conversation array does not exists
                userNode["conversations"] = [newConversationData]
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error==nil else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    self?.finishCreatingConversation(name: name, conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation (name: String, conversationId: String, firstMessage: Message, completion: @escaping (Result<String, Error>) -> Void) {
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name
        ]
        
        let value: [String: Any] = [
            "messages": [collectionMessage],
            
        ]
        
        print ("adding convo: \(conversationId)")
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion (.success(conversationId))
        })
    }
    
    ///Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void ) {
        database.child("\(email)/conversations").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                    let name = dictionary["name"] as? String,
                    let otherUserEmail = dictionary["other_user_email"] as? String,
                    let lastestMessage = dictionary["latest_message"] as? [String:Any],
                    let date = lastestMessage["date"] as? String,
                    let message = lastestMessage["message"] as? String,
                    let type = lastestMessage["type"] as? String,
                    let isRead = lastestMessage["is_read"] as? Bool else {
                        return nil
                }
                let lastestMessageObject = LatestMessage(date: date, text: message, read: isRead, kind: type)
                return Conversation(id: conversationId, otherUsers: [SearchResult(name: name, email: otherUserEmail)],isGroupChat: false, latestMessage: lastestMessageObject)
            })
            completion (.success(conversations))
        })
    }
    
    public func getCurrentConversations (for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void ) {
        var conversations = [Conversation]()
        hasConversations(for: email, completion: { [weak self] success in
            guard let strongSelf = self else {
                return
            }
            if success {
                strongSelf.database.child("\(email)/conversations").observeSingleEvent(of: .value, with: { secondSnapshot in
                    guard let secondValue = secondSnapshot.value as? [[String:Any]] else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    conversations = secondValue.compactMap({ dictionary in
                        guard let conversationId = dictionary["id"] as? String,
                            let name = dictionary["name"] as? String,
                            let otherUserEmail = dictionary["other_user_email"] as? String,
                            let lastestMessage = dictionary["latest_message"] as? [String:Any],
                            let date = lastestMessage["date"] as? String,
                            let message = lastestMessage["message"] as? String,
                            let type = lastestMessage["type"] as? String,
                            let isRead = lastestMessage["is_read"] as? Bool else {
                                return nil
                        }
                        let lastestMessageObject = LatestMessage(date: date, text: message, read: isRead, kind: type)
                        return Conversation(id: conversationId, otherUsers: [SearchResult(name: name, email: otherUserEmail)],isGroupChat: false, latestMessage: lastestMessageObject)
                    })
                    completion (.success(conversations))
                })
            }
            else{
                completion (.failure(DatabaseError.failedToFetch))
            }
        })
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        database.child("\(id)/messages").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap({ dictionary in
                guard let name = dictionary["name"] as? String,
                    let isRead = dictionary["is_read"] as? Bool,
                    let messageID = dictionary["id"] as? String,
                    let content = dictionary["content"] as? String,
                    let senderEmail = dictionary["sender_email"] as? String,
                    let dateString = dictionary["date"] as? String,
                    let type = dictionary["type"] as? String,
                    let date = ChatViewController.dateFormatter.date(from: dateString) else {
                        return nil
                }
                
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                
                var kind: MessageKind?
                if type == "photo" {
                    guard let imageUrl = URL(string: content),
                        let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "video" {
                    guard let videoUrl = URL(string: content),
                        let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: videoUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .video(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                        let latitude = Double(locationComponents[1]) else {
                            return nil
                    }
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return nil
                }
                
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: date,
                               kind: finalKind)
            })
            completion (.success(messages))
        })
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion (false)
            return
        }
        
        let currentEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else{
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message,
                        "type": newMessage.kind.messageKindString
                    ]
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        var position = 0
                        var found = false
                        for var convo in currentUserConversations {
                            if let currentId = convo["id"] as? String, currentId == conversation {
                                convo["latest_message"] = updatedValue
                                currentUserConversations[position] = convo
                                found = true
                                break
                            }
                            position+=1
                        }
                        if !found {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_user_email": otherUserEmail,
                                "name": name,
                                "latest_message": updatedValue,
                            ]
                            currentUserConversations.append(newConversationData)
                        }
                        databaseEntryConversations = currentUserConversations
                    }
                    else {
                        let newConversationData: [String: Any] = [
                            "id": conversation,
                            "other_user_email": otherUserEmail,
                            "name": name,
                            "latest_message": updatedValue,
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        
                        // Update latest message for recipient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            var databaseEntryConversations = [[String: Any]]()
                            
                            guard let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
                                return
                            }
                            
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message,
                                "type": newMessage.kind.messageKindString
                            ]
                            if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                var position = 0
                                var found = false
                                for var convo in otherUserConversations {
                                    if let currentId = convo["id"] as? String, currentId == conversation {
                                        convo["latest_message"] = updatedValue
                                        otherUserConversations[position] = convo
                                        found = true
                                    }
                                    position+=1
                                }
                                if !found {
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_user_email": currentEmail,
                                        "name": currentName,
                                        "latest_message": updatedValue,
                                    ]
                                    otherUserConversations.append(newConversationData)
                                }
                                databaseEntryConversations = otherUserConversations
                            }
                            else {
                                let newConversationData: [String: Any] = [
                                    "id": conversation,
                                    "other_user_email": currentEmail,
                                    "name": currentName,
                                    "latest_message": updatedValue,
                                ]
                                databaseEntryConversations = [
                                    newConversationData
                                ]
                            }
                            
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion (true)
                            })
                        })
                    })
                    
                })
            }
            
        })
    }
    
    public func deleteConversation (conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        print("Deleting conversation with id: \(conversationId)")
        //Get all conversations for current user
        //Delete conversation in collection with target id
        //reset those conversations for that user in database
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { snapshot in
            if var conversations = snapshot.value as? [[String: Any]] {
                var positionToRemove = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String,
                        id == conversationId {
                        print("found conversation to delete")
                        break
                    }
                    positionToRemove += 1
                }

                conversations.remove(at: positionToRemove)
                ref.setValue(conversations, withCompletionBlock: { error, _  in
                    guard error == nil else {
                        completion(false)
                        print("faield to write new conversation array")
                        return
                    }
                    print("deleted conversation")
                    completion(true)
                })
            }
        }
    }
    public func conversationExists (with targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DatabaseManager.safeEmail(emailAddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.safeEmail(emailAddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        })
    }
}

// MARK: - Group Chat Messages
/*
 group_chats: {
    id: {
        members: {
        }
        messages: {
        }
    }
 }
 */
extension DatabaseManager {
    public func groupChatExists(id: String, completion: @escaping (Result<String, Error>) -> Void) {
        database.child("group_chats/\(id)").observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.value as? [[String: Any]] != nil else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(id))
            return
        })
    }
    
    public func createNewGroupChat(with otherUsers: [SearchResult], groupChatName: String, firstMessage: Message, completion: @escaping (Result<String, Error>) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(.failure(DatabaseError.failedToFetch))
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let groupChatId = groupChatName
            
            var otherMembers = [[String:Any]]()
            
            for user in otherUsers {
                otherMembers.append(["name": user.name, "email": user.email])
            }
            
            let newGroupChatData: [String: Any] = [
                "id": groupChatId,
                "other_users": otherMembers,
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message,
                    "type": firstMessage.kind.messageKindString
                ],
            ]
            
            otherMembers.append(["name": currentName, "email": safeEmail])
            for user in otherUsers {
                otherMembers.removeAll(where: {
                    $0["email"] as? String == user.email
                })
                let recipientNewGroupChatData: [String: Any] = [
                    "id": groupChatId,
                    "other_users": otherMembers,
                    "latest_message": [
                        "date": dateString,
                        "is_read": false,
                        "message": message,
                        "type": firstMessage.kind.messageKindString
                    ],
                ]
                // Update recipient conversation entry
                self?.database.child("\(user.email)/group_chats").observeSingleEvent(of: .value, with: { [weak self] snapshot in
                    if var groupChats = snapshot.value as? [[String: Any]] {
                        groupChats.append(recipientNewGroupChatData)
                        self?.database.child("\(user.email)/group_chats").setValue(groupChats)
                    }
                    else {
                        self?.database.child("\(user.email)/group_chats").setValue([recipientNewGroupChatData])
                    }
                })
                otherMembers.append(["name": user.name, "email": user.email])
            }
            
            
            // Update current user conversation entry
            var memberEmails = [String]()
            for user in otherUsers {
                memberEmails.append(user.email)
            }
            memberEmails.append(safeEmail)
            if var groupChats = userNode["group_chats"] as? [[String: Any]] {
                //conversation array exists for current user, append messages
                groupChats.append(newGroupChatData)
                userNode["group_chats"] = groupChats
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error==nil else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    self?.finishCreatingGroupChat(groupChatId: groupChatId, members: memberEmails, firstMessage: firstMessage, completion: completion)
                })
            }
            else {
                //conversation array does not exists
                userNode["group_chats"] = [newGroupChatData]
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error==nil else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    self?.finishCreatingGroupChat(groupChatId: groupChatId, members: memberEmails, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingGroupChat (groupChatId: String, members: [String], firstMessage: Message, completion: @escaping (Result<String, Error>) -> Void) {
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                completion(.failure(DatabaseError.failedToFetch))
                return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "name": currentName,
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [collectionMessage],
            "members": members
        ]
        
        print ("adding group chat: \(groupChatId)")
        
        database.child("group_chats/\(groupChatId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion (.success(groupChatId))
        })
    }
    
    public func sendGroupChatMessage(to conversation: String, otherUserEmails: [String], newMessage: Message, completion: @escaping (Bool) -> Void) {
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String,
            let currentName = UserDefaults.standard.value(forKey: "name") as? String else {
                completion (false)
                return
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let strongSelf = self else{
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            }
            
            let newMessageEntry: [String: Any] = [
                "name": currentName,
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false
            ]
            
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                strongSelf.database.child("\(currentUserEmail)/group_chats").observeSingleEvent(of: .value, with: { snapshot in
                    var databaseEntryConversations = [[String: Any]]()
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message,
                        "type": newMessage.kind.messageKindString
                    ]
                    
                    var memberEmails = [String]()
                    
                    for email in otherUserEmails {
                        memberEmails.append(email)
                    }
                    
                    if var currentUserConversations = snapshot.value as? [[String: Any]] {
                        var position = 0
                        var found = false
                        for var convo in currentUserConversations {
                            if let currentId = convo["id"] as? String, currentId == conversation.replacingOccurrences(of: "group_chats/", with: "") {
                                convo["latest_message"] = updatedValue
                                currentUserConversations[position] = convo
                                found = true
                                break
                            }
                            position+=1
                        }
                        if !found {
                            let newConversationData: [String: Any] = [
                                "id": conversation,
                                "other_users": memberEmails,
                                "latest_message": updatedValue,
                            ]
                            currentUserConversations.append(newConversationData)
                        }
                        databaseEntryConversations = currentUserConversations
                    }
                    else {
                        let newConversationData: [String: Any] = [
                            "id": conversation,
                            "other_users": memberEmails,
                            "latest_message": updatedValue,
                        ]
                        databaseEntryConversations = [
                            newConversationData
                        ]
                    }
                    
                    
                    strongSelf.database.child("\(currentUserEmail)/group_chats").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        memberEmails.append(currentUserEmail)
                        // Update latest message for recipient user
                        for otherUserEmail in otherUserEmails {
                            memberEmails.removeAll(where: {
                                $0 == otherUserEmail
                            })
                            strongSelf.database.child("\(otherUserEmail)/group_chats").observeSingleEvent(of: .value, with: { snapshot in
                                var databaseEntryConversations = [[String: Any]]()
                                
                                let updatedValue: [String: Any] = [
                                    "date": dateString,
                                    "is_read": false,
                                    "message": message,
                                    "type": newMessage.kind.messageKindString
                                ]
                                if var otherUserConversations = snapshot.value as? [[String: Any]] {
                                    var position = 0
                                    var found = false
                                    for var convo in otherUserConversations {
                                        if let currentId = convo["id"] as? String, currentId == conversation.replacingOccurrences(of: "group_chats/", with: "") {
                                            convo["latest_message"] = updatedValue
                                            otherUserConversations[position] = convo
                                            found = true
                                        }
                                        position+=1
                                    }
                                    if !found {
                                        let newConversationData: [String: Any] = [
                                            "id": conversation,
                                            "other_users": memberEmails,
                                            "latest_message": updatedValue,
                                        ]
                                        otherUserConversations.append(newConversationData)
                                    }
                                    databaseEntryConversations = otherUserConversations
                                }
                                else {
                                    let newConversationData: [String: Any] = [
                                        "id": conversation,
                                        "other_users": memberEmails,
                                        "latest_message": updatedValue,
                                    ]
                                    databaseEntryConversations = [
                                        newConversationData
                                    ]
                                }
                                
                                strongSelf.database.child("\(otherUserEmail)/group_chats").setValue(databaseEntryConversations, withCompletionBlock: { error, _ in
                                    guard error == nil else {
                                        completion(false)
                                        return
                                    }
                                })
                            })
                        }
                        completion(true)
                    })
                    
                })
            }
            
        })
    }
    
    public func getAllGroupChats (for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void ) {
        var groupChats = [Conversation]()
        database.child("\(email)/group_chats").observe(.value, with: { snapshot in
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            groupChats = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                    let otherUsers = dictionary["other_users"] as? [[String:Any]],
                    let lastestMessage = dictionary["latest_message"] as? [String:Any],
                    let date = lastestMessage["date"] as? String,
                    let message = lastestMessage["message"] as? String,
                    let type = lastestMessage["type"] as? String,
                    let isRead = lastestMessage["is_read"] as? Bool else {
                        return nil
                }
                let lastestMessageObject = LatestMessage(date: date, text: message, read: isRead, kind: type)
                
                var otherMembers = [SearchResult]()
                for user in otherUsers {
                    otherMembers.append(SearchResult(name: user["name"] as! String, email: user["email"] as! String))
                }
                
                return Conversation(id: conversationId, otherUsers: otherMembers, isGroupChat: true, latestMessage: lastestMessageObject)
            })
            completion (.success(groupChats))
        })
    }
    
    public func getCurrentGroupChats (for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void ) {
        var groupChats = [Conversation]()
        hasGroupChats(for: email, completion: { [weak self] success in
            guard let strongSelf = self else {
                return
            }
            if success {
                strongSelf.database.child("\(email)/group_chats").observeSingleEvent(of: .value, with: { secondSnapshot in
                    guard let secondValue = secondSnapshot.value as? [[String:Any]] else {
                        completion(.failure(DatabaseError.failedToFetch))
                        return
                    }
                    groupChats = secondValue.compactMap({ dictionary in
                        guard let conversationId = dictionary["id"] as? String,
                            let otherUsers = dictionary["other_users"] as? [[String:Any]],
                            let lastestMessage = dictionary["latest_message"] as? [String:Any],
                            let date = lastestMessage["date"] as? String,
                            let message = lastestMessage["message"] as? String,
                            let type = lastestMessage["type"] as? String,
                            let isRead = lastestMessage["is_read"] as? Bool else {
                                return nil
                        }
                        var otherMembers = [SearchResult]()
                        for user in otherUsers {
                            otherMembers.append(SearchResult(name: user["name"] as! String, email: user["email"] as! String))
                        }
                        let lastestMessageObject = LatestMessage(date: date, text: message, read: isRead, kind: type)
                         return Conversation(id: conversationId, otherUsers: otherMembers, isGroupChat: true, latestMessage: lastestMessageObject)
                    })
                    completion (.success(groupChats))
                })
            }
            else{
                completion (.failure(DatabaseError.failedToFetch))
            }
        })
    }
    public func hasConversations (for email: String, completion: @escaping (Bool) -> Void) {
        database.child("\(email)/conversations").observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.value as? [[String:Any]] != nil {
                completion(true)
                return
            }
            completion(false)
        })
    }
    
    public func hasGroupChats (for email: String, completion: @escaping (Bool) -> Void) {
        database.child("\(email)/group_chats").observeSingleEvent(of: .value, with: {snapshot in
            if snapshot.value as? [[String:Any]] != nil {
                completion(true)
                return
            }
            completion(false)
        })
    }
}



struct ChatAppUser {
    let firstName: String
    let lastName: String
    let emailAddress: String
    var safeEmail: String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
