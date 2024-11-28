//
//  LocationManager.swift
//  SportAlert
//
//  Created by Keti Mandunga on 29.11.2024.
//

import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// ViewModel for handling location updates and notifications.
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var location: CLLocation?
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 60.2176, longitude: 24.8041),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @Published var savedLocations: [AlertLocation] = []
    @Published var currentLocationAlert: String? = nil

    override init() {
        super.init()
        setupLocationManager()
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
    }

    func requestPermission() {
        locationManager.requestAlwaysAuthorization()
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func setInitialRegion(center: CLLocationCoordinate2D, name: String) {
        region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        addLocation(AlertLocation(name: name, coordinate: center))
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default: break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        location = currentLocation
        region.center = currentLocation.coordinate
        checkProximityToSavedLocations(currentLocation)
    }

    private func checkProximityToSavedLocations(_ currentLocation: CLLocation) {
        let nearby = savedLocations.first { saved in
            currentLocation.distance(from: CLLocation(
                latitude: saved.coordinate.latitude,
                longitude: saved.coordinate.longitude
            )) <= 50
        }
        
        if let location = nearby {
            triggerNotification(for: location)
            DispatchQueue.main.async {
                self.currentLocationAlert = "You are near \(location.name)"
            }
        } else {
            DispatchQueue.main.async { self.currentLocationAlert = nil }
        }
    }

    private func triggerNotification(for location: AlertLocation) {
        let content = UNMutableNotificationContent()
        content.title = "SpotAlert"
        content.body = "You are near \(location.name)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        notificationCenter.add(request)
    }

    func addLocation(_ location: AlertLocation) {
        if !savedLocations.contains(location) {
            savedLocations.append(location)
        }
    }

    func removeLocation(_ location: AlertLocation) {
        savedLocations.removeAll { $0.id == location.id }
    }
}
