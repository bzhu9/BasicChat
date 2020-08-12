//
//  NewGroupChatViewController.swift
//  BasicChat
//
//  Created by Kyle Xu on 8/11/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit
import JGProgressHUD

struct GroupChat {
    let members: [SearchResult]
    let name: String
    //might need unique id later
}

class NewGroupChatViewController: UIViewController {
    
    public var completion: ((GroupChat) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String:String]]()
    private var hasFetched = false
    
    private var usersInList = [SearchResult]()
    
    private let nameField: UITextField = {
        let field = UITextField()
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Group Chat Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        
        return field
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView(frame: .zero)
        table.register(NewConversationCell.self,
                       forCellReuseIdentifier: NewConversationCell.identifier)
        return table
    }()
    
    private let userLabel: UILabel = {
        let label = UILabel()
        label.text = "Users"
        label.textAlignment = .left
        label.textColor = .black
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    

    private let button: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "person.badge.plus"), for: .normal)
        button.addTarget(self, action: #selector(addUserToList), for: .touchUpInside)
        return button
    }()
    
    @objc private func addUserToList() {
        let vc = UserSearchViewController()
        vc.completion = { [weak self] result in
            self?.usersInList.append(result)
            self?.tableView.reloadData()
        }
        let navVC = UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(nameField)
        view.addSubview(userLabel)
        view.addSubview(button)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        view.backgroundColor = .white
        title = "Create New Group Chat"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissSelf))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createGroupChat))

        
        
        
        // Do any additional setup after loading the view.
    }
    
    @objc private func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func createGroupChat(){
        dismiss(animated: true, completion: { [weak self] in
            guard let groupUsers = self?.usersInList,
                let groupName = self?.nameField.text,
                groupName.replacingOccurrences(of: " ", with: "").count != 0 else {
                    return
            }
            self?.completion?(GroupChat(members: groupUsers, name: groupName))
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        nameField.frame = CGRect(x: 30, y: 70, width: view.width-60, height: 52)
        userLabel.frame = CGRect(x: 30, y: nameField.bottom+10, width: userLabel.intrinsicContentSize.width, height: 52)
        button.frame = CGRect(x: userLabel.right+10, y: nameField.bottom+11, width: button.intrinsicContentSize.width, height: 52)
        tableView.frame = CGRect(x: 30, y: userLabel.bottom+10, width: view.width-60, height: view.height-userLabel.bottom-10)
    }
    
    

   
}

extension NewGroupChatViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersInList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = usersInList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}
