import Foundation

struct MapCoordinate: Equatable, Sendable {
    var latitude: Double
    var longitude: Double
}

struct MapPlace: Equatable, Identifiable, Sendable {
    enum Kind: Equatable, Sendable { case start, forest, rest, destination }
    let id: UUID
    var title: String
    var subtitle: String
    var coordinate: MapCoordinate
    var kind: Kind
}

struct PlaceSearchResult: Equatable, Identifiable, Sendable {
    var id: String
    var name: String
    var address: String
    var coordinate: MapCoordinate
}

struct RouteSummary: Equatable, Sendable {
    var coordinates: [MapCoordinate]
    var distanceMeters: Int
    var durationSeconds: Int
}

struct MapScene: Equatable, Sendable {
    var center: MapCoordinate
    var zoom: Float
    var route: [MapCoordinate]
    var places: [MapPlace]

    static let empty = Self(
        center: .init(latitude: 37.5665, longitude: 126.9780),
        zoom: 16,
        route: [],
        places: []
    )
}
