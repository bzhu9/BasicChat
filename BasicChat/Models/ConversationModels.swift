//
//  ConversationModels.swift
//  BasicChat
//
//  Created by Brian Zhu on 8/30/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation

struct Conversation {
    let id: String
    let otherUsers: [SearchResult]
//    let name: String
    let isGroupChat: Bool
//    let otherUserEmails: [String]
    let latestMessage: LatestMessage
}

extension Conversation: Comparable{
    static func < (lhs: Conversation, rhs: Conversation) -> Bool {
        let lhsDateObject = ChatViewController.dateFormatter.date(from: lhs.latestMessage.date)
        let rhsDateObject = ChatViewController.dateFormatter.date(from: rhs.latestMessage.date)
        if lhsDateObject?.compare(rhsDateObject!) == .orderedAscending{
            return true
        }
        return false
    }
    
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        let lhsDateObject = ChatViewController.dateFormatter.date(from: lhs.latestMessage.date)
        let rhsDateObject = ChatViewController.dateFormatter.date(from: rhs.latestMessage.date)
        if lhsDateObject?.compare(rhsDateObject!) == .orderedSame{
            return true
        }
        return false
    }
}

struct LatestMessage {
    let date: String
    let text: String
    let read: Bool
}
