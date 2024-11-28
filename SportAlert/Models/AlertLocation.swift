//
//  AlertLocation.swift
//  SportAlert
//
//  Created by Keti Mandunga on 29.11.2024.
//

import CoreLocation

// Model representing a location with an identifier, name, and coordinates.
struct AlertLocation: Identifiable, Hashable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D

    init(name: String, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.name = name
        self.coordinate = coordinate
    }

    // Equatable and Hashable conformance for comparison and set operations.
    static func == (lhs: AlertLocation, rhs: AlertLocation) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
    }
}
