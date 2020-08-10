//
//  PhotoViewerViewController.swift
//  BasicChat
//
//  Created by Brian Zhu on 6/29/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit
import SDWebImage

class PhotoViewerViewController: UIViewController {

    private let url: URL
    
    init (with url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Photo"
        view.backgroundColor = .black
        view.addSubview(imageView)
        imageView.sd_setImage(with: self.url, completed: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imageView.frame = view.bounds
    }
}
