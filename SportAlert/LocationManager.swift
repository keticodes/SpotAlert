import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

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
    
    private var lastNotificationTimestamp: [UUID: Date] = [:]

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

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
            locationManager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        location = currentLocation
        region.center = currentLocation.coordinate
        checkProximityToSavedLocations(currentLocation)
    }

    func addLocation(_ location: AlertLocation) {
        if !savedLocations.contains(location) {
            savedLocations.append(location)
            saveLocations()
        }
    }

    func removeLocation(_ location: AlertLocation) {
        savedLocations.removeAll { $0.id == location.id }
        saveLocations()
    }

    func saveLocations() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(savedLocations) {
            UserDefaults.standard.set(encoded, forKey: "savedLocations")
        }
    }

    func loadLocations() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: "savedLocations"),
           let decoded = try? decoder.decode([AlertLocation].self, from: data) {
            savedLocations = decoded
        }
    }

    private func checkProximityToSavedLocations(_ currentLocation: CLLocation) {
        let now = Date()
        let nearby = savedLocations.first { saved in
            let distance = currentLocation.distance(from: CLLocation(latitude: saved.coordinate.latitude, longitude: saved.coordinate.longitude))
            guard distance <= 50 else { return false }

            let lastTriggered = lastNotificationTimestamp[saved.id]
            if let lastTriggered = lastTriggered, now.timeIntervalSince(lastTriggered) < 300 {
                return false
            }
            lastNotificationTimestamp[saved.id] = now
            return true
        }
        
        if let location = nearby {
            triggerNotification(for: location)
            DispatchQueue.main.async { self.currentLocationAlert = "You are near \(location.name)" }
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

    func searchLocation(for query: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        let search = MKLocalSearch(request: request)
        search.start { response, error in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else {
                completion(nil)
                return
            }
            completion(coordinate)
        }
    }
}
