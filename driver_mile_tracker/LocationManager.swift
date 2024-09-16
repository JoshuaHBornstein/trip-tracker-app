//
//  LocationManager.swift
//  driver_mile_tracker
//
//  Created by Josh Bornstein on 9/11/24.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    
    @Published var location: CLLocation? // Publishes location updates to the view
    @Published var totalDistance: Double = 0.0 // Tracks the total distance in meters
    
    private var previousLocation: CLLocation? // To store the previous location for calculating distance
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        self.locationManager.startUpdatingLocation()
    }
    
    func stopTracking() {
        self.locationManager.stopUpdatingLocation()
    }
    
    func requestAuthorization() {
        self.locationManager.requestWhenInUseAuthorization()
    }
        
    func getTripStartTime() -> Date? {
        return previousLocation?.timestamp
    }
    
    // CLLocationManagerDelegate function to handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        if let previous = previousLocation {
            let distance = previous.distance(from: newLocation)
            totalDistance += distance / 1609.34 // conversion
        }
        
        previousLocation = newLocation
        location = newLocation
    }
}

