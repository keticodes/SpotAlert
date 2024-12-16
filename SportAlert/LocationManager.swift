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
        // Starting point at Rautatientori (Helsinki Central Railway Station)
        center: CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
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
        sendNotification(title: "🗺️ New Location Saved", body: "📍 Location '\(location.name)' has been added to SpotAlert.")
    }
    
    func updateLocation(_ location: AlertLocation, newReminder: String) {
        if let index = savedLocations.firstIndex(where: { $0.id == location.id }) {
            // Create a new location with updated reminder
            let updatedLocation = AlertLocation(
                name: location.name,
                coordinate: location.coordinate,
                reminder: newReminder
            )
            savedLocations[index] = updatedLocation
            saveLocations()
            sendNotification(
                title: "🔄 Location Updated",
                body: "📍 Reminder for '\(location.name)' has been modified."
            )
        }
    }
    
    func removeLocation(_ location: AlertLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveLocations()
        sendNotification(title: "🗑️ Location Removed", body: "📍 Location '\(location.name)' has been deleted from SpotAlert.")
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
    
    // Focus map on a specific location
    func focusOnLocation(_ location: AlertLocation) {
        region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        sendNotification(
            title: "🗺️ Location Focused",
            body: "📍 Navigating to \(location.name)"
        )
    }
    func checkProximityToSavedLocations() {
            guard let currentLocation = locationManager.location else { return }
            
            for savedLocation in savedLocations {
                let location = CLLocation(latitude: savedLocation.coordinate.latitude, longitude: savedLocation.coordinate.longitude)
                let distance = currentLocation.distance(from: location)
                
                if distance <= 200 {
                    sendNotification(
                        title: "📍 Proximity Alert",
                        body: "You are within 200 meters of \(savedLocation.name)"
                    )
                }
            }
        }
}
