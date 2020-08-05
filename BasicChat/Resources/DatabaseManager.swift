//
//  DatabaseManager.swift
//  BasicChat
//
//  Created by Brian Zhu on 7/4/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    static let shared = DatabaseManager()
    
    private let database = Database.database().reference()
    
    static func safeEmail (emailAddress: String) -> String {
        var safeEmail = emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}

//MARK: - Account Management
extension DatabaseManager {
    public func userExists(with email: String, completion: @escaping ((Bool) -> Void)){
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value, with: {snapshot in
            guard snapshot.value != nil else {
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
            ], withCompletionBlock: { error, _ in
                guard error == nil else {
                    print ("Failed to write to database")
                    completion(false)
                    return
                }
                
                self.database.child("users").observeSingleEvent(of: .value, with: { snapshot in
                    if var usersCollection = snapshot.value as? [[String: String]] {
                        //append to user dictionary
                        let newElement = [
                                "name": user.firstName + " " + user.lastName,
                                "email": user.safeEmail
                        ]
                        usersCollection.append(newElement)
                        
                        self.database.child("users").setValue(usersCollection, withCompletionBlock: {error, _ in
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
                        
                        self.database.child("users").setValue(viewCollection, withCompletionBlock: {error, _ in
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
    }
}


// MARK: - Sending messages / conversations
extension DatabaseManager {
    
    ///Creates a new conversation with target user email and first message sent
    public func createNewConversation(with otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentEmail)
        
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard var userNode = snapshot.value as? [String:Any] else {
                completion(false)
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
                "latest_message": [
                    "date": dateString,
                    "is_read": false,
                    "message": message
                ],
            ]
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                //conversation array exists for current user, append messages
                conversations.append(newConversationData)
                userNode["conversations"] = conversations
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error==nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
            else {
                //conversation array does not exists
                userNode["conversations"] = [newConversationData]
                ref.setValue(userNode, withCompletionBlock: { error, _ in
                    guard error==nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(conversationId: conversationId, firstMessage: firstMessage, completion: completion)
                })
            }
        })
    }
    
    private func finishCreatingConversation (conversationId: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
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
            completion(false)
            return
        }
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [collectionMessage],
            
        ]
        
        print ("adding convo: \(conversationId)")
        
        database.child("\(conversationId)").setValue(value, withCompletionBlock: { error, _ in
            guard error == nil else {
                completion (false)
                return
            }
            completion (true)
        })
    }
    
    ///Fetches and returns all conversations for the user with passed in email
    public func getAllConversations(for email: String, completion: @escaping (Result<String, Error>) -> Void ) {
        
    }
    
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversation(with id: String, completion: @escaping (Result<String, Error>) -> Void) {
        
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation: String, message: Message, completion: @escaping (Bool) -> Void) {
        
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
