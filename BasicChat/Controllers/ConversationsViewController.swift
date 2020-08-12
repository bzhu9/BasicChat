//
//  ViewController.swift
//  BasicChat
//
//  Created by Brian Zhu on 6/25/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

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

class ConversationsViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var conversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.tableFooterView = UIView(frame: .zero)
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
        return table
    }()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let composeButton = UIBarButtonItem(barButtonSystemItem: .compose,
                                            target: self,
                                            action: #selector(didTapComposeButton))
        let gcButton = UIBarButtonItem(image: UIImage(systemName: "person.3"),
                                       style: .plain,
                                       target: self,
                                       action: #selector(didTapGroupChatButton))
        navigationItem.rightBarButtonItems = [composeButton, gcButton]
        // Do any additional setup after loading the view.
        view.addSubview(tableView)
        view.addSubview(noConversationsLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversations()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification ,object: nil,queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForConversations()
        })
    }
    
    private func startListeningForConversations() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print ("Starting conversation fetch...")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print ("Successfully got conversation models")
                guard !conversations.isEmpty else {
                    return
                }
                let sortedConversations = conversations.sorted(by: {(lhs:Conversation,rhs:Conversation) -> Bool in
                    return lhs > rhs
                } )
                self?.conversations = sortedConversations
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("Failed to get conversations: \(error)")
            }
        })
    }
    
    @objc private func didTapComposeButton() {
        let vc = NewConversationViewController()
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            if let targetConversation = currentConversations.first(where: {
                $0.otherUsers[0].email == DatabaseManager.safeEmail(emailAddress: result.email)
            }) {
                let vc = ChatViewController(users: targetConversation.otherUsers, id: targetConversation.id, isGroupChat: false)
                vc.isNewConversation = false
                vc.title = targetConversation.otherUsers[0].name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else {
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    // WORK HERE
    @objc private func didTapGroupChatButton() {
        let vc = NewGroupChatViewController()
        vc.completion = { [weak self] result in
            self?.createNewGroupChat(result: result)
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    private func createNewConversation(result: SearchResult) {
        let name = result.name
        let safeEmail = DatabaseManager.safeEmail(emailAddress: result.email)
        
        // check in database if conversation with these two users exists
        DatabaseManager.shared.conversationExists(with: safeEmail, completion: { [weak self] results in
            guard let strongSelf = self else {
                return
            }
            switch results {
            case .success(let conversationId):
                let vc = ChatViewController(users: [SearchResult(name: name, email: safeEmail)], id: conversationId, isGroupChat: false)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(users: [SearchResult(name: name, email: safeEmail)], id: nil, isGroupChat: false)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    private func createNewGroupChat (result: GroupChat) {
        DatabaseManager.shared.groupChatExists(id: result.name, completion: { [weak self] results in
            guard let strongSelf = self else {
                return
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                return
            }
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: myEmail)
            
            var otherUsers = [SearchResult]()
            for member in result.members{
                if member.email != safeEmail {
                    otherUsers.append(member)
                }
            }
            
            switch results {
            case .success(let groupChatId):
                let vc = ChatViewController(users: otherUsers, id: groupChatId, isGroupChat: true)
                vc.isNewConversation = false
                vc.title = result.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(users: otherUsers, id: nil, isGroupChat: true)
                vc.isNewConversation = true
                vc.title = result.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth()
    }
    
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func fetchConversations() {
        tableView.isHidden = false
    }

}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func openConversation (_ model: Conversation) {
        var vc: ChatViewController
        if model.isGroupChat {
            vc = ChatViewController(users: model.otherUsers, id: model.id, isGroupChat: true)
            vc.title = model.id
        }
        else {
            vc = ChatViewController(users: model.otherUsers, id: model.id, isGroupChat: false)
            vc.title = model.otherUsers[0].name
        }
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        
        openConversation(model)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { [weak self] success in
                if success {
                    self?.conversations.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .left)
                }
            })
            
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
