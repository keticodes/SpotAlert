//
//  LocationManager.swift
//  SpotAlert
//
//  Created by Keti Mandunga on 11.11.2024.
//

import SwiftUI
import CoreLocation
import MapKit
import UserNotifications

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    @Published var savedLocations: [AlertLocation] = []
    @Published var currentLocationAlert: String?
    
    override init() {
        super.init()
        setupLocationManager()
        requestNotificationPermissions()
        loadLocations()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private func requestNotificationPermissions() {
        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permissions granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func searchLocation(for query: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(nil)
                return
            }
            completion(location.coordinate)
        }
    }
    
    func addLocation(_ location: AlertLocation) {
        savedLocations.append(location)
        saveLocations()
        sendNotification(title: "New Location Saved", body: "Location '\(location.name)' has been added to SpotAlert.")
    }
    
    func removeLocation(_ location: AlertLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveLocations()
        sendNotification(title: "Location Removed", body: "Location '\(location.name)' has been deleted from SpotAlert.")
    }
    
    private func saveLocations() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: "SavedLocations")
        }
    }
    
    func loadLocations() {
        if let savedLocationsData = UserDefaults.standard.object(forKey: "SavedLocations") as? Data {
            let decoder = JSONDecoder()
            if let loadedLocations = try? decoder.decode([AlertLocation].self, from: savedLocationsData) {
                savedLocations = loadedLocations
            }
        }
    }
    
    func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            }
        }
    }
    
    // Location monitoring methods
    func startMonitoringLocation(_ location: AlertLocation) {
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 100, // 100 meters
            identifier: location.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
        sendNotification(title: "Location Monitoring", body: "Now tracking \(location.name)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        sendNotification(title: "Location Entered", body: "You've arrived near \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        sendNotification(title: "Location Exited", body: "You've left the area of \(region.identifier)")
    }
}
