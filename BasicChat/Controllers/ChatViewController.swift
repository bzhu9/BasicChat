//
//  ChatViewController.swift
//  BasicChat
//
//  Created by Brian Zhu on 8/3/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

final class ChatViewController: MessagesViewController {
    
    private var senderPhotoURLS = [String:URL]()
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUsers: [SearchResult]
    private var chatId: String?
    public var isNewConversation = false
    public var isGroupChat: Bool
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "", senderId: safeEmail, displayName: "Joe Smith")
    }
    
    init(users: [SearchResult], id: String?, isGroupChat: Bool) {
        self.otherUsers = users
        print ("hi")
        if id != nil {
            if isGroupChat {
                self.chatId = "group_chats/\(id!)"
            }
            else {
                self.chatId = id
            }
        }
            
        else {
            self.chatId = id
        }
        self.isGroupChat = isGroupChat
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .red
        // Do any additional setup after loading the view.
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInputButton()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside({ [weak self] _ in
            self?.presentInputActionSheet()
        })
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self]_ in
            self?.presentLocationPicker()
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            guard let strongSelf = self else {
                return
            }
            guard let messageId = strongSelf.createMessageId(),
                let chatId = strongSelf.chatId,
                let selfSender = strongSelf.selfSender,
                let name = strongSelf.title else {
                    return
            }
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            print ("long = \(longitude), lat = \(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                    size: .zero)
            let message = Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .location(location))
            var otherUserEmails = [String]()
            for user in strongSelf.otherUsers {
                otherUserEmails.append(user.email)
            }
            if strongSelf.isGroupChat {
                print ("is this called twice?")
                DatabaseManager.shared.sendGroupChatMessage(to: chatId, otherUserEmails: otherUserEmails, newMessage: message, completion: { [weak self] success in
                    if success {
                        print ("Sent location message")
                        self?.messageInputBar.inputTextView.text = nil
                    }
                    else {
                        print ("Failed to send location message")
                    }
                })
            }
            else {
                DatabaseManager.shared.sendMessage(to: chatId, otherUserEmail: otherUserEmails[0], name: name, newMessage: message, completion: { [weak self] success in
                    if success {
                        print ("Sent message")
                        self?.messageInputBar.inputTextView.text = nil
                    }
                    else {
                        print ("Failed to send message")
                    }
                })
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    // Group Chat needs changes
    private func listenforConversationMessages(id: String, shouldScrollToBottom: Bool) {
        DatabaseManager.shared.getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
//                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    self?.messagesCollectionView.reloadData()
                    if shouldScrollToBottom {
                        guard let count = self?.messages.count else {
                            return
                        }
                        //self?.messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: count-1), at: .bottom, animated: true)
                        self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
                    }
                }
            case .failure(let error):
                print("Failed to get messages: \(error)")
            }
        })
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let chatId = chatId {
            listenforConversationMessages(id: chatId, shouldScrollToBottom: true)
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
            let chatId = chatId,
            let selfSender = selfSender,
            let name = self.title else {
                return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //Upload image and send message
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print ("Uploaded Message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else{
                            return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    //CHANGE
                    var otherUserEmails = [String]()
                    for user in strongSelf.otherUsers {
                        otherUserEmails.append(user.email)
                    }
                    if strongSelf.isGroupChat {
                        DatabaseManager.shared.sendGroupChatMessage(to: chatId, otherUserEmails: otherUserEmails, newMessage: message, completion: { success in
                            if success {
                                print ("Sent photo message")
                            }
                            else {
                                print ("Failed to send photo message")
                            }
                        })
                    }
                    else {
                        DatabaseManager.shared.sendMessage(to: chatId, otherUserEmail: otherUserEmails[0], name: name, newMessage: message, completion: { success in
                            if success {
                                print ("Sent photo message")
                            }
                            else {
                                print ("Failed to send photo message")
                            }
                        })
                    }
                
                case .failure(let error):
                    print ("message photo upload error: \(error)")
                }
            })
        }
        else if let videoUrl = info[.mediaURL] as? URL{
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //Upload video and send message
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let urlString):
                    // Ready to send message
                    print ("Uploaded Message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else{
                            return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    //CHANGE
                    var otherUserEmails = [String]()
                    for user in strongSelf.otherUsers {
                        otherUserEmails.append(user.email)
                    }
                    if strongSelf.isGroupChat {
                        DatabaseManager.shared.sendGroupChatMessage(to: chatId, otherUserEmails: otherUserEmails, newMessage: message, completion: { success in
                            if success {
                                print ("Sent video message")
                            }
                            else {
                                print ("Failed to send video message")
                            }
                        })
                    }
                    else {
                        DatabaseManager.shared.sendMessage(to: chatId, otherUserEmail: otherUserEmails[0], name: name, newMessage: message, completion: { success in
                            if success {
                                print ("Sent video message")
                            }
                            else {
                                print ("Failed to send video message")
                            }
                        })
                    }
                case .failure(let error):
                    print ("Message video upload error: \(error)")
                }
            })
            
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
            let selfSender = self.selfSender,
            let messageId = createMessageId() else {
            return
        }
        
        print ("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        //Send Message
        if isNewConversation {
            //create convo in database
            //CHANGE
            if isGroupChat {
                guard let groupChatName = self.title else {
                    return
                }
                DatabaseManager.shared.createNewGroupChat(with: otherUsers, groupChatName: groupChatName, firstMessage: message, completion: { [weak self] result in
                    switch result {
                    case .success(let id):
                        print ("Message Sent")
                        self?.isNewConversation = false
                        self?.chatId = "group_chats/\(id)"
                        self?.messageInputBar.inputTextView.text = nil
                        self?.listenforConversationMessages(id: "group_chats/\(id)", shouldScrollToBottom: true)
                    case .failure(_):
                        print("Failed to send")
                    }
                })
            }
            else {
                DatabaseManager.shared.createNewConversation(with: self.otherUsers[0].email, name: self.title ?? "User", firstMessage: message, completion: { [weak self] result in
                    switch result {
                    case .success(let id):
                        print ("Message Sent")
                        self?.isNewConversation = false
                        self?.chatId = id
                        self?.messageInputBar.inputTextView.text = nil
                        self?.listenforConversationMessages(id: id, shouldScrollToBottom: true)
                    case .failure(_):
                        print("Failed to send")
                    }
                })
            }
        }
        else {
            //not a new conversation
            guard let chatId = chatId, let name = self.title else {
                return
            }
            print (chatId)
            
            //append to existing conversation data
            //CHANGE
            var otherUserEmails = [String]()
            for user in otherUsers {
                otherUserEmails.append(user.email)
            }
            if isGroupChat {
                print ("is this called twice?")
                DatabaseManager.shared.sendGroupChatMessage(to: chatId, otherUserEmails: otherUserEmails, newMessage: message, completion: { [weak self] success in
                    if success {
                        print ("Sent message")
                        self?.messageInputBar.inputTextView.text = nil
                    }
                    else {
                        print ("Failed to send message")
                    }
                })
            }
            else {
                DatabaseManager.shared.sendMessage(to: chatId, otherUserEmail: otherUserEmails[0], name: name, newMessage: message, completion: { [weak self] success in
                    if success {
                        print ("Sent message")
                        self?.messageInputBar.inputTextView.text = nil
                    }
                    else {
                        print ("Failed to send message")
                    }
                })
            }
            
        }
    }
    
    //CHANGE
    private func createMessageId() -> String? {
        //date, otherUserEmail, senderEmail
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let currentUserEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        
        var newIdentifier = ""
        if isGroupChat {
            let groupName = self.title
            newIdentifier = "\(groupName ?? "group")_\(dateString)"
        }
        else {
            newIdentifier = "\(otherUsers[0].email)_\(currentUserEmail)_\(dateString)"
        }
        print("created message id: \(newIdentifier)")
        
        return newIdentifier
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo (let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(
          string: name,
          attributes: [.font: UIFont.systemFont(ofSize: 12)]
        )
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                return 0
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        if message.sender.senderId == safeEmail {
            return 0
        }
        return 20
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        let sender = message.sender
        if self.senderPhotoURLS.keys.contains(sender.senderId){
            avatarView.sd_setImage(with: self.senderPhotoURLS[sender.senderId], completed: nil)
        }
        else {
            let email = message.sender.senderId
            let filename = email + "_profile_picture.png"
            let path = "images/" + filename
            
            StorageManager.shared.downloadURL(for: path, completion: { [weak self] result in
                switch result {
                case .success(let url):
                    DispatchQueue.main.async {
                        avatarView.sd_setImage(with: url, completed: nil)
                    }
                    self?.senderPhotoURLS[sender.senderId] = url
                case .failure(let error):
                    print ("Failed to get download url: \(error)")
                }
            })
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            return .link
        }
        return .secondarySystemBackground
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo (let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video (let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present (vc, animated:  true) {
                  vc.player?.play()
            }
        default:
            break
        }
    }
}
