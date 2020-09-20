//
//  NewAnnouncementsViewController.swift
//  BasicChat
//
//  Created by Kyle Xu on 9/18/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit

class NewAnnouncementsViewController: UIViewController {

    
    @IBOutlet weak var titleField: UITextView!
    @IBOutlet weak var descriptionField: UITextView!
    
    private func setupFields(){
        titleField.layer.borderColor = UIColor.placeholderText.cgColor
        titleField.layer.borderWidth = 1.0
        titleField.layer.cornerRadius = 8
        titleField.delegate = self
        
        descriptionField.layer.borderColor = UIColor.placeholderText.cgColor
        descriptionField.layer.borderWidth = 1.0
        descriptionField.layer.cornerRadius = 8
        descriptionField.delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFields()
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

extension NewAnnouncementsViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == .placeholderText {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            if textView.accessibilityIdentifier == "Title" {
                textView.text = "Title"
            }
            if textView.accessibilityIdentifier == "Description" {
                textView.text = "Description"
            }
            textView.textColor = .placeholderText
        }
        textView.resignFirstResponder()
    }
}
