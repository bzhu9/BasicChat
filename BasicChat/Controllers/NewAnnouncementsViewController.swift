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
    @IBAction func placeImageButtonTapped(_ sender: Any) {
        addImage()
    }
    
    
    private var photoURLs = [String]()
    
    private func setupFields(){
        titleField.layer.borderColor = UIColor.placeholderText.cgColor
        titleField.layer.borderWidth = 1.0
//        titleField.layer.cornerRadius = 8
        titleField.delegate = self
        
        descriptionField.layer.borderColor = UIColor.placeholderText.cgColor
        descriptionField.layer.borderWidth = 1.0
//        descriptionField.layer.cornerRadius = 8
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
                let email = UserDefaults.standard.value(forKey: "email") as? String,
                var photoURLs = self?.photoURLs
                
                else{
                    return
            }
            if photoURLs.isEmpty {
                photoURLs.append("blah")
            }
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            AnnouncementsDatabaseManager.shared.createNewAnnouncement(with: Announcement(authorName: name, authorEmail: safeEmail, title: title, description: description, organization: "Test", photoURLS: photoURLs, comments: [Comment(senderName: "Kyle Xu", senderEmail: "kxu", commentText: "Wow this ia great post!")]), completion: {_ in
                print("Success")
            })

        })
    }
    
    private func addImage() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        self.present(picker, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        
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
extension NewAnnouncementsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + "test" + ChatViewController.dateFormatter.string(from: Date()) + ".png"
            StorageManager.shared.uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                
                switch result {
                case .success(let urlString):
                    strongSelf.photoURLs.append(urlString)
                    // Ready to send message
                    print ("Uploaded Message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                        let placeholder = UIImage(systemName: "plus") else{
                            return
                    }
                    
                    let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                
                case .failure(let error):
                    print ("message photo upload error: \(error)")
                }
            })
        }
    }
}
