import ComposableArchitecture
import Foundation

struct RoutesClient: Sendable {
    var walkingRoute: @Sendable (_ origin: MapCoordinate, _ destination: MapCoordinate) async throws -> RouteSummary
}

extension RoutesClient: DependencyKey {
    static let liveValue = Self(walkingRoute: { origin, destination in
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
              !key.isEmpty, key != "YOUR_API_KEY" else { throw PlacesClient.ClientError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://routes.googleapis.com/directions/v2:computeRoutes")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(Bundle.main.bundleIdentifier ?? "sun.JICUR", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.setValue("routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline", forHTTPHeaderField: "X-Goog-FieldMask")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "origin": ["location": ["latLng": ["latitude": origin.latitude, "longitude": origin.longitude]]],
            "destination": ["location": ["latLng": ["latitude": destination.latitude, "longitude": destination.longitude]]],
            "travelMode": "WALK",
            "polylineQuality": "HIGH_QUALITY",
            "languageCode": "ko",
            "units": "METRIC"
        ])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw PlacesClient.ClientError.invalidResponse }
        let payload = try JSONDecoder().decode(RoutesResponse.self, from: data)
        guard let route = payload.routes.first else { throw PlacesClient.ClientError.invalidResponse }
        return RouteSummary(coordinates: decodePolyline(route.polyline.encodedPolyline),
                            distanceMeters: route.distanceMeters,
                            durationSeconds: Int(route.duration.dropLast()) ?? 0)
    })
    static let testValue = Self(walkingRoute: { origin, destination in
        .init(coordinates: [origin, destination], distanceMeters: 0, durationSeconds: 0)
    })
}

private struct RoutesResponse: Decodable {
    struct Route: Decodable {
        struct Polyline: Decodable { var encodedPolyline: String }
        var duration: String; var distanceMeters: Int; var polyline: Polyline
    }
    var routes: [Route]
}

nonisolated private func decodePolyline(_ encoded: String) -> [MapCoordinate] {
    let bytes = Array(encoded.utf8); var index = 0; var latitude = 0; var longitude = 0; var result: [MapCoordinate] = []
    func nextValue() -> Int? {
        var value = 0; var shift = 0
        while index < bytes.count {
            let byte = Int(bytes[index]) - 63; index += 1
            value |= (byte & 0x1f) << shift; shift += 5
            if byte < 0x20 { return (value & 1) != 0 ? ~(value >> 1) : value >> 1 }
        }
        return nil
    }
    while let latitudeDelta = nextValue(), let longitudeDelta = nextValue() {
        latitude += latitudeDelta; longitude += longitudeDelta
        result.append(.init(latitude: Double(latitude) / 100_000, longitude: Double(longitude) / 100_000))
    }
    return result
}

extension DependencyValues {
    var routesClient: RoutesClient {
        get { self[RoutesClient.self] }
        set { self[RoutesClient.self] = newValue }
    }
}
