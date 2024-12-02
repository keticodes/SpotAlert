import CoreLocation

struct AlertLocation: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    let reminder: String

    init(name: String, coordinate: CLLocationCoordinate2D, reminder: String = "") {
        self.id = UUID()
        self.name = name
        self.coordinate = coordinate
        self.reminder = reminder
    }

    enum CodingKeys: String, CodingKey {
        case id, name, latitude, longitude, reminder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        reminder = try container.decode(String.self, forKey: .reminder)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(reminder, forKey: .reminder)
    }

    // Custom Equatable conformance
    static func == (lhs: AlertLocation, rhs: AlertLocation) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude &&
        lhs.reminder == rhs.reminder
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(coordinate.latitude)
        hasher.combine(coordinate.longitude)
        hasher.combine(reminder)
    }
}
