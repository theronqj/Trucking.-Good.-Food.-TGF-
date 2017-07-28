//
//  ViewController.swift
//  FoodTruck_Working
//
//  Created by Theron Jones on 4/20/17.
//  Copyright © 2017 Theron Jones. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import CoreLocation

class ViewController: UIViewController {

    // MARK: - Variables
    var foodTrucks: [FoodTruck] = []
    var locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var mapView: GMSMapView!
    var placesClient: GMSPlacesClient!
    var zoomLevel: Float = 18.0
    
    // The currently selected place.
    var selectedPlace: GMSPlace?
    
    // A default location to use when location permission is not granted.
    let defaultLocation = CLLocation(latitude: 37.7909, longitude: -122.4016)

    
    // Mobile Food Facility Permited Child Data Set
    let client = sfFoodTruckClients
    
    var markerDictionary: [GMSMarker: Int] = [:]

    var selectedMarker: GMSMarker?
    
    
    // MARK: - Outlets
    @IBOutlet weak var tableViewForCloseFoodTrucks: UITableView!
    @IBOutlet weak var viewOfMap: UIView!
    @IBOutlet weak var mapInfoView: MapInfoView!
    
    
    // MARK: - Overridden Functions
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.distanceFilter = 50
        locationManager.startUpdatingLocation()
        locationManager.delegate = self

        // Get current day
        let currentDay = Date().getDayOfWeek()
        client.get(dataset: "bbb8-hzi6", withFilters: ["dayofweekstr": currentDay], { (result) in
            switch result {
            case .dataset(let data):
                let foodTrucks = data.flatMap{ FoodTruck.decode(fromJSON: $0) }
                self.foodTrucks = foodTrucks
                
                DispatchQueue.main.async {
                    self.addFoodTrucksToMap()
                    self.tableViewForCloseFoodTrucks.reloadData()
                }
                
            case .error(let error):
                print(error)
            }
        })

        // Setup for custom cell registation for that table view, failsafe on tableView.dequeueReusableCell
        tableViewForCloseFoodTrucks.register(UINib(nibName: "FoodTruckTableViewCell", bundle: nil), forCellReuseIdentifier: "cellInTableViewForCloseFoodTrucks")
        
        
        let camera = GMSCameraPosition.camera(withLatitude: defaultLocation.coordinate.latitude,
                                              longitude: defaultLocation.coordinate.longitude,
                                              zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: view.bounds, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        // Adding the map to the view, hiding it until we get a location update.
        mapView.isHidden = true

        
        // Dropping it into our personal view
        mapView.frame = viewOfMap.frame
        viewOfMap.addSubview(mapView)
        viewOfMap.sendSubview(toBack: mapView)
    
        /*  
         No dice, TJ...mapView.selectedMarker?.observeValue(forKeyPath: "icon", of: <#T##Any?#>, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
         */
    }
    
    func addFoodTrucksToMap() {
        for (index, foodTruck) in foodTrucks.enumerated() {
            let marker = GMSMarker()
            // Deprecation of stock colors and implementation of custom switching here
            marker.icon = GMSMarker.markerImage(with: .black)
            marker.title = foodTruck.companyName
            marker.position = foodTruck.location.coordinate
            markerDictionary[marker] = index
            marker.map = mapView
        }
    }

}

// MARK: - VC Extension for _ Food Truck Custom Table View
extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections (in tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView (_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foodTrucks.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableViewForCloseFoodTrucks.dequeueReusableCell(withIdentifier: "cellInTableViewForCloseFoodTrucks", for: indexPath) as? FoodTruckTableViewCell else { return UITableViewCell() }
        let row = foodTrucks[indexPath.row]
        
        cell.delegate = self
        cell.labelCellCompanyName.text = row.companyName
        //cell.imageCellFoodTruck.image = row.picture
        //v1.1 + inclusion of Enum cases for versioning (below)
        //cell.labelCellFoodType.text = row.foodType
        //cell.labelCellLocation.text = row.location
        //cell.labelCellRating.text = String(row.rating)
        return cell
        
    }
}

// MARK: - VC Extension for _ Food Truck Custom Table View Cell Delegate
extension ViewController: FoodTruckTableViewCellDelegate {
    func viewMenuButtonPressed(_ sender: UIButton, forCell cell: UITableViewCell) {
        guard let indexPath = tableViewForCloseFoodTrucks.indexPath(for: cell) else { return }
        let foodTruck = foodTrucks[indexPath.row]
        
        
        let string = "burgers;fries;shakes"
        let parsedString = string.components(separatedBy: ";")
        
        // Segue to pop up view
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PopupViewController") as! PopupViewController
        vc.foodTruck = foodTruck
        
        self.addChildViewController(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
        
        //self.present(vc, animated: true, completion: nil)
        
        
    }
}

// MARK: - VC Extensions for _ Food Truck Location Management
// Delegates to handle events for the location manager.
extension ViewController: CLLocationManagerDelegate {
    
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!
        print("Location: \(location)")
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: zoomLevel)
        
        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted:
            print("Location access was restricted.")
        case .denied:
            print("User denied access to location.")
            // Display the map using the default location.
            mapView.isHidden = false
        case .notDetermined:
            print("Location status not determined.")
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("Location status is OK.")
        }
    }

    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: This is the error: TJ\(error)")
    }
}

// MARK: -  VC Extension for _ Food Truck Map View Delegation
extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        guard let markerIndex = markerDictionary[marker] else { return true }
        let foodTruck = foodTrucks[markerIndex]
        if let selectedMarker = self.selectedMarker {
            selectedMarker.icon = GMSMarker.markerImage(with: .orange)
            self.selectedMarker = nil
        }
        
        selectedMarker = marker
        mapInfoView.isHidden = false
        mapInfoView.configure(with: foodTruck)
        marker.icon = GMSMarker.markerImage(with: .green)
        tableViewForCloseFoodTrucks.scrollToRow(at: IndexPath(row: markerIndex, section: 0), at: .top, animated: true)
        
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if let selectedMarker = self.selectedMarker {
            selectedMarker.icon = GMSMarker.markerImage(with: .orange)
            mapInfoView.isHidden = true
            self.selectedMarker = nil
        }
    }

    
}

