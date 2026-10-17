import ComposableArchitecture
import Foundation

enum RouteEndpoint: Equatable, Sendable { case origin, destination }

@Reducer
struct MapFeature {
    @ObservableState
    struct State: Equatable {
        var scene = MapScene.empty
        var usesGoogleMaps = false
        var message: String?
        var originQuery = ""
        var destinationQuery = ""
        var origin: PlaceSearchResult?
        var destination: PlaceSearchResult?
        var activeEndpoint: RouteEndpoint = .origin
        var searchResults: [PlaceSearchResult] = []
        var isSearching = false
        var isLoadingRoute = false
        var routeSummary: RouteSummary?
    }

    enum Action {
        case task
        case sdkChecked(GoogleMapsClient.Status)
        case queryChanged(RouteEndpoint, String)
        case searchSubmitted(RouteEndpoint)
        case searchResponse(TaskResult<[PlaceSearchResult]>)
        case placeSelected(PlaceSearchResult)
        case routeButtonTapped
        case routeResponse(TaskResult<RouteSummary>)
        case clear(RouteEndpoint)
    }

    @Dependency(\.googleMapsClient) var googleMapsClient
    @Dependency(\.placesClient) var placesClient
    @Dependency(\.routesClient) var routesClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                return .run { send in await send(.sdkChecked(await googleMapsClient.configure())) }

            case let .sdkChecked(status):
                state.usesGoogleMaps = status == .ready
                if status != .ready {
                    state.message = status == .missingAPIKey ? "Google Maps API 키가 필요합니다." : "Google Maps API 키를 확인해 주세요."
                }
                return .none

            case let .queryChanged(endpoint, query):
                state.activeEndpoint = endpoint
                if endpoint == .origin {
                    state.originQuery = query
                    state.origin = nil
                } else {
                    state.destinationQuery = query
                    state.destination = nil
                }
                state.searchResults = []
                state.scene.route = []
                state.routeSummary = nil
                return .none

            case let .searchSubmitted(endpoint):
                state.activeEndpoint = endpoint
                let rawQuery = endpoint == .origin ? state.originQuery : state.destinationQuery
                let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return .none }
                state.isSearching = true
                state.searchResults = []
                let center = state.scene.center
                return .run { send in
                    await send(.searchResponse(TaskResult { try await placesClient.search(query, center) }))
                }

            case let .searchResponse(.success(results)):
                state.isSearching = false
                state.searchResults = results
                state.message = results.isEmpty ? "검색 결과가 없습니다." : nil
                return .none

            case let .searchResponse(.failure(error)):
                state.isSearching = false
                state.message = error.localizedDescription
                return .none

            case let .placeSelected(place):
                if state.activeEndpoint == .origin {
                    state.origin = place
                    state.originQuery = place.name
                } else {
                    state.destination = place
                    state.destinationQuery = place.name
                }
                state.searchResults = []
                state.scene.places = [
                    state.origin.map { .init(id: UUID(), title: "출발", subtitle: "", coordinate: $0.coordinate, kind: .start) },
                    state.destination.map { .init(id: UUID(), title: "도착", subtitle: "", coordinate: $0.coordinate, kind: .destination) }
                ].compactMap { $0 }

                return .none

            case .routeButtonTapped:
                guard let origin = state.origin, let destination = state.destination else { return .none }
                state.isLoadingRoute = true
                state.message = "동선을 계산하고 있습니다."
                return .run { send in
                    await send(.routeResponse(TaskResult {
                        try await routesClient.walkingRoute(origin.coordinate, destination.coordinate)
                    }))
                }

            case let .routeResponse(.success(summary)):
                state.isLoadingRoute = false
                state.routeSummary = summary
                state.scene.route = summary.coordinates
                if let first = summary.coordinates.first, let last = summary.coordinates.last {
                    state.scene.center = .init(latitude: (first.latitude + last.latitude) / 2,
                                               longitude: (first.longitude + last.longitude) / 2)
                }
                let km = Double(summary.distanceMeters) / 1_000
                state.message = String(format: "도보 %.1f km · 약 %d분", km, max(1, summary.durationSeconds / 60))
                return .none

            case let .routeResponse(.failure(error)):
                state.isLoadingRoute = false
                state.message = "동선을 불러오지 못했습니다: \(error.localizedDescription)"
                return .none

            case let .clear(endpoint):
                if endpoint == .origin {
                    state.originQuery = ""; state.origin = nil
                } else {
                    state.destinationQuery = ""; state.destination = nil
                }
                state.searchResults = []
                state.scene.route = []
                state.scene.places = []
                state.routeSummary = nil
                state.message = nil
                return .none
            }
        }
    }
}
