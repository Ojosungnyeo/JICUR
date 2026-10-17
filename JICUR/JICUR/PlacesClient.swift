import ComposableArchitecture
import Foundation

struct PlacesClient: Sendable {
    enum ClientError: LocalizedError {
        case missingAPIKey, invalidResponse
        var errorDescription: String? {
            switch self {
            case .missingAPIKey: "Google Maps API 키가 필요합니다."
            case .invalidResponse: "장소 검색 응답을 읽지 못했습니다."
            }
        }
    }

    var search: @Sendable (_ query: String, _ center: MapCoordinate) async throws -> [PlaceSearchResult]
}

extension PlacesClient: DependencyKey {
    static let liveValue = Self(search: { query, _ in
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
              !key.isEmpty, key != "YOUR_API_KEY" else { throw ClientError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://places.googleapis.com/v1/places:searchText")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(Bundle.main.bundleIdentifier ?? "sun.JICUR", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        request.setValue("places.id,places.displayName,places.formattedAddress,places.location", forHTTPHeaderField: "X-Goog-FieldMask")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "textQuery": query,
            "languageCode": "ko",
            "regionCode": "KR",
            "maxResultCount": 8
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else { throw ClientError.invalidResponse }
        let payload = try JSONDecoder().decode(SearchResponse.self, from: data)
        return payload.places.map {
            PlaceSearchResult(id: $0.id, name: $0.displayName.text, address: $0.formattedAddress,
                              coordinate: .init(latitude: $0.location.latitude, longitude: $0.location.longitude))
        }
    })
    static let testValue = Self(search: { _, _ in [] })
}

private struct SearchResponse: Decodable {
    struct Place: Decodable {
        struct DisplayName: Decodable { var text: String }
        struct Location: Decodable { var latitude: Double; var longitude: Double }
        var id: String; var displayName: DisplayName; var formattedAddress: String; var location: Location
    }
    var places: [Place]
}

extension DependencyValues {
    var placesClient: PlacesClient {
        get { self[PlacesClient.self] }
        set { self[PlacesClient.self] = newValue }
    }
}
