//
//  NewAnnouncementsViewController.swift
//  BasicChat
//
//  Created by Kyle Xu on 9/18/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit

class NewAnnouncementsViewController: UIViewController {

    
    @IBOutlet weak var titleField: UITextField!

    @IBOutlet weak var descriptionField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Create", style: .done, target: self, action: #selector(createAnnouncement))

        // Do any additional setup after loading the view.
    }
    
    @objc private func createAnnouncement() {
        dismiss(animated: true, completion: { [weak self] in
            guard let title = self?.titleField.text, let description = self?.descriptionField.text,
                title.replacingOccurrences(of: " ", with: "").count != 0,
                description.replacingOccurrences(of: " ", with: "").count != 0,
                let name = UserDefaults.standard.value(forKey: "name") as? String,
                let email = UserDefaults.standard.value(forKey: "email") as? String
                
                else{
                    return
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            AnnouncementsDatabaseManager.shared.createNewAnnouncement(with: Announcement(authorName: name, authorEmail: safeEmail, title: title, description: description, organization: "Test", photoURLS: ["testurl"], comments: [Comment(senderName: "Kyle Xu", senderEmail: "kxu", commentText: "Wow this ia great post!")]), completion: {_ in
                print("Success")
            })

        })
    }

}
