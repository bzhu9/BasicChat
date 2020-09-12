//
//  AnnouncementsViewController.swift
//  BasicChat
//
//  Created by Kyle Xu on 8/30/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit



class AnnouncementsViewController: UIViewController {
    
    private var announcements = [Announcement]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.tableFooterView = UIView(frame: .zero)
        table.register(AnnouncementTableViewCell.self, forCellReuseIdentifier: AnnouncementTableViewCell.identifier)
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let composeButton = UIBarButtonItem(barButtonSystemItem: .add,
                                            target: self,
                                            action: #selector(didTapComposeButton))
        view.addSubview(tableView)
        navigationItem.rightBarButtonItems = [composeButton]
        startListeningForAnnouncements()
        tableView.delegate = self
        tableView.dataSource = self

        // Do any additional setup after loading the view.
    }
    @objc private func didTapComposeButton(){
        AnnouncementsDatabaseManager.shared.createNewAnnouncement(with: Announcement(authorName: "Brian Zhu", authorEmail: "bzhu", title: "My first post", description: "wow look this is my first post!", organization: "Test", photoURLS: ["testurl"], comments: [Comment(senderName: "Kyle Xu", senderEmail: "kxu", commentText: "Wow this ia great post!")]), completion: {_ in
            print("Success")
        })
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }    
    private func startListeningForAnnouncements(){
        print("Starting announcements fetch...")
        AnnouncementsDatabaseManager.shared.getAllAnouncements({ [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result{
            case .success(let announcements):
                strongSelf.announcements = announcements
                DispatchQueue.main.async {
                    strongSelf.tableView.reloadData()
                }
            case .failure(let error):
                print("Failed to get announcements: \(error)")
            }
        })
    }
}

extension AnnouncementsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return announcements.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = announcements[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: AnnouncementTableViewCell.identifier, for: indexPath) as! AnnouncementTableViewCell
        cell.configure(with: model)
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 300
    }
    
    
}
