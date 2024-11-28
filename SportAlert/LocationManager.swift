// LocationManager
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
        locationManager.distanceFilter = 10 // Notify every 10 meters
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
        
        // Automatically add initial location
        let initialLocation = AlertLocation(name: name, coordinate: center)
        addLocation(initialLocation)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.startMonitoringSignificantLocationChanges()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        
        location = currentLocation
        region = MKCoordinateRegion(
            center: currentLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        
        checkProximityToSavedLocations(currentLocation)
    }
    
    private func checkProximityToSavedLocations(_ currentLocation: CLLocation) {
        var nearestLocation: AlertLocation? = nil
        var minDistance = Double.infinity
        
        for location in savedLocations {
            let locationCoordinate = location.coordinate
            let savedLocation = CLLocation(latitude: locationCoordinate.latitude, 
                                           longitude: locationCoordinate.longitude)
            
            let distance = currentLocation.distance(from: savedLocation)
            
            if distance <= 50 { // Within 50 meters
                if distance < minDistance {
                    minDistance = distance
                    nearestLocation = location
                }
            }
        }
        
        if let nearestLocation = nearestLocation {
            triggerLocationNotification(for: nearestLocation)
            DispatchQueue.main.async {
                self.currentLocationAlert = "You are at \(nearestLocation.name)"
            }
        } else {
            DispatchQueue.main.async {
                self.currentLocationAlert = nil
            }
        }
    }
    
    private func triggerLocationNotification(for location: AlertLocation) {
        let content = UNMutableNotificationContent()
        content.title = "SpotAlert"
        content.body = "You have arrived at \(location.name)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString, 
            content: content, 
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func addLocation(_ location: AlertLocation) {
        savedLocations.append(location)
        
        // Create geofence region
        let region = CLCircularRegion(
            center: location.coordinate,
            radius: 50, // 50 meters
            identifier: location.id.uuidString
        )
        region.notifyOnEntry = true
        
        locationManager.startMonitoring(for: region)
    }
    
    func removeLocation(_ location: AlertLocation) {
        savedLocations.removeAll { $0.id == location.id }
        
        // Remove geofence monitoring
        locationManager.stopMonitoring(for: CLCircularRegion(
            center: location.coordinate,
            radius: 50,
            identifier: location.id.uuidString
        ))
    }
}
