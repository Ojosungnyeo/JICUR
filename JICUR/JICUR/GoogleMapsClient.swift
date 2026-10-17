import ComposableArchitecture
import Foundation
import GoogleMaps

struct GoogleMapsClient: Sendable {
    enum Status: Equatable, Sendable { case ready, missingAPIKey, rejectedAPIKey }
    var configure: @Sendable () async -> Status
}

extension GoogleMapsClient: DependencyKey {
    static let liveValue = Self(configure: {
        await MainActor.run {
            guard let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
                  !key.isEmpty, key != "YOUR_API_KEY" else { return .missingAPIKey }
            return GMSServices.provideAPIKey(key) ? .ready : .rejectedAPIKey
        }
    })
    static let testValue = Self(configure: { .missingAPIKey })
}

extension DependencyValues {
    var googleMapsClient: GoogleMapsClient {
        get { self[GoogleMapsClient.self] }
        set { self[GoogleMapsClient.self] = newValue }
    }
}
