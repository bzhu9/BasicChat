//
//  LocationPickerViewController.swift
//  BasicChat
//
//  Created by Brian Zhu on 8/21/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class LocationPickerViewController: UIViewController {
    
    public var completion: ((CLLocationCoordinate2D) -> Void)?
    private var coordinates: CLLocationCoordinate2D?
    private var isPickable = true
    
    private let map: MKMapView = {
        let map = MKMapView()
        return map
    }()
    
    init(coordinates: CLLocationCoordinate2D?) {
        super.init(nibName: nil, bundle: nil)
        self.coordinates = coordinates
        self.isPickable = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if isPickable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(sendButtonTapped))
            let gesture = UITapGestureRecognizer(target: self, action: #selector(didTapMap(_:)))
            gesture.numberOfTouchesRequired = 1
            gesture.numberOfTapsRequired = 1
            map.addGestureRecognizer(gesture)
        }
        else {
            guard let coordinates = self.coordinates else {
                return
            }
            //drop pin
            let pin = MKPointAnnotation()
            pin.coordinate = coordinates
            map.addAnnotation(pin)
        }
        view.backgroundColor = .systemBackground
        view.addSubview(map)
        // Do any additional setup after loading the view.
    }
    
    @objc func sendButtonTapped() {
        guard let coordinates = coordinates else {
            return
        }
        navigationController?.popViewController(animated: true)
        completion?(coordinates)
    }
    
    @objc func didTapMap(_ gesture: UITapGestureRecognizer){
        let locationInView = gesture.location(in: map)
        let coordinates = map.convert(locationInView, toCoordinateFrom: map)
        self.coordinates = coordinates
        
        map.removeAnnotations(map.annotations)
        //drop pin
        let pin = MKPointAnnotation()
        pin.coordinate = coordinates
        map.addAnnotation(pin)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        map.frame = view.bounds
    }
}
