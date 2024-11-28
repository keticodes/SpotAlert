import SwiftUI
import MapKit
import CoreLocation
import UserNotifications

// AlertLocation Model
struct AlertLocation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    
    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.name = name
        self.coordinate = coordinate
    }
}
