//
//  AnnouncementsViewController.swift
//  BasicChat
//
//  Created by Kyle Xu on 8/30/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit



class AnnouncementsViewController: UIViewController {
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView(frame: .zero)
        table.register(AnnouncementTableViewCell.self, forCellReuseIdentifier: AnnouncementTableViewCell.identifier)
        return table
    }()
    
    private let button: UIButton = {
        let button = UIButton()
        button.setTitle("ADD", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        view.addSubview(button)
        button.addTarget(self,
                              action: #selector(tap),
                              for: .touchUpInside)
        tableView.delegate = self
        tableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    @objc private func tap(){
        AnnouncementsDatabaseManager.shared.createNewAnnouncement(with: Announcement(authorName: "Brian Zhu", authorEmail: "bzhu", title: "My first post", description: "wow look this is my first post!", organisation: "Test", photoURLS: [], comments: []), completion: {_ in
            print("Success")
        })
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //        tableView.frame = view.bounds
        button.frame = CGRect(x: 30,
                                   y: view.height/2,
                                   width: 150,
                                   height: 52)
    }    

}

extension AnnouncementsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AnnouncementTableViewCell.identifier, for: indexPath)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    
}
