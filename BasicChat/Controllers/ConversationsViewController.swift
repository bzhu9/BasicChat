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

final class ConversationsViewController: UIViewController {
    
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
        startListeningForConversations()
        startListeningForGroupChats ()
        
        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification ,object: nil,queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.startListeningForConversations()
            strongSelf.startListeningForGroupChats ()
        })
    }
    
    @IBAction func crashButtonTapped(_ sender: AnyObject) {
        fatalError()
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
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversations):
                print ("Successfully got conversation models")
                var groupChats = [Conversation]()
                DatabaseManager.shared.getCurrentGroupChats(for: safeEmail, completion: { secondResult in
                    switch secondResult {
                    case .success(let gc):
                        groupChats = gc
                        /*guard !conversations.isEmpty else {
                            return
                        }*/
                        
                    case .failure(let error):
                        print("Failed to get group chats (oof): \(error)")
                    }
                    
                    print(conversations+groupChats)
                    let sortedConversations = (conversations+groupChats).sorted(by: {(lhs:Conversation,rhs:Conversation) -> Bool in
                        return lhs > rhs
                    })
                    
                    if sortedConversations.isEmpty {
                        self?.tableView.isHidden = true
                        self?.noConversationsLabel.isHidden = false
                        print ("hi")
                        return
                    }
                    self?.tableView.isHidden = false
                    self?.noConversationsLabel.isHidden = true
                    
                    strongSelf.conversations = sortedConversations
                    
                    DispatchQueue.main.async {
                        strongSelf.tableView.reloadData()
                    }
                    
                })
            case .failure(let error):
                print("Failed to get conversations: \(error)")
            }
        })
    }
    
    private func startListeningForGroupChats () {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        print ("Starting groupChat fetch...")
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllGroupChats(for: safeEmail, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let groupChats):
                print ("Successfully got group chat models")
                var conversations = [Conversation]()
                DatabaseManager.shared.getCurrentConversations(for: safeEmail, completion: { secondResult in
                    switch secondResult {
                    case .success(let convos):
                        conversations = convos
                        /*guard !groupChats.isEmpty else {
                            return
                        }*/
                        
                    case .failure(let error):
                        print("Failed to get conversations: \(error)")
                    }
                    print(conversations+groupChats)
                    let sortedConversations = (conversations+groupChats).sorted(by: {(lhs:Conversation,rhs:Conversation) -> Bool in
                        return lhs > rhs
                    })
                    
                    if sortedConversations.isEmpty {
                        self?.tableView.isHidden = true
                        self?.noConversationsLabel.isHidden = false
                        return
                    }
                    
                    self?.tableView.isHidden = false
                    self?.noConversationsLabel.isHidden = true
                    
                    strongSelf.conversations = sortedConversations
                    
                    DispatchQueue.main.async {
                        strongSelf.tableView.reloadData()
                    }
                    
                })
            case .failure(let error):
                print("Failed to get group chats: \(error)")
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
        noConversationsLabel.frame = CGRect(x: 10, y: (view.height-100)/2, width: view.width-20, height: 100)
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
    
    func readMessage (_ model: Conversation) {
        DatabaseManager.shared.markAsRead(with: model, completion: { success in
            if !success {
                print ("Error ecured while reading message")
            }
        })
    }
    
    func openConversation (_ model: Conversation) {
        var vc: ChatViewController
        readMessage(model)
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
        var model = conversations[indexPath.row]
        model.latestMessage.read = true
        openConversation(model)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 115
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            DatabaseManager.shared.deleteConversation(conversationId: conversationId, completion: { success in
                if !success {
                    print ("Failed to delete conversation")
                }
            })
            
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
