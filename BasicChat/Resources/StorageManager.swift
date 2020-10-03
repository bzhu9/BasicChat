//
//  StorageManager.swift
//  BasicChat
//
//  Created by Brian Zhu on 8/3/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation
import FirebaseStorage

/// Allows you to get, fetch and upload files to firebase storage
final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard let strongSelf = self else {
                return
            }
            
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            strongSelf.storage.child("images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url return: urlString")
                completion (.success(urlString))
            })
        })
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url return: urlString")
                completion (.success(urlString))
            })
        })
    }
    
    /// Upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        
        let metadata = StorageMetadata()
        //specify MIME type
        metadata.contentType = "video/quicktime"
        
        //convert video url to data
        if let videoData = NSData(contentsOf: fileUrl) as Data? {
            //use 'putData' instead
            storage.child("message_videos/\(fileName)").putData(videoData, metadata: metadata, completion: { [weak self] metadata, error in
                guard error == nil else {
                    //failed
                    print("Failed to upload video file to firebase")
                    completion(.failure(StorageErrors.failedToUpload))
                    return
                }
                self?.storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
                    guard let url = url else {
                        print("Failed to get download url")
                        completion(.failure(StorageErrors.failedToGetDownloadUrl))
                        return
                    }
                    
                    let urlString = url.absoluteString
                    print("download url return: urlString")
                    completion (.success(urlString))
                })
            })
        }
        
    }
    public func uploadAnnouncementPhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("announcement_images/\(fileName)").putData(data, metadata: nil, completion: { [weak self] metadata, error in
            guard error == nil else {
                //failed
                print("Failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self?.storage.child("announcement_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url return: urlString")
                completion (.success(urlString))
            })
        })
    }
    
    public enum StorageErrors: Error {
        case failedToUpload
        
        case failedToGetDownloadUrl
    }
    
    public func downloadURL (for path: String, completion: @escaping (Result<URL, Error>) -> Void ) {
        let reference = storage.child(path)
        
        reference.downloadURL(completion: { url, error in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetDownloadUrl))
                return
            }
            completion(.success(url))
        })
    }
}
